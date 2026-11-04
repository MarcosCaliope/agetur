require 'test_helper'

class SorderItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @sorder_item = sorder_items(:one)
  end

  test "should get index" do
    get sorder_items_url
    assert_response :success
  end

  test "should get commission report" do
    get showcomis_url
    assert_response :success
  end

  test "should filter commission report by vendor and inclusive date range" do
    sorder = sorders(:two)
    hoje = sorder.sorder_items.create!(vendor: vendors(:one), snomepax: "Hoje", amountcomission: 30, amountcomissionpay: 10)
    sorder.sorder_items.create!(vendor: vendors(:two), snomepax: "Outro Vendedor", amountcomission: 5)
    sorder.sorder_items.create!(vendor: vendors(:one), snomepax: "Mes Passado", created_at: 1.month.ago)

    dia = Date.current.iso8601
    get showcomis_url, params: { q: { vendor_id_eq: vendors(:one).id, created_at_gteq: dia, created_at_lteq: dia } }
    assert_response :success
    assert_select "td", text: hoje.snomepax
    assert_select "td", text: "20.0"
    assert_select "td", text: "Outro Vendedor", count: 0
    assert_select "td", text: "Mes Passado", count: 0
  end

  test "should get new" do
    get new_sorder_item_url
    assert_response :success
  end

  test "should create sorder_item" do
    assert_difference('SorderItem.count') do
      post sorder_items_url, params: { sorder_item: { comments: @sorder_item.comments, sorder_id: @sorder_item.sorder_id } }
    end

    assert_redirected_to sorder_item_url(SorderItem.last)
  end

  test "should show sorder_item" do
    get sorder_item_url(@sorder_item)
    assert_response :success
  end

  test "should get edit" do
    get edit_sorder_item_url(@sorder_item)
    assert_response :success
  end

  test "should update sorder_item" do
    patch sorder_item_url(@sorder_item), params: { sorder_item: { comments: @sorder_item.comments, sorder_id: @sorder_item.sorder_id } }
    assert_redirected_to sorder_item_url(@sorder_item)
  end

  test "should destroy sorder_item" do
    assert_difference('SorderItem.count', -1) do
      delete sorder_item_url(@sorder_item)
    end

    assert_redirected_to sorder_items_url
  end

  test "a cancelled passenger is brought back into its order" do
    @sorder_item.update!(scancelado: "S")

    patch reativar_sorder_item_url(@sorder_item)

    assert_redirected_to sorder_url(@sorder_item.sorder)
    assert_not @sorder_item.reload.cancelado?
  end

  test "a passenger with payments can't be deleted for good, nor anything in a closed order" do
    @sorder_item.update!(amount: 100)
    @sorder_item.pagamentos.create!(data: Date.current, valor: 30, forma_pagamento: "D")
    assert_no_difference("SorderItem.count") { delete sorder_item_url(@sorder_item) }
    assert_match "cancele-o em vez de excluir", flash[:alert]

    outro = sorder_items(:two)
    outro.update!(scancelado: "S")
    outro.sorder.update!(encerrada: true)
    assert_no_difference("SorderItem.count") { delete sorder_item_url(outro) }
    patch reativar_sorder_item_url(outro)
    assert outro.reload.cancelado?
    assert_redirected_to sorder_url(outro.sorder)
  end
  test "a passenger is transferred or copied to another order from the order's page" do
    destino = sorders(:one)
    get sorder_url(@sorder_item.sorder)
    assert_select "a[title='Transferir / copiar para outra OS'] i.fa-exchange"

    get movimentar_sorder_item_url(@sorder_item)
    assert_response :success
    assert_select "button", text: "Transferir"
    assert_select "button[formaction='#{copiar_sorder_item_path(@sorder_item)}']", text: "Copiar"

    assert_difference("SorderItem.count") { post copiar_sorder_item_url(@sorder_item), params: { destino_id: destino.id } }
    assert_redirected_to sorder_url(destino)

    post transferir_sorder_item_url(@sorder_item), params: { destino_id: destino.id }
    assert_redirected_to sorder_url(destino)
    assert_equal destino.id, @sorder_item.reload.sorder_id

    get historico_sorder_url(destino)
    assert_select "td", text: "Transferiu"
    assert_select "li", text: /Ordem de serviço: .*\(#{sorders(:two).id}\) → .*\(#{destino.id}\)/
  end

  test "the typed order is described, with why it can't take the passenger" do
    destino = sorders(:one)
    get movimentar_sorder_item_url(@sorder_item), params: { destino_id: destino.id }, xhr: true
    assert_response :success
    assert_select "div.alert-info[data-descricao=?]", "OS nº #{destino.id} — 02/07/2021 13:25 — #{destino.destination.description}"
    assert_match "Guia: #{destino.tourguide.sname}", response.body
    assert_no_match "<html", response.body

    get movimentar_sorder_item_url(@sorder_item), params: { destino_id: @sorder_item.sorder_id }, xhr: true
    assert_select "div.alert-warning", text: /É a OS atual do passageiro/

    get movimentar_sorder_item_url(@sorder_item), params: { destino_id: 0 }, xhr: true
    assert_select "div.alert-warning", text: "OS nº 0 não encontrada."

    get movimentar_sorder_item_url(@sorder_item), params: { destino_id: destino.id }
    assert_select "#destino-movimentacao div.alert-info"
    assert_select "button[data-confirm=?]", "Transferir #{@sorder_item.nome_passageiro} para a OS nº #{destino.id} — 02/07/2021 13:25 — #{destino.destination.description}?"
  end

  test "a transfer to a missing order goes back to the form with the error" do
    post transferir_sorder_item_url(@sorder_item), params: { destino_id: 0 }

    assert_redirected_to movimentar_sorder_item_url(@sorder_item, destino_id: 0)
    assert_equal "OS de destino não encontrada.", flash[:alert]
    assert_equal sorders(:two).id, @sorder_item.reload.sorder_id
  end
end
