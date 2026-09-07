# frozen_string_literal: true

# The MSV serving (docs/design/msv.md) — put your view contract on the wire.
# The starter lexicon/panel/cockpit in app/msv/ are ready; uncomment to serve:
# GET /app/manifest (the contract), GET /app/envelope (the surfaces),
# POST /app/signals (telemetry/stated — channel stamped by route),
# GET /app/stream (reshape pings). clients/web/index.html is a minimal
# posture-B client; `rm -rf clients/` always leaves a working headless app.
#
# require_relative "../app/msv/instruments/lexicon"
# require_relative "../app/msv/cockpit"
#
# Lightyear::MSV.serve do |msv|
#   msv.lexicon       = LEXICON
#   msv.cockpit       = Cockpit
#   msv.situation_for = ->(session) {
#     observer = Lightyear.realm.agents.find_by!(name: "concierge") # seed one
#     Lightyear::MSV::Situation.new(
#       scope: observer.memory_of(Lightyear.realm.entity("user-#{session.subject}")),
#       keys: %i[intent],
#     )
#   }
#   msv.model_for = ->(viewer) { nil }
#   msv.inference = ->(signal, situation) {
#     # the deterministic tier: mechanical signals -> beliefs
#   }
# end
