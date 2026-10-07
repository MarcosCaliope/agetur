require 'test_helper'

class VendorDestinationTest < ActiveSupport::TestCase
  test "commission is a percentage and net prices can't be negative" do
    registro = VendorDestination.new(vendor: vendors(:one), destination: destinations(:one), commission: 101, net_chd: -1)
    assert_not registro.valid?
    assert registro.errors[:commission].any?
    assert registro.errors[:net_chd].any?
    registro.assign_attributes(commission: 100, net_chd: 0)
    assert registro.valid?
  end

  test "one row per vendor and destination" do
    VendorDestination.create!(vendor: vendors(:one), destination: destinations(:one), commission: 5)
    assert_not VendorDestination.new(vendor: vendors(:one), destination: destinations(:one)).valid?
  end
end
