# frozen_string_literal: true
# Generated from blueprint.yml by Lightyear::Blueprint (deterministic build).
# register! is idempotent (find-or-create); grants are not yet (Phase 3).

realm = Lightyear.realm

# The incumbent systems (the broker): onboard once, commission agents against them forever.

# TODO(edgar): set its credential (blueprint named it "sec_user_agent") + complete base_url and each endpoint's method/path.
unless realm.connections.exists?(system: "edgar")
  realm.connect(:edgar, source_kind: :http, config: {
    "base_url" => "https://data.sec.gov",
    "user_agent" => ENV["SEC_USER_AGENT"],
    "endpoints" => {
      "edgar/fetch" => {
        "method" => "get",
        "path" => "/Archives/edgar/data/{cik}/{accession_nodash}/{accession}.txt",
        "resource" => "accession",
        "impact" => "low",
      },
    },
  })
end

# Commission the workforce.
clerk = ClerkAgent.register!(realm: realm, name: "Clerk", readiness: "supervised")
clerk.set_charter(mission: "Hold the record desk. Retrieve hashed public-record sources and filing headers. Do not extract claims, gloss, brief, or forecast. Unknown → say unknown.\n")

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
