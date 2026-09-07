# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "rack/mock"
require "as_of/blob_store"
require "as_of/edgar_header"

class FilingTest < Lightyear::Support::TestCase
  FIXTURE = File.expand_path("fixtures/edgar/0001045810-24-000123.txt", __dir__)

  setup do
    @dir = Dir.mktmpdir("tao-edgar-blobs")
  end

  teardown { FileUtils.remove_entry(@dir) }

  test "header parse reads accession, form, cik, company, filed_at" do
    h = AsOf::EdgarHeader.parse(File.binread(FIXTURE))
    assert_equal "0001045810-24-000123", h.accession
    assert_equal "8-K", h.form
    assert_equal "0001045810", h.cik
    assert_equal "NVIDIA CORP", h.company_name
    assert_equal Time.utc(2024, 11, 1), h.filed_at
  end

  test "ingest fixture 8-K is deterministic and GET /v1/filing/{acc} has a live source" do
    filing = assert_no_llm_calls {
      IngestEdgarJob.perform_now(path: FIXTURE, store_root: @dir)
    }
    assert_equal "0001045810-24-000123", filing.accession
    assert_equal "8-K", filing.form
    assert filing.source, "evidence source exists"
    assert_match(/\Asha256:[0-9a-f]{64}\z/, filing.source.content_hash)

    status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/filing/#{filing.accession}"))
    assert_equal 200, status
    payload = JSON.parse(body.join)
    assert_equal "0001045810-24-000123", payload["accession"]
    assert_equal "8-K", payload["form"]
    assert_equal "0001045810", payload["cik"]
    assert_equal [], payload["facts"]
    assert_equal [], payload["claims"]
  end

  test "same fixture re-ingest keeps one filing and one source hash" do
    assert_no_llm_calls {
      IngestEdgarJob.perform_now(path: FIXTURE, store_root: @dir)
      IngestEdgarJob.perform_now(path: FIXTURE, store_root: @dir)
    }
    assert_equal 1, Filing.where(accession: "0001045810-24-000123").count
    assert_equal 1, Source.where(native_id: "0001045810-24-000123").count
  end
end
