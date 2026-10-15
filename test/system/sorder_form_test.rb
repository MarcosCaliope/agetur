require "application_system_test_case"

# The order form's JavaScript: lista_pax.js and edicao_ordem.js.
class SorderFormTest < ApplicationSystemTestCase
  setup do
    @sorder = sorders(:one)
    @item = @sorder.sorder_items.create!(snomepax: "Maria", qtdepax: 3)
    sign_in users(:one)
  end

  def campo(nome)
    find("input[name$='[#{nome}]']", match: :first)
  end

  test "the pax list recounts PAX and CHD as it's typed" do
    visit edit_sorder_path(@sorder)
    click_on "[Adicionar à lista pax]"
    campo("snome").fill_in(with: "Bia")
    find("input[type=checkbox][name$='[chd]']", match: :first).check
    assert_equal %w[1 1], [campo("qtdepax").value, campo("qtdechd").value]

    find("input[type=checkbox][name$='[colo]']", match: :first).check
    assert_equal %w[1 0], [campo("qtdepax").value, campo("qtdechd").value]
  end

  test "leaving a changed form asks first" do
    visit edit_sorder_path(@sorder)
    click_on "Voltar"
    assert_current_path sorders_path, ignore_query: true

    visit edit_sorder_path(@sorder)
    campo("apto").fill_in(with: "101")
    click_on "Voltar"
    assert_text "Alterações não gravadas"
    click_on "Continuar editando"
    assert_no_text "Alterações não gravadas"
    assert_current_path edit_sorder_path(@sorder)

    click_on "Voltar"
    click_on "Gravar alterações"
    assert_text "Ordem de serviço atualizada"
    assert_equal "101", @item.reload.apto

    visit edit_sorder_path(@sorder)
    campo("apto").fill_in(with: "202")
    click_on "Voltar"
    click_on "Sair sem gravar"
    assert_current_path sorders_path, ignore_query: true
    assert_equal "101", @item.reload.apto
  end

  test "shows who else is editing and releases the form on leaving" do
    SorderEdicao.create!(sorder: @sorder, usuario: "outra@example.com", visto_em: Time.current)
    visit edit_sorder_path(@sorder)
    assert_text "esta ordem está sendo editada agora por outra@example.com"
    assert_equal ["outra@example.com", users(:one).email].sort, @sorder.edicoes.pluck(:usuario).sort

    click_on "Voltar"
    assert_current_path sorders_path, ignore_query: true
    assert_equal ["outra@example.com"], @sorder.edicoes.reload.pluck(:usuario)
  end
end
