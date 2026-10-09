require 'test_helper'

class SordersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @sorder = sorders(:one)
  end

  test "should get index" do
    get sorders_url
    assert_response :success
  end

  test "should get new" do
    get new_sorder_url
    assert_response :success
  end

  test "should create sorder" do
    assert_difference('Sorder.count') do
      post sorders_url, params: { sorder: { data: @sorder.data, sobservacoes: @sorder.sobservacoes,
        destination_id: @sorder.destination_id, tourguide_id: @sorder.tourguide_id,
        driver_id: @sorder.driver_id, vehicle_id: @sorder.vehicle_id, company_id: @sorder.company_id } }
    end

    assert_redirected_to sorder_url(Sorder.last)
  end

  test "should show sorder" do
    get sorder_url(@sorder)
    assert_response :success
  end

  test "should filter sorders by destination" do
    get sorders_url, params: { q: { destination_id_eq: destinations(:one).id } }
    assert_response :success
    assert_select "tbody tr", count: 0
    get sorders_url, params: { q: { destination_id_eq: destinations(:two).id, data_gteq: "2021-07-01", data_lteq: "2021-07-03" } }
    assert_select "tbody tr", count: Sorder.count
  end

  test "should create sorder with commission fields on passengers" do
    assert_difference('SorderItem.count') do
      post sorders_url, params: { sorder: { data: @sorder.data, destination_id: @sorder.destination_id, tourguide_id: @sorder.tourguide_id,
        driver_id: @sorder.driver_id, vehicle_id: @sorder.vehicle_id, company_id: @sorder.company_id,
        sorder_items_attributes: { "0" => { snomepax: "Maria", qtdepax: 2, amount: 100, amountpay: 40, vendor_id: vendors(:one).id,
          amountcomission: 30, amountcomissionpay: 10, amountcomissionrep: 5, amountcomissionreppay: 2, scancelado: "N" } } } }
    end
    item = Sorder.last.sorder_items.first
    assert_equal ["Maria", 10.0, 5.0, 2.0, "N"], [item.snomepax, item.amountcomissionpay, item.amountcomissionrep, item.amountcomissionreppay, item.scancelado]
  end

  test "should save the pax list of a passenger and show it on the order and its PDF" do
    patch sorder_url(@sorder), params: { sorder: { sorder_items_attributes: { "0" => { snomepax: "Titular", qtdepax: 3,
      companions_attributes: { "0" => { snome: "Ana", documenttype: "RG", document: "123", chd: "1", colo: "0" },
                               "1" => { snome: "", documenttype: "", chd: "0", colo: "0" } } } } } }
    item = @sorder.sorder_items.find_by!(snomepax: "Titular")
    assert_equal ["Ana (RG 123, CHD)"], item.companions.map(&:descricao), "a row without a name is ignored"

    get edit_sorder_url(@sorder)
    assert_select "input[value=Ana]"
    get sorder_url(@sorder)
    assert_select "td", text: /Lista pax: Ana \(RG 123, CHD\)/
    get export_sorder_url(@sorder)
    assert_response :success

    companion = item.companions.first
    patch sorder_url(@sorder), params: { sorder: { sorder_items_attributes: { "0" => { id: item.id,
      companions_attributes: { "0" => { id: companion.id, _destroy: "1" } } } } } }
    assert_empty item.companions.reload
  end

  test "should hide cancelled passengers and show totals" do
    @sorder.sorder_items.create!(snomepax: "Ativo", qtdepax: 2, scancelado: "N")
    @sorder.sorder_items.create!(snomepax: "Desistiu", qtdepax: 3, scancelado: "S")
    get sorder_url(@sorder)
    assert_select "td", text: "Ativo"
    assert_select "td", text: "Desistiu", count: 0
    assert_match "Total de PAX:</strong> 2", response.body
  end

  test "should show sorder when its company has no logo" do
    @sorder.company.update!(logoform: nil)
    get sorder_url(@sorder)
    assert_response :success
  end

  test "should export sorder as pdf" do
    get export_sorder_url(sorders(:two))
    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert response.body.start_with?("%PDF")
  end

  test "order form offers only active vendors, plus inactive ones already on the order" do
    ativo, inativo, usado = vendors(:one), vendors(:two), Vendor.create!(sname: "USADO", active: false)
    ativo.update!(sname: "ATIVO")
    inativo.update!(sname: "INATIVO", active: false)
    item = @sorder.sorder_items.create!
    item.update_column(:vendor_id, usado.id)

    get edit_sorder_url(@sorder)
    vendedores = css_select("select[name$='[vendor_id]']").first.css("option").map(&:text)
    assert_includes vendedores, "ATIVO"
    assert_includes vendedores, "USADO"
    assert_not_includes vendedores, "INATIVO"
  end

  test "should refuse an inactive vendor on a new passenger" do
    assert_no_difference("Sorder.count") { refuse_inactive_vendor }
  end

  def refuse_inactive_vendor
    inativo = vendors(:two).tap { |v| v.update!(active: false) }
    post sorders_url, params: { sorder: { data: @sorder.data, destination_id: @sorder.destination_id, tourguide_id: @sorder.tourguide_id,
      driver_id: @sorder.driver_id, vehicle_id: @sorder.vehicle_id, company_id: @sorder.company_id,
      sorder_items_attributes: { "0" => { snomepax: "X", vendor_id: inativo.id } } } }
    assert_select "#error_explanation li", text: "Vendedor do passageiro está inativo"
  end

  test "should get edit" do
    get edit_sorder_url(@sorder)
    assert_response :success
    assert_select "a[href=?]", export_sorder_path(@sorder), text: "Exportar PDF"
  end

  test "should not link to export on new" do
    get new_sorder_url
    assert_select "a", text: "Exportar PDF", count: 0
  end

  test "should update sorder" do
    patch sorder_url(@sorder), params: { sorder: { data: @sorder.data, sobservacoes: @sorder.sobservacoes } }
    assert_redirected_to sorder_url(@sorder)
  end

  test "should confirm actions with Portuguese messages" do
    patch sorder_url(@sorder), params: { sorder: { sobservacoes: "editado" } }
    follow_redirect!
    assert_select ".alert-success", text: "Ordem de serviço atualizada com sucesso."
  end

  test "should show validation errors in Portuguese" do
    post sorders_url, params: { sorder: { sobservacoes: "sem dados" } }
    assert_select "#error_explanation h2", text: "Não foi possível gravar ordem de serviço: 5 erros"
    assert_select "#error_explanation li", text: "Roteiro é obrigatório(a)"
    assert_select "input[type=submit][value=?]", "Criar Ordem de serviço"
  end

  test "closing an order makes its bills and blocks changes until reopened" do
    @sorder.update!(valorguia: 50)
    assert_difference("Payable.count") { patch encerrar_sorder_url(@sorder) }
    follow_redirect!
    assert_select ".alert-success", text: "Ordem de serviço encerrada. 1 conta(s) a pagar gerada(s)."
    assert_select "a", text: "[Reabrir OS]"

    get edit_sorder_url(@sorder)
    assert_redirected_to sorder_url(@sorder)
    patch sorder_url(@sorder), params: { sorder: { sobservacoes: "mudou" } }
    assert_not_equal "mudou", @sorder.reload.sobservacoes

    assert_difference("Payable.count", -1) { patch reabrir_sorder_url(@sorder) }
    assert_not @sorder.reload.encerrada?
  end

  test "saving an order brings in the passengers booked for its destination and date" do
    @sorder.update!(data: Time.zone.local(2026, 11, 5, 8))
    booking = Booking.create!(data: Date.current, snome: "Agendada", vendor: vendors(:one))
    booking.items.create!(destination: @sorder.destination, data_passeio: Date.new(2026, 11, 5), valor: 50)

    patch sorder_url(@sorder), params: { sorder: { sorder_items_attributes: { "0" => { snomepax: "Digitado", qtdepax: 1 } } } }
    follow_redirect!
    assert_select ".alert-success", text: "Ordem de serviço atualizada com sucesso. Agendados incluídos: Agendada."
    assert_equal %w[Agendada Digitado], @sorder.sorder_items.order(:snomepax).pluck(:snomepax)
  end

  test "should destroy sorder" do
    assert_difference('Sorder.count', -1) do
      delete sorder_url(@sorder)
    end

    assert_redirected_to sorders_url
  end
end
