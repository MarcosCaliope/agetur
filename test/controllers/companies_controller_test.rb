require 'test_helper'

class CompaniesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @company = companies(:one)
  end

  test "should get index" do
    get companies_url
    assert_response :success
  end

  test "should get index when a company has no logos" do
    @company.update!(logoform: nil, logoentrada: "")
    get companies_url
    assert_response :success
  end

  test "should get new" do
    get new_company_url
    assert_response :success
    assert_select "select[name=?] option", "company[state_id]", text: states(:two).uf
  end

  test "should upload, show and remove logos" do
    patch company_url(@company), params: { company: { logo_entrada: fixture_file_upload("logo.png", "image/png") } }
    assert_redirected_to company_url(@company)
    assert @company.reload.logo_entrada.attached?

    get company_url(@company)
    assert_select "img[src*='/rails/active_storage/blobs/'][src$='logo.png']"

    get edit_company_url(@company)
    assert_select "input[type=file][name=?]", "company[logo_entrada]"
    assert_select "input[type=checkbox][name=?]", "company[remover_logo_entrada]"

    patch company_url(@company), params: { company: { remover_logo_entrada: "1" } }
    assert_not @company.reload.logo_entrada.attached?
  end

  test "should reject a non-image logo and redisplay the form" do
    patch company_url(@company), params: { company: { logo_entrada: fixture_file_upload("customers.txt", "text/plain") } }
    assert_response :unprocessable_entity
    assert_select "#error_explanation li", text: /Logo de entrada deve ser uma imagem/
    assert_not @company.reload.logo_entrada.attached?
  end

  test "should show the company's state abbreviation" do
    get company_url(@company)
    assert_match @company.state.uf, response.body
    assert_no_match "#<State", response.body
  end

  test "should create company" do
    assert_difference('Company.count') do
      post companies_url, params: { company: { address: @company.address, city: @company.city, cnpj: @company.cnpj, comments: @company.comments, email: @company.email, iretorno: @company.iretorno, logoentrada: @company.logoentrada, logoform: @company.logoform, name: @company.name, osdupla: @company.osdupla, osincludechdcalc: @company.osincludechdcalc, osmodel: @company.osmodel, osshowcan: @company.osshowcan, osshowcanrel: @company.osshowcanrel, osshowrep: @company.osshowrep, phone: @company.phone, site: @company.site, state_id: @company.state_id } }
    end

    assert_redirected_to company_url(Company.last)
  end

  test "should show company" do
    get company_url(@company)
    assert_response :success
  end

  test "should get edit" do
    get edit_company_url(@company)
    assert_response :success
  end

  test "should update company" do
    patch company_url(@company), params: { company: { address: @company.address, city: @company.city, cnpj: @company.cnpj, comments: @company.comments, email: @company.email, iretorno: @company.iretorno, logoentrada: @company.logoentrada, logoform: @company.logoform, name: @company.name, osdupla: @company.osdupla, osincludechdcalc: @company.osincludechdcalc, osmodel: @company.osmodel, osshowcan: @company.osshowcan, osshowcanrel: @company.osshowcanrel, osshowrep: @company.osshowrep, phone: @company.phone, site: @company.site, state_id: @company.state_id } }
    assert_redirected_to company_url(@company)
  end

  test "should destroy company" do
    assert_difference('Company.count', -1) do
      delete company_url(@company)
    end

    assert_redirected_to companies_url
  end
end
