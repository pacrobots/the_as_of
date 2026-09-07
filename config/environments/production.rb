# frozen_string_literal: true

Lightyear.application.configure do |config|
  # Your REAL production identity. Set REALM_FQDN to your domain on the host —
  # it must serve /.well-known/did.json there so peer Realms can verify your
  # signatures. The default below is an obvious placeholder; `lightyear realm`
  # will show it so a missing REALM_FQDN is caught before it signs anything.
  config.realm_fqdn = ENV.fetch("REALM_FQDN", "theasof.com")
end
