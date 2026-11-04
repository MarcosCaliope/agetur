require "application_system_test_case"

# Transferir / copiar: movimentar_passageiro.js describes the typed order.
class MovimentarPassageiroTest < ApplicationSystemTestCase
  setup do
    @item = sorders(:two).sorder_items.create!(snomepax: "Maria")
    @destino = sorders(:one)
    sign_in users(:one)
  end

  test "typing the order number shows which order gets the passenger, and the transfer asks naming it" do
    visit movimentar_sorder_item_path(@item)
    descricao = "OS nº #{@destino.id} — 02/07/2021 13:25 — #{@destino.destination.description}"

    fill_in "Nº da OS de destino", with: @destino.id
    assert_selector "#destino-movimentacao .alert-info", text: descricao

    fill_in "Nº da OS de destino", with: "999999"
    assert_selector "#destino-movimentacao .alert-warning", text: "OS nº 999999 não encontrada."

    fill_in "Nº da OS de destino", with: @destino.id
    assert_selector "#destino-movimentacao .alert-info", text: descricao
    mensagem = accept_confirm { click_on "Transferir" }
    assert_equal "Transferir Maria para a #{descricao}?", mensagem
    assert_text "transferido da OS nº #{sorders(:two).id}"
    assert_equal @destino.id, @item.reload.sorder_id
  end
end
