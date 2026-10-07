require 'test_helper'

class SorderTest < ActiveSupport::TestCase
  test "total_pax and total_chd ignore cancelled passengers" do
    sorder = sorders(:one)
    sorder.sorder_items.create!(qtdepax: 2, qtdechd: 1, scancelado: "N")
    sorder.sorder_items.create!(qtdepax: 3, qtdechd: 0)
    sorder.sorder_items.create!(qtdepax: 4, qtdechd: 2, scancelado: "S")

    assert_equal 5, sorder.total_pax
    assert_equal 1, sorder.total_chd
  end
end
