# frozen_string_literal: true
# Generated from blueprint.yml by Lightyear::Blueprint (deterministic build).
# register! is idempotent (find-or-create); grants are not yet (Phase 3).

realm = Lightyear.realm

require_relative "../lib/as_of/broker"

# The incumbent systems (the broker): onboard once, commission agents against them forever.
AsOf::Broker.ensure!(realm)
Rule.seed!

# Commission the workforce.
gloss_writer = GlossWriterAgent.register!(realm: realm, name: "GlossWriter", readiness: "supervised")
gloss_writer.set_charter(mission: "Explain a record in at most eight sentences. Every sentence must be supportable by source_ids. No new numbers. No advice verbs. No forecasts. Task is gloss only.\n")

edgar_reporter = EdgarReporterAgent.register!(realm: realm, name: "EdgarReporter", readiness: "supervised")
edgar_reporter.set_charter(mission: "Cover whitelist issuers. Extract filing headers then facts from source bytes. Only use provided text. Never invent numbers. A number not present in source bytes is dropped. No advice verbs. No forecasts as asserted claims.\n")

brief_desk = BriefDeskAgent.register!(realm: realm, name: "BriefDesk", readiness: "supervised")
brief_desk.set_charter(mission: "Answer brief/query from retrieved sources only. Headline at most 140 characters. Only use provided text. Never invent numbers. No advice verbs. No forecasts as asserted claims. Corrections append supersedes.\n")

clerk = ClerkAgent.register!(realm: realm, name: "Clerk", readiness: "supervised")
clerk.set_charter(mission: "Hold the record desk. Retrieve hashed public-record sources, filing headers, official series snapshots, seeded rule pointers, and watch lists. Do not extract claims, gloss, brief, or forecast. Unknown → say unknown. Do not paraphrase a rule without a pointer.\n")

# The DEVELOPMENT operator (the both-hats posture): in development, YOU are the desk.
if Lightyear.env == "development" && Lightyear.realm
  operator = Lightyear::Trust::Principal.find_or_create_by!(
    realm: Lightyear.realm, name: ENV["USER"] || "operator",
  )
  already = Lightyear::Trust::Writ.held_by(operator.did).any? do |writ|
    writ.verified? && writ.grants?("approve/anything")
  end
  Lightyear.realm.grant("approve/*", on: "*", for: :forever, to: operator.did) unless already
  %w[store rotate revoke].each do |act|
    verb = "realm/credentials/#{act}"
    has = Lightyear::Trust::Writ.held_by(operator.did).any? { |w| w.verified? && w.allows?(verb, on: "*") }
    Lightyear.realm.grant(verb, on: "*", for: :forever, to: operator.did) unless has
  end
end
