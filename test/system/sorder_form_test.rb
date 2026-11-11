require "application_system_test_case"

# The order form's JavaScript: lista_pax.js, edicao_ordem.js and the
# "Pagar comissão" menu (Bootstrap dropdown + rails-ujs) and the
# "Transferir / copiar" link, which comes back to the form, and the
# quick-add modals for guide, driver and vehicle (cadastro_rapido.js).
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

  test "pays a passenger's vendor commission from the form" do
    @item.update!(vendor: vendors(:one), amountcomission: 25)
    visit edit_sorder_path(@sorder)
    click_on "Pagar comissão"
    assert_difference("CashEntry.count") do
      accept_confirm(/Pagar hoje R\$ 25,00 de comissão/) { click_on "PIX" }
      assert_text "lançada no caixa"
    end
    assert_current_path edit_sorder_path(@sorder)
    assert_equal ["O", 25], [CashEntry.last.forma_pagamento, CashEntry.last.valor]
    assert_equal 25, @item.reload.amountcomissionpay
    assert_no_button "Pagar comissão"
  end
  test "transfers a passenger from the form and comes back to it" do
    destino = sorders(:two)
    visit edit_sorder_path(@sorder)
    click_on "Transferir / copiar"
    fill_in "Nº da OS de destino", with: destino.numero
    assert_selector "#destino-movimentacao .alert-info", text: "OS nº #{destino.numero}"
    accept_confirm { click_on "Transferir" }

    assert_text "Passageiro Maria transferido da OS nº #{@sorder.numero} para a OS nº #{destino.numero}."
    assert_current_path edit_sorder_path(@sorder)
    assert_no_link "Transferir / copiar"
    assert_equal destino.id, @item.reload.sorder_id
  end

  test "the + next to the guide and vehicle creates one in a modal and selects it" do
    visit new_sorder_path
    find("button[title='Cadastrar guia']").click
    within("#novo-guia") do
      assert_selector "input:focus" # shown: Bootstrap no longer moves the focus
      fill_in "Nome", with: "JOANA"
      click_on "Cadastrar e selecionar"
    end
    assert_no_selector "#novo-guia", visible: true
    assert_selector "#sorder_tourguide_id option:checked", text: "JOANA"
    assert_equal "JOANA", find("#sorder_tourguide_id option:checked").text
    assert Tourguide.exists?(sname: "JOANA")

    find("button[title='Cadastrar veículo']").click
    within("#novo-veiculo") do
      assert_selector "input:focus"
      fill_in "Placa", with: "ABC1D23"
      click_on "Cadastrar e selecionar"
    end
    assert_no_selector "#novo-veiculo", visible: true
    assert_selector "#sorder_vehicle_id option:checked", text: "ABC1D23"
    assert_equal "ABC1D23", find("#sorder_vehicle_id option:checked").text
    assert_equal companies(:two).state_id, Vehicle.find_by!(license: "ABC1D23").state_id
  end

  test "the + next to a passenger's vendor creates one, picks it there and offers it to every passenger" do
    @sorder.sorder_items.create!(snomepax: "Pedro", qtdepax: 1)
    visit edit_sorder_path(@sorder)
    selects = all("select[name$='[vendor_id]']").to_a
    alvo = selects.find { |select| select.find(:xpath, "ancestor::*[contains(@class,'nested-fields')][1]").has_field?(with: "Pedro") }
    alvo.find(:xpath, "following-sibling::button[@title='Cadastrar vendedor'][1]").click
    within("#novo-vendedor") do
      assert_selector "input:focus"
      fill_in "Nome", with: "ZECA VENDAS"
      fill_in "Comissão (%)", with: "10"
      click_on "Cadastrar e selecionar"
    end
    assert_no_selector "#novo-vendedor", visible: true
    assert_selector "option:checked", text: "ZECA VENDAS"

    vendedor = Vendor.find_by!(sname: "ZECA VENDAS")
    assert_equal [10.0, true], [vendedor.commission, vendedor.active]
    assert_equal vendedor.id.to_s, alvo.value
    (selects - [alvo]).each do |select|
      assert_not_equal vendedor.id.to_s, select.value
      assert select.has_selector?("option", text: "ZECA VENDAS")
    end

    click_on "[Adicionar PAX]"
    assert all("select[name$='[vendor_id]']").last.has_selector?("option", text: "ZECA VENDAS"), "new passengers get it too"
  end
end
