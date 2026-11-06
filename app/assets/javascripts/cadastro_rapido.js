// Order form's quick-add modals (sorders/_cadastro_rapido): creates the
// guide, driver or vehicle through its cadastro's JSON create action, then
// adds it to the order's select and picks it, without leaving the order.
$(document).on("submit", "form.cadastro-rapido", function (evento) {
  evento.preventDefault();
  var form = this;
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
          var select = document.getElementById(form.getAttribute("data-select"));
          var opcao = new Option(dados[form.getAttribute("data-rotulo")], dados.id, true, true);
          select.appendChild(opcao);
          select.dispatchEvent(new Event("change", { bubbles: true }));
          form.reset();
          erros.hidden = true;
          $(form.closest(".modal")).modal("hide");
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
