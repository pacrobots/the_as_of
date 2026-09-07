# frozen_string_literal: true

require "as_of/edgar_header"
require "as_of/blob_store"
require "as_of/filing_extract"

# Fetch-or-fixture → blob + Source, then header extract. Never calls a model.
class IngestEdgarJob < ApplicationJob
  queue_as :ingest

  def perform(path:, store_root: nil)
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    bytes = File.binread(path)
    headers = AsOf::EdgarHeader.parse(bytes)
    store = store_root ? AsOf::BlobStore.new(root: store_root) : AsOf::BlobStore.new
    digest = AsOf::BlobStore.hash_of(bytes)
    existed = Source.exists?(content_hash: digest)
    source = Source.ingest(
      kind: "edgar",
      native_id: headers.accession,
      url: "fixture://#{File.basename(path)}",
      bytes: bytes,
      published_at: headers.filed_at,
      license: "us_gov",
      store: store
    )
    filing = Filing.record_headers!(source: source, headers: headers)
    AsOf::FilingExtract.run!(filing, bytes: bytes)
    FetchLog.record!(
      source_kind: "edgar", native_id: headers.accession,
      url: "fixture://#{File.basename(path)}", http_status: 200,
      bytes: bytes.bytesize, content_hash: source.content_hash,
      outcome: existed ? "kept" : "new",
      duration_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000).round
    )
    filing
  rescue StandardError => e
    FetchLog.record!(source_kind: "edgar", url: path.to_s, outcome: "failed",
                     error_class: e.class.name, error_message: e.message.to_s[0, 500])
    raise
  end
end
