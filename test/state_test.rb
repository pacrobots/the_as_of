# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "rack/mock"

class StateTest < Lightyear::Support::TestCase
  FIXTURE = File.expand_path("fixtures/fred/unrate.json", __dir__)
  REVISED = File.expand_path("fixtures/fred/unrate_revised.json", __dir__)

  setup { @dir = Dir.mktmpdir("tao-fred-blobs") }
  teardown { FileUtils.remove_entry(@dir) }

  test "FRED fixture ingest is deterministic and /v1/state has fred.unrate vintage official" do
    assert_no_llm_calls {
      IngestFredJob.perform_now(path: FIXTURE, name: "fred.unrate", store_root: @dir)
    }
    status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/state"))
    assert_equal 200, status
    payload = JSON.parse(body.join)
    unrate = payload["series"].find { |s| s["name"] == "fred.unrate" }
    assert unrate, payload["series"].inspect
    assert_equal "official", unrate["vintage"]
    assert_equal 3.9, unrate["value"]
    assert unrate["source_id"].start_with?("sha256:")
  end

  test "mutate series yields replace on /v1/diff?since=" do
    assert_no_llm_calls {
      IngestFredJob.perform_now(path: FIXTURE, name: "fred.unrate", store_root: @dir)
      IngestFredJob.perform_now(path: REVISED, name: "fred.unrate", store_root: @dir)
    }
    status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/diff?since=2024-02-15T00:00:00Z"))
    assert_equal 200, status
    items = JSON.parse(body.join)["items"]
    replace = items.find { |i| i["path"] == "/series/fred.unrate/value" }
    assert replace, items.inspect
    assert_equal "replace", replace["op"]
    assert_equal 3.9, replace["before"]["value"]
    assert_equal 4.1, replace["after"]["value"]
  end

  test "GET /v1/state?at= returns the observation known then; too early is low_data" do
    IngestFredJob.perform_now(path: FIXTURE, name: "fred.unrate", store_root: @dir)
    status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/state?at=2024-01-15T00:00:00Z"))
    assert_equal 200, status
    unrate = JSON.parse(body.join)["series"].find { |s| s["name"] == "fred.unrate" }
    assert_equal 3.7, unrate["value"]

    status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/state?at=2020-01-01T00:00:00Z"))
    assert_equal 503, status
    assert_equal "low_data", JSON.parse(body.join).dig("error", "code")
  end

  test "GET /v1/diff without since is 422" do
    status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/diff"))
    assert_equal 422, status
    assert_equal "bad_request", JSON.parse(body.join).dig("error", "code")
  end
end
