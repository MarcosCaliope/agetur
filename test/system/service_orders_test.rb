require "application_system_test_case"

class ServiceOrdersTest < ApplicationSystemTestCase
  setup do
    @service_order = service_orders(:one)
  end

  test "visiting the index" do
    visit service_orders_url
    assert_selector "h1", text: "Service Orders"
  end

  test "creating a Service order" do
    visit service_orders_url
    click_on "New Service Order"

    check "Bcancelado" if @service_order.bcancelado
    check "Bpagto" if @service_order.bpagto
    fill_in "Data", with: @service_order.data
    fill_in "Destination", with: @service_order.destination_id
    fill_in "Driver", with: @service_order.driver_id
    fill_in "Ibloqueio", with: @service_order.ibloqueio
    fill_in "Icapacidade", with: @service_order.icapacidade
    fill_in "Iflgaberto", with: @service_order.iflgaberto
    fill_in "Ilitros", with: @service_order.ilitros
    fill_in "Sobservacoes", with: @service_order.sobservacoes
    fill_in "Sodometrofim", with: @service_order.sodometrofim
    fill_in "Sodometroinicio", with: @service_order.sodometroinicio
    fill_in "Tourguide", with: @service_order.tourguide_id
    fill_in "Valorcombustivel", with: @service_order.valorcombustivel
    fill_in "Valordespesas", with: @service_order.valordespesas
    fill_in "Valorfinalos", with: @service_order.valorfinalos
    fill_in "Valorguia", with: @service_order.valorguia
    fill_in "Valormotorista", with: @service_order.valormotorista
    fill_in "Valoros", with: @service_order.valoros
    fill_in "Valorpedagio", with: @service_order.valorpedagio
    fill_in "Vehicle", with: @service_order.vehicle_id
    click_on "Create Service order"

    assert_text "Service order was successfully created"
    click_on "Back"
  end

  test "updating a Service order" do
    visit service_orders_url
    click_on "Edit", match: :first

    check "Bcancelado" if @service_order.bcancelado
    check "Bpagto" if @service_order.bpagto
    fill_in "Data", with: @service_order.data
    fill_in "Destination", with: @service_order.destination_id
    fill_in "Driver", with: @service_order.driver_id
    fill_in "Ibloqueio", with: @service_order.ibloqueio
    fill_in "Icapacidade", with: @service_order.icapacidade
    fill_in "Iflgaberto", with: @service_order.iflgaberto
    fill_in "Ilitros", with: @service_order.ilitros
    fill_in "Sobservacoes", with: @service_order.sobservacoes
    fill_in "Sodometrofim", with: @service_order.sodometrofim
    fill_in "Sodometroinicio", with: @service_order.sodometroinicio
    fill_in "Tourguide", with: @service_order.tourguide_id
    fill_in "Valorcombustivel", with: @service_order.valorcombustivel
    fill_in "Valordespesas", with: @service_order.valordespesas
    fill_in "Valorfinalos", with: @service_order.valorfinalos
    fill_in "Valorguia", with: @service_order.valorguia
    fill_in "Valormotorista", with: @service_order.valormotorista
    fill_in "Valoros", with: @service_order.valoros
    fill_in "Valorpedagio", with: @service_order.valorpedagio
    fill_in "Vehicle", with: @service_order.vehicle_id
    click_on "Update Service order"

    assert_text "Service order was successfully updated"
    click_on "Back"
  end

  test "destroying a Service order" do
    visit service_orders_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Service order was successfully destroyed"
  end
end
