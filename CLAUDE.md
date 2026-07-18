# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Agetur is a Ruby on Rails 5.2 (Ruby 2.7.0) back-office application for a tour/travel agency: it manages customers, destinations, hotels, vehicles, drivers, tour guides, vendors, agencies, states and companies, and issues "sorders" (service orders) that bundle a trip's guide/driver/vehicle/destination with per-passenger `sorder_items`. Two Devise-backed user types (`User` and `Admin`) get separate namespaced back-offices.

## Commands

```bash
bundle install                    # install gems
bin/setup                         # bootstrap (bundle install, db setup)

bin/rails server                  # run the app (default port 3000)
bin/rails console

bin/rails db:create db:migrate    # set up MySQL database (see config/database.yml)
bin/rails db:seed

bin/rails test                                          # full test suite
bin/rails test test/models/sorder_test.rb                # single file
bin/rails test test/models/sorder_test.rb:12              # single test at line 12
bin/rails test:system                                     # Capybara/Selenium system tests
```

There is no configured linter/rubocop in the Gemfile — don't assume one exists.

## Database

MySQL via `mysql2`. Credentials are hardcoded in `config/database.yml` for dev/test (`root` / a literal password), production reads `AGETUR_DATABASE_PASSWORD` from the environment. Schema is managed through migrations in `db/migrate` + `db/schema.rb` (`ActiveRecord::Schema`, currently at version `2021_08_24_141717`).

## Architecture

**Standard Rails MVC**, scaffold-generated controllers/views (`resources :x` + jbuilder JSON views alongside HTML). No API/GraphQL layer, no background job system, no service objects beyond `app/pdfs/`.

### The `sorder`/`sorder_item` vs. legacy `service_order`/`service_order_item` split

The domain model was renamed mid-project from `ServiceOrder`/`ServiceOrderItem` to `Sorder`/`SorderItem`, but the old MySQL tables (`service_orders`, `service_order_items`) and their FKs are still present in `db/schema.rb` — only the Rails-side model/controller/view/helper/asset files were removed (see working-tree deletions). When working on order-related features, use `Sorder`/`SorderItem`/`sorders_controller.rb`, not the deleted `service_order*` files. Don't resurrect the old files; if you need to drop the legacy tables, do it via a proper migration.

Key relations:
- `Sorder` has_many `sorder_items` (accepts_nested_attributes_for, `allow_destroy: true`), belongs_to `destination`, `tourguide`, `company`, `driver`, `vehicle`.
- `SorderItem` belongs_to `sorder`, `customer`, `hotel`, `vendor`.
- `Customer`, `Vehicle`, `Company`, `Destination` belong_to `state` (optional for `Customer`).
- Ransack (`gem 'ransack', github: 'activerecord-hackery/ransack'`) powers search/filtering, e.g. `SordersController#index` does `Sorder.ransack(params[:q])`.

### PDF generation — three different mechanisms coexist

1. **`app/pdfs/*.rb`** (`HotelPdf`, `SorderPdf`, `OsrelPdf`) — classes that subclass `Prawn::Document`, build a table in `initialize`, and are rendered via `send_data pdf.render, ...` from `respond_to do |format| format.pdf { ... } end` blocks in controllers (see `HotelsController`, `SordersController#index`). This is the current/preferred pattern for new list-style PDFs.
2. **`lib/generate_pdf.rb`** (`GeneratePdf` module) — older Prawn + Gruff (chart) based generator used by `SordersController#export`, writes files directly to `public/*.pdf`/`public/*.jpg` and redirects to them. Treat as legacy; several referenced instance variables (`details`, `name`, `price`) are undefined and this path is not fully functional.
3. **`app/views/sorders/index.pdf.prawn`** — a `prawn-rails` template-based PDF view, an alternate/older approach to the same `sorders#index` PDF format. `app/views/layouts/pdf.html.erb`/`.html.haml` and `wicked_pdf`/`pdfkit` gems are also present in the Gemfile but largely unused/commented out in controllers.

When adding a new exportable PDF list, follow pattern (1): add an `app/pdfs/<name>_pdf.rb` class and a `format.pdf` branch in the controller.

### Auth / namespacing

- `devise_for :users` and `devise_for :admins` — two independent authenticatable models (`app/models/user.rb`, `app/models/admin.rb`), no shared base.
- `UsersBackofficeController` / `AdminsBackofficeController` are base controllers with `before_action :authenticate_user!` / `authenticate_admin!` and their own layouts (`users_backoffice`, `admins_backoffice`); controllers under `users_backoffice/` and `admins_backoffice/` namespaces should inherit from these rather than `ApplicationController` directly.
- Most resourceful controllers (`hotels`, `customers`, `sorders`, etc.) currently have **no** `before_action :authenticate_*!` — they are not gated behind Devise despite the back-office namespaces existing.

### Misc

- `TxtController#importar` bulk-imports `Customer` records from an uploaded CSV-like `.txt` file (comma-split, no header validation) and skips CSRF verification.
- Frontend: Sprockets asset pipeline (CoffeeScript + SCSS per-controller files under `app/assets/`), Bootstrap 4/jQuery via `package.json` + `yarn`, plus a vendored `public/templates/gentelella/` admin theme.
- `config/application.rb` contains two `class Application` definitions in different modules (`Agetur::Application` and a stray `RailsPdf::Application` with commented-out PDFKit middleware) — the latter appears to be leftover/dead code, not the app's actual entry point.
