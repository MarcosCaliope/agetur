# Agetur

Back-office for a tour/travel agency: customers, hotels, vehicles, guides, vendors and the service orders (OS) that bundle each trip's passengers. Rails 7.2, Ruby 3.4.5, PostgreSQL.

## Setup

```bash
cp .env.example .env     # database settings
bin/setup                # bundle install + db:setup
bin/rails dev:setup      # optional: recreate dev DB with admin@admin.com / user@user.com (123456)
bin/rails db:seed        # Brazilian states, needed before companies/vehicles/destinations
bin/rails server
```

## Tests

```bash
bin/rails test           # everything except system tests
bin/rails test:system    # headless Chrome
```

## More

- `CLAUDE.md`: architecture, conventions and the rules that are easy to break.
- `docs/deploy-render.md`: deploying to Render.
