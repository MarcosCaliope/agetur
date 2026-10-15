// Order form (sorders/_form, data-avisar-alteracoes): asks before leaving
// with changes not yet saved. Links inside the app get a dialog to save,
// leave or keep editing; closing or reloading the tab can only get the
// browser's own warning.
//
// The edit page (#edicao-ordem) also tells the server every 30 s that the
// form is still open (SorderEdicao), shows who else is editing, and says
// when the form is left.
(function () {
  var batida;

  function formulario() {
    return $("form[data-avisar-alteracoes]");
  }

  function alterado() {
    var form = formulario();
    return form.length > 0 && !form.data("liberado") && form.serialize() !== form.data("estado-inicial");
  }

  function liberar() {
    formulario().data("liberado", true);
  }

  function token() {
    return $("meta[name=csrf-token]").attr("content");
  }

  function emFrase(nomes) {
    return nomes.length < 2 ? nomes.join("") : nomes.slice(0, -1).join(", ") + " e " + nomes[nomes.length - 1];
  }

  function perguntar(url) {
    var modal = $("#modal-sair-da-ordem");
    if (!modal.length) {
      modal = $(
        '<div class="modal fade" id="modal-sair-da-ordem" tabindex="-1" role="dialog" aria-labelledby="modal-sair-da-ordem-titulo">' +
        '<div class="modal-dialog" role="document"><div class="modal-content">' +
        '<div class="modal-header"><h5 class="modal-title" id="modal-sair-da-ordem-titulo">Alterações não gravadas</h5></div>' +
        '<div class="modal-body">Há alterações nesta ordem de serviço que ainda não foram gravadas. O que deseja fazer?</div>' +
        '<div class="modal-footer">' +
        '<button type="button" class="btn btn-primary" data-acao="atualizar">Gravar alterações</button>' +
        '<button type="button" class="btn btn-outline-danger" data-acao="sair">Sair sem gravar</button>' +
        '<button type="button" class="btn btn-secondary" data-dismiss="modal">Continuar editando</button>' +
        "</div></div></div></div>"
      );
      $("body").append(modal);
    }
    modal.find("[data-acao=atualizar]").off("click").on("click", function () {
      modal.modal("hide");
      formulario().find("[type=submit]").first().trigger("click");
    });
    modal.find("[data-acao=sair]").off("click").on("click", function () {
      liberar();
      modal.modal("hide");
      Turbolinks.visit(url);
    });
    modal.modal("show");
  }

  function sairDaEdicao() {
    var painel = $("#edicao-ordem");
    clearInterval(batida);
    if (!painel.length || painel.data("saiu")) return;
    painel.data("saiu", true);
    var dados = new FormData();
    dados.append("_method", "delete");
    dados.append("authenticity_token", token());
    navigator.sendBeacon(painel.data("url"), dados);
  }

  document.addEventListener("turbolinks:load", function () {
    var form = formulario();
    if (form.length) {
      form.data("estado-inicial", form.serialize());
      form.on("submit", liberar);
    }

    clearInterval(batida);
    var painel = $("#edicao-ordem");
    if (!painel.length) return;
    var sinal = function () {
      $.ajax({ url: painel.data("url"), method: "PATCH", dataType: "json", headers: { "X-CSRF-Token": token() } })
        .done(function (resposta) {
          var aviso = painel.find(".outros-editando");
          aviso.find(".nomes").text(emFrase(resposta.outros));
          aviso.prop("hidden", resposta.outros.length === 0);
        });
    };
    sinal();
    batida = setInterval(sinal, 30000);
  });

  $(document).on("click", "[data-sair-sem-salvar]", liberar);

  document.addEventListener("turbolinks:before-visit", function (event) {
    if (!alterado()) return;
    event.preventDefault();
    perguntar(event.data.url);
  });

  window.addEventListener("beforeunload", function (event) {
    if (!alterado()) return;
    event.preventDefault();
    event.returnValue = "";
  });

  document.addEventListener("turbolinks:visit", sairDaEdicao);
  window.addEventListener("pagehide", sairDaEdicao);
})();
