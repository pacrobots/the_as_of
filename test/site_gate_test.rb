# frozen_string_literal: true

require "test_helper"
require "rack/mock"
require "as_of/site_gate"

class SiteGateTest < Lightyear::Support::TestCase
  setup { ENV["SITE_PASSWORD"] = "test-gate" }
  teardown { ENV.delete("SITE_PASSWORD") }

  def call(path, user: nil, pass: nil)
    env = Rack::MockRequest.env_for("https://as-of.test#{path}")
    if user
      env["HTTP_AUTHORIZATION"] = "Basic " + ["#{user}:#{pass}"].pack("m0")
    end
    Lightyear::Server.app.call(env)
  end

  test "SITE_PASSWORD rejects anonymous /v1/prices" do
    status, headers, = call("/v1/prices")
    assert_equal 401, status
    assert_match(/Basic/, headers["www-authenticate"].to_s)
  end

  test "SITE_PASSWORD accepts basic auth from any IP" do
    status, = call("/v1/prices", user: "tao", pass: "test-gate")
    assert_equal 200, status
  end

  test "health stays open for Kamal" do
    status, = call("/v1/health")
    assert_equal 200, status
  end
end
