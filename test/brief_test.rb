# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "rack/mock"

class BriefTest < Lightyear::Support::TestCase
  FIXTURE = File.expand_path("fixtures/edgar/0001045810-24-000123.txt", __dir__)

  setup { @dir = Dir.mktmpdir("tao-brief-blobs") }
  teardown { FileUtils.remove_entry(@dir) }

  def ingest!
    IngestEdgarJob.perform_now(path: FIXTURE, store_root: @dir)
  end

  test "POST /v1/brief/query on Item 2.02 keeps numbers in source bytes" do
    bytes = File.binread(FIXTURE)
    assert_no_llm_calls {
      ingest!
      status, _h, body = Lightyear::Server.app.call(
        Rack::MockRequest.env_for("https://as-of.test/v1/brief/query", method: "POST",
                                  input: JSON.generate("question" => "Item 2.02 revenue")))
      assert_equal 200, status
      payload = JSON.parse(body.join)
      refute_empty payload["numbers"]
      payload["numbers"].each do |n|
        assert_includes bytes, n["value"].to_s
      end
      refute_empty payload["sources"]
      refute AsOf::Judge.advice?(payload["headline"])
    }
  end

  test "GET /v1/brief/{id} returns the same object" do
    ingest!
    brief = Brief.compose!(question: "Item 2.02")
    status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/brief/#{brief.id}"))
    assert_equal 200, status
    assert_equal brief.id.to_s, JSON.parse(body.join)["id"]
  end

  test "correction supersedes without rewriting the original" do
    ingest!
    a = Brief.compose!(question: "Item 2.02")
    b = a.correct!(headline: "#{a.headline} (corrected)")
    assert_includes b.supersedes, a.id.to_s
    a.reload
    assert_equal "ok", a.status
    refute_includes a.headline, "(corrected)"
    _status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/brief/#{a.id}"))
    assert_equal a.headline, JSON.parse(body.join)["headline"]
  end

  test "invented numbers are dropped by the Judge" do
    assert_equal [], AsOf::Judge.grounded_facts(
      [{ "name" => "revenue", "value" => "999999999" }],
      "Revenue was 35000000000"
    )
    refute_empty AsOf::Judge.grounded_facts(
      [{ "name" => "revenue", "value" => "35000000000" }],
      "Revenue was 35000000000"
    )
  end
end
