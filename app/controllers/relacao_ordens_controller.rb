# Relação de ordens (Relatórios tab): see RelacaoOrdens.
class RelacaoOrdensController < ApplicationController
  # GET /relatorios/ordens(.pdf)?inicio=&fim=&modo=&agrupar=&situacao=&cancelados=&destination_id=&vendor_id=...
  def index
    @relacao = RelacaoOrdens.new(params)
    respond_to do |format|
      format.html do
        @opcoes = RelacaoOrdens::FILTROS.to_h do |nome, (_, modelo, coluna, _)|
          [nome, modelo.order(coluna).pluck(coluna, :id)]
        end
      end
      format.pdf do
        send_data RelacaoOrdensPdf.new(@relacao, empresa_atual).render, filename: "relacao_ordens.pdf",
                                                                       type: "application/pdf", disposition: "inline"
      end
    end
  end
end
