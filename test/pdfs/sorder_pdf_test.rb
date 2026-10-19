require 'test_helper'

class SorderPdfTest < ActiveSupport::TestCase
  test "lists each order's PAX and CHD, without cancelled passengers" do
    sorder = sorders(:two)
    sorder.sorder_items.update_all(qtdepax: 0, qtdechd: 0)
    sorder.sorder_items.create!(snomepax: "Ana", qtdepax: 3, qtdechd: 1)
    sorder.sorder_items.create!(snomepax: "Bia", qtdepax: 2, qtdechd: 2, scancelado: "S")

    linhas = SorderPdf.new(Sorder.all).send(:sorder_id_all)
    assert_equal %w[PAX CHD], linhas.first.last(2)
    assert_equal [3, 1], linhas.find { |l| l.first == sorder.id }.last(2)
  end
end
