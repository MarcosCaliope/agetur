require 'test_helper'

class PesquisaCadastrosTest < ActionDispatch::IntegrationTest
  LISTAS = {
    customers: Customer, agencies: Agency, hotels: Hotel, vendors: Vendor, tourguides: Tourguide,
    drivers: Driver, vehicles: Vehicle, destinations: Destination, companies: Company
  }.freeze

  setup { sign_in users(:one) }

  test "every cadastro list has the search box and a code column" do
    LISTAS.each_key do |lista|
      get public_send("#{lista}_path")
      assert_select "form[role=search] input[name=busca]", 1, "#{lista} should have a search box"
      assert_select "thead th", { text: "Código" }, "#{lista} should show the code"
    end
  end

  test "searching narrows the list, shows the count and offers to clear" do
    Agency.create!(sname: "CEARÁ ROTAS")
    get agencies_path, params: { busca: "ceara" }
    assert_select "tbody tr", 1
    assert_select "tbody td", text: "CEARÁ ROTAS"
    assert_select "form[role=search] .text-muted", text: /1 registro encontrado para "ceara"/
    assert_select "form[role=search] a[href=?]", agencies_path, text: "Limpar"
    assert_select "input[name=busca][value=ceara]"
  end

  test "searching by code finds the record" do
    vendedor = Vendor.create!(sname: "ALEX TURISMO", sistger_id: 2348)
    get vendors_path, params: { busca: vendedor.id.to_s }
    assert_select "tbody td", text: "ALEX TURISMO"
    get vendors_path, params: { busca: "2348" }
    assert_select "tbody td", text: "ALEX TURISMO"
  end

  test "the hotel PDF follows the search" do
    Hotel.create!(sname: "POUSADA SERRA")
    get hotels_path, params: { busca: "serra" }
    assert_select "a[href=?]", hotels_path(busca: "serra", format: "pdf")
  end
end
