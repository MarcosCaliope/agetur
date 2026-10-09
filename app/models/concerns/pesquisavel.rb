# Free-text search for cadastro lists: `Model.pesquisar("ceara")` matches the
# columns given to `pesquisavel_por` ignoring case and accents, and a number
# also matches the record's code (id) or its SISTGER code.
module Pesquisavel
  extend ActiveSupport::Concern

  MAX_CODIGO = 2**31 - 1

  class_methods do
    def pesquisavel_por(*colunas)
      @colunas_pesquisa = colunas.map(&:to_s)
    end

    def pesquisar(termo)
      termo = termo.to_s.squish
      return all if termo.empty?

      padrao = "%#{sanitize_sql_like(termo)}%"
      condicoes = @colunas_pesquisa.map { |coluna| "unaccent(#{table_name}.#{connection.quote_column_name(coluna)}) ILIKE unaccent(:padrao)" }
      if termo.match?(/\A\d+\z/) && termo.to_i <= MAX_CODIGO
        condicoes << "#{table_name}.id = :numero"
        condicoes << "#{table_name}.sistger_id = :numero" if column_names.include?("sistger_id")
      end
      where(condicoes.join(" OR "), padrao: padrao, numero: termo.to_i)
    end
  end
end
