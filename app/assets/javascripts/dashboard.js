// Home page tabs: open the tab named in the URL hash (/#processos) and keep
// the hash in sync, so reloading or coming back keeps the same tab open.
document.addEventListener("turbolinks:load", function () {
  var tabs = $(".dashboard-tabs a[data-toggle='tab']");
  if (!tabs.length) return;

  if (window.location.hash) {
    tabs.filter("[href='" + window.location.hash + "']").tab("show");
  }

  tabs.on("shown.bs.tab", function (event) {
    history.replaceState(history.state, "", event.target.hash);
  });
});
