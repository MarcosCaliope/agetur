require "application_system_test_case"

class SorderItemsTest < ApplicationSystemTestCase
  setup do
    @sorder_item = sorder_items(:one)
  end

  test "visiting the index" do
    visit sorder_items_url
    assert_selector "h1", text: "Sorder Items"
  end

  test "creating a Sorder item" do
    visit sorder_items_url
    click_on "New Sorder Item"

    fill_in "Comments", with: @sorder_item.comments
    fill_in "Sorder", with: @sorder_item.sorder_id
    click_on "Create Sorder item"

    assert_text "Sorder item was successfully created"
    click_on "Back"
  end

  test "updating a Sorder item" do
    visit sorder_items_url
    click_on "Edit", match: :first

    fill_in "Comments", with: @sorder_item.comments
    fill_in "Sorder", with: @sorder_item.sorder_id
    click_on "Update Sorder item"

    assert_text "Sorder item was successfully updated"
    click_on "Back"
  end

  test "destroying a Sorder item" do
    visit sorder_items_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Sorder item was successfully destroyed"
  end
end
