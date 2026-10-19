# Agendamentos por usuário (Relatórios tab): see AgendamentosPorUsuario.
class AgendamentosPorUsuarioController < ApplicationController
  # GET /relatorios/agendamentos-por-usuario(.pdf)?inicio=&fim=&usuario=&cancelados=
  def index
    @relatorio = AgendamentosPorUsuario.new(params)
    respond_to do |format|
      format.html
      format.pdf do
        send_data AgendamentosPorUsuarioPdf.new(@relatorio, empresa_atual).render, filename: "agendamentos_por_usuario.pdf",
                                                                                 type: "application/pdf", disposition: "inline"
      end
    end
  end
end
