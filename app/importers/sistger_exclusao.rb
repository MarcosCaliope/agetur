# Deletes every record of the chosen SISTGER steps' tables in one company,
# imported or created here (Manutenção > SISTGER > Excluir, admins only, and
# `bin/rails sistger:excluir`). Meant to clear a company before importing it
# again, so it writes no history and runs no callbacks (delete_all).
#
# Steps run in one transaction, dependents first (EXCLUSAO). Before deleting a
# table it counts the rows that still reference it through a foreign key
# without ON DELETE (read from the database, so new tables are covered): any
# left means a record that stays would break, so it raises and nothing is
# deleted. The message names the referencing table, so the user can include
# its step too (or, for bookings and users, which aren't steps, remove them).
#
# "ordens" also deletes the orders' passengers with their pax lists, payments,
# bills and history (sorder_auditorias). It refuses orders holding booked
# tours (booking_items), which belong to the bookings screen. Cash entries
# they posted stay, unlinked, unless "caixa" is chosen too.
class SistgerExclusao
  class Erro < StandardError; end

  # Deletion order: what references a table goes before it.
  EXCLUSAO = %w[ordens caixa horarios comissoes_roteiro agencias clientes vendedores hoteis guias motoristas veiculos roteiros].freeze

  Resultado = Struct.new(:etapa, :excluidos, keyword_init: true)

  def self.etapas
    EXCLUSAO.map { |chave| SistgerImport.etapa(chave) }
  end

  def self.etapa(chave)
    raise Erro, "Etapa desconhecida: #{chave}" unless EXCLUSAO.include?(chave)

    SistgerImport.etapa(chave)
  end

  def initialize(empresa_id)
    @empresa_id = empresa_id or raise Erro, "Escolha a empresa."
  end

  # {chave => records the step would delete}.
  def contagens(chaves = EXCLUSAO)
    sem_escopo { ordenadas(chaves).index_with { |chave| registros(chave).count } }
  end

  def excluir(chaves)
    chaves = ordenadas(chaves)
    raise Erro, "Selecione ao menos uma tabela para excluir." if chaves.empty?

    sem_escopo do
      ActiveRecord::Base.transaction do
        chaves.map { |chave| Resultado.new(etapa: self.class.etapa(chave), excluidos: excluir_etapa(chave)) }
      end
    end
  end

  private

  def ordenadas(chaves)
    chaves = Array(chaves).map(&:to_s)
    chaves.each { |chave| self.class.etapa(chave) }
    EXCLUSAO & chaves
  end

  def sem_escopo(&)
    Current.set(filtrar_empresa: false, so_a_propria_empresa: false, empresa_id: @empresa_id, &)
  end

  def registros(chave)
    modelo = self.class.etapa(chave).modelo.constantize
    return modelo.where(vendor_id: Vendor.unscoped.where(company_id: @empresa_id).select(:id)) if modelo == VendorDestination

    modelo.unscoped.where(company_id: @empresa_id)
  end

  def excluir_etapa(chave)
    alvo = registros(chave)
    return excluir_ordens(alvo) if chave == "ordens"

    verificar_referencias!(chave, alvo)
    alvo.delete_all
  end

  def excluir_ordens(ordens)
    itens = SorderItem.unscoped.where(sorder_id: ordens.select(:id))
    agendados = BookingItem.unscoped.where(sorder_item_id: itens.select(:id)).count
    raise Erro, "Ordens de serviço: #{agendados} passeio(s) agendado(s) estão nestas ordens. Retire-os das ordens antes." if agendados.positive?

    SorderAuditoria.unscoped.where(sorder_id: ordens.select(:id)).delete_all
    itens.delete_all # companions, payments and bills cascade; cash entries are unlinked
    verificar_referencias!("ordens", ordens)
    ordens.delete_all
  end

  # Foreign keys without ON DELETE pointing at the table, from rows that stay.
  def verificar_referencias!(chave, alvo)
    tabela = alvo.klass.table_name
    conexao = ActiveRecord::Base.connection
    usos = conexao.tables.flat_map do |origem|
      conexao.foreign_keys(origem).filter_map do |fk|
        next unless fk.to_table == tabela && fk.on_delete.nil?

        total = conexao.select_value(<<~SQL).to_i
          SELECT COUNT(*) FROM #{conexao.quote_table_name(origem)}
          WHERE #{conexao.quote_column_name(fk.column)} IN (#{alvo.select(:id).to_sql})
        SQL
        "#{total} #{nome_da_tabela(origem)}" if total.positive?
      end
    end
    return if usos.empty?

    raise Erro, "#{self.class.etapa(chave).nome}: ainda em uso por #{usos.to_sentence}. " \
                "Inclua essas tabelas na exclusão, ou exclua esses registros antes."
  end

  def nome_da_tabela(tabela)
    modelo = tabela.classify.safe_constantize
    modelo.respond_to?(:model_name) ? modelo.model_name.human(count: 2).downcase : tabela
  end
end
