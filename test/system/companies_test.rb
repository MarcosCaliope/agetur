require "application_system_test_case"

class CompaniesTest < ApplicationSystemTestCase
  setup do
    @company = companies(:one)
  end

  test "visiting the index" do
    visit companies_url
    assert_selector "h1", text: "Companies"
  end

  test "creating a Company" do
    visit companies_url
    click_on "New Company"

    fill_in "Address", with: @company.address
    fill_in "City", with: @company.city
    fill_in "Cnpj", with: @company.cnpj
    fill_in "Comments", with: @company.comments
    fill_in "Email", with: @company.email
    fill_in "Iretorno", with: @company.iretorno
    fill_in "Logoentrada", with: @company.logoentrada
    fill_in "Logoform", with: @company.logoform
    fill_in "Name", with: @company.name
    fill_in "Osdupla", with: @company.osdupla
    fill_in "Osincludechdcalc", with: @company.osincludechdcalc
    fill_in "Osmodel", with: @company.osmodel
    fill_in "Osshowcan", with: @company.osshowcan
    fill_in "Osshowcanrel", with: @company.osshowcanrel
    fill_in "Osshowrep", with: @company.osshowrep
    fill_in "Phone", with: @company.phone
    fill_in "Site", with: @company.site
    fill_in "State", with: @company.state_id
    click_on "Create Company"

    assert_text "Company was successfully created"
    click_on "Back"
  end

  test "updating a Company" do
    visit companies_url
    click_on "Edit", match: :first

    fill_in "Address", with: @company.address
    fill_in "City", with: @company.city
    fill_in "Cnpj", with: @company.cnpj
    fill_in "Comments", with: @company.comments
    fill_in "Email", with: @company.email
    fill_in "Iretorno", with: @company.iretorno
    fill_in "Logoentrada", with: @company.logoentrada
    fill_in "Logoform", with: @company.logoform
    fill_in "Name", with: @company.name
    fill_in "Osdupla", with: @company.osdupla
    fill_in "Osincludechdcalc", with: @company.osincludechdcalc
    fill_in "Osmodel", with: @company.osmodel
    fill_in "Osshowcan", with: @company.osshowcan
    fill_in "Osshowcanrel", with: @company.osshowcanrel
    fill_in "Osshowrep", with: @company.osshowrep
    fill_in "Phone", with: @company.phone
    fill_in "Site", with: @company.site
    fill_in "State", with: @company.state_id
    click_on "Update Company"

    assert_text "Company was successfully updated"
    click_on "Back"
  end

  test "destroying a Company" do
    visit companies_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Company was successfully destroyed"
  end
end
