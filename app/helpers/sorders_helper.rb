module SordersHelper
  # Label of a field in an order's history (SorderAuditoria#alteracoes): a
  # foreign key takes its association's name.
  def campo_auditado(auditoria, campo)
    modelo = auditoria.registro_type.safe_constantize
    return campo.humanize unless modelo

    associacao = associacao_auditada(modelo, campo)
    modelo.human_attribute_name(associacao ? associacao.name : campo)
  end

  # A value in an order's history: a foreign key shows the record's name.
  def valor_auditado(auditoria, campo, valor)
    return "(vazio)" if valor.nil? || valor == ""

    associacao = associacao_auditada(auditoria.registro_type.safe_constantize, campo)
    if associacao
      registro = associacao.klass.find_by(id: valor)
      return registro ? "#{descricao_registro(registro)} (#{valor})" : valor.to_s
    end

    case [campo, valor]
    in [_, true | false] then sim_nao(valor)
    in ["scancelado", "S" | "N"] then sim_nao(valor == "S")
    in ["forma_pagamento", String] if SorderItem::FORMAS_PAGAMENTO.key?(valor) then SorderItem::FORMAS_PAGAMENTO[valor]
    in [_, Float] then number_with_precision(valor, precision: 2)
    in [_, /\A\d{4}-\d\d-\d\dT/] then l(Time.zone.parse(valor), format: "%d/%m/%Y %H:%M")
    in [_, /\A\d{4}-\d\d-\d\d\z/] then l(Date.parse(valor))
    else valor.to_s
    end
  end

  # "antes → depois", or just the side there is when the record was created
  # or deleted.
  def alteracao_auditada(auditoria, campo, (antes, depois))
    if auditoria.acao == "excluiu"
      valor_auditado(auditoria, campo, antes)
    elsif antes.nil? && !auditoria.alteracao?
      valor_auditado(auditoria, campo, depois)
    else
      "#{valor_auditado(auditoria, campo, antes)} → #{valor_auditado(auditoria, campo, depois)}"
    end
  end

  private

  def associacao_auditada(modelo, campo)
    modelo&.reflect_on_all_associations(:belongs_to)&.find { |a| !a.polymorphic? && a.foreign_key.to_s == campo }
  end
end
