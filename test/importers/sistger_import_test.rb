require 'test_helper'

class SistgerImportTest < ActiveSupport::TestCase
  setup do
    @ce = State.create!(uf: "CE", name: "Ceará")
    @fonte = SistgerFonteFalsa.new(
      "Tblfilial" => [{ "iCODIGO" => 1, "sNome" => "ISA TURISMO   ", "sNomeRed" => "ISATURISMO", "sEndereco" => "RUA A ",
                        "sCidade" => "FORTALEZA", "sEstado" => "CE", "sCNPJ" => "10.554.031/0001-48", "sCGF" => "06.123",
                        "sEmail" => "A@B.COM", "sWeb" => "WWW.ISA.COM", "sTelefones" => "(85) 1234", "iModeloOS" => 2,
                        "iflgOSDupla" => 1, "bretorno" => true, "sMostraCanceladosOS" => "N", "sMostraCancelados" => "S",
                        "sMostraRepassados" => "N", "sCalculaValorCHD" => "S" }],
      "tblClientes" => [{ "iCodigo" => 10, "snome" => "MARIA  ", "scgc" => "123", "scgf" => "ISENTO", "stelefone" => "8599",
                          "sfone2" => "", "sfax" => nil, "semail" => "", "sWEB" => "maria.com", "sendereco" => "RUA B",
                          "sBairro" => "CENTRO", "scidade" => "FORTALEZA", "sestado" => nil, "scep" => "60000", "scontato" => "  ",
                          "sendcobranca" => "RUA C", "sBairrocob" => nil, "scidcobranca" => "SOBRAL", "sestcobranca" => "CE",
                          "scepcobranca" => nil, "stelcobranca" => "8577", "sfone2cobranca" => nil, "sfaxcobranca" => nil }],
      "tblVendedor" => [generico(2348, "ALEX TURISMO", "sEndereco" => "OSVALDO CRUZ, 01 ", "sBairro" => "MEIRELES",
                                 "sCidade" => "FORTALEZA", "sEstado" => "CE", "sCep" => "60110345", "sTelefone1" => "8533",
                                 "sTelefone2" => "  ", "sContato" => "8598", "sCNPJ" => "000", "sNomeReduzido" => "ALEX",
                                 "sClassificacao" => "", "nPctComissao" => BigDecimal("5"), "bAtivo" => false, "bComissao" => true)],
      "tblAgenciaViagem" => [generico(7, "CEARÁ ROTAS", "sNomeReduzido" => "CEARA", "sCidade" => "FORTALEZA", "sEstado" => "CE",
                                      "nPctComissao" => BigDecimal("10"), "iCodVendedor" => 2348)],
      "tblHotel" => [generico(2, "FORTALEZA MAR HOTEL", "sNomeReduzido" => "FORTALEZA MAR", "sEndereco" => "AV X",
                              "sBairro" => "MEIRELES", "sCidade" => "FORTALEZA", "sEstado" => "CE", "sCep" => "60000000",
                              "sTelefone1" => "8533", "sTelefone2" => " ", "nValorDiaria" => BigDecimal("150.5"))],
      "tblAgenteViagem" => [generico(31, "MARCOS", "sNomeReduzido" => "GUIA", "sContato" => "8599"),
                            generico(32, "SANDRA ", "sNomeReduzido" => "GUIA"),
                            generico(29, "ANA NANCHEN", "sNomeReduzido" => "ANA GUIA")],
      "tblFuncionarios" => [generico(5, "ELIAS SILVA", "sNomeReduzido" => "ELIAS")],
      "tblveiculos" => [{ "iCodigo" => 1, "sPlacas" => "OCI6328", "sTipo" => "VAN", "sMarca" => "DUCATO  ", "sModelo" => "DUCATO",
                          "sAnoFabricacao" => "09", "sAnoModelo" => "10  ", "sCor" => "PRATA", "sCidade" => "FORTALEZA",
                          "sEstado" => "CE", "sCapacidade" => "16", "sTanque" => nil, "sChassi" => "9BD", "sOdometro" => nil,
                          "sRenavam" => "123", "iAnoLicenciamento" => 2024, "dtAquisicao" => Time.utc(2014, 5, 2),
                          "sKitSeguro" => "N" }],
      "TblDistancias" => [{ "iCodigo" => 0, "sDescricao" => "ITAIÇABA   ", "sDistancia" => 520, "sEstado" => nil,
                            "nValorIndividual" => BigDecimal("80"), "nValorIndividualChd" => nil, "nNetAdulto" => BigDecimal("60"),
                            "nNetChd" => nil, "nNetAdultoCartao" => nil, "nNetCHDCartao" => nil, "nIndCombo" => BigDecimal("150"),
                            "nIndCHDCombo" => nil, "nNETCombo" => BigDecimal("120"), "nNetComboCHD" => nil }],
      "tblVendedorRoteiro" => [
        { "iCodVendedor" => 2348, "iCodRoteiro" => 0, "cValorComissao" => BigDecimal("15"), "cValorNet" => BigDecimal("80"),
          "cValorNetCHD" => nil, "cValorNetCartao" => BigDecimal("85"), "cValorNetCHDCartao" => nil },
        { "iCodVendedor" => 9999, "iCodRoteiro" => 0, "cValorComissao" => BigDecimal("5"), "cValorNet" => nil,
          "cValorNetCHD" => nil, "cValorNetCartao" => nil, "cValorNetCHDCartao" => nil }
      ],
      "tblOrdemServico" => [
        ordem(1, guia: "SANDRA", motorista: "ELIAS", veiculo: 1, placa: ""),
        ordem(2, guia: "*", motorista: "  ", veiculo: 0, placa: "VAN"),
        ordem(3, guia: "ANA GUIA", motorista: "ELIAS", veiculo: 0, placa: "", data: Time.utc(5025, 12, 2)),
        ordem(4, guia: "GUIA", motorista: "OUTRO", veiculo: 1, placa: "")
      ],
      "tblOrdemServicoItens" => [
        item(1, 1, nome: "JORGE", hotel_codigo: 2, hotel: "OUTRO NOME", agencia_codigo: 7, agencia: "X"),
        item(1, 2, nome: "LEANDRO", hotel_codigo: 0, hotel: "BRASIL TROPICAL", agencia_codigo: 0, agencia: "NOVA AGENCIA", cancelado: "S"),
        item(99, 1, nome: "ORFAO")
      ],
      "tblListaPax" => [
        { "iNumero" => 1, "iSequencial" => 1, "sNomeCliente" => "NADIA" },
        { "iNumero" => 1, "iSequencial" => 1, "sNomeCliente" => "PEDRO " }
      ]
    )
    @import = SistgerImport.new(@fonte)
  end

  # A row of SISTGER's generic cadastro screen (aliased columns).
  def generico(codigo, nome, campos = {})
    { "iCodigo" => codigo, "sNome" => nome, "sNomeReduzido" => nil, "sEndereco" => nil, "sBairro" => nil, "sCidade" => nil,
      "sEstado" => nil, "sCep" => nil, "sTelefone1" => nil, "sTelefone2" => nil, "sEmail" => nil, "sContato" => nil,
      "sCNPJ" => nil, "sFax" => nil }.merge(campos)
  end

  def ordem(numero, guia:, motorista:, veiculo:, placa:, data: Time.utc(2025, 10, 1))
    { "iNumero" => numero, "Data" => data, "iCodDestino" => 0, "iCodVeiculo" => veiculo, "sPlacas" => placa,
      "sNomeRedGuia" => guia, "sNomeRedMotorista" => motorista, "nValorGuia" => BigDecimal("50"), "nValorMotorista" => nil,
      "nValorPedagio" => nil, "nDespesas" => nil, "nValorCombustivel" => nil, "nValorOS" => BigDecimal("640"),
      "ValorFinalOS" => BigDecimal("640"), "sObservacoes" => "OBS #{numero}", "bCancelado" => false }
  end

  def item(numero, seq, nome:, hotel_codigo: 0, hotel: nil, agencia_codigo: 0, agencia: nil, cancelado: "N")
    { "iNumero" => numero, "iSequencial" => seq, "iCodCliente" => 10, "sNomeCliente" => nome, "iCodHotel" => hotel_codigo,
      "sHotel" => hotel, "sNumeroApto" => "101", "iNumeroPax" => 2, "iNumeroCHD" => 1, "sHora" => "08:00", "sTelefone" => "85",
      "nValor" => BigDecimal("400"), "nValorPago" => BigDecimal("100"), "iCodVendedor" => 2348, "nValorComissao" => BigDecimal("40"),
      "nValorRecVendedor" => BigDecimal("10"), "iCodRepassado" => agencia_codigo, "sRepassado" => agencia,
      "nValorComissaoRepassado" => BigDecimal("20"), "nValorPagoRepasse" => nil, "sFlgCancelado" => cancelado,
      "sTipoDoc" => "RG  ", "sNumeroDoc" => "000", "sObservacoes" => "COMBO" }
  end

  def importar_cadastros
    %w[empresa clientes vendedores agencias hoteis guias motoristas veiculos roteiros].each { |etapa| @import.importar(etapa) }
  end

  test "imports cadastros, trimming text and resolving states" do
    importar_cadastros

    empresa = Company.find_by!(sistger_id: 1)
    assert_equal ["ISA TURISMO", "ISATURISMO", "06.123", @ce, 2, 1, 1, 0, 1, "S"],
                 [empresa.name, empresa.short_name, empresa.state_registration, empresa.state, empresa.osmodel, empresa.osdupla,
                  empresa.iretorno, empresa.osshowcan, empresa.osshowcanrel, empresa.osincludechdcalc]

    cliente = Customer.find_by!(sistger_id: 10)
    assert_equal ["MARIA", "123", "ISENTO", "RUA B", "CENTRO", "60000", nil, "maria.com", nil, nil],
                 [cliente.nome, cliente.document, cliente.state_registration, cliente.address, cliente.neighborhood,
                  cliente.zipcode, cliente.state, cliente.website, cliente.contact, cliente.comments]
    assert_equal ["RUA C", "SOBRAL", @ce, "8577"],
                 [cliente.billing_address, cliente.billing_city, cliente.billing_state, cliente.billing_phone]

    hotel = Hotel.find_by!(sistger_id: 2)
    assert_equal [150.5, "FORTALEZA MAR", "AV X", "MEIRELES", "FORTALEZA", @ce, "60000000", "8533", nil, nil],
                 [hotel.Valordiaria, hotel.short_name, hotel.address, hotel.neighborhood, hotel.city, hotel.state,
                  hotel.zipcode, hotel.phone, hotel.phone2, hotel.comments]

    vendedor = Vendor.find_by!(sistger_id: 2348)
    agencia = Agency.find_by!(sistger_id: 7)
    assert_equal ["CEARA", 10.0, vendedor, @ce, nil], [agencia.short_name, agencia.commission, agencia.vendor, agencia.state, agencia.comments]

    assert_equal ["ALEX", "OSVALDO CRUZ, 01", "MEIRELES", "FORTALEZA", @ce, "60110345", "8533", nil, "8598", "000", nil, 5.0, false, nil],
                 [vendedor.short_name, vendedor.address, vendedor.neighborhood, vendedor.city, vendedor.state, vendedor.zipcode,
                  vendedor.phone, vendedor.phone2, vendedor.contact, vendedor.document, vendedor.classification,
                  vendedor.commission, vendedor.active, vendedor.comments]
    assert vendedor.no_commission, "bComissao is SISTGER's 'Não Pagar Comissão'"

    assert_equal [["MARCOS", "GUIA", "8599"], ["SANDRA", "GUIA", nil], ["ANA NANCHEN", "ANA GUIA", nil]],
                 Tourguide.where.not(sistger_id: nil).order(:sistger_id).pluck(:sname, :short_name, :contact).rotate(1)
    assert_equal ["ELIAS SILVA", "ELIAS"], Driver.find_by!(sistger_id: 5).values_at(:sname, :short_name)

    veiculo = Vehicle.find_by!(sistger_id: 1)
    assert_equal ["DUCATO", "VAN", "09", "10", "16", "9BD", "123", 2024, Date.new(2014, 5, 2), "N", @ce, nil],
                 [veiculo.brand, veiculo.vehicle_type, veiculo.manufacture_year, veiculo.year, veiculo.capacity, veiculo.chassis,
                  veiculo.renavam, veiculo.licensing_year, veiculo.acquired_on, veiculo.insurance_kit, veiculo.state, veiculo.comments]

    roteiro = Destination.find_by!(sistger_id: 0)
    assert_equal ["ITAIÇABA", @ce], [roteiro.description, roteiro.state], "missing UF falls back to the company's state"
    assert_equal [150.0, nil, 120.0, nil], [roteiro.value_combo, roteiro.value_combo_chd, roteiro.value_net_combo, roteiro.value_net_combo_chd]
  end

  test "imports commissions by destination, keyed by vendor and destination" do
    erro = assert_raises(SistgerImport::Erro) { @import.importar("comissoes_roteiro") }
    assert_match "Importe vendedores antes", erro.message

    importar_cadastros
    resultado = @import.importar("comissoes_roteiro")
    assert_equal [1, 2], [resultado.gravados, resultado.lidos]
    assert_match "1 comissão(ões) ignorada(s)", resultado.avisos.join

    registro = Vendor.find_by!(sistger_id: 2348).vendor_destinations.sole
    assert_equal ["ITAIÇABA", 15.0, 80.0, 85.0], [registro.destination.description, registro.commission, registro.net_adult, registro.net_adult_card]
    assert_no_difference("VendorDestination.count") { @import.importar("comissoes_roteiro") }
    assert_equal({ sistger: 2, importados: 1, ultimo_sistger: 9999, ultimo_importado: 2348 }, @import.contagens["comissoes_roteiro"])
  end

  test "re-importing vendors keeps observations written here" do
    @import.importar("vendedores")
    Vendor.find_by!(sistger_id: 2348).update!(comments: "Paga no dia 10")
    @import.importar("vendedores")
    assert_equal "Paga no dia 10", Vendor.find_by!(sistger_id: 2348).comments
  end

  test "re-importing updates instead of duplicating and leaves manual records alone" do
    manual = Customer.create!(nome: "MANUAL")
    @import.importar("clientes")
    Customer.find_by!(sistger_id: 10).update!(nome: "EDITADO AQUI")

    assert_no_difference("Customer.count") { @import.importar("clientes") }
    assert_equal "MARIA", Customer.find_by!(sistger_id: 10).nome
    assert_equal "MANUAL", manual.reload.nome
  end

  test "orders need the company and destinations first" do
    erro = assert_raises(SistgerImport::Erro) { @import.importar("ordens") }
    assert_equal "Importe empresa antes de ordens de serviço.", erro.message
  end

  test "orders link guides and drivers from the register by name or unique short name, else by the text" do
    importar_cadastros
    resultado = @import.importar("ordens")

    assert_equal 4, resultado.gravados
    assert_match "nº 3 em 02/12/5025", resultado.avisos.join

    os1, os2, os3, os4 = (1..4).map { |n| Sorder.find_by!(sistger_id: n) }
    assert_equal [32, 5], [os1.tourguide.sistger_id, os1.driver.sistger_id], "SANDRA by name, ELIAS by short name"
    assert_equal ["OCI6328", "ITAIÇABA", "ISA TURISMO"], [os1.vehicle.license, os1.destination.description, os1.company.name]
    assert_equal 29, os3.tourguide.sistger_id, "ANA GUIA is the unique short name of ANA NANCHEN"
    assert_nil os4.tourguide.sistger_id, "GUIA is shared by several guides, so a guide named GUIA is created"
    assert_equal ["GUIA", "OUTRO"], [os4.tourguide.sname, os4.driver.sname]
    assert_equal ["*", SistgerImport::NAO_INFORMADO, "VAN"], [os2.tourguide.sname, os2.driver.sname, os2.vehicle.license]
    assert_equal SistgerImport::NAO_INFORMADO, os3.vehicle.license
    assert_equal @ce, os2.vehicle.state
    assert_equal [50.0, 640.0, "OBS 1"], [os1.valorguia, os1.valoros, os1.sobservacoes]
  end

  test "passengers resolve hotel and agency by code, else by the text, and keep the extra passenger list" do
    importar_cadastros
    @import.importar("ordens")
    resultado = @import.importar("passageiros")

    assert_equal [2, 3], [resultado.gravados, resultado.lidos]
    assert_match "1 passageiro(s) ignorado(s)", resultado.avisos.join

    jorge = SorderItem.find_by!(sistger_numero: 1, sistger_sequencial: 1)
    assert_equal ["JORGE", "FORTALEZA MAR HOTEL", Agency.find_by!(sistger_id: 7).id, "MARIA", "ALEX TURISMO", "N"],
                 [jorge.snomepax, jorge.hotel.sname, jorge.agency_id, jorge.customer.nome, jorge.vendor.sname, jorge.scancelado]
    assert_equal "COMBO | Lista de passageiros: NADIA, PEDRO", jorge.comments
    assert_equal [40.0, 10.0, 20.0, 300.0], [jorge.amountcomission, jorge.amountcomissionpay, jorge.amountcomissionrep, jorge.total_passeio]

    leandro = SorderItem.find_by!(sistger_numero: 1, sistger_sequencial: 2)
    assert_equal ["BRASIL TROPICAL", "NOVA AGENCIA", "S"], [leandro.hotel.sname, Agency.find(leandro.agency_id).sname, leandro.scancelado]
    assert_equal 2, Sorder.find_by!(sistger_id: 1).total_pax, "cancelled passenger is not counted"

    assert_no_difference(["SorderItem.count", "Hotel.count", "Agency.count"]) { @import.importar("passageiros") }
  end

  test "preview maps rows without saving" do
    assert_no_difference(["Sorder.count", "Tourguide.count"]) do
      linhas = @import.previa("ordens", SistgerImport::Filtro.todos, 2)
      assert_equal 2, linhas.size
      assert_equal ["SANDRA", "*"], linhas.map { |l| l[:guia] }
    end
  end

  test "import honors the filter" do
    importar_cadastros
    filtro = SistgerImport::Filtro.de_params(modo: "periodo", inicio: "2025-10-01", fim: "2025-10-31")
    resultado = @import.importar("ordens", filtro)
    assert_equal 3, resultado.gravados
    assert_equal "período 01/10/2025 a 31/10/2025", resultado.filtro.descricao
    assert_equal [1, 2, 4], Sorder.where.not(sistger_id: nil).order(:sistger_id).pluck(:sistger_id), "nº 3 is dated 5025"
  end

  test "contagens compares SISTGER rows with imported records" do
    @import.importar("clientes")
    assert_equal({ sistger: 1, importados: 1, ultimo_sistger: 10, ultimo_importado: 10 }, @import.contagens["clientes"])
    assert_equal({ sistger: 4, importados: 0, ultimo_sistger: 4, ultimo_importado: nil }, @import.contagens["ordens"])
    # passenger 99/1 points at an order that doesn't exist: not the "last" one
    assert_equal({ sistger: 3, importados: 0, ultimo_sistger: 1, ultimo_importado: nil }, @import.contagens["passageiros"])
  end
end
