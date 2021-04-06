require "application_system_test_case"

class ServiceOrderItemsTest < ApplicationSystemTestCase
  setup do
    @service_order_item = service_order_items(:one)
  end

  test "visiting the index" do
    visit service_order_items_url
    assert_selector "h1", text: "Service Order Items"
  end

  test "creating a Service order item" do
    visit service_order_items_url
    click_on "New Service Order Item"

    fill_in "Agency", with: @service_order_item.agency_id
    fill_in "Amount", with: @service_order_item.amount
    fill_in "Amountcomission", with: @service_order_item.amountcomission
    fill_in "Amountpay", with: @service_order_item.amountpay
    fill_in "Apto", with: @service_order_item.apto
    fill_in "Comments", with: @service_order_item.comments
    fill_in "Document", with: @service_order_item.document
    fill_in "Documenttype", with: @service_order_item.documenttype
    fill_in "Hotel", with: @service_order_item.hotel_id
    fill_in "Hour", with: @service_order_item.hour
    fill_in "Nomepax", with: @service_order_item.nomepax
    fill_in "Phone", with: @service_order_item.phone
    fill_in "Qtdepax", with: @service_order_item.qtdepax
    fill_in "Service order", with: @service_order_item.service_order_id
    fill_in "Vendor", with: @service_order_item.vendor_id
    click_on "Create Service order item"

    assert_text "Service order item was successfully created"
    click_on "Back"
  end

  test "updating a Service order item" do
    visit service_order_items_url
    click_on "Edit", match: :first

    fill_in "Agency", with: @service_order_item.agency_id
    fill_in "Amount", with: @service_order_item.amount
    fill_in "Amountcomission", with: @service_order_item.amountcomission
    fill_in "Amountpay", with: @service_order_item.amountpay
    fill_in "Apto", with: @service_order_item.apto
    fill_in "Comments", with: @service_order_item.comments
    fill_in "Document", with: @service_order_item.document
    fill_in "Documenttype", with: @service_order_item.documenttype
    fill_in "Hotel", with: @service_order_item.hotel_id
    fill_in "Hour", with: @service_order_item.hour
    fill_in "Nomepax", with: @service_order_item.nomepax
    fill_in "Phone", with: @service_order_item.phone
    fill_in "Qtdepax", with: @service_order_item.qtdepax
    fill_in "Service order", with: @service_order_item.service_order_id
    fill_in "Vendor", with: @service_order_item.vendor_id
    click_on "Update Service order item"

    assert_text "Service order item was successfully updated"
    click_on "Back"
  end

  test "destroying a Service order item" do
    visit service_order_items_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Service order item was successfully destroyed"
  end
end
