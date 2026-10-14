require 'test_helper'

# Each user sees and creates only their company's data (DaEmpresa); an admin,
# or a user allowed every company, works in the company picked in the header.
class EmpresasTest < ActionDispatch::IntegrationTest
  setup do
    @outra = companies(:one)
    @hotel_da_outra = Hotel.create!(sname: "HOTEL DA OUTRA EMPRESA", company: @outra)
  end

  test "lists only the user's company records" do
    sign_in users(:one)
    get hotels_url
    assert_response :success
    assert_select "td", text: hotels(:one).sname
    assert_select "td", text: @hotel_da_outra.sname, count: 0
  end

  test "another company's record is not found" do
    sign_in users(:one)
    get hotel_url(@hotel_da_outra)
    assert_response :not_found
    sign_in users(:one) # the error page doesn't keep the test sign-in
    delete hotel_url(@hotel_da_outra)
    assert_response :not_found
    assert Hotel.unscoped.exists?(@hotel_da_outra.id)
  end

  test "new records take the user's company" do
    sign_in users(:one)
    post hotels_url, params: { hotel: { sname: "NOVO HOTEL" } }
    assert_equal companies(:two), Hotel.find_by!(sname: "NOVO HOTEL").company
  end

  test "an order can't point at another company's records" do
    sign_in users(:one)
    sorder = sorders(:one)
    assert_no_difference("Sorder.count") do
      post sorders_url, params: { sorder: { data: Date.current, destination_id: sorder.destination_id, tourguide_id: sorder.tourguide_id,
                                            driver_id: sorder.driver_id, vehicle_id: sorder.vehicle_id,
                                            sorder_items_attributes: { "0" => { snomepax: "PAX", hotel_id: @hotel_da_outra.id } } } }
    end
    assert_select "#error_explanation li", text: "Hotel do passageiro não é válido"
  end

  test "a user sees only their own company" do
    sign_in users(:one)
    get companies_url
    assert_select "td", text: companies(:two).name
    assert_select "a[href=?]", company_path(@outra), count: 0
    get root_url
    assert_select ".empresa-atual", text: "Empresa: #{companies(:two).name}"
  end

  test "a user without company sees no data" do
    users(:sem_rotas).update!(acesso_total: true)
    sign_in users(:sem_rotas)
    get hotels_url
    assert_response :success
    assert_select "td", text: hotels(:one).sname, count: 0
    assert_no_difference("Hotel.unscoped.count") do
      post hotels_url, params: { hotel: { sname: "SEM EMPRESA" } }
    end
    assert_select "#error_explanation li", text: "Empresa é obrigatório(a)"
    get root_url
    assert_select ".empresa-atual", text: "Empresa: nenhuma"
  end

  test "an admin switches the company to work in" do
    sign_in admins(:one)
    patch trocar_empresa_url, params: { empresa_id: @outra.id }
    assert_redirected_to root_url
    get hotels_url
    assert_select "td", text: @hotel_da_outra.sname
    assert_select "td", text: hotels(:one).sname, count: 0
    get companies_url
    assert_select "td", text: companies(:two).name
    assert_select "td", text: @outra.name

    patch trocar_empresa_url, params: { empresa_id: companies(:two).id }
    get hotels_url
    assert_select "td", text: hotels(:one).sname
    assert_select "select#empresa_id option[selected]", text: companies(:two).name
  end

  test "a user bound to a company can't switch" do
    sign_in users(:one)
    get hotels_url
    assert_select "select#empresa_id", count: 0
    patch trocar_empresa_url, params: { empresa_id: @outra.id }
    assert_redirected_to root_url
    follow_redirect!
    assert_select ".alert-danger", text: "Seu cadastro não permite trocar de empresa."
    get hotels_url
    assert_select "td", text: @hotel_da_outra.sname, count: 0
  end

  test "a user allowed every company picks one in the header" do
    users(:consulta).update!(acesso_empresa: User::TODAS_EMPRESAS, permissoes: %w[hotels#index companies#index])
    sign_in users(:consulta)
    patch trocar_empresa_url, params: { empresa_id: @outra.id }
    get hotels_url
    assert_select "select#empresa_id option[selected]", text: @outra.name
    assert_select "td", text: @hotel_da_outra.sname
    assert_select "td", text: hotels(:one).sname, count: 0
    get companies_url
    assert_select "td", text: companies(:two).name
    assert_select "td", text: @outra.name

    patch trocar_empresa_url, params: { empresa_id: companies(:two).id }
    get hotels_url
    assert_select "td", text: hotels(:one).sname
    assert_select "td", text: @hotel_da_outra.sname, count: 0
  end

  test "switching needs a signed-in account" do
    patch trocar_empresa_url, params: { empresa_id: @outra.id }
    assert_redirected_to new_user_session_url
  end

  test "the admin sets a user's company, all of them or none" do
    sign_in admins(:one)
    user = users(:consulta)
    get edit_admins_backoffice_user_url(user)
    assert_select "select[name='user[acesso_empresa]'] option[selected]", text: companies(:two).name
    assert_select "select[name='user[acesso_empresa]'] option[value=todas]", text: "Todas as empresas"

    patch admins_backoffice_user_url(user), params: { user: { acesso_empresa: @outra.id } }
    assert_equal [@outra, false], [user.reload.company, user.todas_empresas?]

    patch admins_backoffice_user_url(user), params: { user: { acesso_empresa: "todas" } }
    assert_equal [nil, true], [user.reload.company, user.todas_empresas?]
    get admins_backoffice_users_url
    assert_select "td", text: /Todas \(escolhe no topo\)/

    patch admins_backoffice_user_url(user), params: { user: { acesso_empresa: "" } }
    assert_equal [nil, false], [user.reload.company, user.todas_empresas?]
  end
end
