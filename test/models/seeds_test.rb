require 'test_helper'

class SeedsTest < ActiveSupport::TestCase
  test "seeds create the 27 Brazilian states once" do
    2.times { load Rails.root.join("db/seeds.rb") }
    assert_equal 27, State.where(uf: %w[AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI RJ RN RS RO RR SC SP SE TO]).count
    assert_equal "Ceará", State.find_by(uf: "CE").name
  end
end
