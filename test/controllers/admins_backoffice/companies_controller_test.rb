require 'test_helper'

class AdminsBackoffice::CompaniesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in admins(:one)
  end

  test "lists companies with their access situation" do
    companies(:one).update!(acesso_bloqueado: true)
    companies(:two).update!(acesso_liberado_ate: Date.current + 10)
    get admins_backoffice_companies_url
    assert_response :success
    assert_select "span.badge-danger", text: "Bloqueada"
    assert_select "span.badge-success", text: "Liberada"
    assert_select "a[title='Editar acesso'] i.fa-pencil", count: 2
  end

  test "blocks a company and sets the date its access runs to" do
    get edit_admins_backoffice_company_url(companies(:two))
    assert_response :success
    patch admins_backoffice_company_url(companies(:two)), params: { company: { acesso_bloqueado: "1", acesso_liberado_ate: "2026-12-10", name: "Outro" } }
    assert_redirected_to admins_backoffice_companies_url
    companies(:two).reload
    assert companies(:two).acesso_bloqueado?
    assert_equal Date.new(2026, 12, 10), companies(:two).acesso_liberado_ate
    assert_equal "MyString", companies(:two).name, "only the access fields are changed here"
  end

  test "users can't open it, nor lift the block through the companies screen" do
    sign_out :admin
    sign_in users(:one)
    get admins_backoffice_companies_url
    assert_redirected_to new_admin_session_path

    companies(:two).update!(acesso_liberado_ate: Date.current + 1)
    patch company_url(companies(:two)), params: { company: { acesso_bloqueado: "1", acesso_liberado_ate: "" } }
    companies(:two).reload
    assert_not companies(:two).acesso_bloqueado?
    assert_equal Date.current + 1, companies(:two).acesso_liberado_ate
  end
end
