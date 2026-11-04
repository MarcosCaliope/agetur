// Passageiro > Transferir / copiar: as the order number is typed, shows
// which order it is (date, roteiro, guide) and names it in the buttons'
// confirmation, so the passenger doesn't go to the wrong order.
document.addEventListener("turbolinks:load", function () {
  var form = document.getElementById("movimentar-passageiro");
  if (!form) return;

  var campo = form.querySelector("[name=destino_id]");
  var quadro = document.getElementById("destino-movimentacao");
  var espera, ultima = 0;

  function confirmar(descricao) {
    form.querySelectorAll("button[data-acao]").forEach(function (botao) {
      botao.setAttribute("data-confirm", botao.getAttribute("data-acao") + " " + form.getAttribute("data-passageiro") +
        " para a " + (descricao || "OS informada") + "?");
    });
  }

  function buscar() {
    var numero = campo.value.trim();
    var pedido = ++ultima;
    if (!numero) {
      quadro.innerHTML = "";
      confirmar(null);
      return;
    }
    fetch(form.getAttribute("data-busca") + "?destino_id=" + encodeURIComponent(numero),
          { headers: { "X-Requested-With": "XMLHttpRequest" } })
      .then(function (resposta) { return resposta.text(); })
      .then(function (html) {
        if (pedido !== ultima) return; // an older answer arriving late
        quadro.innerHTML = html;
        var alerta = quadro.querySelector("[data-descricao]");
        confirmar(alerta && alerta.getAttribute("data-descricao"));
      });
  }

  campo.addEventListener("input", function () {
    clearTimeout(espera);
    espera = setTimeout(buscar, 300);
  });
});
