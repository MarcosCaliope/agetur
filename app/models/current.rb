# Per-request state, set by ApplicationController#definir_empresa.
#
# empresa_id: the company whose data the request sees and creates (DaEmpresa).
# filtrar_empresa: whether DaEmpresa's scope applies. Off outside a signed-in
#   request (console, seeds, tests that don't set it).
# so_a_propria_empresa: a User also sees only their own Company record; an
#   admin sees and manages them all.
# usuario: the signed-in account's e-mail, recorded on the order passengers
#   it creates (SorderItem#usuario).
class Current < ActiveSupport::CurrentAttributes
  attribute :empresa_id, :filtrar_empresa, :so_a_propria_empresa, :usuario
end
