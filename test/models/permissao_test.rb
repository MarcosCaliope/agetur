require 'test_helper'

class PermissaoTest < ActiveSupport::TestCase
  test "form and submit share one key" do
    assert_equal "sorders#create", Permissao.chave("sorders", "new")
    assert_equal "sorders#update", Permissao.chave("sorders", "edit")
    assert_equal "payables#pagar", Permissao.chave("payables", "pagamento")
    assert_equal "sorders#export", Permissao.chave("sorders", :export)
  end

  test "lists the routes of the system's screens" do
    sorders = Permissao.grupos.find { |grupo| grupo.controller == "sorders" }
    assert_equal "Ordens de serviço", sorders.rotulo
    chaves = sorders.itens.map(&:chave)
    assert_equal %w[sorders#export sorders#historico sorders#encerrar sorders#reabrir sorders#index sorders#create sorders#update sorders#show sorders#destroy].sort, chaves.sort
    incluir = sorders.itens.find { |item| item.chave == "sorders#create" }
    assert_equal "Incluir (Novo)", incluir.rotulo
    assert_includes incluir.rotas, "GET /sorders/new"
    assert_includes incluir.rotas, "POST /sorders"
  end

  test "leaves out sign in, the home page and the back-offices" do
    controllers = Permissao.grupos.map(&:controller)
    assert_includes controllers, "sistger_imports"
    %w[devise/sessions site/welcome admins_backoffice/users users_backoffice/welcome active_storage/disk rails/info].each do |livre|
      assert_not_includes controllers, livre
    end
  end

  test "every route has a Portuguese label" do
    Permissao.grupos.each do |grupo|
      grupo.itens.each { |item| assert_no_match(/\A[a-z]/, item.rotulo, item.chave) }
    end
  end
end
