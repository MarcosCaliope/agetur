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
  # periodo: whether the date-period filter applies.
  Etapa = Struct.new(:chave, :nome, :tabela, :modelo, :colunas, :codigo, :ordem, :periodo, :depende_de, keyword_init: true)

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
    Etapa.new(chave: "ordens", nome: "Ordens de serviço", tabela: "tblOrdemServico", modelo: "Sorder", codigo: "iNumero",
              periodo: true, depende_de: %w[empresa roteiros],
              colunas: "iNumero, Data, iCodDestino, iCodVeiculo, sPlacas, sNomeRedGuia, sNomeRedMotorista, nValorGuia, " \
                       "nValorMotorista, nValorPedagio, nDespesas, nValorCombustivel, nValorOS, ValorFinalOS, " \
                       "CAST(sObservacoes AS nvarchar(4000)) AS sObservacoes, bCancelado"),
    Etapa.new(chave: "passageiros", nome: "Passageiros", tabela: "tblOrdemServicoItens", modelo: "SorderItem", codigo: "iNumero",
              ordem: "iNumero, iSequencial", periodo: true, depende_de: %w[ordens],
              colunas: "iNumero, iSequencial, iCodCliente, sNomeCliente, iCodHotel, sHotel, sNumeroApto, iNumeroPax, iNumeroCHD, " \
                       "sHora, sTelefone, nValor, nValorPago, iCodVendedor, nValorComissao, nValorRecVendedor, iCodRepassado, " \
                       "sRepassado, nValorComissaoRepassado, nValorPagoRepasse, sFlgCancelado, sTipoDoc, sNumeroDoc, " \
                       "CAST(sObservacoes AS nvarchar(4000)) AS sObservacoes")
  ].each { |etapa| etapa.ordem ||= etapa.codigo }.each(&:freeze).freeze

  # Labels for reference columns shown in the preview before they're resolved to ids.
  ROTULOS = {
    uf: "UF", roteiro: "Roteiro (código SISTGER)", guia: "Guia", motorista: "Motorista",
    veiculo: "Veículo (código SISTGER)", placa: "Placa", ordem: "Ordem (nº SISTGER)",
    sequencial: "Sequencial", cliente: "Cliente (código SISTGER)", hotel_codigo: "Hotel (código SISTGER)",
    hotel: "Hotel", vendedor: "Vendedor (código SISTGER)", agencia_codigo: "Agência de repasse (código SISTGER)",
    agencia: "Agência de repasse"
  }.freeze

  LOTE = 1000

  Resultado = Struct.new(:etapa, :filtro, :lidos, :gravados, :avisos, keyword_init: true)

  class Erro < StandardError; end

  def self.etapa(chave)
    ETAPAS.find { |e| e.chave == chave } or raise Erro, "Etapa desconhecida: #{chave}"
  end

  def initialize(fonte = Fonte.new)
    @fonte = fonte
  end

  # {chave => {sistger:, importados:, ultimo_sistger:, ultimo_importado:}}:
  # row counts and highest legacy code (order number for passengers) on
  # each side, to help pick the code range still to import.
  def contagens
    ETAPAS.to_h do |etapa|
      coluna = etapa.chave == "passageiros" ? :sistger_numero : :sistger_id
      importados = etapa.modelo.constantize.where.not(coluna => nil)
      # A few legacy passengers point at order numbers that don't exist; they
      # can't be imported, so they don't count as the last one.
      onde = "iNumero IN (SELECT iNumero FROM tblOrdemServico)" if etapa.chave == "passageiros"
      origem = @fonte.resumo(etapa.tabela, etapa.codigo, ultimo_onde: onde)
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
    gravados = etapa.modelo.constantize.transaction { gravar(chave, linhas.map { |l| mapear(chave, l) }, avisos) }
    Resultado.new(etapa: etapa, filtro: filtro, lidos: linhas.size, gravados: gravados, avisos: avisos)
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
    linhas = @fonte.linhas(filtro.sql(etapa, limite: limite))
    etapa.chave == "passageiros" ? juntar_lista_pax(linhas) : linhas
  end

  # tblListaPax holds the other passengers of an order item; their names are
  # appended to the item's observations.
  def juntar_lista_pax(linhas)
    numeros = linhas.map { |l| l["iNumero"] }.uniq
    return linhas if numeros.empty?

    # A preview filters by order number; a full import reads the whole table
    # in one pass, much faster than batches of IN (...) that each scan it.
    filtro = numeros.size <= LOTE ? "WHERE iNumero IN (#{numeros.map { |n| Integer(n) }.join(',')}) " : ""
    nomes = Hash.new { |h, k| h[k] = [] }
    @fonte.linhas("SELECT iNumero, iSequencial, sNomeCliente FROM tblListaPax #{filtro}" \
                  "ORDER BY iNumero, iSequencial, iSeqAdicional").each do |pax|
      nome = texto(pax["sNomeCliente"])
      nomes[[pax["iNumero"], pax["iSequencial"]]] << nome if nome
    end
    linhas.map { |l| l.merge("lista_pax" => nomes[[l["iNumero"], l["iSequencial"]]]) }
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
        valorcombustivel: numero(l["nValorCombustivel"]), valoros: numero(l["nValorOS"]), valorfinalos: numero(l["ValorFinalOS"]) }
    when "passageiros"
      lista = Array(l["lista_pax"])
      { ordem: l["iNumero"], sequencial: l["iSequencial"], cliente: l["iCodCliente"], snomepax: texto(l["sNomeCliente"]),
        documenttype: texto(l["sTipoDoc"]), document: texto(l["sNumeroDoc"]),
        hotel_codigo: l["iCodHotel"], hotel: texto(l["sHotel"]), apto: texto(l["sNumeroApto"]),
        qtdepax: l["iNumeroPax"], qtdechd: l["iNumeroCHD"], hour: texto(l["sHora"]), phone: texto(l["sTelefone"]),
        amount: numero(l["nValor"]), amountpay: numero(l["nValorPago"]),
        vendedor: l["iCodVendedor"], amountcomission: numero(l["nValorComissao"]), amountcomissionpay: numero(l["nValorRecVendedor"]),
        agencia_codigo: l["iCodRepassado"], agencia: texto(l["sRepassado"]),
        amountcomissionrep: numero(l["nValorComissaoRepassado"]), amountcomissionreppay: numero(l["nValorPagoRepasse"]),
        scancelado: texto(l["sFlgCancelado"]) == "S" ? "S" : "N",
        comments: juntar(texto(l["sObservacoes"]), (rotulado("Lista de passageiros", lista.join(", ")) if lista.any?), separador: " | ") }
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
    when "passageiros"
      gravar_passageiros(registros, avisos)
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
      upsert(chave, registros)
    end
  end

  def upsert(chave, registros, unique_by: :sistger_id)
    modelo = self.class.etapa(chave).modelo.constantize
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

    linhas = validos.map do |r|
      r.except(:roteiro, :guia, :motorista, :veiculo, :placa).merge(
        destination_id: roteiros[r[:roteiro]], tourguide_id: guias[r[:guia]], driver_id: motoristas[r[:motorista]],
        vehicle_id: veiculos_codigo[r[:veiculo]] || placas[r[:placa]], company_id: empresa_id
      )
    end
    upsert("ordens", linhas)
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
    upsert("passageiros", linhas, unique_by: %i[sistger_numero sistger_sequencial])
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

  def rotulado(rotulo, valor)
    valor = texto(valor)
    "#{rotulo}: #{valor}" if valor.present?
  end

  def juntar(*partes, separador: " / ")
    partes.map { |p| texto(p) }.compact.join(separador).presence
  end
end
