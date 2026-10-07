require 'test_helper'

class AgenciesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @agency = agencies(:one)
  end

  test "should get index" do
    get agencies_url
    assert_response :success
    assert_select "h1", text: "Agências"
    assert_select "th", text: "Nome"
    assert_select "a", text: "Editar"
    assert_select "a[data-confirm=?]", "Tem certeza?"
    assert_select "a", text: "Nova Agência"
  end

  test "form labels and buttons are in Portuguese" do
    get new_agency_url
    assert_select "h1", text: "Nova Agência"
    assert_select "label", text: "Endereço"
    assert_select "input[type=submit][value=?]", "Criar Agência"
  end

  test "should get new" do
    get new_agency_url
    assert_response :success
  end

  test "should create agency" do
    assert_difference('Agency.count') do
      post agencies_url, params: { agency: { address: @agency.address, comments: @agency.comments, email: @agency.email, phone: @agency.phone, sname: @agency.sname } }
    end

    assert_redirected_to agency_url(Agency.last)
  end

  test "should show agency" do
    get agency_url(@agency)
    assert_response :success
  end

  test "should get edit" do
    get edit_agency_url(@agency)
    assert_response :success
  end

  test "should update agency" do
    patch agency_url(@agency), params: { agency: { address: @agency.address, comments: @agency.comments, email: @agency.email, phone: @agency.phone, sname: @agency.sname } }
    assert_redirected_to agency_url(@agency)
  end

  test "should destroy agency" do
    assert_difference('Agency.count', -1) do
      delete agency_url(@agency)
    end

    assert_redirected_to agencies_url
  end

  test "form has the SISTGER fields and saves them" do
    get new_agency_url
    (%w[sname short_name document email address neighborhood city state_id zipcode phone phone2 fax contact comments] + %w[commission vendor_id]).each { |campo| assert_select "[name=?]", "agency[#{campo}]" }
    assert_select "label", text: "Vendedor correspondente"

    assert_difference("Agency.count") { post agencies_url, params: { agency: { sname: "AGENCIA NOVA", short_name: "NOVA", city: "FORTALEZA", state_id: states(:two).id, contact: "Bia", commission: 12.5, vendor_id: vendors(:one).id } } }
    registro = Agency.order(:id).last
    assert_equal ["NOVA", "Bia", 12.5, vendors(:one).id], registro.values_at(*[:short_name, :contact, :commission, :vendor_id])
    get agency_url(registro)
    assert_response :success
  end
end
