# Imports data from the legacy SISTGER SQL Server database (Manutenção tab).
#
# Each step reads one SISTGER table and upserts it here keyed by the legacy
# primary key (sistger_id, or sistger_numero/sistger_sequencial for order
# items), so running a step again updates what it imported instead of
# duplicating it. Records created directly in this app are never touched.
#
# Legacy service orders store guide, driver, vehicle plate, hotel and
# "repassado" agency as free text (their code columns are mostly 0). When
# no record matches by code, the text in the field is used: an existing
# record with that name/plate is reused, otherwise one is created.
class SistgerImport
  NAO_INFORMADO = "Não informado".freeze

  # codigo: legacy key column (code ranges, "last N"); ordem: default ORDER BY;
  # periodo: whether the date-period filter applies; origem: what to read
  # FROM when it isn't the table itself (a join), aliased by the table name.
  Etapa = Struct.new(:chave, :nome, :tabela, :modelo, :colunas, :codigo, :ordem, :periodo, :depende_de, :origem,
                     keyword_init: true) do
    def from = origem ? "(#{origem}) #{tabela}" : tabela

    # The SISTGER table(s) it reads, for the screen.
    def tabelas = origem ? origem.scan(/(?:FROM|JOIN) (\w+)/).join(" + ") : tabela
  end

  # Columns of SISTGER's generic cadastro screen (frmCadGenerico: vendors,
  # agencies, hotels, guides, drivers). Aliased so row keys don't depend on
  # each table's column casing (tblFuncionarios has iCODIGO, snome, ...).
  def self.colunas(nomes) = nomes.split.map { |c| "#{c} AS #{c}" }.join(", ")
  GENERICO = colunas("iCodigo sNome sNomeReduzido sEndereco sBairro sCidade sEstado sCep sTelefone1 sTelefone2 sEmail sContato sCNPJ sFax").freeze

  ETAPAS = [
    Etapa.new(chave: "empresa", nome: "Empresa", tabela: "Tblfilial", modelo: "Company", codigo: "iCODIGO",
              colunas: colunas("iCODIGO sNome sNomeRed sEndereco sCidade sEstado sCNPJ sCGF sEmail sWeb sTelefones iModeloOS " \
                               "iflgOSDupla bretorno sMostraCanceladosOS sMostraCancelados sMostraRepassados sCalculaValorCHD")),
    Etapa.new(chave: "clientes", nome: "Clientes", tabela: "tblClientes", modelo: "Customer", codigo: "iCodigo",
              colunas: colunas("iCodigo snome scgc scgf sendereco sBairro scidade sestado scep stelefone sfone2 sfax scontato " \
                               "semail sWEB sendcobranca sBairrocob scidcobranca sestcobranca scepcobranca stelcobranca " \
                               "sfone2cobranca sfaxcobranca")),
    Etapa.new(chave: "vendedores", nome: "Vendedores", tabela: "tblVendedor", modelo: "Vendor", codigo: "iCodigo",
              colunas: "#{GENERICO}, #{colunas('sClassificacao nPctComissao bAtivo bComissao')}"),
    Etapa.new(chave: "agencias", nome: "Agências", tabela: "tblAgenciaViagem", modelo: "Agency", codigo: "iCodigo",
              colunas: "#{GENERICO}, #{colunas('nPctComissao iCodVendedor')}"),
    Etapa.new(chave: "hoteis", nome: "Hotéis", tabela: "tblHotel", modelo: "Hotel", codigo: "iCodigo",
              colunas: "#{GENERICO}, #{colunas('nValorDiaria')}"),
    Etapa.new(chave: "guias", nome: "Guias", tabela: "tblAgenteViagem", modelo: "Tourguide", codigo: "iCodigo",
              colunas: GENERICO),
    Etapa.new(chave: "motoristas", nome: "Motoristas", tabela: "tblFuncionarios", modelo: "Driver", codigo: "iCodigo",
              colunas: GENERICO),
    Etapa.new(chave: "veiculos", nome: "Veículos", tabela: "tblveiculos", modelo: "Vehicle", codigo: "iCodigo",
              colunas: colunas("iCodigo sPlacas sTipo sMarca sModelo sAnoFabricacao sAnoModelo sCor sCidade sEstado sCapacidade " \
                               "sTanque sChassi sOdometro sRenavam iAnoLicenciamento dtAquisicao sKitSeguro")),
    Etapa.new(chave: "roteiros", nome: "Roteiros", tabela: "TblDistancias", modelo: "Destination", codigo: "iCodigo",
              colunas: colunas("iCodigo sDescricao sDistancia sEstado nValorIndividual nValorIndividualChd nNetAdulto nNetChd " \
                               "nNetAdultoCartao nNetCHDCartao nIndCombo nIndCHDCombo nNETCombo nNetComboCHD")),
    Etapa.new(chave: "comissoes_roteiro", nome: "Comissões por roteiro", tabela: "tblVendedorRoteiro",
              modelo: "VendorDestination", codigo: "iCodVendedor", ordem: "iCodVendedor, iCodRoteiro",
              depende_de: %w[vendedores roteiros],
              colunas: colunas("iCodVendedor iCodRoteiro cValorComissao cValorNet cValorNetCHD cValorNetCartao cValorNetCHDCartao")),
    Etapa.new(chave: "ordens", nome: "Ordens de serviço", tabela: "tblOrdemServico", modelo: "Sorder", codigo: "iNumero",
              periodo: true, depende_de: %w[empresa roteiros],
              colunas: "iNumero, Data, iCodDestino, iCodVeiculo, sPlacas, sNomeRedGuia, sNomeRedMotorista, nValorGuia, " \
                       "nValorMotorista, nValorPedagio, nDespesas, nValorCombustivel, nValorOS, ValorFinalOS, " \
                       "CAST(sObservacoes AS nvarchar(4000)) AS sObservacoes, bCancelado, iFlgAberto"),
    # cx_num (header) + cx_mov (lines): one cash book entry per line.
    Etapa.new(chave: "caixa", nome: "Caixa", tabela: "caixa", modelo: "CashEntry", codigo: "numero", ordem: "numero, iSql",
              periodo: true,
              origem: "SELECT m.numero, m.iSql, m.descricao, m.qtd, m.valor, m.total, m.tpMov, m.iNumeroOS, m.iSeq, " \
                      "c.data AS Data, c.requerente, c.scpfcnpj, c.tipo_pg FROM cx_mov m JOIN cx_num c ON c.numero = m.numero",
              colunas: "numero, iSql, descricao, qtd, valor, total, tpMov, iNumeroOS, iSeq, Data, requerente, scpfcnpj, tipo_pg")
  ].each { |etapa| etapa.ordem ||= etapa.codigo }.each(&:freeze).freeze

  # Parts of an order, read and saved by the "ordens" step for the orders it
  # imports (they have no filter of their own).
  PARTES_DA_ORDEM = [
    Etapa.new(chave: "passageiros", nome: "Passageiros", tabela: "tblOrdemServicoItens", modelo: "SorderItem", codigo: "iNumero",
              ordem: "iNumero, iSequencial",
              colunas: "iNumero, iSequencial, iCodCliente, sNomeCliente, iCodHotel, sHotel, sNumeroApto, iNumeroPax, iNumeroCHD, " \
                       "sHora, sTelefone, nValor, nValorPago, iCodVendedor, nValorComissao, nValorRecVendedor, iCodRepassado, " \
                       "sRepassado, nValorComissaoRepassado, nValorPagoRepasse, sFlgCancelado, sTipoDoc, sNumeroDoc, " \
                       "nDesconto, nDescontoVendedor, CAST(sObservacoes AS nvarchar(4000)) AS sObservacoes"),
    Etapa.new(chave: "recebimentos", nome: "Recebimentos", tabela: "tblOrdemServicoPagtos", modelo: "SorderItemPayment",
              codigo: "iNumero", ordem: "iNumero, iSql, iSeq",
              colunas: "iNumero, iSql, iSeq, sDescri, cValor, data, sUsuario, iNumeroCXA"),
    Etapa.new(chave: "lista_pax", nome: "Lista pax", tabela: "tblListaPax", modelo: "SorderItemCompanion", codigo: "iNumero",
              ordem: "iNumero, iSequencial, iSeqAdicional",
              colunas: "iNumero, iSequencial, iSeqAdicional, iClienteAdc, sNomeCliente, sTipoDoc, sNumeroDoc, SCHD, SCOLO")
  ].each(&:freeze).freeze

  # Labels for reference columns shown in the preview before they're resolved to ids.
  ROTULOS = {
    uf: "UF", roteiro: "Roteiro (código SISTGER)", guia: "Guia", motorista: "Motorista",
    veiculo: "Veículo (código SISTGER)", placa: "Placa", ordem: "Ordem (nº SISTGER)",
    sequencial: "Sequencial", cliente: "Cliente (código SISTGER)", hotel_codigo: "Hotel (código SISTGER)",
    hotel: "Hotel", vendedor: "Vendedor (código SISTGER)", agencia_codigo: "Agência de repasse (código SISTGER)",
    agencia: "Agência de repasse"
  }.freeze

  LOTE = 1000

  # detalhes: what was saved along with the step (an order's passengers and pax list).
  Resultado = Struct.new(:etapa, :filtro, :lidos, :gravados, :avisos, :detalhes, keyword_init: true)

  class Erro < StandardError; end

  def self.etapa(chave)
    ETAPAS.find { |e| e.chave == chave } or raise Erro, "Etapa desconhecida: #{chave}"
  end

  def initialize(fonte = Fonte.new)
    @fonte = fonte
  end

  # {chave => {sistger:, importados:, ultimo_sistger:, ultimo_importado:}}:
  # row counts and highest legacy code on each side, to help pick the code
  # range still to import.
  def contagens
    ETAPAS.to_h do |etapa|
      coluna = etapa.chave == "caixa" ? :sistger_numero : :sistger_id
      importados = etapa.modelo.constantize.where.not(coluna => nil)
      if etapa.chave == "comissoes_roteiro" # keyed by vendor + destination, counted by the vendor's code
        coluna = "vendors.sistger_id"
        importados = VendorDestination.joins(:vendor).where.not(vendors: { sistger_id: nil })
      end
      origem = @fonte.resumo(etapa.from, etapa.codigo)
      [etapa.chave, { sistger: origem[:total], importados: importados.count,
                      ultimo_sistger: origem[:ultimo], ultimo_importado: importados.maximum(coluna) }]
    end
  end

  # First rows of a step (honoring the filter), mapped but not saved.
  # References show the legacy code or the text they will be matched by.
  def previa(chave, filtro = Filtro.todos, limite = 5)
    linhas = ler(self.class.etapa(chave), filtro, limite: limite)
    linhas.map { |linha| mapear(chave, linha) }
  end

  def importar(chave, filtro = Filtro.todos)
    etapa = self.class.etapa(chave)
    verificar_dependencias(etapa)
    linhas = ler(etapa, filtro)
    avisos = []
    @detalhes = []
    gravados = etapa.modelo.constantize.transaction { gravar(chave, linhas.map { |l| mapear(chave, l) }, avisos) }
    Resultado.new(etapa: etapa, filtro: filtro, lidos: linhas.size, gravados: gravados, avisos: avisos, detalhes: @detalhes)
  end

  # Runs the chosen steps in dependency order. filtros: {chave => Filtro}.
  def importar_etapas(chaves, filtros = {})
    ETAPAS.select { |etapa| chaves.include?(etapa.chave) }
          .map { |etapa| importar(etapa.chave, filtros.fetch(etapa.chave, Filtro.todos)) }
  end

  def importar_tudo
    importar_etapas(ETAPAS.map(&:chave))
  end

  private

  # ---- SQL ---------------------------------------------------------------

  def ler(etapa, filtro, limite: nil)
    @fonte.linhas(filtro.sql(etapa, limite: limite))
  end

  # Rows of an order part (passengers, pax list) for the orders `numeros`.
  # Few orders are filtered by number; many read the whole table in one
  # pass, much faster than batches of IN (...) that each scan it.
  def ler_da_ordem(parte, numeros)
    return [] if numeros.empty?

    filtro = numeros.size <= LOTE ? " WHERE iNumero IN (#{numeros.map { |n| Integer(n) }.join(',')})" : ""
    linhas = @fonte.linhas("SELECT #{parte.colunas} FROM #{parte.from}#{filtro} ORDER BY #{parte.ordem}")
    return linhas unless filtro.empty?

    numeros = numeros.to_set
    linhas.select { |l| numeros.include?(l["iNumero"]) }
  end

  # ---- Mapping (one SISTGER row -> attributes here) -------------------------

  def mapear(chave, l)
    case chave
    when "empresa"
      { sistger_id: l["iCODIGO"], name: texto(l["sNome"]), short_name: texto(l["sNomeRed"]), cnpj: texto(l["sCNPJ"]),
        state_registration: texto(l["sCGF"]), address: texto(l["sEndereco"]), city: texto(l["sCidade"]), uf: texto(l["sEstado"]),
        email: texto(l["sEmail"]), site: texto(l["sWeb"]), phone: texto(l["sTelefones"]), osmodel: l["iModeloOS"],
        osdupla: l["iflgOSDupla"], iretorno: l["bretorno"] ? 1 : 0, osshowcan: sim(l["sMostraCanceladosOS"]),
        osshowcanrel: sim(l["sMostraCancelados"]), osshowrep: sim(l["sMostraRepassados"]),
        osincludechdcalc: texto(l["sCalculaValorCHD"]) }
    when "clientes"
      # Observations are left out (here and below) so re-importing keeps what was written here.
      { sistger_id: l["iCodigo"], nome: texto(l["snome"]), document: texto(l["scgc"]), state_registration: texto(l["scgf"]),
        address: texto(l["sendereco"]), neighborhood: texto(l["sBairro"]), city: texto(l["scidade"]), uf: texto(l["sestado"]),
        zipcode: texto(l["scep"]), phone: texto(l["stelefone"]), phone2: texto(l["sfone2"]), fax: texto(l["sfax"]),
        contact: texto(l["scontato"]), email: texto(l["semail"]), website: texto(l["sWEB"]),
        billing_address: texto(l["sendcobranca"]), billing_neighborhood: texto(l["sBairrocob"]),
        billing_city: texto(l["scidcobranca"]), uf_cobranca: texto(l["sestcobranca"]), billing_zipcode: texto(l["scepcobranca"]),
        billing_phone: texto(l["stelcobranca"]), billing_phone2: texto(l["sfone2cobranca"]), billing_fax: texto(l["sfaxcobranca"]) }
    when "vendedores"
      generico(l).merge(classification: texto(l["sClassificacao"]), commission: numero(l["nPctComissao"]),
                        active: l["bAtivo"] != false, no_commission: l["bComissao"] == true)
    when "agencias"
      generico(l).merge(commission: numero(l["nPctComissao"]), vendedor: l["iCodVendedor"])
    when "hoteis"
      generico(l).merge(Valordiaria: numero(l["nValorDiaria"]))
    when "guias", "motoristas"
      generico(l)
    when "comissoes_roteiro"
      { vendedor: l["iCodVendedor"], roteiro: l["iCodRoteiro"], commission: numero(l["cValorComissao"]),
        net_adult: numero(l["cValorNet"]), net_chd: numero(l["cValorNetCHD"]),
        net_adult_card: numero(l["cValorNetCartao"]), net_chd_card: numero(l["cValorNetCHDCartao"]) }
    when "veiculos"
      { sistger_id: l["iCodigo"], license: texto(l["sPlacas"]), vehicle_type: texto(l["sTipo"]), brand: texto(l["sMarca"]),
        smodel: texto(l["sModelo"]), manufacture_year: texto(l["sAnoFabricacao"]), year: texto(l["sAnoModelo"]),
        color: texto(l["sCor"]), city: texto(l["sCidade"]), uf: texto(l["sEstado"]), capacity: texto(l["sCapacidade"]),
        tank: texto(l["sTanque"]), chassis: texto(l["sChassi"]), odometer: texto(l["sOdometro"]), renavam: texto(l["sRenavam"]),
        licensing_year: l["iAnoLicenciamento"].presence, acquired_on: l["dtAquisicao"]&.to_date,
        insurance_kit: texto(l["sKitSeguro"]) }
    when "roteiros"
      { sistger_id: l["iCodigo"], description: texto(l["sDescricao"]), distance: l["sDistancia"], uf: texto(l["sEstado"]),
        valuenormal: numero(l["nValorIndividual"]), valuenormalchd: numero(l["nValorIndividualChd"]),
        valuenet: numero(l["nNetAdulto"]), valuenetchd: numero(l["nNetChd"]),
        valuecard: numero(l["nNetAdultoCartao"]), valuecardchd: numero(l["nNetCHDCartao"]),
        value_combo: numero(l["nIndCombo"]), value_combo_chd: numero(l["nIndCHDCombo"]),
        value_net_combo: numero(l["nNETCombo"]), value_net_combo_chd: numero(l["nNetComboCHD"]) }
    when "ordens"
      { sistger_id: l["iNumero"], data: l["Data"],
        sobservacoes: juntar(texto(l["sObservacoes"]), ("CANCELADA no SISTGER" if l["bCancelado"]), separador: " | "),
        roteiro: l["iCodDestino"], guia: texto(l["sNomeRedGuia"]) || NAO_INFORMADO,
        motorista: texto(l["sNomeRedMotorista"]) || NAO_INFORMADO,
        veiculo: l["iCodVeiculo"], placa: texto(l["sPlacas"]) || NAO_INFORMADO,
        valorguia: numero(l["nValorGuia"]), valormotorista: numero(l["nValorMotorista"]),
        valorpedagio: numero(l["nValorPedagio"]), valordespesas: numero(l["nDespesas"]),
        valorcombustivel: numero(l["nValorCombustivel"]), valoros: numero(l["nValorOS"]), valorfinalos: numero(l["ValorFinalOS"]),
        encerrada: l["iFlgAberto"] == 1 }
    when "caixa"
      { sistger_numero: Integer(l["numero"]), sistger_linha: Integer(l["iSql"]), data: l["Data"]&.to_date,
        tipo: texto(l["tpMov"]) == "S" ? "S" : "E", forma_pagamento: CashEntry::FORMAS.key?(texto(l["tipo_pg"])) ? texto(l["tipo_pg"]) : "D",
        valor: numero(l["total"] || l["valor"])&.abs, descricao: texto(l["descricao"]) || "Lançamento do SISTGER nº #{Integer(l['numero'])}",
        requerente: texto(l["requerente"]), documento: (doc = texto(l["scpfcnpj"])) && !doc.match?(/\A0*\z/) ? doc : nil,
        ordem: l["iNumeroOS"].to_i, sequencial: l["iSeq"].to_i }
    when "recebimentos"
      { ordem: l["iNumero"], sequencial: l["iSql"], sistger_seq: l["iSeq"], descricao: texto(l["sDescri"]), valor: numero(l["cValor"]),
        data: l["data"]&.to_date, usuario: texto(l["sUsuario"]), sistger_caixa: l["iNumeroCXA"].to_i.nonzero? }
    when "passageiros"
      { ordem: l["iNumero"], sequencial: l["iSequencial"], cliente: l["iCodCliente"], snomepax: texto(l["sNomeCliente"]),
        documenttype: texto(l["sTipoDoc"]), document: texto(l["sNumeroDoc"]),
        hotel_codigo: l["iCodHotel"], hotel: texto(l["sHotel"]), apto: texto(l["sNumeroApto"]),
        qtdepax: l["iNumeroPax"], qtdechd: l["iNumeroCHD"], hour: texto(l["sHora"]), phone: texto(l["sTelefone"]),
        amount: numero(l["nValor"]), amountpay: numero(l["nValorPago"]),
        vendedor: l["iCodVendedor"], amountcomission: numero(l["nValorComissao"]), amountcomissionpay: numero(l["nValorRecVendedor"]),
        agencia_codigo: l["iCodRepassado"], agencia: texto(l["sRepassado"]),
        amountcomissionrep: numero(l["nValorComissaoRepassado"]), amountcomissionreppay: numero(l["nValorPagoRepasse"]),
        scancelado: texto(l["sFlgCancelado"]) == "S" ? "S" : "N",
        discount: numero(l["nDesconto"]), vendor_discount: numero(l["nDescontoVendedor"]),
        comments: texto(l["sObservacoes"]) }
    when "lista_pax"
      { ordem: l["iNumero"], sequencial: l["iSequencial"], sistger_seq_adicional: l["iSeqAdicional"], cliente: l["iClienteAdc"],
        snome: texto(l["sNomeCliente"]), documenttype: texto(l["sTipoDoc"]), document: texto(l["sNumeroDoc"]),
        chd: texto(l["SCHD"]) == "S", colo: texto(l["SCOLO"]) == "S" }
    end
  end

  # Fields of SISTGER's generic cadastro screen.
  def generico(l)
    { sistger_id: l["iCodigo"], sname: texto(l["sNome"]), short_name: texto(l["sNomeReduzido"]), document: texto(l["sCNPJ"]),
      email: texto(l["sEmail"]), address: texto(l["sEndereco"]), neighborhood: texto(l["sBairro"]), city: texto(l["sCidade"]),
      uf: texto(l["sEstado"]), zipcode: texto(l["sCep"]), phone: texto(l["sTelefone1"]), phone2: texto(l["sTelefone2"]),
      fax: texto(l["sFax"]), contact: texto(l["sContato"]) }
  end

  # ---- Saving --------------------------------------------------------------

  def gravar(chave, registros, avisos)
    case chave
    when "ordens"
      gravar_ordens(registros, avisos)
    when "comissoes_roteiro"
      gravar_comissoes_roteiro(registros, avisos)
    when "caixa"
      gravar_caixa(registros, avisos)
    else
      estados = estados_por_uf
      padrao = estado_padrao(estados)
      precisa_estado = %w[empresa veiculos roteiros].include?(chave) # companies, vehicles and destinations require one
      vendedores = Vendor.where.not(sistger_id: nil).pluck(:sistger_id, :id).to_h if chave == "agencias"
      registros = registros.map do |r|
        r = r.dup
        r[:state_id] = estados[r.delete(:uf)&.upcase] || (padrao if precisa_estado)
        r[:billing_state_id] = estados[r.delete(:uf_cobranca)&.upcase] if chave == "clientes"
        r[:vendor_id] = vendedores[r.delete(:vendedor)] if chave == "agencias"
        r
      end
      upsert(self.class.etapa(chave).modelo.constantize, registros)
    end
  end

  def upsert(modelo, registros, unique_by: :sistger_id)
    registros.each_slice(LOTE) { |lote| modelo.upsert_all(lote, unique_by: unique_by) }
    registros.size
  end

  def gravar_ordens(registros, avisos)
    empresa_id = Company.where.not(sistger_id: nil).order(:sistger_id).pick(:id) or
      raise Erro, "Importe a empresa antes das ordens de serviço."
    roteiros = Destination.where.not(sistger_id: nil).pluck(:sistger_id, :id).to_h
    veiculos_codigo = Vehicle.where.not(sistger_id: nil).pluck(:sistger_id, :id).to_h
    # Orders keep the guide's/driver's (short) name as text: match the
    # imported register by name or short name, else create one.
    guias = ids_por_nome(Tourguide, :sname, registros.map { |r| r[:guia] }, tambem: :short_name)
    motoristas = ids_por_nome(Driver, :sname, registros.map { |r| r[:motorista] }, tambem: :short_name)
    sem_veiculo = registros.reject { |r| veiculos_codigo[r[:veiculo]] }
    estado = estado_padrao(estados_por_uf)
    placas = ids_por_nome(Vehicle, :license, sem_veiculo.map { |r| r[:placa] }, { state_id: estado })

    sem_roteiro, validos = registros.partition { |r| roteiros[r[:roteiro]].nil? }
    avisos << "#{sem_roteiro.size} ordem(ns) ignorada(s) por roteiro inexistente (nº #{sem_roteiro.first(5).map { |r| r[:sistger_id] }.join(', ')})." if sem_roteiro.any?
    datas_estranhas = validos.select { |r| r[:data] && !r[:data].year.between?(1990, 2100) }
    if datas_estranhas.any?
      exemplos = datas_estranhas.first(3).map { |r| "nº #{r[:sistger_id]} em #{r[:data].strftime('%d/%m/%Y')}" }.join(", ")
      avisos << "#{datas_estranhas.size} ordem(ns) com data fora do normal importada(s) como estão (#{exemplos})."
    end

    # The order number (id) is SISTGER's iNumero. A number already taken by
    # an order created here stays with it, and the legacy order is skipped.
    renumerar_ordens
    ocupados = Sorder.where(id: validos.map { |r| r[:sistger_id] }).where("sistger_id IS DISTINCT FROM id").pluck(:id)
    if ocupados.any?
      avisos << "#{ocupados.size} ordem(ns) ignorada(s) porque o número já é de outra ordem deste sistema (nº #{ocupados.sort.first(5).join(', ')})."
      validos = validos.reject { |r| ocupados.include?(r[:sistger_id]) }
    end

    linhas = validos.map do |r|
      r.except(:roteiro, :guia, :motorista, :veiculo, :placa).merge(
        id: r[:sistger_id], destination_id: roteiros[r[:roteiro]], tourguide_id: guias[r[:guia]], driver_id: motoristas[r[:motorista]],
        vehicle_id: veiculos_codigo[r[:veiculo]] || placas[r[:placa]], company_id: empresa_id
      )
    end
    gravados = upsert(Sorder, linhas)
    Sorder.connection.reset_pk_sequence!(Sorder.table_name)
    gravar_partes_da_ordem(linhas.map { |l| l[:id] }, avisos)
    gravados
  end

  # Passengers (tblOrdemServicoItens) and their pax list (tblListaPax) of
  # the orders just saved.
  def gravar_partes_da_ordem(numeros, avisos)
    passageiros, recebimentos, lista_pax = PARTES_DA_ORDEM
    itens = ler_da_ordem(passageiros, numeros).map { |l| mapear("passageiros", l) }
    @detalhes << "#{gravar_passageiros(itens, avisos)} passageiro(s)"
    pagos = ler_da_ordem(recebimentos, numeros).map { |l| mapear("recebimentos", l) }
    @detalhes << "#{gravar_recebimentos(numeros, pagos, avisos)} recebimento(s)"
    pax = ler_da_ordem(lista_pax, numeros).map { |l| mapear("lista_pax", l) }
    @detalhes << "#{gravar_lista_pax(numeros, pax, avisos)} na lista pax"
  end

  # Gives imported orders numbered otherwise (before iNumero became the id)
  # their SISTGER number, when it's free. Passengers follow via the FK's
  # ON UPDATE CASCADE. Negating first avoids clashes while swapping.
  def renumerar_ordens
    conexao = Sorder.connection
    conexao.execute("UPDATE sorders SET id = -id WHERE sistger_id IS NOT NULL AND id <> sistger_id")
    conexao.execute("UPDATE sorders SET id = sistger_id WHERE id < 0 AND sistger_id NOT IN (SELECT id FROM sorders WHERE id > 0)")
    conexao.execute("UPDATE sorders SET id = -id WHERE id < 0")
  end

  def gravar_comissoes_roteiro(registros, avisos)
    vendedores = Vendor.where.not(sistger_id: nil).pluck(:sistger_id, :id).to_h
    roteiros = Destination.where.not(sistger_id: nil).pluck(:sistger_id, :id).to_h
    sem_vinculo, validos = registros.partition { |r| vendedores[r[:vendedor]].nil? || roteiros[r[:roteiro]].nil? }
    avisos << "#{sem_vinculo.size} comissão(ões) ignorada(s) por vendedor ou roteiro não importado." if sem_vinculo.any?

    linhas = validos.map do |r|
      r.except(:vendedor, :roteiro).merge(vendor_id: vendedores[r[:vendedor]], destination_id: roteiros[r[:roteiro]])
    end
    upsert(VendorDestination, linhas, unique_by: %i[vendor_id destination_id])
  end

  def gravar_passageiros(registros, avisos)
    ordens = Sorder.where.not(sistger_id: nil).pluck(:sistger_id, :id).to_h
    clientes = Customer.where.not(sistger_id: nil).pluck(:sistger_id, :id).to_h
    vendedores = Vendor.where.not(sistger_id: nil).pluck(:sistger_id, :id).to_h
    hoteis_codigo = Hotel.where.not(sistger_id: nil).pluck(:sistger_id, :id).to_h
    agencias_codigo = Agency.where.not(sistger_id: nil).pluck(:sistger_id, :id).to_h
    hoteis = ids_por_nome(Hotel, :sname, registros.reject { |r| hoteis_codigo[r[:hotel_codigo]] }.filter_map { |r| r[:hotel] })
    agencias = ids_por_nome(Agency, :sname, registros.reject { |r| agencias_codigo[r[:agencia_codigo]] }.filter_map { |r| r[:agencia] })

    sem_ordem, validos = registros.partition { |r| ordens[r[:ordem]].nil? }
    avisos << "#{sem_ordem.size} passageiro(s) ignorado(s) porque a ordem não existe no SISTGER ou não foi importada." if sem_ordem.any?

    linhas = validos.map do |r|
      r.except(:ordem, :sequencial, :cliente, :hotel_codigo, :hotel, :vendedor, :agencia_codigo, :agencia).merge(
        sistger_numero: r[:ordem], sistger_sequencial: r[:sequencial], sorder_id: ordens[r[:ordem]],
        customer_id: clientes[r[:cliente]], vendor_id: vendedores[r[:vendedor]],
        hotel_id: hoteis_codigo[r[:hotel_codigo]] || hoteis[r[:hotel]],
        agency_id: agencias_codigo[r[:agencia_codigo]] || agencias[r[:agencia]]
      )
    end
    upsert(SorderItem, linhas, unique_by: %i[sistger_numero sistger_sequencial])
  end

  # Payments of imported items are replaced by SISTGER's (those added here
  # stay). They link to the cash book entry SISTGER posted them as, when
  # the cash book was imported.
  def gravar_recebimentos(numeros, registros, avisos)
    itens = itens_importados(numeros)
    SorderItemPayment.where(sorder_item_id: itens.values).where.not(sistger_seq: nil).delete_all

    invalidos, registros = registros.partition { |r| r[:valor].to_f <= 0 || r[:data].nil? }
    sem_item, validos = registros.partition { |r| itens[[r[:ordem], r[:sequencial]]].nil? }
    avisos << "#{invalidos.size} recebimento(s) sem valor ou data ignorado(s)." if invalidos.any?
    avisos << "#{sem_item.size} recebimento(s) ignorado(s) porque o passageiro não foi importado." if sem_item.any?

    caixa = lancamentos_do_caixa(validos.filter_map { |r| r[:sistger_caixa] })
    agora = Time.current
    linhas = validos.map do |r|
      lancamento = caixa[r[:sistger_caixa]]
      r.except(:ordem, :sequencial).merge(sorder_item_id: itens[[r[:ordem], r[:sequencial]]], cash_entry_id: lancamento&.first,
                                          forma_pagamento: lancamento&.last, created_at: agora, updated_at: agora)
    end
    linhas.each_slice(LOTE) { |lote| SorderItemPayment.insert_all(lote) }
    linhas.size
  end

  # Cash book: entries are keyed by SISTGER's number and line. Each links to
  # its order/passenger, and payments posted as it get linked back.
  def gravar_caixa(registros, avisos)
    invalidos, validos = registros.partition { |r| r[:valor].to_f <= 0 || r[:data].nil? }
    avisos << "#{invalidos.size} lançamento(s) de caixa sem valor ou data ignorado(s)." if invalidos.any?

    ordens = Sorder.where(id: validos.map { |r| r[:ordem] }.uniq).pluck(:id).to_set
    itens = itens_importados(ordens.to_a)
    linhas = validos.map do |r|
      r.except(:ordem, :sequencial).merge(
        categoria: r[:tipo] == "S" ? "Pagamento de conta" : (r[:ordem].positive? ? "Recebimento de passeio" : "Outros"),
        sorder_id: (r[:ordem] if ordens.include?(r[:ordem])), sorder_item_id: itens[[r[:ordem], r[:sequencial]]]
      )
    end
    gravados = upsert(CashEntry, linhas, unique_by: %i[sistger_numero sistger_linha])

    SorderItemPayment.connection.execute(<<~SQL)
      UPDATE sorder_item_payments p
         SET cash_entry_id = c.id, forma_pagamento = c.forma_pagamento
        FROM (SELECT DISTINCT ON (sistger_numero) id, sistger_numero, forma_pagamento
                FROM cash_entries WHERE sistger_numero IS NOT NULL ORDER BY sistger_numero, sistger_linha) c
       WHERE p.sistger_caixa = c.sistger_numero
    SQL
    gravados
  end

  # {[order number, sequential] => id} of the imported items of these orders.
  def itens_importados(numeros)
    SorderItem.where(sistger_numero: numeros).pluck(:sistger_numero, :sistger_sequencial, :id)
              .to_h { |numero, sequencial, id| [[numero, sequencial], id] }
  end

  # {SISTGER cash number => [id, payment method]} of imported entries (first line).
  def lancamentos_do_caixa(numeros)
    CashEntry.where(sistger_numero: numeros.uniq).order(:sistger_numero, :sistger_linha)
             .pluck(:sistger_numero, :id, :forma_pagamento).each_with_object({}) { |(n, id, forma), h| h[n] ||= [id, forma] }
  end

  # The pax list of imported items is replaced by SISTGER's; names added
  # here (no sistger_seq_adicional) stay.
  def gravar_lista_pax(numeros, registros, avisos)
    itens = itens_importados(numeros)
    SorderItemCompanion.where(sorder_item_id: itens.values).where.not(sistger_seq_adicional: nil).delete_all

    sem_nome, registros = registros.partition { |r| r[:snome].nil? }
    sem_item, validos = registros.partition { |r| itens[[r[:ordem], r[:sequencial]]].nil? }
    avisos << "#{sem_nome.size} nome(s) em branco na lista pax ignorado(s)." if sem_nome.any?
    avisos << "#{sem_item.size} nome(s) da lista pax ignorado(s) porque o passageiro não foi importado." if sem_item.any?

    clientes = Customer.where(sistger_id: validos.map { |r| r[:cliente] }.uniq).pluck(:sistger_id, :id).to_h
    agora = Time.current
    linhas = validos.map do |r|
      r.except(:ordem, :sequencial, :cliente).merge(sorder_item_id: itens[[r[:ordem], r[:sequencial]]],
                                                     customer_id: clientes[r[:cliente]], created_at: agora, updated_at: agora)
    end
    linhas.each_slice(LOTE) { |lote| SorderItemCompanion.insert_all(lote) }
    linhas.size
  end

  # {name => id}, creating records for names not found (exact match).
  # `tambem` is a second column to match (e.g. short_name) when it
  # identifies a single record; a match on `coluna` wins.
  def ids_por_nome(modelo, coluna, nomes, extras = {}, tambem: nil)
    nomes = nomes.compact.uniq
    ids = {}
    if tambem
      modelo.where(tambem => nomes).pluck(tambem, :id).group_by(&:first).each do |nome, pares|
        ids[nome] = pares.first.last if pares.one?
      end
    end
    ids.merge!(modelo.where(coluna => nomes).pluck(coluna, :id).to_h)
    faltando = nomes - ids.keys
    faltando.each_slice(LOTE) do |lote|
      modelo.insert_all(lote.map { |nome| { coluna => nome }.merge(extras) }, returning: [coluna, :id]).rows.each do |nome, id|
        ids[nome] = id
      end
    end
    ids
  end

  def verificar_dependencias(etapa)
    Array(etapa.depende_de).each do |chave|
      dependencia = self.class.etapa(chave)
      modelo = dependencia.modelo.constantize
      next if modelo.where.not(sistger_id: nil).exists?

      raise Erro, "Importe #{dependencia.nome.downcase} antes de #{etapa.nome.downcase}."
    end
  end

  def estados_por_uf
    State.pluck(:uf, :id).to_h.transform_keys { |uf| uf.to_s.strip.upcase }
  end

  # States are required on companies, vehicles and destinations; when SISTGER
  # has none, use the imported company's state (the agency's home state).
  def estado_padrao(estados)
    Company.where.not(sistger_id: nil).order(:sistger_id).pick(:state_id) ||
      Company.order(:id).pick(:state_id) || estados.values.first
  end

  # ---- Value helpers ------------------------------------------------------------

  def texto(valor)
    valor.is_a?(String) ? valor.strip.presence : valor
  end

  def numero(valor)
    valor&.to_f
  end

  def sim(valor)
    texto(valor) == "S" ? 1 : 0
  end

  def endereco(*partes)
    juntar(*partes, separador: ", ")
  end

  def juntar(*partes, separador: " / ")
    partes.map { |p| texto(p) }.compact.join(separador).presence
  end
end
