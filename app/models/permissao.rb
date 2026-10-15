# The routes a User can be allowed, read from config/routes.rb so a new screen
# shows up in the user form by itself. A permission is "controller#action";
# new/edit share the key of create/update (the form and its submit are one
# permission), and payables' pagamento screen shares pagar's.
#
# Only controllers that run the permission check are listed: ApplicationController
# subclasses, minus Devise, the public site, the back-offices and the header's
# company switch and the own-password screen.
module Permissao
  Item = Struct.new(:chave, :rotulo, :rotas)
  Grupo = Struct.new(:controller, :rotulo, :itens)

  MESMA_ACAO = { "new" => "create", "edit" => "update" }.freeze
  MESMA_CHAVE = { "payables#pagamento" => "payables#pagar" }.freeze
  ORDEM = %w[index show create update destroy].freeze
  LIVRES = [SiteController, UsersBackofficeController, AdminsBackofficeController, DeviseController, TrocaEmpresaController, SenhasController].freeze

  module_function

  def chave(controller, action)
    chave = "#{controller}##{MESMA_ACAO.fetch(action.to_s, action.to_s)}"
    MESMA_CHAVE.fetch(chave, chave)
  end

  def controlado?(controller)
    (@controlados ||= {}).fetch(controller) do
      classe = "#{controller}_controller".camelize.safe_constantize
      @controlados[controller] = classe.present? && classe < ApplicationController && LIVRES.none? { |livre| classe <= livre }
    end
  end

  def grupos
    rotas = Rails.application.routes.routes.filter_map do |rota|
      controller, action = rota.defaults.values_at(:controller, :action)
      next unless controller && action && controlado?(controller)

      [controller, chave(controller, action), "#{rota.verb} #{rota.path.spec.to_s.delete_suffix('(.:format)')}"]
    end

    rotas.group_by(&:first).map do |controller, linhas|
      itens = linhas.group_by { |linha| linha[1] }.map do |chave, das_rotas|
        Item.new(chave, rotulo_da_acao(chave), das_rotas.map(&:last).uniq)
      end.sort_by.with_index { |item, posicao| [ORDEM.index(item.chave.split("#").last) || ORDEM.size, posicao] }
      Grupo.new(controller, rotulo_do_controller(controller), itens)
    end.sort_by { |grupo| I18n.transliterate(grupo.rotulo) }
  end

  def chaves
    grupos.flat_map(&:itens).map(&:chave)
  end

  def rotulo_do_controller(controller)
    modelo = controller.classify.safe_constantize
    padrao = modelo.respond_to?(:model_name) ? modelo.model_name.human(count: 2) : controller.humanize
    I18n.t("permissoes.controllers.#{controller}", default: padrao)
  end

  def rotulo_da_acao(chave)
    controller, action = chave.split("#")
    I18n.t("permissoes.acoes.#{controller}.#{action}", default: I18n.t("permissoes.acoes.#{action}", default: action.humanize))
  end
end
