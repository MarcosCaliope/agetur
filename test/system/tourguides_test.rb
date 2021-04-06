require "application_system_test_case"

class TourguidesTest < ApplicationSystemTestCase
  setup do
    @tourguide = tourguides(:one)
  end

  test "visiting the index" do
    visit tourguides_url
    assert_selector "h1", text: "Tourguides"
  end

  test "creating a Tourguide" do
    visit tourguides_url
    click_on "New Tourguide"

    fill_in "Address", with: @tourguide.address
    fill_in "Comments", with: @tourguide.comments
    fill_in "Email", with: @tourguide.email
    fill_in "Phone", with: @tourguide.phone
    fill_in "Sname", with: @tourguide.sname
    click_on "Create Tourguide"

    assert_text "Tourguide was successfully created"
    click_on "Back"
  end

  test "updating a Tourguide" do
    visit tourguides_url
    click_on "Edit", match: :first

    fill_in "Address", with: @tourguide.address
    fill_in "Comments", with: @tourguide.comments
    fill_in "Email", with: @tourguide.email
    fill_in "Phone", with: @tourguide.phone
    fill_in "Sname", with: @tourguide.sname
    click_on "Update Tourguide"

    assert_text "Tourguide was successfully updated"
    click_on "Back"
  end

  test "destroying a Tourguide" do
    visit tourguides_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Tourguide was successfully destroyed"
  end
end
