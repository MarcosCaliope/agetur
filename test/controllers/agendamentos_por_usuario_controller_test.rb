require "test_helper"

class AgendamentosPorUsuarioControllerTest < ActionDispatch::IntegrationTest
  include TextoDoPdf

  setup do
    sign_in users(:one)
    @ordem = sorders(:one)
    @ordem.update!(data: Time.zone.local(2026, 10, 5, 8))
    sorders(:two).update!(data: Time.zone.local(2026, 9, 30, 8))
    hotels(:one).update!(sname: "Praiano")
    @ordem.sorder_items.create!(snomepax: "Ana", hotel: hotels(:one), usuario: "gloria@example.com")
    @ordem.sorder_items.create!(snomepax: "Bia", usuario: "gloria@example.com")
    @ordem.sorder_items.create!(snomepax: "Caio", usuario: "higor@example.com")
    @ordem.sorder_items.create!(snomepax: "Cancelada", usuario: "higor@example.com", scancelado: "S")
    @ordem.sorder_items.create!(snomepax: "Antigo", usuario: nil)
    sorders(:two).sorder_items.create!(snomepax: "Fora", usuario: "gloria@example.com")
    @periodo = { inicio: "2026-10-01", fim: "2026-10-31" }
  end

  test "groups the period's passengers by the user who placed them, with each user's count" do
    get agendamentos_por_usuario_url(@periodo)
    assert_response :success
    assert_equal ["gloria@example.com", "higor@example.com"], css_select("tr.table-secondary th").map(&:text)
    assert_select "tbody td", text: "Praiano"
    assert_select "tbody td", text: /Fora|Cancelada|Antigo/, count: 0
    assert_equal ["Total do usuário: 2", "Total do usuário: 1"], css_select("tbody tr.font-weight-bold td").map(&:text)
    assert_select "tfoot td", text: "Total geral: 3"
    assert_select "p.text-muted", text: /1 passageiro do período sem usuário/
    assert_select "td", text: I18n.l(Date.current) # record date
  end

  test "filters by user and shows cancelled passengers on request" do
    get agendamentos_por_usuario_url(@periodo.merge(usuario: "higor@example.com", cancelados: "1"))
    assert_equal ["higor@example.com"], css_select("tr.table-secondary th").map(&:text)
    assert_select "tbody td", text: "Cancelada (cancelado)"
    assert_select "tfoot td", text: "Total geral: 2"
  end

  test "a passenger placed from a booking shows the booking's record date" do
    booking = Booking.create!(data: Date.new(2026, 9, 1), snome: "Dora", vendor: vendors(:one), usuario: "gloria@example.com",
                              created_at: Time.zone.local(2026, 9, 1, 10))
    passeio = booking.items.create!(destination: @ordem.destination, data_passeio: Date.new(2026, 10, 5))
    passeio.lancar_na_os!(@ordem)
    get agendamentos_por_usuario_url(@periodo)
    assert_select "tr", text: /Dora.*01\/09\/2026/m
  end

  test "exports it as PDF" do
    get agendamentos_por_usuario_url(@periodo.merge(format: :pdf))
    assert_equal "application/pdf", response.media_type
    texto = texto_do_pdf(response.body)
    assert_includes texto, "Passeios agendados por usuário de 01/10/2026 a 31/10/2026"
    assert_includes texto, "gloria@example.com"
    assert_includes texto, "Total do usuário: 2"
    assert_includes texto, "Total geral: 3"
  end

  test "a user without the route is sent home" do
    sign_out users(:one)
    sign_in users(:consulta)
    get agendamentos_por_usuario_url
    assert_redirected_to root_url
  end
end
