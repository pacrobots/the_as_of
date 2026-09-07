# syntax=docker/dockerfile:1
# The production image (docs/design/deploy-estate.md). Deployed by Kamal:
# fill config/deploy.yml's placeholders, then `kamal setup` once and
# `kamal deploy` forever. Two TRANSITIONAL steps below (marked) disappear
# when the lightyear gems publish.

FROM ruby:3.4-slim AS base
WORKDIR /app
ENV LIGHTYEAR_ENV=production BUNDLE_DEPLOYMENT=1 BUNDLE_WITHOUT=development:test
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
      build-essential git libsqlite3-dev curl && \
    rm -rf /var/lib/apt/lists/*

FROM base AS build
COPY Gemfile Gemfile.lock ./
# TRANSITIONAL (dies at gold master): the framework gems are a private git
# dependency — bundle needs a read token, delivered as a BuildKit secret
# (never an ENV bake-in):
#   kamal build ... (the secret rides .kamal/secrets -> LIGHTYEAR_GEM_READ_TOKEN)
RUN --mount=type=secret,id=lightyear_gem_read_token \
    if [ -s /run/secrets/lightyear_gem_read_token ]; then \
      bundle config set --local github.com "x-access-token:$(cat /run/secrets/lightyear_gem_read_token)"; \
    fi && bundle install && bundle config unset --local github.com || true
# Embedder model bake skipped: production recall is lexical on the 4Gi Skyvim box.
COPY . .

FROM base
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app
# The durable ground: the SQLite database + storage live on a Kamal volume.
VOLUME /app/storage
EXPOSE 4321
# db:prepare at boot (migrations ride the gem map — no vendored copies),
# then the server. The jobs role overrides CMD in deploy.yml.
ENTRYPOINT ["./bin/docker-entrypoint"]
CMD ["./bin/lightyear", "server", "-p", "4321"]
