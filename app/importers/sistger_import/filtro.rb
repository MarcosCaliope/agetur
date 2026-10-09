class SistgerImport
  # Which rows of a step to import: all, a date period (orders/passengers,
  # by order date), a code range, or the last N by code. For passengers the
  # code is the order number and "last N" means the last N orders.
  class Filtro
    MODOS = {
      "todos" => "Todos",
      "periodo" => "Período",
      "faixa" => "Faixa de código",
      "ultimos" => "Últimos registros"
    }.freeze
    MAX_ULTIMOS = 100_000

    attr_reader :modo, :inicio, :fim, :de, :ate, :quantidade

    def self.todos
      new(modo: "todos")
    end

    # From form params {modo:, inicio:, fim:, de:, ate:, quantidade:}.
    def self.de_params(params)
      params = (params || {}).to_h.symbolize_keys
      new(modo: params[:modo].presence || "todos",
          inicio: data(params[:inicio], "Data inicial"), fim: data(params[:fim], "Data final"),
          de: inteiro(params[:de], "Código inicial"), ate: inteiro(params[:ate], "Código final"),
          quantidade: inteiro(params[:quantidade], "Quantidade"))
    end

    def self.data(valor, rotulo)
      Date.iso8601(valor) if valor.present?
    rescue Date::Error
      raise Erro, "#{rotulo} inválida: #{valor}"
    end

    def self.inteiro(valor, rotulo)
      Integer(valor, 10) if valor.present?
    rescue ArgumentError
      raise Erro, "#{rotulo} inválido: #{valor}"
    end

    def initialize(modo:, inicio: nil, fim: nil, de: nil, ate: nil, quantidade: nil)
      raise Erro, "Filtro desconhecido: #{modo}" unless MODOS.key?(modo)

      @modo, @inicio, @fim, @de, @ate, @quantidade = modo, inicio, fim, de, ate, quantidade
      validar
    end

    def todos? = modo == "todos"
    def ultimos? = modo == "ultimos"

    # "SELECT [TOP n] colunas FROM tabela [WHERE ...] ORDER BY ..." for a step.
    # `limite` caps the rows (used by the preview).
    def sql(etapa, limite: nil)
      raise Erro, "#{etapa.nome}: filtro por período não disponível." if modo == "periodo" && !etapa.periodo

      condicoes = []
      ordem = etapa.ordem
      topo = limite

      case modo
      when "periodo"
        condicoes << periodo_sql
      when "faixa"
        faixa = [("#{etapa.codigo} >= #{de}" if de), ("#{etapa.codigo} <= #{ate}" if ate)].compact.join(" AND ")
        condicoes << faixa
      when "ultimos"
        topo = [quantidade, limite].compact.min
        ordem = "#{etapa.codigo} DESC"
      end

      sql = +"SELECT #{"TOP #{Integer(topo)} " if topo}#{etapa.colunas} FROM #{etapa.from}"
      sql << " WHERE #{condicoes.join(' AND ')}" if condicoes.any?
      sql << " ORDER BY #{ordem}"
    end

    def descricao
      case modo
      when "todos" then "todos"
      when "periodo" then "período #{[inicio, fim].map { |d| d&.strftime('%d/%m/%Y') || '…' }.join(' a ')}"
      when "faixa" then "códigos #{de || '…'} a #{ate || '…'}"
      when "ultimos" then "últimos #{quantidade}"
      end
    end

    private

    def validar
      case modo
      when "periodo"
        raise Erro, "Informe a data inicial e/ou final do período." unless inicio || fim
        raise Erro, "A data inicial é posterior à final." if inicio && fim && inicio > fim
      when "faixa"
        raise Erro, "Informe o código inicial e/ou final da faixa." unless de || ate
        raise Erro, "O código inicial é maior que o final." if de && ate && de > ate
      when "ultimos"
        raise Erro, "Informe quantos registros importar (1 a #{MAX_ULTIMOS})." unless quantidade&.between?(1, MAX_ULTIMOS)
      end
    end

    # Order date between inicio and fim (inclusive), as SQL Server literals.
    def periodo_sql
      [("Data >= '#{inicio.strftime('%Y%m%d')}'" if inicio), ("Data < '#{(fim + 1).strftime('%Y%m%d')}'" if fim)].compact.join(" AND ")
    end
  end
end
