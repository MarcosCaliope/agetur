require 'test_helper'

class ServiceOrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @service_order = service_orders(:one)
  end

  test "should get index" do
    get service_orders_url
    assert_response :success
  end

  test "should get new" do
    get new_service_order_url
    assert_response :success
  end

  test "should create service_order" do
    assert_difference('ServiceOrder.count') do
      post service_orders_url, params: { service_order: { bcancelado: @service_order.bcancelado, bpagto: @service_order.bpagto, data: @service_order.data, destination_id: @service_order.destination_id, driver_id: @service_order.driver_id, ibloqueio: @service_order.ibloqueio, icapacidade: @service_order.icapacidade, iflgaberto: @service_order.iflgaberto, ilitros: @service_order.ilitros, sobservacoes: @service_order.sobservacoes, sodometrofim: @service_order.sodometrofim, sodometroinicio: @service_order.sodometroinicio, tourguide_id: @service_order.tourguide_id, valorcombustivel: @service_order.valorcombustivel, valordespesas: @service_order.valordespesas, valorfinalos: @service_order.valorfinalos, valorguia: @service_order.valorguia, valormotorista: @service_order.valormotorista, valoros: @service_order.valoros, valorpedagio: @service_order.valorpedagio, vehicle_id: @service_order.vehicle_id } }
    end

    assert_redirected_to service_order_url(ServiceOrder.last)
  end

  test "should show service_order" do
    get service_order_url(@service_order)
    assert_response :success
  end

  test "should get edit" do
    get edit_service_order_url(@service_order)
    assert_response :success
  end

  test "should update service_order" do
    patch service_order_url(@service_order), params: { service_order: { bcancelado: @service_order.bcancelado, bpagto: @service_order.bpagto, data: @service_order.data, destination_id: @service_order.destination_id, driver_id: @service_order.driver_id, ibloqueio: @service_order.ibloqueio, icapacidade: @service_order.icapacidade, iflgaberto: @service_order.iflgaberto, ilitros: @service_order.ilitros, sobservacoes: @service_order.sobservacoes, sodometrofim: @service_order.sodometrofim, sodometroinicio: @service_order.sodometroinicio, tourguide_id: @service_order.tourguide_id, valorcombustivel: @service_order.valorcombustivel, valordespesas: @service_order.valordespesas, valorfinalos: @service_order.valorfinalos, valorguia: @service_order.valorguia, valormotorista: @service_order.valormotorista, valoros: @service_order.valoros, valorpedagio: @service_order.valorpedagio, vehicle_id: @service_order.vehicle_id } }
    assert_redirected_to service_order_url(@service_order)
  end

  test "should destroy service_order" do
    assert_difference('ServiceOrder.count', -1) do
      delete service_order_url(@service_order)
    end

    assert_redirected_to service_orders_url
  end
end
