# frozen_string_literal: true

Lightyear.application.configure do |config|
  # A hermetic test identity, distinct from development so the two DBs never
  # share a Realm. Seeded into the test DB by `db:prepare`.
  config.realm_fqdn = "as-of.test"
end
