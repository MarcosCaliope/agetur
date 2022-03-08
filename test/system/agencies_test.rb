require "application_system_test_case"

class AgenciesTest < ApplicationSystemTestCase
  setup do
    @agency = agencies(:one)
  end

  test "visiting the index" do
    visit agencies_url
    assert_selector "h1", text: "Agencies"
  end

  test "creating a Agency" do
    visit agencies_url
    click_on "New Agency"

    fill_in "Address", with: @agency.address
    fill_in "Comments", with: @agency.comments
    fill_in "Email", with: @agency.email
    fill_in "Phone", with: @agency.phone
    fill_in "Sname", with: @agency.sname
    click_on "Create Agency"

    assert_text "Agency was successfully created"
    click_on "Back"
  end

  test "updating a Agency" do
    visit agencies_url
    click_on "Edit", match: :first

    fill_in "Address", with: @agency.address
    fill_in "Comments", with: @agency.comments
    fill_in "Email", with: @agency.email
    fill_in "Phone", with: @agency.phone
    fill_in "Sname", with: @agency.sname
    click_on "Update Agency"

    assert_text "Agency was successfully updated"
    click_on "Back"
  end

  test "destroying a Agency" do
    visit agencies_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Agency was successfully destroyed"
  end
end
