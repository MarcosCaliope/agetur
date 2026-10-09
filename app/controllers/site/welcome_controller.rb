class Site::WelcomeController < SiteController
  # The home page is public; the dashboard's figures are only loaded for a
  # signed-in account.
  def index
    @empresa = Company.first
    return unless user_signed_in? || admin_signed_in?

    @cadastros = [
      { nome: "Clientes",    total: Customer.count,    lista: customers_path,    novo: new_customer_path },
      { nome: "Agências",    total: Agency.count,      lista: agencies_path,     novo: new_agency_path },
      { nome: "Hotéis",      total: Hotel.count,       lista: hotels_path,       novo: new_hotel_path },
      { nome: "Vendedores",  total: Vendor.count,      lista: vendors_path,      novo: new_vendor_path },
      { nome: "Veículos",    total: Vehicle.count,     lista: vehicles_path,     novo: new_vehicle_path },
      { nome: "Motoristas",  total: Driver.count,      lista: drivers_path,      novo: new_driver_path },
      { nome: "Guias",       total: Tourguide.count,   lista: tourguides_path,   novo: new_tourguide_path },
      { nome: "Roteiros",    total: Destination.count, lista: destinations_path, novo: new_destination_path },
      { nome: "Empresa",     total: Company.count,     lista: companies_path,    novo: new_company_path }
    ]

    hoje = Time.zone.today
    @ordens_total = Sorder.count
    @ordens_hoje = Sorder.where(data: hoje.all_day).count
    @ordens_proximas = Sorder.where(data: hoje.tomorrow.beginning_of_day..(hoje + 7).end_of_day).count

    @caixa_saldo = CashEntry.saldo
    @caixa_hoje = CashEntry.where(data: hoje)
    @contas_abertas = Payable.abertas
    @contas_vencidas = Payable.abertas.where(vencimento: ...hoje)

    @comissoes_a_receber = SorderItem.ativos
      .sum("COALESCE(amountcomission, 0) - COALESCE(amountcomissionpay, 0)")
  end
end
