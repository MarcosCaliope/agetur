#!/usr/bin/env bash
# Render's build command (render.yaml): gems, the yarn packages Sprockets
# reads from node_modules (Bootstrap, jQuery), the precompiled assets, and,
# because the free plan has no pre-deploy command, the migrations and seeds.
set -o errexit

# Render's image also has a Bun wrapper, and ExecJS picks it over Node. Bun
# can't run ExecJS's temp files, which breaks compiling the CoffeeScript.
export EXECJS_RUNTIME=Node

bundle install
npx --yes yarn@1.22.22 install --frozen-lockfile --production
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate
bundle exec rails db:seed
