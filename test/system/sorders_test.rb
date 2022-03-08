require "application_system_test_case"

class SordersTest < ApplicationSystemTestCase
  setup do
    @sorder = sorders(:one)
  end

  test "visiting the index" do
    visit sorders_url
    assert_selector "h1", text: "Sorders"
  end

  test "creating a Sorder" do
    visit sorders_url
    click_on "New Sorder"

    fill_in "Data", with: @sorder.data
    fill_in "Sobservacoes", with: @sorder.sobservacoes
    click_on "Create Sorder"

    assert_text "Sorder was successfully created"
    click_on "Back"
  end

  test "updating a Sorder" do
    visit sorders_url
    click_on "Edit", match: :first

    fill_in "Data", with: @sorder.data
    fill_in "Sobservacoes", with: @sorder.sobservacoes
    click_on "Update Sorder"

    assert_text "Sorder was successfully updated"
    click_on "Back"
  end

  test "destroying a Sorder" do
    visit sorders_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Sorder was successfully destroyed"
  end
end
