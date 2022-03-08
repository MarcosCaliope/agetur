require "application_system_test_case"

class HotelsTest < ApplicationSystemTestCase
  setup do
    @hotel = hotels(:one)
  end

  test "visiting the index" do
    visit hotels_url
    assert_selector "h1", text: "Hotels"
  end

  test "creating a Hotel" do
    visit hotels_url
    click_on "New Hotel"

    fill_in "Valordiaria", with: @hotel.Valordiaria
    fill_in "Address", with: @hotel.address
    fill_in "Comments", with: @hotel.comments
    fill_in "Email", with: @hotel.email
    fill_in "Phone", with: @hotel.phone
    fill_in "Sname", with: @hotel.sname
    click_on "Create Hotel"

    assert_text "Hotel was successfully created"
    click_on "Back"
  end

  test "updating a Hotel" do
    visit hotels_url
    click_on "Edit", match: :first

    fill_in "Valordiaria", with: @hotel.Valordiaria
    fill_in "Address", with: @hotel.address
    fill_in "Comments", with: @hotel.comments
    fill_in "Email", with: @hotel.email
    fill_in "Phone", with: @hotel.phone
    fill_in "Sname", with: @hotel.sname
    click_on "Update Hotel"

    assert_text "Hotel was successfully updated"
    click_on "Back"
  end

  test "destroying a Hotel" do
    visit hotels_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Hotel was successfully destroyed"
  end
end
