# frozen_string_literal: true

require "json"
require "date"
require "as_of/blob_store"
require "as_of/catalog"
require "as_of/fred_client"

# Fixture or live FRED observations → Source receipt + SeriesSnapshot rows. No LLM.
# Live path stores a receipt (id, time, body hash), not a FRED JSON dump.
class IngestFredJob < ApplicationJob
  queue_as :ingest

  def perform(path: nil, name:, store_root: nil)
    spec = AsOf::Catalog.series_named(name)
    raise ArgumentError, "unknown series #{name}" unless spec

    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    raw, url, status = load_bytes(path, spec)
    duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000).round
    unless (200..299).cover?(status)
      FetchLog.record!(source_kind: "fred", native_id: spec["native_id"], url: url,
                       http_status: status, bytes: raw.bytesize, outcome: "failed",
                       error_message: "HTTP #{status}", duration_ms: duration)
      raise "FRED HTTP #{status}"
    end

    payload = JSON.parse(raw)
    store_bytes = path ? raw : receipt(spec, raw, payload)
    store = store_root ? AsOf::BlobStore.new(root: store_root) : AsOf::BlobStore.new
    digest = AsOf::BlobStore.hash_of(store_bytes)
    existed = Source.exists?(content_hash: digest)
    source = Source.ingest(
      kind: "fred",
      native_id: spec["native_id"],
      url: url,
      bytes: store_bytes,
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
    FetchLog.record!(source_kind: "fred", native_id: spec["native_id"], url: url,
                     http_status: status, bytes: raw.bytesize, content_hash: digest,
                     outcome: existed ? "kept" : "new", duration_ms: duration)
    source
  rescue StandardError => e
    unless e.message.start_with?("FRED HTTP")
      FetchLog.record!(source_kind: "fred", native_id: spec && spec["native_id"], url: url || "fred://#{name}",
                       outcome: "failed", error_class: e.class.name, error_message: e.message.to_s[0, 500])
    end
    raise
  end

  private

  def load_bytes(path, spec)
    if path
      [File.binread(path), "fixture://#{File.basename(path)}", 200]
    else
      res = AsOf::FredClient.observations(spec["native_id"])
      [res[:bytes], res[:url], res[:status]]
    end
  end

  def receipt(spec, raw, payload)
    JSON.generate(
      "native_id" => spec["native_id"],
      "retrieved_at" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
      "observation_count" => Array(payload["observations"]).size,
      "body_sha256" => AsOf::BlobStore.hash_of(raw),
      "citation" => spec["citation"]
    )
  end
end
