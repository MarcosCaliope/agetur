require 'test_helper'

class SorderItemCompanionTest < ActiveSupport::TestCase
  test "needs a name" do
    companion = sorder_items(:one).companions.build
    assert_not companion.valid?
    assert_includes companion.errors.full_messages, "Nome não pode ficar em branco"
  end

  test "is removed with its passenger" do
    item = sorder_items(:one)
    item.companions.create!(snome: "Ana")
    assert_difference("SorderItemCompanion.count", -1) { item.destroy! }
  end
end
