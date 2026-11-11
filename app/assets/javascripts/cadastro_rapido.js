// Order form's quick-add modals (sorders/_cadastro_rapido): creates the
// destination, guide, driver, vehicle, hotel, vendor or repasse agency through its cadastro's JSON create
// action, then adds it to every select the form's data-selects matches
// (each passenger's hotel, vendor or agency, and the passengers cocoon adds later) and picks
// it in the select next to the "+" that opened the modal.
$(document).on("click", ".cadastro-rapido-abrir", function () {
  $($(this).data("target")).data("alvo", $(this).prevAll("select").get(0));
});

// Bootstrap focuses the modal itself once it's shown: then start typing in the first field.
$(document).on("shown.bs.modal", ".cadastro-rapido-modal", function () {
  $(this).find("input:visible:first").trigger("focus");
});

$(document).on("submit", "form.cadastro-rapido", function (evento) {
  evento.preventDefault();
  var form = this;
  var modal = form.closest(".modal");
  var seletor = form.getAttribute("data-selects");
  var erros = form.querySelector(".cadastro-rapido-erros");
  var botao = form.querySelector("[type=submit]");

  function mostrarErros(mensagens) {
    erros.innerHTML = "";
    mensagens.forEach(function (mensagem) {
      var linha = document.createElement("div");
      linha.textContent = mensagem;
      erros.appendChild(linha);
    });
    erros.hidden = false;
  }

  // Cocoon builds new passengers from the add link's template: give it the option too.
  function incluirNosModelos(rotulo, id) {
    $("a.add_fields[data-association-insertion-template]").each(function () {
      var modelo = document.createElement("template");
      modelo.innerHTML = $(this).attr("data-association-insertion-template");
      var selects = modelo.content.querySelectorAll(seletor);
      if (!selects.length) return;
      selects.forEach(function (select) { select.appendChild(new Option(rotulo, id)); });
      $(this).attr("data-association-insertion-template", modelo.innerHTML)
             .data("association-insertion-template", modelo.innerHTML);
    });
  }

  botao.disabled = true;
  fetch(form.action, {
    method: "POST",
    body: new FormData(form),
    headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" },
    credentials: "same-origin"
  })
    .then(function (resposta) {
      return resposta.json().catch(function () { return {}; }).then(function (dados) {
        if (resposta.ok) {
          var rotulo = dados[form.getAttribute("data-rotulo")];
          var alvo = $(modal).data("alvo") || document.querySelector(seletor);
          document.querySelectorAll(seletor).forEach(function (select) { select.appendChild(new Option(rotulo, dados.id)); });
          incluirNosModelos(rotulo, dados.id);
          alvo.value = dados.id;
          alvo.dispatchEvent(new Event("change", { bubbles: true }));
          form.reset();
          erros.hidden = true;
          $(modal).modal("hide");
        } else if (resposta.status === 403) {
          mostrarErros(["Seu perfil não tem acesso a este cadastro."]);
        } else {
          mostrarErros(dados.errors || ["Não foi possível cadastrar. Tente de novo."]);
        }
      });
    })
    .catch(function () { mostrarErros(["Sem resposta do servidor. Tente de novo."]); })
    .then(function () { botao.disabled = false; });
});
