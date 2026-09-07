# frozen_string_literal: true

require "test_helper"
require "rack/mock"
require "as_of/markdown"
require "as_of/state"
require "open3"

class SurfaceTest < Lightyear::Support::TestCase
  def rpc(method, params = nil)
    body = { "jsonrpc" => "2.0", "id" => 1, "method" => method }
    body["params"] = params if params
    env = Rack::MockRequest.env_for("https://as-of.test/mcp", method: "POST", input: JSON.generate(body))
    env["CONTENT_TYPE"] = "application/json"
    Lightyear::Server.app.call(env)
  end

  test "GET /v1/catalog is free and names series without values" do
    status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/catalog"))
    assert_equal 200, status
    payload = JSON.parse(body.join)
    assert_includes payload["series_names"], "fred.unrate"
    refute payload["series_names"].any? { |n| n.to_s.match?(/\d\.\d/) }
  end

  test "GET /v1/state.md is a markdown render of the same JSON" do
    IngestFredJob.perform_now(
      path: File.expand_path("fixtures/fred/unrate.json", __dir__),
      name: "fred.unrate",
      store_root: Dir.mktmpdir
    )
    json_status, _, json_body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/state"))
    md_status, headers, md_body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/state.md"))
    assert_equal 200, json_status
    assert_equal 200, md_status
    assert_match %r{text/markdown}, headers["content-type"]
    payload = JSON.parse(json_body.join)
    md = md_body.join
    payload["series"].each do |f|
      assert_includes md, f["name"]
      assert_includes md, f["value"].to_s
      assert_includes md, f["source_id"]
    end
    refute_includes md, "overweight"
  end

  test "MCP tools/list includes the tao reads" do
    status, _h, body = rpc("tools/list")
    assert_equal 200, status
    names = JSON.parse(body.join).dig("result", "tools").map { |t| t["name"] }
    %w[tao/state tao/diff tao/filing tao/rule tao/source tao/explain tao/brief_query tao/watches_list].each do |n|
      assert_includes names, n
    end
  end

  test "MCP tao/state returns the same snapshot shape as /v1/state" do
    status, _h, body = rpc("tools/call", "name" => "tao/state", "arguments" => {})
    assert_equal 200, status
    inner = JSON.parse(JSON.parse(body.join).dig("result", "content", 0, "text"))
    assert inner.key?("series")
    assert inner.key?("as_of")
  end

  test "bin/asof ingest-live is guarded" do
    exe = File.expand_path("../bin/asof", __dir__)
    stdout, stderr, status = Open3.capture3({ "INGEST_LIVE" => "0" }, "ruby", exe, "ingest-live")
    refute status.success?
    assert_match(/INGEST_LIVE=1/, stdout + stderr)
  end
end
