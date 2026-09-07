# frozen_string_literal: true

require "test_helper"
require "fileutils"

class FetchLogTest < Lightyear::Support::TestCase
  FIXTURE = File.expand_path("fixtures/edgar/0001045810-24-000123.txt", __dir__)

  setup { @dir = Dir.mktmpdir("tao-fetch-blobs") }
  teardown { FileUtils.remove_entry(@dir) }

  test "edgar ingest writes a fetch log without secrets" do
    assert_no_llm_calls {
      IngestEdgarJob.perform_now(path: FIXTURE, store_root: @dir)
    }
    row = FetchLog.last_ok("edgar")
    assert row
    assert_equal "new", row.outcome
    assert_equal 200, row.http_status
    assert row.content_hash.start_with?("sha256:")
    refute_includes row.as_public.to_s, "api_key"
    IngestEdgarJob.perform_now(path: FIXTURE, store_root: @dir)
    assert_equal "kept", FetchLog.order(:id).last.outcome
  end

  test "fred fixture ingest logs kept vs new" do
    path = File.expand_path("fixtures/fred/unrate.json", __dir__)
    IngestFredJob.perform_now(path: path, name: "fred.unrate", store_root: @dir)
    assert_equal "new", FetchLog.last_ok("fred").outcome
    IngestFredJob.perform_now(path: path, name: "fred.unrate", store_root: @dir)
    assert_equal "kept", FetchLog.order(:id).last.outcome
  end
end
