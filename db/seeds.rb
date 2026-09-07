# frozen_string_literal: true
# Generated from blueprint.yml by Lightyear::Blueprint (deterministic build).
# register! is idempotent (find-or-create); grants are not yet (Phase 3).

realm = Lightyear.realm

require_relative "../lib/as_of/broker"

# The incumbent systems (the broker): onboard once, commission agents against them forever.
AsOf::Broker.ensure!(realm)
Rule.seed!

# Commission the workforce.
clerk = ClerkAgent.register!(realm: realm, name: "Clerk", readiness: "supervised")
clerk.set_charter(mission: "Hold the record desk. Retrieve hashed public-record sources, filing headers, official series snapshots, and seeded rule pointers. Do not extract claims, gloss, brief, or forecast. Unknown → say unknown. Do not paraphrase a rule without a pointer.\n")

# The DEVELOPMENT operator (the both-hats posture): in development, YOU are the desk.
if Lightyear.env == "development" && Lightyear.realm
  operator = Lightyear::Trust::Principal.find_or_create_by!(
    realm: Lightyear.realm, name: ENV["USER"] || "operator",
  )
  already = Lightyear::Trust::Writ.held_by(operator.did).any? do |writ|
    writ.verified? && writ.grants?("approve/anything")
  end
  Lightyear.realm.grant("approve/*", on: "*", for: :forever, to: operator.did) unless already
end
