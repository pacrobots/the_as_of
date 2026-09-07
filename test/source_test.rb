# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "rack/mock"
require "as_of/blob_store"

class SourceTest < Lightyear::Support::TestCase
  setup do
    @dir = Dir.mktmpdir("tao-source-blobs")
    @store = AsOf::BlobStore.new(root: @dir)
  end

  teardown { FileUtils.remove_entry(@dir) }

  test "ingest stores bytes and returns SourceMeta-shaped JSON" do
    src = Source.ingest(
      kind: "edgar", native_id: "0000000000-00-000001", url: "https://example.test/a",
      bytes: "8-K fixture", published_at: Time.utc(2024, 1, 15, 21),
      license: "us_gov", store: @store
    )
    assert_match(/\Asha256:[0-9a-f]{64}\z/, src.content_hash)
    assert_equal "8-K fixture", @store.get(src.content_hash)
    meta = src.as_meta
    assert_equal src.content_hash, meta["id"]
    assert_equal "edgar", meta["kind"]
    assert_equal "us_gov", meta["license"]
    assert meta["bytes"].positive?
  end

  test "same bytes re-ingest yield one row" do
    a = Source.ingest(kind: "edgar", native_id: "acc-1", url: "https://example.test/1",
                      bytes: "same", store: @store)
    b = Source.ingest(kind: "edgar", native_id: "acc-1", url: "https://example.test/1",
                      bytes: "same", store: @store)
    assert_equal a.id, b.id
    assert_equal 1, Source.where(content_hash: a.content_hash).count
  end

  test "hash change for the same native_id is a new row; old row kept" do
    old = Source.ingest(kind: "fred", native_id: "UNRATE", url: "https://example.test/unrate",
                        bytes: "v1", store: @store)
    neu = Source.ingest(kind: "fred", native_id: "UNRATE", url: "https://example.test/unrate",
                        bytes: "v2", store: @store)
    refute_equal old.id, neu.id
    assert Source.exists?(old.id)
    assert Source.exists?(neu.id)
  end

  test "GET /v1/source/{hash} returns meta not bytes" do
    src = Source.ingest(kind: "treasury", native_id: "yield", url: "https://example.test/y",
                        bytes: "csv", store: @store)
    status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/source/#{src.content_hash}"))
    assert_equal 200, status
    payload = JSON.parse(body.join)
    assert_equal src.content_hash, payload["id"]
    refute payload.key?("body")
    assert_equal "csv".bytesize, payload["bytes"]
  end
end
