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
# TRANSITIONAL (dies at gold master): the embedder MODEL payload is not in
# git — bake it into the image (checksum-verified by the gem's own build),
# so production never fetches at runtime (the assets:precompile cousin).
RUN bundle exec ruby -e 'require "lightyear/embedder_bge"; \
      exit 0 if Lightyear::EmbedderBge.available?; \
      gem_dir = Gem.loaded_specs["lightyear-embedder-bge"].full_gem_path; \
      script = File.join(gem_dir, "build/fetch_data.rb"); \
      system(RbConfig.ruby, script, chdir: gem_dir) || abort("model bake failed")'
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
