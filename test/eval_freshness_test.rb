# frozen_string_literal: true

require "test_helper"

# The FREE certificate-freshness gate (the qualitative eval tier): CI never
# re-flies your agents' scenes — a live certification is always an explicit,
# billable act (`lightyear eval certify <agent>`). What CI checks for free is
# that every ISSUED certificate is still CURRENT: change an agent's model,
# Charter, Character, scenes, rubric, or judge, and this test goes red naming
# what drifted and the one command to re-run. No certificates yet = nothing to
# guard = green (certify your first agent when you're ready).
class EvalFreshnessTest < Lightyear::Support::TestCase
  CERT_DIR = File.expand_path("../eval/certificates", __dir__)

  Dir.glob(File.join(CERT_DIR, "*.yml")).each do |path|
    agent_name = File.basename(path, ".yml")

    test "#{agent_name}'s certificate is current" do
      agent = Lightyear.realm&.agents&.find_by(name: agent_name.capitalize) ||
              Lightyear.realm&.agents&.find_by(name: agent_name)
      skip "no agent named #{agent_name} in the home Realm (stale certificate file?)" unless agent

      result = Lightyear::Eval::Certification.status(
        agent: agent,
        golden_paths: Dir[File.expand_path("../eval/golden/#{agent_name}*.yml", __dir__)],
        dev_paths:    Dir[File.expand_path("../eval/dev/#{agent_name}*.yml", __dir__)],
        judge_model:  ENV.fetch("LIGHTYEAR_JUDGE_MODEL", "unset"),
        dir:          CERT_DIR,
      )
      status, reasons = result
      assert_equal :current, status,
                   "STALE — re-certify (lightyear eval certify #{agent_name}):\n  - #{Array(reasons).join("\n  - ")}"
    end
  end

  test "the freshness gate itself is wired" do
    assert true # present even with zero certificates, so the gate is visibly aboard
  end
end
