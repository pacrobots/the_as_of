# frozen_string_literal: true

source "https://rubygems.org"

# pacificrobots/lightyear#55 (Server.mount) is on main.
# Local overlay: bundle config local.lightyear vendor/lightyear
gem "lightyear", github: "pacificrobots/lightyear", branch: "main"
gem "lightyear-embedder-bge", github: "pacificrobots/lightyear", branch: "main", glob: "gems/lightyear-embedder-bge/*.gemspec"
gem "sqlite3", "~> 2.9"
# json 3.0 dropped JSON.parse(str, opts); ActiveSupport 8.1 still passes quirks_mode.
gem "json", "~> 2.13"
gem "puma" # the Rack server `lightyear server` and config.ru run on
# The LLM wire your agents' brains (and, if enabled, memory derivation) speak
# through — one gem, every provider in config/runtimes.yml, cloud or local.
# Deliberately the APP's dependency, not lightyear's: you own the pin.
gem "ruby_llm", ">= 1.16", "< 2.0"
# Hybrid memory recall works out of the box: the local embedding model (and the engine it
# runs on) arrives WITH lightyear — the lightyear-embedder-bge gem — so nothing is fetched
# at runtime and nothing leaves the machine. Opt out per-env with `recall: lexical`, or
# swap in a cloud embedder, in config/runtimes.yml.

group :development, :test do
  gem "debug"
  gem "rake" # the Rakefile's test task (was a transitive dep until solid_queue was dropped)
end
