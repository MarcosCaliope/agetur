// Order form: when a passenger's pax list changes, recount their PAX and CHD
// as SorderItem#contar_lista_pax does on save (the holder is one PAX, each
// named person a PAX or a CHD, colo doesn't count).
(function () {
  function nome(linha) {
    return $.trim(linha.find("input[name$='[snome]']").val());
  }

  function recontar(lista) {
    var pax = 1, chd = 0;
    lista.find(".nested-fields").each(function () {
      var linha = $(this);
      var removida = /^(1|true)$/.test(linha.find("input[name$='[_destroy]']").val());
      if (removida || !nome(linha) || linha.find("input[type=checkbox][name$='[colo]']").is(":checked")) return;
      if (linha.find("input[type=checkbox][name$='[chd]']").is(":checked")) chd++; else pax++;
    });
    var item = lista.closest(".nested-fields");
    item.find("input[name$='[qtdepax]']").val(pax);
    item.find("input[name$='[qtdechd]']").val(chd);
  }

  $(document).on("input change", ".lista-pax input[name$='[snome]'], .lista-pax input[type=checkbox]", function () {
    recontar($(this).closest(".lista-pax"));
  });

  // A removed row only changes the count if it had a name.
  $(document).on("cocoon:before-remove", ".lista-pax", function (event, linha) {
    $(this).data("recontar", !!nome(linha));
  });
  $(document).on("cocoon:after-remove", ".lista-pax", function () {
    var lista = $(this);
    if (lista.data("recontar")) setTimeout(function () { recontar(lista); });
  });
})();
