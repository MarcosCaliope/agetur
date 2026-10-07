require 'test_helper'

class VendorDestinationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @vendor = vendors(:one).tap { |v| v.update!(commission: 10) }
    @praia, @serra = destinations(:one), destinations(:two)
    @praia.update!(description: "CANOA QUEBRADA")
    @serra.update!(description: "JERICOACOARA")
  end

  def linha(destination, commission: 10, **valores)
    { destination.id.to_s => { commission: commission }.merge(valores) }
  end

  test "requires login" do
    sign_out :user
    get vendor_comissoes_url(@vendor)
    assert_redirected_to new_user_session_path
  end

  test "lists every destination, prefilled with the vendor's default commission" do
    get vendor_comissoes_url(@vendor)
    assert_response :success
    assert_select "tr.comissao-roteiro", Destination.count
    assert_select "input[name=?][value=?]", "comissoes[#{@praia.id}][commission]", "10.0"
    assert_select "input[name=?]", "comissoes[#{@praia.id}][net_adult_card]"
    assert_select "a[href=?]", vendor_path(@vendor), text: "Voltar ao vendedor"
  end

  test "stores only destinations that differ from the vendor's defaults" do
    assert_difference("VendorDestination.count", 1) do
      patch vendor_comissoes_url(@vendor), params: { comissoes: linha(@praia, commission: 15, net_adult: 80, net_chd_card: 40)
                                                                  .merge(linha(@serra)) }
    end
    assert_redirected_to vendor_comissoes_path(@vendor)
    registro = @vendor.vendor_destinations.sole
    assert_equal [@praia, 15.0, 80.0, nil, nil, 40.0],
                 [registro.destination, registro.commission, registro.net_adult, registro.net_chd, registro.net_adult_card, registro.net_chd_card]

    follow_redirect!
    assert_select ".alert-success", text: "Comissões por roteiro gravadas com sucesso."
    assert_select "tr.personalizado td", text: "CANOA QUEBRADA"
    assert_select "input[name=?][value=?]", "comissoes[#{@praia.id}][net_adult]", "80.0"
  end

  test "a destination set back to the defaults is removed" do
    @vendor.vendor_destinations.create!(destination: @praia, commission: 15)
    assert_difference("VendorDestination.count", -1) do
      patch vendor_comissoes_url(@vendor), params: { comissoes: linha(@praia, commission: 10, net_adult: "") }
    end
  end

  test "invalid values save nothing and show the destination with the error" do
    assert_no_difference("VendorDestination.count") do
      patch vendor_comissoes_url(@vendor), params: { comissoes: linha(@praia, commission: 15).merge(linha(@serra, commission: 150)) }
    end
    assert_response :unprocessable_entity
    assert_select "#error_explanation li", text: /JERICOACOARA: % Comissão deve estar entre 0 e 100|JERICOACOARA: % Comissão/
    assert_select "tr.table-danger td", text: "JERICOACOARA"
  end

  test "vendor pages link to the screen" do
    get vendor_url(@vendor)
    assert_select "a[href=?]", vendor_comissoes_path(@vendor), text: "Comissão por roteiro"
    get vendors_url
    assert_select "a[href=?]", vendor_comissoes_path(@vendor), text: "Comissões"
  end
end
