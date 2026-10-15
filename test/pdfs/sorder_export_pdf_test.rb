require 'test_helper'

class SorderExportPdfTest < ActiveSupport::TestCase
  setup do
    @sorder = sorders(:one)
    @empresa = @sorder.company
    @ativo = @sorder.sorder_items.create!(snomepax: "Maria", qtdepax: 2, qtdechd: 1, amount: 300, amountpay: 100, scancelado: "N",
                                          companions_attributes: [{ snome: "Ana", documenttype: "RG", document: "123" }, { snome: "Bia", chd: true }])
    @cancelado = @sorder.sorder_items.create!(snomepax: "Desistiu", qtdepax: 3, amount: 90, scancelado: "S")
    @repassado = @sorder.sorder_items.create!(snomepax: "Outra agência", qtdepax: 4, amount: 50, agency: agencies(:two))
  end

  def pdf = SorderExportPdf.new(@sorder.reload)

  test "renders the order with its pax list" do
    documento = pdf
    assert_operator documento.render.bytesize, :>, 0
    assert_includes documento.send(:itens), @ativo
  end

  test "cancelled and passed-on passengers show only when the company asks, and never count" do
    @empresa.update!(osshowcan: 1, osshowrep: 1)
    documento = pdf
    assert_equal [@ativo, @cancelado, @repassado].map(&:id).sort, documento.send(:itens).map(&:id).sort
    assert_equal [@ativo.id], documento.send(:contados).map(&:id)

    @empresa.update!(osshowcan: 0, osshowrep: 0)
    assert_equal [@ativo.id], pdf.send(:itens).map(&:id)
  end

  test "the amount is what's left to receive" do
    assert_equal [200.0], pdf.send(:contados).map(&:total_passeio)
  end

  test "text outside the PDF fonts doesn't break the PDF" do
    @ativo.update!(snomepax: "Maria 😀 Ōno")
    assert_operator pdf.render.bytesize, :>, 0
  end
end
