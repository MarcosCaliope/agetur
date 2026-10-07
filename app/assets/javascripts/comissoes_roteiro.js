// Vendor > Comissão por roteiro: filter the destination rows by name and,
// optionally, only the customized ones (filtering only hides rows; every
// row is still submitted).
document.addEventListener("turbolinks:load", function () {
  var form = document.getElementById("comissoes-roteiro");
  if (!form) return;

  var busca = document.getElementById("filtro-roteiros");
  var personalizados = document.getElementById("so-personalizados");

  function filtrar() {
    var termo = busca.value.trim().toLowerCase();
    form.querySelectorAll("tr.comissao-roteiro").forEach(function (linha) {
      var visivel = linha.getAttribute("data-roteiro").indexOf(termo) !== -1 &&
        (!personalizados.checked || linha.classList.contains("personalizado"));
      linha.style.display = visivel ? "" : "none";
    });
  }

  busca.addEventListener("input", filtrar);
  personalizados.addEventListener("change", filtrar);
});
