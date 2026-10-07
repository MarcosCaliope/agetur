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

PostgreSQL via `pg`. `config/database.yml` reads `AGETUR_DATABASE_HOST` (default `localhost`), `AGETUR_DATABASE_USERNAME` (default `agetur`) and `AGETUR_DATABASE_PASSWORD` from the environment. Databases are `agetur_{development,test,production}`. `db/schema.rb` is `ActiveRecord::Schema[7.2]` and was regenerated natively against Postgres. The legacy `service_orders`/`service_order_items` tables are gone.

Test fixtures are interdependent. Controller tests destroy the `:one` fixture of a resource, so fixtures that reference another resource (state, destination, sorder, ...) point at its `:two` fixture so the FK does not block the delete. Keep that convention when adding fixtures.

## Git history

Work happens on `main` (tracking `origin/main`). The Rails 7.2 history was merged into it via PR #1 (merge commit `9772fec`). Before that, `origin/main` was a separate 2022 history (Rails 6.1/MySQL) sharing no commits with this one. Its commission work was ported in `a002710`, and merge commit `8dfdf7e` (`-s ours`, tree unchanged) links the two histories. The 2022 commits, including a committed `config/master.key` and `node_modules/`/`tmp/`, remain in history. Never force-push `main`.

## Architecture

Standard scaffold-style Rails MVC: `resources :x` controllers with HTML views plus jbuilder JSON views. There is no API layer, no background jobs and no service objects; the only extra layer is `app/pdfs/`. Frontend is Sprockets (CoffeeScript + SCSS per controller under `app/assets/`), Turbolinks, Bootstrap 4/jQuery from `package.json` via yarn, and a vendored `public/templates/gentelella/` admin theme. There is no `app/javascript`/importmap.

### Orders: `Sorder` / `SorderItem`

The model was renamed from `ServiceOrder`/`ServiceOrderItem`. Use `Sorder`/`SorderItem`, and don't resurrect `service_order*` code.

- `Sorder` has_many `sorder_items` (`accepts_nested_attributes_for`, `allow_destroy: true`; the nested form in `sorders/_form.html.erb` uses `cocoon` with `_sorder_item_fields.html.erb`). It belongs_to `destination`, `tourguide`, `driver`, `vehicle` and `company`, all required.
- `SorderItem` belongs_to `sorder`. Its `customer`, `hotel` and `vendor` associations are `optional: true` because they are filled in per passenger.
- FKs live on `sorders`/`companies`. `Destination`, `Vehicle` and `State` therefore use `has_many` (`:sorders`/`:companies`), not `belongs_to`.
- `SordersController` populates select options through many `set_*_options` before_actions. Each one plucks `[name, id]` pairs.
- Passenger items carry commission data: `amountcomission`/`amountcomissionpay` (vendor commission and the part received), `amountcomissionrep`/`amountcomissionreppay` (the same for the agency it was passed to), `snomepax` (typed passenger name, which replaced the customer select; use `SorderItem#nome_passageiro`, which falls back to `customer`) and `scancelado` (`"S"`/`"N"`). Blank `scancelado` means *not* cancelled, so filter with the `SorderItem.ativos` scope, not `scancelado == "N"`. `Sorder#total_pax`/`total_chd` and the show page/PDF only count active items.
- `GET /showcomis` (`SorderItemsController#showcomis`) is the commission report, filtered by item `created_at` range and vendor. `comissoes_query` stretches "Data Final" to the end of that day.
- Ransack (4.x) powers search/filtering on sorders, hotels and the commission report. Ransack 4 raises unless the model allowlists searchable fields via `self.ransackable_attributes`, so add new filter fields there.
- `_forma.html.erb` / `_sordera_item_fields.html.erb` are alternate/unused partials alongside the real `_form` / `_sorder_item_fields`.

### PDF generation

1. **Preferred:** `app/pdfs/*.rb` (`HotelPdf`, `SorderPdf`, `OsrelPdf`, `SorderExportPdf`). These are `Prawn::Document` subclasses (with `prawn-table`) that build the document in `initialize`. Controllers render them with `send_data pdf.render, ...`, either from a `format.pdf` branch (`HotelsController#index`, `SordersController#index`) or from a dedicated action (`SordersController#export`, the single-order PDF at `/sorders/:id/export`). Follow this pattern for new PDFs.
2. `app/views/sorders/index.pdf.prawn` is an older `prawn-rails` template. The `pdfkit`, `wicked_pdf` and `wkhtmltopdf-binary` gems and the `layouts/pdf.html.*` files are present but effectively unused.

### Auth / namespacing

- `devise_for :users` and `devise_for :admins` set up two independent models with no shared base.
- `UsersBackofficeController` / `AdminsBackofficeController` run `authenticate_user!` / `authenticate_admin!` and use their own layouts. Controllers under the `users_backoffice/` and `admins_backoffice/` namespaces inherit from them. Tests for those controllers need `sign_in` (`Devise::Test::IntegrationHelpers` is included in `test_helper.rb`).
- `ApplicationController` requires a signed-in User **or** Admin (`authenticate_user_or_admin!`) for every controller, so new controllers are protected by default. `SiteController` (public home page) and the two back-office base controllers `skip_before_action` it, and Devise's own controllers are exempt. Controller tests must `sign_in users(:one)` in `setup`. `test/controllers/authentication_test.rb` covers the logged-out behavior.
- Neither `User` nor `Admin` is `:registerable` (no `/users/sign_up` or `/admins/sign_up`, and no in-app password change). Create accounts from the console, e.g. `User.create!(email:, password:)`.
- The public site is `site/welcome#index` (root and `/inicio`).

### Misc

- `TxtController#importar` (`POST /txt/importar`) bulk-imports `Customer` records from an uploaded comma-separated `.txt`. It does no header validation and skips CSRF verification. Its messages are shown only in `txt/index`; the layouts render no `flash`.
- `Company` logos (`logoform`, `logoentrada`) are optional plain filenames under `public/`. Render them with `company_logo_tag` (`CompaniesHelper`), which skips blank values.
