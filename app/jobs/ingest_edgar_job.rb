# frozen_string_literal: true

require "as_of/edgar_header"
require "as_of/blob_store"

# Fetch-or-fixture → blob + Source, then header extract. Never calls a model.
class IngestEdgarJob < ApplicationJob
  queue_as :ingest

  def perform(path:, store_root: nil)
    bytes = File.binread(path)
    headers = AsOf::EdgarHeader.parse(bytes)
    store = store_root ? AsOf::BlobStore.new(root: store_root) : AsOf::BlobStore.new
    source = Source.ingest(
      kind: "edgar",
      native_id: headers.accession,
      url: "fixture://#{File.basename(path)}",
      bytes: bytes,
      published_at: headers.filed_at,
      license: "us_gov",
      store: store
    )
    Filing.record_headers!(source: source, headers: headers)
  end
end
