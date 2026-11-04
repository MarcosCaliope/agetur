module SorderItemsHelper
  # "OS nº 15 — 05/11/2026 08:00 — City tour": the order a passenger is
  # transferred or copied to (movimentar).
  def descricao_destino(sorder)
    ["OS nº #{sorder.id}", sorder.data && l(sorder.data, format: "%d/%m/%Y %H:%M"), sorder.destination&.description]
      .compact.join(" — ")
  end

  # The confirmation of the Transferir / Copiar buttons, naming the order
  # once it's known (movimentar_passageiro.js updates it as it's typed).
  def confirmar_movimentacao(acao, sorder_item, destino)
    "#{acao} #{sorder_item.nome_passageiro} para a #{destino ? descricao_destino(destino) : 'OS informada'}?"
  end
end
