require 'test_helper'

class SistgerExclusoesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in admins(:one)
    patch trocar_empresa_url, params: { empresa_id: companies(:two).id }
  end

  test "only admins open it, not even users with acesso_total, and users don't see the link" do
    sign_out :admin
    sign_in users(:one)
    get sistger_exclusoes_url
    assert_redirected_to root_path
    delete sistger_exclusoes_url, params: { etapas: %w[caixa], confirmacao: "EXCLUIR" }
    assert_redirected_to root_path
    assert_not_includes Permissao.chaves, "sistger_exclusoes#index"

    get sistger_imports_url
    assert_select "a[href=?]", sistger_exclusoes_path, count: 0
  end

  test "lists the tables with the company's counts" do
    get sistger_exclusoes_url
    assert_response :success
    assert_select ".alert-danger", /#{companies(:two).name}/
    assert_select "tr.sistger-etapa", SistgerExclusao::EXCLUSAO.size
    assert_select "#sistger-exclusao", count: 0
  end

  test "chosen tables ask for the confirmation with what will be deleted" do
    get sistger_exclusoes_url, params: { etapas: %w[hoteis guias] }
    assert_select "#sistger-exclusao li", 2
    assert_select "#sistger-exclusao input[name=confirmacao]"
  end

  test "deletes only after typing EXCLUIR" do
    assert_no_difference("Tourguide.unscoped.count") do
      delete sistger_exclusoes_url, params: { etapas: %w[guias], confirmacao: "sim" }
    end
    assert_redirected_to sistger_exclusoes_path(etapas: %w[guias])

    SorderItem.unscoped.delete_all
    Sorder.unscoped.delete_all
    delete sistger_exclusoes_url, params: { etapas: %w[guias], confirmacao: "excluir" }
    assert_redirected_to sistger_exclusoes_path
    assert_match(/Guias: 2/, flash[:notice])
    assert_equal 0, Tourguide.unscoped.where(company_id: companies(:two).id).count
  end

  test "a refusal deletes nothing and explains what to include" do
    assert_no_difference("Tourguide.unscoped.count") do
      delete sistger_exclusoes_url, params: { etapas: %w[guias], confirmacao: "EXCLUIR" }
    end
    assert_match(/ordens de serviço/i, flash[:alert])
  end
end
