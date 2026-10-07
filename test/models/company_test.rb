require 'test_helper'

class CompanyTest < ActiveSupport::TestCase
  setup do
    @company = companies(:one)
  end

  test "logo returns the uploaded image" do
    @company.logo_entrada.attach(io: file_fixture("logo.png").open, filename: "logo.png")
    assert_equal @company.logo_entrada, @company.logo(:entrada)
    assert_nil @company.logo(:formulario)
  end

  test "logo falls back to a legacy file name only when the file exists in public/" do
    @company.logoentrada = "smartlogo.png"
    assert_equal "smartlogo.png", @company.logo(:entrada)

    ["D:\\SISTGER\\grf\\smartlogoGD.jpg", "nao_existe.png", "../config/database.yml", ""].each do |nome|
      @company.logoentrada = nome
      assert_nil @company.logo(:entrada), "#{nome.inspect} should not be used as a logo"
    end
  end

  test "rejects non-image uploads" do
    @company.logo_entrada.attach(io: file_fixture("customers.txt").open, filename: "clientes.txt")
    assert_not @company.valid?
    assert_includes @company.errors[:logo_entrada], "deve ser uma imagem PNG, JPG, GIF ou WebP"
  end

  test "detects the real type of a file renamed to .png" do
    @company.logo_entrada.attach(io: StringIO.new("%PDF-1.4\n%fake\n"), filename: "logo.png")
    assert_equal "application/pdf", @company.logo_entrada.blob.content_type
    assert_not @company.valid?
  end

  test "rejects images over 2 MB" do
    @company.logo_formulario.attach(io: StringIO.new(file_fixture("logo.png").binread + ("\0" * 2.megabytes)), filename: "grande.png", content_type: "image/png", identify: false)
    assert_not @company.valid?
    assert_includes @company.errors[:logo_formulario], "deve ter no máximo 2 MB"
  end
end
