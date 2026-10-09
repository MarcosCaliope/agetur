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

bin/rails test                                   # full suite (models + controllers)
bin/rails test test/models/sorder_test.rb        # single file
bin/rails test test/models/sorder_test.rb:12     # single test at line 12
bin/rails test:system                            # Capybara/Selenium (Selenium Manager resolves the driver)
```

No linter (rubocop etc.) is configured.

## Database

Local settings live in `.env` (gitignored, loaded by `dotenv-rails` in development/test; template in `.env.example`), so `bin/rails server`/`test` need no exported variables. PostgreSQL via `pg`. `config/database.yml` reads `AGETUR_DATABASE_HOST` (default `localhost`), `AGETUR_DATABASE_USERNAME` (default `agetur`) and `AGETUR_DATABASE_PASSWORD` from the environment. Databases are `agetur_{development,test,production}`. `db/schema.rb` is `ActiveRecord::Schema[7.2]` and was regenerated natively against Postgres. The legacy `service_orders`/`service_order_items` tables are gone.

`bin/rails db:seed` creates the 27 Brazilian states (idempotent). Companies, vehicles and destinations require a state, so a fresh database needs the seed before those can be created.

Test fixtures are interdependent. Controller tests destroy the `:one` fixture of a resource, so fixtures that reference another resource (state, destination, sorder, ...) point at its `:two` fixture so the FK does not block the delete. Keep that convention when adding fixtures.

## Git history

Work happens on `main` (tracking `origin/main`). The Rails 7.2 history was merged into it via PR #1 (merge commit `9772fec`). Before that, `origin/main` was a separate 2022 history (Rails 6.1/MySQL) sharing no commits with this one. Its commission work was ported in `a002710`, and merge commit `8dfdf7e` (`-s ours`, tree unchanged) links the two histories. The 2022 commits, including a committed `config/master.key` and `node_modules/`/`tmp/`, remain in history. Never force-push `main`.

## Architecture

Standard scaffold-style Rails MVC: `resources :x` controllers with HTML views plus jbuilder JSON views. There is no API layer, no background jobs and no service objects; the only extra layer is `app/pdfs/`. Frontend is Sprockets (CoffeeScript + SCSS per controller under `app/assets/`), Turbolinks, Bootstrap 4/jQuery from `package.json` via yarn, and a vendored `public/templates/gentelella/` admin theme. There is no `app/javascript`/importmap.

### Orders: `Sorder` / `SorderItem`

The model was renamed from `ServiceOrder`/`ServiceOrderItem`. Use `Sorder`/`SorderItem`, and don't resurrect `service_order*` code.

- `Sorder` has_many `sorder_items` (`accepts_nested_attributes_for`, `allow_destroy: true`; the nested form in `sorders/_form.html.erb` uses `cocoon` with `_sorder_item_fields.html.erb`). It belongs_to `destination`, `tourguide`, `driver`, `vehicle` and `company`, all required.
- Vendors, hotels, agencies, guides and drivers share SISTGER's generic cadastro screen (`frmCadGenerico`): short name, CPF/CNPJ, address/neighborhood/city/state/CEP, two phones, fax and contact. Forms render it with `shared/_campos_contato` (needs `@state_options`), and show pages use `shared/_detalhes`. Customers (`CAR-fontes/frmCadClientes`) add state registration, website and a billing block. Re-imports never overwrite `comments`.
- Vendors mirror SISTGER's vendor screen (`frmCadGenerico` with `tblVendedor`, sources in `D:\SISTGER\OS-Fontes`). `active` (bAtivo): inactive vendors are left out of the order form's vendor select and refused by `SorderItem#vendedor_ativo`, but only when the vendor is newly chosen, so imported/old items stay editable. `no_commission` (bComissao) is the "Não pagar comissão" checkbox.
- `VendorDestination` (`/vendors/:id/comissoes-por-roteiro`, SISTGER's `frmVendedorRoteiro`/`tblVendedorRoteiro`) holds a vendor's commission % and net prices (adult/CHD, cash/card) per destination. The screen is one grid of every destination prefilled with the vendor's default %. Only rows that differ from the default are stored, and rows set back to it are deleted. Not yet used by the order form; SISTGER fills commission/net from it on order entry.
- `SorderItem` belongs_to `sorder`. Its `customer`, `hotel` and `vendor` associations are `optional: true` because they are filled in per passenger.
- `SorderItemCompanion` (`item.companions`, SISTGER's "lista pax" `tblListaPax`) holds the other people travelling under a passenger item: name, document, `chd`, `colo`. It's nested inside each item in the order form (cocoon, `_companion_fields`), and the show page and PDF list it under the holder's name.
- FKs live on `sorders`/`companies`. `Destination`, `Vehicle` and `State` therefore use `has_many` (`:sorders`/`:companies`), not `belongs_to`.
- `SordersController` populates select options through many `set_*_options` before_actions. Each one plucks `[name, id]` pairs.
- Passenger items carry commission data: `amountcomission`/`amountcomissionpay` (vendor commission and the part received), `amountcomissionrep`/`amountcomissionreppay` (the same for the agency it was passed to), `snomepax` (typed passenger name, which replaced the customer select; use `SorderItem#nome_passageiro`, which falls back to `customer`) and `scancelado` (`"S"`/`"N"`). Blank `scancelado` means *not* cancelled, so filter with the `SorderItem.ativos` scope, not `scancelado == "N"`. `Sorder#total_pax`/`total_chd` and the show page/PDF only count active items.
- `GET /showcomis` (`SorderItemsController#showcomis`) is the commission report, filtered by item `created_at` range and vendor. `comissoes_query` stretches "Data Final" to the end of that day.
- Ransack (4.x) powers search/filtering on sorders, hotels and the commission report. Ransack 4 raises unless the model allowlists searchable fields via `self.ransackable_attributes`, so add new filter fields there.
- `_forma.html.erb` / `_sordera_item_fields.html.erb` are alternate/unused partials alongside the real `_form` / `_sorder_item_fields`.

### Financeiro: recebimentos, caixa, contas a pagar

Ported from SISTGER's `frmLancamentoOS` (sources in `D:\SISTGER\OS-Fontes`). There, only passenger payments and the cash book were really used. The bills-to-pay code (`tblOrdemPagar`, `tblDuplicatas`) sits after an `Exit Sub` in "Encerrar OS" and its tables are empty.
- `SorderItemPayment` (`item.pagamentos`, `/sorder_items/:id/recebimentos`, SISTGER's `tblOrdemServicoPagtos`): creating or destroying one moves `amountpay` by its value. It doesn't recompute a sum, because imported items carry a paid amount without detailed payments. It also creates or destroys its `CashEntry` unless `lancar_no_caixa` is off. It's refused above `SorderItem#total_passeio` (value − paid − `discount` − `vendor_discount`, as SISTGER) or on a closed order.
- `CashEntry` (`/caixa`, SISTGER's `cx_num`+`cx_mov`, one row per line): `tipo` `E`/`S`, `forma_pagamento` from `CashEntry::FORMAS`, `valor` always positive, and `CashEntry.saldo` signs it. Entries made by a payment or a paid bill are `automatico?` and can be changed only from their origin.
- `Payable` (`/contas-a-pagar`): `tipo` comissao_vendedor / comissao_repasse / custo_os / avulsa. `Sorder#encerrar!` creates the first three from the active items' commission balances (skipping `no_commission` vendors) and the order's costs (`Sorder::CUSTOS`). They're due on the order date and keyed by `origem`, so closing again doesn't duplicate them. `reabrir!` drops the unpaid ones. `pagar!` posts an exit in the cash book and, for commissions, adds to the item's `amountcomissionpay`/`amountcomissionreppay`. `estornar!` undoes both.
- `sorders.encerrada` (SISTGER's `iFlgAberto`): `SordersController` refuses edit/update/destroy on a closed order.

### SISTGER import (Manutenção tab)

`SistgerImport` (`app/importers/sistger_import.rb`) reads the legacy SISTGER SQL Server through `SistgerImport::Fonte` (`tiny_tds`) and upserts one step per table: empresa → clientes, vendedores, agências (after vendors, for their "vendedor correspondente"), hotéis, guias (`tblAgenteViagem`), motoristas (`tblFuncionarios`), veículos, roteiros → comissões por roteiro → ordens → caixa. The orders step also brings, for the orders it imports, their passengers (`tblOrdemServicoItens`), payments (`tblOrdemServicoPagtos`) and pax list (`tblListaPax`). These are `PARTES_DA_ORDEM`: they aren't steps and have no filter of their own. The UI is `SistgerImportsController` at `/manutencao/sistger`. The user ticks steps and gives each a `SistgerImport::Filtro`:
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

1. **Preferred:** `app/pdfs/*.rb` (`HotelPdf`, `SorderPdf`, `OsrelPdf`, `SorderExportPdf`). These are `Prawn::Document` subclasses (with `prawn-table`) that build the document in `initialize`. Controllers render them with `send_data pdf.render, ...`, either from a `format.pdf` branch (`HotelsController#index`, `SordersController#index`) or from a dedicated action (`SordersController#export`, the single-order PDF at `/sorders/:id/export`). Follow this pattern for new PDFs.
2. `app/views/sorders/index.pdf.prawn` is an older `prawn-rails` template. The `pdfkit`, `wicked_pdf` and `wkhtmltopdf-binary` gems and the `layouts/pdf.html.*` files are present but effectively unused.

### Auth / namespacing

- `devise_for :users` and `devise_for :admins` set up two independent models with no shared base.
- `UsersBackofficeController` / `AdminsBackofficeController` run `authenticate_user!` / `authenticate_admin!` and use their own layouts. Controllers under the `users_backoffice/` and `admins_backoffice/` namespaces inherit from them. Tests for those controllers need `sign_in` (`Devise::Test::IntegrationHelpers` is included in `test_helper.rb`).
- `ApplicationController` requires a signed-in User **or** Admin (`authenticate_user_or_admin!`) for every controller, so new controllers are protected by default. `SiteController` (public home page) and the two back-office base controllers `skip_before_action` it, and Devise's own controllers are exempt. Controller tests must `sign_in users(:one)` in `setup`. `test/controllers/authentication_test.rb` covers the logged-out behavior.
- Neither `User` nor `Admin` is `:registerable` (no `/users/sign_up` or `/admins/sign_up`, and no in-app password change). Create accounts from the console, e.g. `User.create!(email:, password:)`.
- The home page is `site/welcome#index` (root and `/inicio`). It's public: logged-out visitors get a sign-in card, and signed-in accounts get a tabbed dashboard (Cadastros / Processos / Relatórios) with record counts built in `Site::WelcomeController`. Add new sections there. Bootstrap tabs; `app/assets/javascripts/dashboard.js` keeps the active tab in the URL hash.

### Misc

- Default locale is `pt-BR` (fallback `en`). `rails-i18n` and `devise-i18n` provide the framework/Devise translations, `config/locales/devise.pt-BR.yml` overrides Devise messages, and `config/locales/models.pt-BR.yml` holds Portuguese model/attribute names, used in validation errors, form error headers and submit buttons. Flash messages render once, from `layouts/_flash.html.erb` in every layout; don't add per-view `notice` markup. Controller notices are hardcoded Portuguese strings.
- The scoped Devise views (`app/views/users/`, `app/views/admins/`) were generated with `rails g devise:i18n:views` and then had their lazy keys (`t(".sign_in")`) rewritten to absolute `devise.*` keys. Lazy keys there would resolve to `users.sessions.new.*`, which has no translation. Keep that if you regenerate them, and re-delete the `registrations/` views, since sign-up is closed. The same applies to their `mailer/` views.
- Mail isn't delivered in development: `letter_opener_web` catches it, and Devise password-reset e-mails show up at `/letter_opener` (mounted only in development, no login needed). Production has no SMTP configured, and Devise's `mailer_sender` is still the placeholder.
- Cadastro lists search with `Model.pesquisar(params[:busca])` (`Pesquisavel` concern; columns declared with `pesquisavel_por`). The match ignores case and accents (Postgres `unaccent`, enabled by a migration), and a number also matches `id` or `sistger_id`. Views render `shared/_pesquisa` and a "Código" column. Add both to new cadastro lists.
- Cadastro index pages (and the sorders list) show `ultimo_registro(Model)` (`ApplicationHelper`): the highest-id record with its name and SISTGER code. Add it to new cadastro lists. Teach `descricao_registro` the model's name column if it isn't `sname`.
- `TxtController#importar` (`POST /txt/importar`) bulk-imports `Customer` records from an uploaded comma-separated `.txt`. It does no header validation and skips CSRF verification. 
- `Company` logos are Active Storage uploads (`has_one_attached :logo_entrada` for the home page, `:logo_formulario` for service orders). They're validated as PNG/JPG/GIF/WebP up to 2 MB and removable via the `remover_logo_*` form checkboxes. The legacy string columns `logoentrada`/`logoform` are only a fallback when they name a file that exists under `public/`. Old records hold Windows paths like `D:\\SISTGER\\...`, which are ignored. Always render logos with `company_logo_tag(company, :entrada | :formulario, height:)`. Files live on the `:local` disk service (`storage/`, gitignored), so production needs that directory persisted.
