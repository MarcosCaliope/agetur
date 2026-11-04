# "Ajuda": the user manual (processes, not cadastros). Every signed-in
# account may read it, so it's left out of the route permissions
# (Permissao::LIVRES).
class AjudaController < ApplicationController
  skip_before_action :verificar_permissao!

  def index
  end
end
