# frozen_string_literal: true

require "json"
require "date"
require "as_of/blob_store"
require "as_of/catalog"

# Fixture or live FRED observations JSON → Source + SeriesSnapshot rows. No LLM.
class IngestFredJob < ApplicationJob
  queue_as :ingest

  def perform(path:, name:, store_root: nil)
    spec = AsOf::Catalog.series_named(name)
    raise ArgumentError, "unknown series #{name}" unless spec

    bytes = File.binread(path)
    payload = JSON.parse(bytes)
    store = store_root ? AsOf::BlobStore.new(root: store_root) : AsOf::BlobStore.new
    source = Source.ingest(
      kind: "fred",
      native_id: spec["native_id"],
      url: "fixture://#{File.basename(path)}",
      bytes: bytes,
      license: "us_gov",
      store: store
    )
    Array(payload["observations"]).each do |obs|
      next if obs["value"].to_s.empty? || obs["value"] == "."

      date = Date.iso8601(obs["date"])
      SeriesSnapshot.record!(
        name: spec["name"],
        value: obs["value"],
        unit: spec["unit"],
        vintage: spec["vintage"],
        observed_at: Time.utc(date.year, date.month, date.day),
        source: source
      )
    end
    source
  end
end
