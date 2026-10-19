# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Agetur is a Ruby on Rails 7.2 (Ruby 3.4.5, pinned via `.ruby-version` / `mise.toml`) back-office application for a tour/travel agency: it manages customers, destinations, hotels, vehicles, drivers, tour guides, vendors, agencies, states and companies, and issues "sorders" (service orders) that bundle a trip's guide/driver/vehicle/destination/company with per-passenger `sorder_items`. Two Devise-backed user types (`User` and `Admin`) get separate namespaced back-offices. UI strings and many code comments are in Portuguese.

The app was upgraded from Rails 5.2 / Ruby 2.7 / MySQL. `config.load_defaults 7.2` is active, so `belongs_to` is required by default. Mark an association `optional: true` when the form allows it to be blank.

## Commands

```bash
bundle install
bin/setup                         # bundle install + db:setup + log/tmp clear

bin/rails server
bin/rails console

bin/rails db:create db:migrate    # or db:schema:load
bin/rails db:seed

bin/rails test                                   # everything except system tests (models, controllers, importers, pdfs, helpers)
bin/rails test test/models/sorder_test.rb        # single file
bin/rails test test/models/sorder_test.rb:12     # single test at line 12
bin/rails test:system                            # headless Chrome; SYSTEM_TEST_HEADED=1 shows the window
```

No linter or formatter is configured (no RuboCop/Brakeman in the Gemfile). `test/integration/` and `test/mailers/` are empty scaffold folders. Request-level tests live in `test/controllers/`.

System tests (`test/system/`) cover only what needs a browser: the order form's JavaScript (`sorder_form_test.rb`). CRUD is covered by the controller tests. Selenium Manager downloads Chrome and chromedriver to `~/.cache/selenium`. `ApplicationSystemTestCase` passes that Chrome's path itself, because Rails resolves only chromedriver's path, and that makes Selenium skip the browser lookup. On WSL, Chrome needs `libnss3 libnspr4 libasound2t64` installed.

`bin/rails dev:setup` (`lib/tasks/dev.rake`) drops and recreates the development database, then creates `admin@admin.com` and `user@user.com` (password `123456`). It doesn't seed states. The user it creates has no company and no routes, so it only sees the home page.

## Database

Local settings live in `.env` (gitignored, loaded by `dotenv-rails` in development/test; template in `.env.example`), so `bin/rails server`/`test` need no exported variables. PostgreSQL via `pg`. `config/database.yml` reads `AGETUR_DATABASE_HOST` (default `localhost`), `AGETUR_DATABASE_USERNAME` (default `agetur`) and `AGETUR_DATABASE_PASSWORD` from the environment. Databases are `agetur_{development,test,production}`. `db/schema.rb` is `ActiveRecord::Schema[7.2]` and was regenerated natively against Postgres. The legacy `service_orders`/`service_order_items` tables are gone.

`bin/rails db:seed` creates the 27 Brazilian states (idempotent). Companies, vehicles and destinations require a state, so a fresh database needs the seed before those can be created.

Test fixtures are interdependent. Controller tests destroy the `:one` fixture of a resource, so fixtures that reference another resource (state, destination, sorder, ...) point at its `:two` fixture so the FK does not block the delete. Keep that convention when adding fixtures.

## Git history

Work happens on `main`. Its history includes a committed `config/master.key` (plus `node_modules/` and `tmp/`) from an older 2022 line of commits, so treat that key as exposed. Never force-push `main`, not even to purge them.

## Architecture

Standard scaffold-style Rails MVC: `resources :x` controllers with HTML views plus jbuilder JSON views. There is no API layer, no background jobs and no service objects; the only extra layer is `app/pdfs/`. Frontend is Sprockets (CoffeeScript + SCSS per controller under `app/assets/`), Turbolinks, Bootstrap 4 (`bootstrap.bundle`, so Popper is included and dropdowns work)/jQuery from `package.json` via yarn, and a vendored `public/templates/gentelella/` admin theme. There is no `app/javascript`/importmap.

### Orders: `Sorder` / `SorderItem`

The model was renamed from `ServiceOrder`/`ServiceOrderItem`. Use `Sorder`/`SorderItem`, and don't resurrect `service_order*` code. `_forma.html.erb` / `_sordera_item_fields.html.erb` are unused leftovers next to the real `_form` / `_sorder_item_fields`.

- `Sorder` nests `sorder_items` (cocoon), which nest `companions` (the pax list). Its destination, guide, driver, vehicle and company are required, while an item's customer, hotel and vendor are optional.
- FKs live on `sorders`/`companies`, so `Destination`, `Vehicle` and `State` use `has_many`, not `belongs_to`.
- Vendors, hotels, agencies, guides and drivers share one contact block: forms render `shared/_campos_contato` (needs `@state_options`), and show pages render `shared/_detalhes`. Re-imports never overwrite `comments`.
- Inactive vendors are refused only when newly chosen, so old and imported items stay editable.
- **Cancelled items:** blank `scancelado` means *not* cancelled. Filter with `SorderItem.ativos`, never `scancelado == "N"`. Totals, the show page and the PDF count only active items.
- **Passenger name:** use `SorderItem#nome_passageiro`. The typed `snomepax` replaced the customer select.
- **Commissions** (`amountcomission*`, vendor and repasse agency) are payables, not receivables.
- **Paid amounts** (`SordersController::PAGOS`) are read-only in the form, and only admins may submit them. Payments and commission payments move them.
- **Concurrent editing:** `sorders.lock_version` counts changes to the order, its items and its paid amounts. Only `SordersController#update` checks it, answering a stale form with a 409. Rails' optimistic locking is off. Any new code that writes items or paid amounts with `update_columns`/`update_all` must call `Sorder.nova_versao!(id)`. `SorderEdicao` only warns who else has the form open.
- Ransack 4 raises unless the model lists the field in `self.ransackable_attributes`. It filters sorders, hotels and the commission report (`/showcomis`).

### Financeiro: recebimentos, caixa, contas a pagar

Ported from SISTGER's `frmLancamentoOS` (sources in `D:\SISTGER\OS-Fontes`). Each model's header comment documents its part.
- A `SorderItemPayment` moves `amountpay` by its own value and never recomputes a sum, because imported items carry a paid amount without detailed payments. It also posts its `CashEntry` unless `lancar_no_caixa` is off.
- Cash entries made by a payment or a paid bill are `automatico?` and change only from their origin. `valor` is always positive and `tipo` (`E`/`S`) signs it.
- Closing an order (`Sorder#encerrar!`) turns what's left of its commissions and costs into `Payable`s. Closing again updates the open bills (`Payable.de_comissao`) instead of duplicating them, and `reabrir!` drops the unpaid ones. `pagar!`/`estornar!` post or undo the cash exit and the item's paid commission. `/comissoes/pagamento` pays in batch without closing the order. The order form's "Pagar comissão" menu (per passenger, one link per payment form) posts there with `retorno=ordem` to pay one vendor commission today and return to the order.
- A closed order (`encerrada`) refuses edit/update/destroy and new payments.

### Relação de ordens

`/relatorios/ordens` (`RelacaoOrdensController`, a card in the Relatórios tab) ports SISTGER's "Relação de O. Serviço" reports (by period, vendor, roteiro, guide, hotel) into one screen. `RelacaoOrdens` (a plain class in `app/models/`) loads the passengers of the period's orders with the filters, and the view and `RelacaoOrdensPdf` share it. Lines are one per order (sintético) or per passenger (analítico), optionally grouped with subtotals. Grouping by vendor or hotel splits an order among its passengers. Cancelled passengers show only on request and never count in the totals.

### Resumo operacional

`/relatorios/resumo-operacional` (`ResumoOperacionalController`, `ResumoOperacional`, `ResumoOperacionalPdf`) ports SISTGER's "Resumo Operacional Ordem de Serviço": every order in a period, by number, with its costs (`Sorder::CUSTOS`), value (active passengers' amount less both discounts), vendor commissions and total (value − commissions − costs). Like SISTGER's printout, it computes these instead of reading `valoros`/`valorfinalos`, which only the legacy form kept up to date. The PDF reproduces SISTGER's three-line block per order. SISTGER's "Qtde. Litros" is left out: no fuel quantity is stored.

### Agendamentos por usuário

`/relatorios/agendamentos-por-usuario` (`AgendamentosPorUsuario` + controller + PDF) ports SISTGER's "Passeios Agendados por Usuário", which read the `tblOrdemServicoItensLog` inserts: the period's order passengers grouped by who placed them. `sorder_items.usuario` holds that account's e-mail: `SorderItem` fills it on create from `Current.usuario` (set in `definir_empresa`), and a booked tour placed in an order brings its booking's `usuario` (`BookingItem#dados_para_ordem`). Imported passengers and those created before the column have none; the report only counts them. The import's `upsert_all` never touches the column.

### Agendamentos

`Booking` (`/agendamentos`) holds booked tours (`BookingItem`) that are later placed in an order.
- `BookingItem#lancar_na_os!` creates the order's `SorderItem` and moves the pax list, the expected commission and the down payments (with their cash entries) over. `retirar_da_os!`, or deleting that passenger in the order, hands them back.
- Every successful create/update in `SordersController` runs `Sorder#incluir_agendamentos!`, which pulls in pending tours for that destination and date. A passenger already typed with the same name (ignoring case and accents) is linked instead of duplicated. A tour taken out of an order gets `inclusao_automatica` false, so it doesn't come back by itself.
- Placed tours and their bookings can't be deleted.
- A blank time takes `PickupTime.hora_para(hotel, destination)`, for both booked tours and order items.

### SISTGER import (Manutenção tab)

`SistgerImport` (`app/importers/sistger_import.rb`) reads the legacy SISTGER SQL Server through `SistgerImport::Fonte` (`tiny_tds`) and upserts one step per table: empresa → clientes, vendedores, agências (after vendors, for their "vendedor correspondente"), hotéis, guias (`tblAgenteViagem`), motoristas (`tblFuncionarios`), veículos, roteiros → horários de passeio, comissões por roteiro → ordens → caixa. The orders step also brings, for the orders it imports, their passengers (`tblOrdemServicoItens`), payments (`tblOrdemServicoPagtos`) and pax list (`tblListaPax`). These are `PARTES_DA_ORDEM`: they aren't steps and have no filter of their own. The UI is `SistgerImportsController` at `/manutencao/sistger`. The user ticks steps and gives each a `SistgerImport::Filtro`:
- all;
- a period (orders and caixa only, by date);
- a code range (order number for orders);
- the last N.

Previews honor the filter. Chosen steps always run in dependency order.
- Re-importing an order replaces the pax list and payments of its imported items. Ones added in this app (`sistger_seq_adicional`/`sistger_seq` NULL) stay. Imported payments don't touch `amountpay`. The caixa step reads a join (`Etapa#origem`) and links payments to their entry through `sistger_caixa`.
- Connection settings (`SistgerImport::Configuracao`): each `SISTGER_DB_*` env var wins, and anything unset falls back to the Windows registry key the old SISTGER client uses (`HKCU\SOFTWARE\VB and VBA Program Settings\oServico\BANCO_DE_DADOS`), read with `reg.exe` under WSL. In dev, `.env` sets only host/port: the registry's named instance `mynt\sqlexpress` needs the SQL Browser, which WSL can't reach. Database, user and password come from the registry. `SISTGER_DB_REGISTRO=off` disables the registry lookup.
- Records carry the legacy key (`sistger_id`; `sistger_numero`+`sistger_sequencial` on `sorder_items`), so re-importing updates instead of duplicating. Records created in this app have NULL and are never touched.
- An imported order's `id` (the order number shown everywhere) is SISTGER's `iNumero`, equal to its `sistger_id`. Each order import renumbers older imports to match (`renumerar_ordens`; the `sorder_items` FK has `ON UPDATE CASCADE`). It then resets the `sorders` id sequence past the highest number. An `iNumero` already used by an order created here is skipped with a warning.
- Legacy orders keep guide, driver, plate, hotel and repasse agency mostly as free text (code columns are 0). Guides and drivers are matched to the imported register by name, or by a short name that only one of them has (`ids_por_nome(..., tambem: :short_name)`). When no code matches, the importer finds or creates a record named after the text (`ids_por_nome`). That is why the import creates thousands of hotel names. Blank values become `"Não informado"`.
- The legacy server is SQL Server 2014 RTM and only offers TLS 1.0, which tiny_tds/FreeTDS refuse. `SISTGER_DB_ENCRYPTION=off` points `FREETDSCONF` at `config/freetds-sem-criptografia.conf` (no TLS). tiny_tds 3.x also refuses TDS < 7.3, so don't try the `tsql`-only 7.0 workaround.
- Tests never hit SQL Server: they stub `SistgerImport::Fonte` with `test/support/sistger_fonte_falsa.rb`, canned rows keyed by table name.
- A full import is about 30 s, run synchronously in the request (there's no job system).

### PDF generation

1. **Preferred:** `app/pdfs/*.rb` (`HotelPdf`, `SorderPdf`, `OsrelPdf`, `SorderExportPdf`, `ReciboCaixaPdf`, `ResumoCaixaPdf`, `RelacaoOrdensPdf`, `ResumoOperacionalPdf`, `AgendamentosPorUsuarioPdf`; shared header/number formatting in the `PdfFormatacao` module). These are `Prawn::Document` subclasses (with `prawn-table`) that build the document in `initialize`. Controllers render them with `send_data pdf.render, ...`, either from a `format.pdf` branch (`HotelsController#index`, `SordersController#index`) or from a dedicated action (`SordersController#export`, the single-order PDF at `/sorders/:id/export`). Follow this pattern for new PDFs.
   - `SorderExportPdf` reproduces SISTGER's printed order models (OSmod2..7), picked by the company's `osmodel` (SISTGER's `iModeloOS`) through `SorderExportPdf.modelo_da`. Blank or unknown values fall back to model 6. `MODELOS` declares each model's columns (widths add up to 802 pt), how the pax list is shown (`:lista`/`:linha`/none), the payment form (model 3, `SorderItem#forma_pagamento`, SISTGER's `sFormaPagto`: D/Q/C/P, plus PIX as `O`, the cash book's key) and the footer (`:km`, or `:caixa` for model 7). The footer prints the model number. Each page repeats the company/trip header and the KM/notes footer. Each passenger gets a block: document, phone, PAX/CHD, time, amount left to receive (`total_passeio`) and vendor, with the pax list under the holder and the item's `comments` under the hotel. Cancelled and passed-on (`agency_id`) passengers appear only when the company has "Exibir cancelados na OS"/"Exibir repasse na OS" set (`Company#exibir_cancelados_na_os?`/`exibir_repasse_na_os?`; SISTGER prints with `sMostraCanceladosOS`, not `sMostraCancelados`), and never count in the totals. Items come in SISTGER's entry order (`sistger_sequencial`, then id). Text passes through `limpo`, because the built-in fonts only cover Windows-1252.
2. `app/views/sorders/index.pdf.prawn` is an older `prawn-rails` template. The `pdfkit`, `wicked_pdf` and `wkhtmltopdf-binary` gems and the `layouts/pdf.html.*` files are present but effectively unused.

### Auth / namespacing

- `devise_for :users` and `devise_for :admins` set up two independent models with no shared base.
- `UsersBackofficeController` / `AdminsBackofficeController` run `authenticate_user!` / `authenticate_admin!` and use their own layouts. Controllers under the `users_backoffice/` and `admins_backoffice/` namespaces inherit from them. Tests for those controllers need `sign_in` (`Devise::Test::IntegrationHelpers` is included in `test_helper.rb`).
- `ApplicationController` requires a signed-in User **or** Admin (`authenticate_user_or_admin!`) for every controller, so new controllers are protected by default. `SiteController` (public home page) and the two back-office base controllers `skip_before_action` it, and Devise's own controllers are exempt. Controller tests must `sign_in users(:one)` in `setup`. `test/controllers/authentication_test.rb` covers the logged-out behavior.
- Neither `User` nor `Admin` is `:registerable` (no `/users/sign_up` or `/admins/sign_up`). Admins manage users at `/admins_backoffice/usuarios` (password left blank on edit keeps the current one). Admins themselves are created from the console, e.g. `Admin.create!(email:, password:)`. Any signed-in account changes its own password at `/minha-senha` (`SenhasController`, in `Permissao::LIVRES`; current password required), linked from the home page and admin headers.
- Route permissions live on each `User`: `permissoes` (Postgres string array of `"controller#action"` keys) or `acesso_total`, checked in the user's form at `/admins_backoffice/usuarios` ("Copiar" starts a new user from another's routes). `ApplicationController#verificar_permissao!` sends a user to the home page with an alert (403 for non-HTML) unless `pode_acessar?(controller_path, action_name)`. Admins pass everything, and a user with no routes only gets the home page. `ApplicationHelper#link_to` is overridden to drop links to routes the user can't open (it recognizes the href and `method:`), so screens need no per-link checks; the dashboard still hides whole cards and tabs with `pode_acessar?`. The checkbox list comes from the routes (`Permissao.grupos`), so a new screen shows up by itself; label its custom actions in `config/locales/permissoes.pt-BR.yml`. `new`/`edit` share the key of `create`/`update`. Controllers in `Permissao::LIVRES` (site, back-offices, Devise) skip the check. Fixtures: `users(:one)`/`(:two)` have `acesso_total`, `users(:consulta)` a few routes, `users(:sem_rotas)` none.
- The home page is `site/welcome#index` (root and `/inicio`). It's public: logged-out visitors get a sign-in card, and signed-in accounts get a tabbed dashboard (Cadastros / Processos / Relatórios) with record counts built in `Site::WelcomeController`. Add new sections there. Bootstrap tabs; `app/assets/javascripts/dashboard.js` keeps the active tab in the URL hash.

### Empresas (data per company)

- Every cadastro and movement table has a required `company_id`, and its model includes the `DaEmpresa` concern. States are shared. Companions and `VendorDestination` are reached only through their parent and have no column.
- `ApplicationController#definir_empresa` fills `Current`. It's the first `before_action`, never skipped, and not prepended: it must run after the CSRF check, or looking up the account on a sign-in request makes Devise reset the token and every login fails (`csrf_login_test.rb` covers it).
  - An admin, or a user with `todas_empresas` ("Todas as empresas" in the user form), works in the company picked in the header (`escolhe_empresa?`). The picker is `layouts/_empresa_atual`, posting to `PATCH /trocar-empresa` (`TrocaEmpresaController`, outside the route permissions), and the choice is kept in `session[:empresa_id]`, defaulting to the first company.
  - Any other user works in `user.company` and sees no data without one.
  - The form sets both columns through the virtual `User#acesso_empresa` (blank, `"todas"` or a company id).
- `DaEmpresa`'s `default_scope` then filters every query, including `find` (another company's id is a 404), selects, counts, Ransack and PDFs. New rows take `Current.empresa_id`, or their parent's company via `da_empresa via:`. An optional reference to a record the scope hides fails validation.
- `Company` itself is scoped to a bound user's own record (`Current.so_a_propria_empresa`). Admins and `todas_empresas` users see every company.
- Use `empresa_atual` (a helper) for "the company of this page", never `Company.first`. The order form has no company select; an order belongs to the company being worked in.
- Outside a request (console, seeds) nothing is filtered and `company_id` must be given. Tests set `Current.empresa_id` to `companies(:two)` in `test_helper.rb`, and every fixture belongs to `:two`. Users `:one`/`:two`/`:consulta` work in it, `:sem_rotas` has none. Add `company: two` to new fixtures.
- `upsert_all`/`insert_all` skip callbacks, so pass `company_id` yourself. The SISTGER import runs with the scope off (`sem_escopo_de_empresa`) and writes everything to the company imported from SISTGER, or to the importer's company until that one is imported.

### Adding a cadastro

The conventions in this file each apply to a new cadastro. Together:
- **Model:** a required `company_id` with `include DaEmpresa`. Declare the search columns with `pesquisavel_por`. Add `self.ransackable_attributes` if the list is filtered. Add a `sistger_id` column if SISTGER will import it. Give the model and its attributes Portuguese names in `config/locales/models.pt-BR.yml`.
- **Index view:** `shared/_pesquisa`, a "Código" column and `ultimo_registro(Model)`. Teach `descricao_registro` the name column if it isn't `sname`. Row links (show/edit/delete and similar) go in one column as Font Awesome icons via `link_icone(icone, titulo, url, html_options)`, spaced with `class: "ml-2"`. Tests find them with `assert_select "a[title=...] i.fa-..."`.
- **Permissions:** routes show up in the user form by themselves. Label custom actions in `config/locales/permissoes.pt-BR.yml`.
- **Dashboard:** add a card, with its count, in `Site::WelcomeController` and its view, behind `pode_acessar?`.
- **Tests:** `sign_in users(:one)` in controller tests. Fixtures get `company: two`, and references to another resource point at its `:two` fixture.

### Misc

- Default locale is `pt-BR` (fallback `en`). `rails-i18n` and `devise-i18n` provide the framework/Devise translations, `config/locales/devise.pt-BR.yml` overrides Devise messages, and `config/locales/models.pt-BR.yml` holds Portuguese model/attribute names, used in validation errors, form error headers and submit buttons. Flash messages render once, from `layouts/_flash.html.erb` in every layout; don't add per-view `notice` markup. Controller notices are hardcoded Portuguese strings.
- The scoped Devise views (`app/views/users/`, `app/views/admins/`) were generated with `rails g devise:i18n:views` and then had their lazy keys (`t(".sign_in")`) rewritten to absolute `devise.*` keys. Lazy keys there would resolve to `users.sessions.new.*`, which has no translation. Keep that if you regenerate them, and re-delete the `registrations/` views, since sign-up is closed. The same applies to their `mailer/` views.
- Mail isn't delivered in development: `letter_opener_web` catches it, and Devise password-reset e-mails show up at `/letter_opener` (mounted only in development, no login needed). Production has no SMTP configured, and Devise's `mailer_sender` is still the placeholder.
- Cadastro lists search with `Model.pesquisar(params[:busca])` (`Pesquisavel` concern; columns declared with `pesquisavel_por`). The match ignores case and accents (Postgres `unaccent`, enabled by a migration), and a number also matches `id` or `sistger_id`. Views render `shared/_pesquisa` and a "Código" column. Add both to new cadastro lists.
- Cadastro index pages (and the sorders list) show `ultimo_registro(Model)` (`ApplicationHelper`): the highest-id record with its name and SISTGER code. Add it to new cadastro lists. Teach `descricao_registro` the model's name column if it isn't `sname`.
- `TxtController#importar` (`POST /txt/importar`) bulk-imports `Customer` records from an uploaded comma-separated `.txt`. It does no header validation and skips CSRF verification. 
- `Company` logos are Active Storage uploads (`has_one_attached :logo_entrada` for the home page, `:logo_formulario` for service orders). They're validated as PNG/JPG/GIF/WebP up to 2 MB and removable via the `remover_logo_*` form checkboxes. The legacy string columns `logoentrada`/`logoform` are only a fallback when they name a file that exists under `public/`. Old records hold Windows paths like `D:\\SISTGER\\...`, which are ignored. Always render logos with `company_logo_tag(company, :entrada | :formulario, height:)`. Files live on the `:local` disk service (`storage/`, gitignored), so production needs that directory persisted.
