# Stands in for SistgerImport::Fonte in tests: serves canned SISTGER rows
# by table name, honoring TOP n, ORDER BY ... DESC, iCodigo ranges, Data periods and
# "WHERE iNumero IN (...)" (enough for the filters the tests use).
class SistgerFonteFalsa
  def initialize(tabelas)
    @tabelas = tabelas
  end

  def linhas(sql)
    linhas = @tabelas.fetch(sql[/FROM (\w+)/, 1], [])
    if (numeros = sql[/WHERE iNumero IN \(([^)]*)\)/, 1])
      numeros = numeros.split(",").map(&:to_i)
      linhas = linhas.select { |l| numeros.include?(l["iNumero"]) }
    end
    if (minimo = sql[/WHERE iCodigo >= (\d+)/, 1]) then linhas = linhas.select { |l| l["iCodigo"] >= minimo.to_i } end
    if (maximo = sql[/iCodigo <= (\d+)/, 1]) then linhas = linhas.select { |l| l["iCodigo"] <= maximo.to_i } end
    if (inicio = sql[/Data >= '(\d{8})'/, 1]) then linhas = linhas.select { |l| l["Data"] >= Time.utc(*inicio.unpack("A4A2A2").map(&:to_i)) } end
    if (fim = sql[/Data < '(\d{8})'/, 1]) then linhas = linhas.select { |l| l["Data"] < Time.utc(*fim.unpack("A4A2A2").map(&:to_i)) } end
    linhas = linhas.reverse if sql.end_with?("DESC")
    linhas = linhas.first(Integer(sql[/TOP (\d+)/, 1])) if sql =~ /SELECT TOP \d+/
    linhas.map(&:dup)
  end

  # tabela may be a joined source ("(SELECT ... FROM cx_mov ...) caixa"):
  # its rows are canned under the first table it reads.
  def resumo(tabela, coluna)
    linhas = @tabelas.fetch(tabela[/FROM (\w+)/, 1] || tabela, [])
    { total: linhas.size, ultimo: linhas.filter_map { |l| l[coluna] }.max }
  end

  def fechar; end
end
