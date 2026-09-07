# frozen_string_literal: true

require "test_helper"
require "rack/mock"
require "as_of/notices"
require "as_of/fred_client"

class NoticesTest < Lightyear::Support::TestCase
  test "GET /v1/notices is free and carries the FRED disclaimer" do
    status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/notices"))
    assert_equal 200, status
    payload = JSON.parse(body.join)
    assert_equal AsOf::Notices::FRED_DISCLAIMER, payload.dig("fred", "disclaimer")
    assert payload.dig("fred", "terms")
  end

  test "health, catalog, and openapi show the disclaimer" do
    health = JSON.parse(Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/health"))[2].join)
    assert_equal AsOf::Notices::FRED_DISCLAIMER, health["fred_disclaimer"]

    catalog = JSON.parse(Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/catalog"))[2].join)
    assert_equal AsOf::Notices::FRED_DISCLAIMER, catalog.dig("notices", "fred", "disclaimer")

    spec = JSON.parse(Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/openapi.json"))[2].join)
    assert_includes spec.dig("info", "description"), "not endorsed or certified"
  end

  test "state JSON and markdown include notices" do
    payload = AsOf::State.snapshot
    assert_equal AsOf::Notices::FRED_DISCLAIMER, payload.dig("notices", "fred", "disclaimer")
    md = AsOf::Markdown.state(payload)
    assert_includes md, "not endorsed or certified"
  end

  test "FredClient redacts api_key from logged URLs" do
    uri = URI("https://api.stlouisfed.org/fred/series/observations?series_id=UNRATE&api_key=SECRET&file_type=json")
    out = AsOf::FredClient.redact(uri)
    refute_includes out, "SECRET"
    assert_includes out, "series_id=UNRATE"
  end
end
