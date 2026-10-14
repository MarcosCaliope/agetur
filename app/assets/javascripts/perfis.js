// Perfil de acesso form: a group's header checkbox marks or clears all its
// routes, and "Acesso total" greys the route list out (it allows everything).
$(document).on("change", ".perfil-marcar-grupo", function () {
  $(this).closest(".perfil-grupo").find(".perfil-permissao").prop("checked", this.checked);
});

$(document).on("change", ".perfil-permissao", function () {
  var grupo = $(this).closest(".perfil-grupo");
  grupo.find(".perfil-marcar-grupo").prop("checked", grupo.find(".perfil-permissao:not(:checked)").length === 0);
});

function atualizarAcessoTotal() {
  var total = $(".perfil-acesso-total").prop("checked");
  $(".perfil-rotas").css("opacity", total ? 0.5 : 1);
}

$(document).on("change", ".perfil-acesso-total", atualizarAcessoTotal);
document.addEventListener("turbolinks:load", atualizarAcessoTotal);
