# frozen_string_literal: true
#
# Your domain topology — where your agents' reachable records live
# (guides: deployment-designs). Three shapes:
#
#   MONOLITH — this file stays empty. Your blueprint's entities are ActiveRecord
#   models IN this app; opt one in for agents directly on the model:
#
#     class Invoice < ApplicationRecord
#       reachable_by_agents scopes: [:overdue], writable: [:status]
#     end
#
#   No base_url, no resolver: in-process resolution, same governance. (Never
#   point a RestResolver at THIS app — the projection/scopes/writable protection
#   comes from the gate, not the wire; a loopback HTTP hop buys nothing.)
#
#   OPERATES-ON / CONSTELLATION — declare each host app you operate ONCE, by
#   name; group its models; coordinates from ENV, secrets in the credentials
#   store (never here):
#
#     Lightyear::AgentReachable.host :billing,
#       via: Lightyear::Agents::Host::RestResolver.new(base_url: ENV.fetch("BILLING_URL"),
#                                                      fetch: BillingApi.method(:get)) do
#       expose "Invoice", scopes: [:overdue], writable: [:status]
#       expose "Payment"
#     end
#
#   ANOTHER LIGHTYEAR REALM is not a host — it's a sovereign. Correspond with it
#   (MTP, or its MCP membrane) and let its gate mediate its domain.
