# Passeios repassados (Relatórios tab): see PasseiosRepassados.
class PasseiosRepassadosController < ApplicationController
  # GET /relatorios/passeios-repassados(.pdf)?inicio=&fim=&agencia_id=&cancelados=
  def index
    @relatorio = PasseiosRepassados.new(params)
    respond_to do |format|
      format.html
      format.pdf do
        send_data PasseiosRepassadosPdf.new(@relatorio, empresa_atual).render, filename: "passeios_repassados.pdf",
                                                                             type: "application/pdf", disposition: "inline"
      end
    end
  end
end
