require 'test_helper'

class VendorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @vendor = vendors(:one)
  end

  test "should get index" do
    get vendors_url
    assert_response :success
    assert_select "tr:not(.text-muted) td:first-child", text: @vendor.id.to_s
  end

  test "should get new" do
    get new_vendor_url
    assert_response :success
    %w[sname short_name document address neighborhood city state_id zipcode phone phone2 fax contact email
       classification commission comments active no_commission].each do |campo|
      assert_select "[name=?]", "vendor[#{campo}]"
    end
    assert_select "label", text: "CPF/CNPJ"
  end

  test "should save the SISTGER fields and show an inactive vendor" do
    estado = states(:two)
    post vendors_url, params: { vendor: { sname: "JOSIMAR GUIA", short_name: "JOSIMAR", document: "123.456.789-00",
                                          neighborhood: "MEIRELES", city: "FORTALEZA", state_id: estado.id, zipcode: "60110345",
                                          phone2: "8599", fax: "8533", contact: "Josi", classification: "Guia", active: "0",
                                          no_commission: "1" } }
    vendor = Vendor.last
    assert_redirected_to vendor_url(vendor)
    assert_equal ["JOSIMAR", estado, "Guia", false, true],
                 [vendor.short_name, vendor.state, vendor.classification, vendor.active, vendor.no_commission]

    get vendor_url(vendor)
    assert_select ".badge", text: "Inativo"
    assert_select ".badge", text: "Não pagar comissão"
    assert_select "dd", text: "FORTALEZA"
    assert_select "dd", text: estado.uf
    get new_vendor_url
    assert_select "datalist#classificacoes option[value=Guia]"
    get vendors_url
    assert_select "tr.text-muted td", text: "Inativo"
  end

  test "should create vendor" do
    assert_difference('Vendor.count') do
      post vendors_url, params: { vendor: { address: @vendor.address, comments: @vendor.comments, commission: @vendor.commission, email: @vendor.email, phone: @vendor.phone, sname: @vendor.sname } }
    end

    assert_redirected_to vendor_url(Vendor.last)
  end

  test "should show vendor" do
    get vendor_url(@vendor)
    assert_response :success
  end

  test "should get edit" do
    get edit_vendor_url(@vendor)
    assert_response :success
  end

  test "should update vendor" do
    patch vendor_url(@vendor), params: { vendor: { address: @vendor.address, comments: @vendor.comments, commission: @vendor.commission, email: @vendor.email, phone: @vendor.phone, sname: @vendor.sname } }
    assert_redirected_to vendor_url(@vendor)
  end

  test "should destroy vendor" do
    assert_difference('Vendor.count', -1) do
      delete vendor_url(@vendor)
    end

    assert_redirected_to vendors_url
  end
end
