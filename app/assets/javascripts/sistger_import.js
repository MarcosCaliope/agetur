// Manutenção > Importar do SISTGER: show only the inputs of each row's
// filter mode, "select all", and previews that carry the row's filter.
document.addEventListener("turbolinks:load", function () {
  var form = document.getElementById("sistger-import");
  if (!form) return;

  function atualizarCampos(linha) {
    var modo = linha.querySelector(".sistger-modo").value;
    linha.querySelectorAll(".sistger-campos").forEach(function (campos) {
      campos.style.display = campos.getAttribute("data-modo") === modo ? "" : "none";
    });
  }

  form.querySelectorAll(".sistger-etapa").forEach(function (linha) {
    atualizarCampos(linha);
    linha.querySelector(".sistger-modo").addEventListener("change", function () { atualizarCampos(linha); });

    linha.querySelector(".sistger-previa").addEventListener("click", function () {
      var parametros = [];
      linha.querySelectorAll("select[name^='filtros'], input[name^='filtros']").forEach(function (campo) {
        if (campo.value !== "") parametros.push(encodeURIComponent(campo.name) + "=" + encodeURIComponent(campo.value));
      });
      Turbolinks.visit(this.getAttribute("data-url") + (parametros.length ? "?" + parametros.join("&") : ""));
    });
  });

  var todas = document.getElementById("sistger-todas");
  todas.addEventListener("change", function () {
    form.querySelectorAll(".sistger-marcar").forEach(function (caixa) { caixa.checked = todas.checked; });
  });
});
