require 'test_helper'

class Site::WelcomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get site_welcome_index_url
    assert_response :success
  end

  test "logged out visitors see only the sign in card, no figures" do
    get root_url
    assert_select "a[href=?]", new_user_session_path, text: "Entrar"
    assert_select ".dashboard-tabs", count: 0
    assert_select ".dashboard-total", count: 0
  end

  test "dashboard has the three tabs" do
    sign_in users(:one)
    get root_url
    assert_select ".dashboard-tabs a[data-toggle=tab]", 3
    assert_select ".dashboard-tabs a[href='#cadastros']", text: "Cadastros"
    assert_select ".dashboard-tabs a[href='#processos']", text: "Processos"
    assert_select ".dashboard-tabs a[href='#relatorios']", text: "Relatórios"
  end

  test "cadastros tab links to every cadastro with its count" do
    sign_in users(:one)
    get root_url
    {
      "Clientes" => [customers_path, Customer], "Agências" => [agencies_path, Agency],
      "Hotéis" => [hotels_path, Hotel], "Vendedores" => [vendors_path, Vendor],
      "Veículos" => [vehicles_path, Vehicle], "Motoristas" => [drivers_path, Driver],
      "Guias" => [tourguides_path, Tourguide], "Roteiros" => [destinations_path, Destination],
      "Empresa" => [companies_path, Company]
    }.each do |nome, (path, model)|
      assert_select "#cadastros .card", text: /#{nome}/ do
        assert_select ".dashboard-total", text: model.count.to_s
        assert_select "a[href=?]", path, text: "Abrir"
      end
    end
  end

  test "processos tab counts service orders by date" do
    sign_in users(:one)
    base = sorders(:one)
    attrs = base.attributes.slice("destination_id", "tourguide_id", "driver_id", "vehicle_id", "company_id")
    Sorder.create!(attrs.merge("data" => Time.zone.now))
    Sorder.create!(attrs.merge("data" => 3.days.from_now))
    get root_url
    assert_select "#processos .card", text: /Ordem de Serviço/ do
      assert_select ".dashboard-total", text: "1"                      # hoje
      assert_select ".dashboard-total", text: Sorder.count.to_s         # total
      assert_select "a[href=?]", new_sorder_path, text: "Nova ordem"
    end
    assert_select "#processos a[href=?]", txt_path
  end

  test "relatorios tab shows commission still to receive, ignoring cancelled passengers" do
    sign_in users(:one)
    sorder = sorders(:two)
    sorder.sorder_items.create!(amountcomission: 30, amountcomissionpay: 10, scancelado: "N")
    sorder.sorder_items.create!(amountcomission: 50, scancelado: "S")
    get root_url
    assert_select "#relatorios .dashboard-total", text: "R$ 20,00"
    assert_select "#relatorios a[href=?]", showcomis_path
  end
end
