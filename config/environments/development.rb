# frozen_string_literal: true

Lightyear.application.configure do |config|
  # Your home Realm's identity in development — a local placeholder. It needn't
  # resolve (did:web resolution only matters when a PEER Realm verifies you, which
  # needs a real deployed domain). `db:prepare` seeds this Realm into the dev DB.
  config.realm_fqdn = "as-of.localhost"
end
