# frozen_string_literal: true

require "test_helper"
require "rack/mock"
require "yaml"
require "as_of/rate_limit"

class HardenTest < Lightyear::Support::TestCase
  setup { AsOf::RateLimit.reset! }
  teardown do
    ENV.delete("RATE_LIMIT")
    ENV.delete("RATE_LIMIT_PER_MIN")
    AsOf::RateLimit.reset!
  end

  test "cadence.yml names edgar, fred, and federal_register without LLM on unchanged hashes" do
    beats = YAML.safe_load_file("config/cadence.yml").fetch("beats")
    %w[edgar fred federal_register].each { |k| assert beats[k], k }
    assert_match(/new source hash/, beats["edgar"]["note"])
    assert File.exist?("config/watchlists.yaml")
    assert File.exist?("config/agencies.yaml")
  end

  test "sec_user_agent uses CONTACT_EMAIL" do
    old_c, old_u = ENV["CONTACT_EMAIL"], ENV["SEC_USER_AGENT"]
    ENV["SEC_USER_AGENT"] = ""
    ENV["CONTACT_EMAIL"] = "ops@theasof.com"
    assert_equal "AsOf/0.1 (+ops@theasof.com)", AsOf.sec_user_agent
  ensure
    ENV["CONTACT_EMAIL"] = old_c
    ENV["SEC_USER_AGENT"] = old_u
  end

  test "rate limit returns 429 rate_limited on /v1" do
    ENV["RATE_LIMIT"] = "1"
    ENV["RATE_LIMIT_PER_MIN"] = "2"
    2.times do
      status, = Lightyear::Server.app.call(Rack::MockRequest.env_for("https://as-of.test/v1/prices"))
      assert_equal 200, status
    end
    status, _h, body = Lightyear::Server.app.call(Rack::MockRequest.env_for("https://as-of.test/v1/prices"))
    assert_equal 429, status
    assert_equal "rate_limited", JSON.parse(body.join).dig("error", "code")
  end

  test "rate limit does not close the DID door" do
    ENV["RATE_LIMIT"] = "1"
    ENV["RATE_LIMIT_PER_MIN"] = "1"
    status, = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/.well-known/agent-card.json"))
    assert_equal 200, status
  end

  test "lightyear ledger verify is ok on the test realm" do
    report = Lightyear.realm.verify_chain
    assert report.ok?, report.message
  end

  test "deploy.yml carries CONTACT_EMAIL and theasof.com" do
    deploy = YAML.safe_load_file("config/deploy.yml")
    assert_equal "theasof.com", deploy.dig("proxy", "host")
    assert deploy.dig("env", "clear", "CONTACT_EMAIL").to_s.include?("@")
  end
end
