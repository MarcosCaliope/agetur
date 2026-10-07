require 'test_helper'

class CustomersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @customer = customers(:one)
  end

  test "should get index" do
    get customers_url
    assert_response :success
    assert_select "p.ultimo-registro", text: /Último registro: nº/
  end

  test "should get new" do
    get new_customer_url
    assert_response :success
  end

  test "should create customer" do
    assert_difference('Customer.count') do
      post customers_url, params: { customer: { city: @customer.city, comments: @customer.comments, document: @customer.document, email: @customer.email, nome: @customer.nome, phone: @customer.phone } }
    end

    assert_redirected_to customer_url(Customer.last)
  end

  test "should show customer" do
    get customer_url(@customer)
    assert_response :success
  end

  test "should get edit" do
    get edit_customer_url(@customer)
    assert_response :success
  end

  test "should update customer" do
    patch customer_url(@customer), params: { customer: { city: @customer.city, comments: @customer.comments, document: @customer.document, email: @customer.email, nome: @customer.nome, phone: @customer.phone } }
    assert_redirected_to customer_url(@customer)
  end

  test "should destroy customer" do
    assert_difference('Customer.count', -1) do
      delete customer_url(@customer)
    end

    assert_redirected_to customers_url
  end

  test "form has the SISTGER fields and saves them" do
    get new_customer_url
    (%w[nome document state_registration email website address neighborhood city state_id zipcode phone phone2 fax contact comments billing_address billing_neighborhood billing_city billing_state_id billing_zipcode billing_phone billing_phone2 billing_fax]).each { |campo| assert_select "[name=?]", "customer[#{campo}]" }
    assert_select "label", text: "Endereço de cobrança"

    assert_difference("Customer.count") { post customers_url, params: { customer: { nome: "MARIA", state_registration: "ISENTO", address: "RUA B", website: "maria.com", billing_address: "RUA C", billing_city: "SOBRAL", billing_state_id: states(:two).id } } }
    registro = Customer.order(:id).last
    assert_equal ["ISENTO", "RUA B", "maria.com", "RUA C", "SOBRAL", states(:two).id], registro.values_at(*[:state_registration, :address, :website, :billing_address, :billing_city, :billing_state_id])
    get customer_url(registro)
    assert_response :success
  end
end
