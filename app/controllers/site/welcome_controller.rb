class Site::WelcomeController < SiteController
  ABAS = { "cadastros" => "Cadastros", "processos" => "Processos", "relatorios" => "Relatórios", "manutencao" => "Manutenção" }.freeze

  # The home page is public; the dashboard's figures are only loaded for a
  # signed-in account.
  def index
    @empresa = Company.first
    return unless user_signed_in? || admin_signed_in?

    # Only the cadastros the user may them list.
    @cadastros = [
      { nome: "Clientes", controller: "customers", total: Customer.count, lista: customers_path, novo: new_customer_path },
      { nome: "Agências", controller: "agencies", total: Agency.count, lista: agencies_path, novo: new_agency_path },
      { nome: "Hotéis", controller: "hotels", total: Hotel.count, lista: hotels_path, novo: new_hotel_path },
      { nome: "Vendedores", controller: "vendors", total: Vendor.count, lista: vendors_path, novo: new_vendor_path },
      { nome: "Veículos", controller: "vehicles", total: Vehicle.count, lista: vehicles_path, novo: new_vehicle_path },
      { nome: "Motoristas", controller: "drivers", total: Driver.count, lista: drivers_path, novo: new_driver_path },
      { nome: "Guias", controller: "tourguides", total: Tourguide.count, lista: tourguides_path, novo: new_tourguide_path },
      { nome: "Roteiros", controller: "destinations", total: Destination.count, lista: destinations_path, novo: new_destination_path },
      { nome: "Horários de passeio", controller: "pickup_times", total: PickupTime.count, lista: pickup_times_path, novo: new_pickup_time_path },
      { nome: "Empresa", controller: "companies", total: Company.count, lista: companies_path, novo: new_company_path }
    ].select { |cadastro| pode_acessar?(cadastro[:controller]) }

    # Tabs with nothing the user may open are left out.
    visiveis = {
      "cadastros" => @cadastros.any?,
      "processos" => %w[sorders bookings cash_entries payables txt].any? { |controller| pode_acessar?(controller) },
      "relatorios" => pode_acessar?("sorder_items", "showcomis") || pode_acessar?("commission_payments"),
      "manutencao" => pode_acessar?("sistger_imports")
    }
    @abas = ABAS.select { |aba, _| visiveis[aba] }

    hoje = Time.zone.today
    @ordens_total = Sorder.count
    @ordens_hoje = Sorder.where(data: hoje.all_day).count
    @ordens_proximas = Sorder.where(data: hoje.tomorrow.beginning_of_day..(hoje + 7).end_of_day).count

    @agendamentos_pendentes = BookingItem.pendentes.where(data_passeio: hoje..).count
    @agendamentos_semana = BookingItem.ativos.where(data_passeio: hoje..(hoje + 7)).count
    @caixa_saldo = CashEntry.saldo
    @caixa_hoje = CashEntry.where(data: hoje)
    @contas_abertas = Payable.abertas
    @contas_vencidas = Payable.abertas.where(vencimento: ...hoje)

    @comissoes_a_pagar = SorderItem.ativos
      .sum("COALESCE(amountcomission, 0) - COALESCE(amountcomissionpay, 0)")
  end
end
