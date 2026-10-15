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

  test "the company's model picks the layout, else model 6" do
    @empresa.update!(osmodel: 7)
    assert_equal 7, pdf.modelo
    @empresa.update!(osmodel: 0)
    assert_equal 6, pdf.modelo
    @empresa.update!(osmodel: nil)
    assert_equal 6, pdf.modelo
  end

  test "every model renders, with what each one prints" do
    @ativo.update!(forma_pagamento: "Q", comments: "COMBO", customer: customers(:two))
    SorderExportPdf::MODELOS.each_key do |modelo|
      documento = SorderExportPdf.new(@sorder.reload, modelo: modelo)
      assert_operator documento.render.bytesize, :>, 0, "modelo #{modelo}"
    end
    item = @ativo.reload
    modelo5 = SorderExportPdf.new(@sorder, modelo: 5)
    assert_equal ActiveSupport::NumberHelper.number_to_delimited(customers(:two).sistger_id || customers(:two).id, delimiter: "."),
                 modelo5.send(:valor_da_coluna, :cod_cliente, item)
    modelo7 = SorderExportPdf.new(@sorder, modelo: 7)
    assert_equal 0, modelo7.send(:valor_da_coluna, :colo, item)
    assert_equal "Cheque", item.nome_forma_pagamento
  end
end
