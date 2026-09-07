# frozen_string_literal: true

require "test_helper"

# GENERATED from blueprint.yml — the plan's promises, asserted. Extend freely;
# regenerate never (preserve: true — this file is yours after first write).
class GovernanceTest < Lightyear::Support::TestCase
  # Provisioned ONCE at class load — OUTSIDE test transactions (they roll back;
  # a per-test seed would vanish with the first test's rollback).
  load File.expand_path("../db/seeds.rb", __dir__)

  test "Clerk: commissioned, hands on, no may-but-cannot gap" do
    agent = Lightyear.realm.agents.find_by!(name: "Clerk")
    tools = agent.all_tools.filter_map { |t| t.verb if t.respond_to?(:verb) }
    writs = Lightyear::Trust::Writ.held_by(agent.did).reject(&:revoked?)
    abilities = writs.flat_map { |w| Hash(w.payload_json&.dig("scope")).values.flatten }.uniq
    gap = abilities.reject { |x| x == "*" || x.start_with?("treasury/", "commerce/") || tools.include?(x) }
    assert_empty gap, "authority without capability: #{gap.join(', ')}"
  end

  test "a stranger's reach is refused before any side effect" do
    agent = Lightyear.realm.agents.first
    action = Lightyear::Agents::Reach::Action.new(verb: "vault/raid", target: "*", params: {}, envoy: nil)
    assert_raises(Lightyear::Agents::Reach::Unauthorized) { Lightyear::Agents::Reach.gate(agent, action, nil) }
  end
end
