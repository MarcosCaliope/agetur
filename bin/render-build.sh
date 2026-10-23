#!/usr/bin/env bash
# Render's build command (render.yaml): gems, the yarn packages Sprockets
# reads from node_modules (Bootstrap, jQuery), and the precompiled assets.
# Migrations and seeds run in the pre-deploy command instead.
set -o errexit

bundle install
npx --yes yarn@1.22.22 install --frozen-lockfile --production
bundle exec rails assets:precompile
bundle exec rails assets:clean
