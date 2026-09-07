# frozen_string_literal: true

# Seed data. Run per environment with: bin/lightyear db:seed
#
# This is where you COMMISSION your Realm's standing agents. Declaring an agent
# (the class in app/agents/) is code and carries to every environment for free;
# commissioning one (giving it an identity in a Realm) is a deliberate, recorded
# act — so it lives here, runs per-env, and mints the right DID for each Realm
# (dev's agent is did:web:<dev fqdn>#name, prod's is did:web:<prod fqdn>#name).
#
# register! is idempotent (find-or-register by realm + name), so re-running this
# on every deploy is safe — it never churns an existing agent's identity.
#
#   ConciergeAgent
#     .register!(realm: Lightyear.realm, name: "Remy")
#     .set_charter(Lightyear.charter("concierge"))   # app/agents/charters/concierge.md

# The DEVELOPMENT operator (the both-hats posture): in development, YOU are
# the desk. This grant makes every requires_approval pause decidable by you —
# at /desk in the browser, or `lightyear decisions` in the terminal. It is
# development-only and deliberate: production operators are commissioned by
# hand, with narrower grants and real login in front of the desk.
if Lightyear.env == "development" && Lightyear.realm
  operator = Lightyear::Trust::Principal.find_or_create_by!(
    realm: Lightyear.realm, name: ENV["USER"] || "operator",
  )
  already = Lightyear::Trust::Writ.held_by(operator.did).any? do |writ|
    writ.verified? && writ.grants?("approve/anything")
  end
  Lightyear.realm.grant("approve/*", on: "*", for: :forever, to: operator.did) unless already
end
