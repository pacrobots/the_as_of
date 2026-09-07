# frozen_string_literal: true

require "test_helper"
require "rack/mock"
require "lightyear/server"

class V1Test < Lightyear::Support::TestCase
  test "GET /v1/health is free and reports DEV_FREE" do
    status, headers, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/health"))
    assert_equal 200, status
    assert_equal "application/json", headers["content-type"]
    payload = JSON.parse(body.join)
    assert_equal true, payload["ok"]
    assert payload["as_of"]
    assert_equal true, payload["dev_free"]
    assert_equal false, payload.dig("ingest", "ok")
    assert_equal "fred_only", payload.dig("ingest", "scope")
  end

  test "GET /v1/ingest is 503 until a fresh FRED fetch exists" do
    status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/ingest"))
    assert_equal 503, status
    payload = JSON.parse(body.join)
    assert_equal false, payload["ok"]
    assert payload["series"].any?
    assert payload["series"].all? { |row| row["stale"] }
  end

  test "GET /v1/openapi.json lists MVP routes including explain and watches" do
    status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/openapi.json"))
    assert_equal 200, status
    spec = JSON.parse(body.join)
    assert_equal "As-Of", spec.dig("info", "title")
    paths = spec["paths"].keys
    assert_includes paths, "/v1/explain/{target_type}/{target_id}"
    assert_includes paths, "/v1/watches"
    assert_includes paths, "/v1/ingest"
  end

  test "unknown /v1 path is 404 with the product error shape" do
    status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/nope"))
    assert_equal 404, status
    assert_equal "not_found", JSON.parse(body.join).dig("error", "code")
  end

  test "framework doors still answer beside /v1" do
    status, = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/.well-known/agent-card.json"))
    assert_equal 200, status
  end
end
