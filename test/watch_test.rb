# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "rack/mock"

class WatchTest < Lightyear::Support::TestCase
  FIXTURE = File.expand_path("fixtures/edgar/0001045810-24-000123.txt", __dir__)
  CIK = "0001045810"

  setup { @dir = Dir.mktmpdir("tao-watch-blobs") }
  teardown { FileUtils.remove_entry(@dir) }

  def call(path, method: "GET", body: nil)
    opts = { method: method }
    opts[:input] = JSON.generate(body) if body
    env = Rack::MockRequest.env_for("https://as-of.test#{path}", opts)
    env["CONTENT_TYPE"] = "application/json" if body
    Lightyear::Server.app.call(env)
  end

  test "POST /v1/watches then GET list and DELETE" do
    status, _h, body = call("/v1/watches", method: "POST",
                            body: { "entities" => [{ "type" => "cik", "id" => CIK, "name" => "NVIDIA CORP" }] })
    assert_equal 200, status
    watch = JSON.parse(body.join)
    assert watch["id"]
    assert_equal CIK, watch["entities"][0]["id"]

    status, _h, body = call("/v1/watches")
    assert_equal 200, status
    ids = JSON.parse(body.join)["watches"].map { |w| w["id"] }
    assert_includes ids, watch["id"]

    status, = call("/v1/watches/#{watch['id']}", method: "DELETE")
    assert_equal 200, status
    status, _h, body = call("/v1/watches")
    refute_includes JSON.parse(body.join)["watches"].map { |w| w["id"] }, watch["id"]
  end

  test "watch on fixture CIK filters /v1/diff" do
    assert_no_llm_calls {
      IngestEdgarJob.perform_now(path: FIXTURE, store_root: @dir)
    }
    status, _h, body = call("/v1/watches", method: "POST",
                            body: { "entities" => [{ "type" => "cik", "id" => CIK }] })
    watch_id = JSON.parse(body.join)["id"]

    status, _h, body = call("/v1/diff?since=2020-01-01T00:00:00Z&watch_id=#{watch_id}")
    assert_equal 200, status
    items = JSON.parse(body.join)["items"]
    assert items.any? { |i| i["path"].include?("0001045810-24-000123") }, items.inspect
    assert items.all? { |i| i.dig("entity", "type") == "cik" && i.dig("entity", "id") == CIK }
  end

  test "POST /v1/watches without entities is 422" do
    status, _h, body = call("/v1/watches", method: "POST", body: { "entities" => [] })
    assert_equal 422, status
    assert_equal "bad_request", JSON.parse(body.join).dig("error", "code")
  end
end
