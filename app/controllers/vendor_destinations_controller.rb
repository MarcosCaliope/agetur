# "Comissão por roteiro" of a vendor (SISTGER's frmVendedorRoteiro): one
# editable grid with every destination. Only destinations that differ from
# the vendor's defaults (its commission %, no net prices) are stored.
class VendorDestinationsController < ApplicationController
  before_action :set_vendor

  # GET /vendors/1/comissoes-por-roteiro
  def show
    carregar_grade
  end

  # PATCH /vendors/1/comissoes-por-roteiro
  def update
    @linhas = carregar_grade
    invalidas = []

    VendorDestination.transaction do
      @destinations.each do |destination|
        valores = valores_de(destination.id)
        next unless valores

        registro = @linhas[destination.id] ||= @vendor.vendor_destinations.build(destination: destination)
        registro.assign_attributes(valores)
        if padrao?(registro)
          registro.destroy if registro.persisted?
        elsif !registro.save
          invalidas << registro
        end
      end
      raise ActiveRecord::Rollback if invalidas.any?
    end

    if invalidas.any?
      @erros = invalidas.map { |r| "#{r.destination.description}: #{r.errors.full_messages.to_sentence}" }
      render :show, status: :unprocessable_entity
    else
      redirect_to vendor_comissoes_path(@vendor), notice: "Comissões por roteiro gravadas com sucesso."
    end
  end

  private

  def set_vendor
    @vendor = Vendor.find(params[:vendor_id])
  end

  def carregar_grade
    @destinations = Destination.order(:description)
    @linhas = @vendor.vendor_destinations.includes(:destination).index_by(&:destination_id)
  end

  # Submitted values of one destination's row; nil when the row wasn't sent.
  def valores_de(destination_id)
    linha = params.dig(:comissoes, destination_id.to_s) or return
    linha.permit(:commission, *VendorDestination::VALORES).to_h.transform_values(&:presence)
  end

  # A row matching the vendor's defaults isn't worth storing.
  def padrao?(registro)
    registro.commission.to_f.round(2) == @vendor.commission.to_f.round(2) &&
      VendorDestination::VALORES.all? { |campo| registro.public_send(campo).to_f.zero? }
  end
end
