# Resumo operacional (Relatórios tab): see ResumoOperacional.
class ResumoOperacionalController < ApplicationController
  # GET /relatorios/resumo-operacional(.pdf)?inicio=&fim=
  def index
    @resumo = ResumoOperacional.new(params)
    respond_to do |format|
      format.html
      format.pdf do
        send_data ResumoOperacionalPdf.new(@resumo, empresa_atual).render, filename: "resumo_operacional.pdf",
                                                                          type: "application/pdf", disposition: "inline"
      end
    end
  end
end
