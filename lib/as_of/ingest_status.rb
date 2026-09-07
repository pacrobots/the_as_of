# frozen_string_literal: true

require "yaml"
require_relative "catalog"
require_relative "notices"
require_relative "ingest_beat"

module AsOf
  # Operator probe for the FRED-only public-gate week. Kamal keeps using
  # /v1/health (always 200 if the process is up). /v1/ingest is 503 when stale.
  module IngestStatus
    CADENCE_PATH = File.expand_path("../../config/cadence.yml", __dir__)
    GATE_SECONDS = 7 * 24 * 3600

    module_function

    def payload(now: Time.now.utc)
      beat = fred_beat
      stale_after = parse_duration(beat["stale_after"] || beat["every"] || "8h")
      rows = series_rows(stale_after: stale_after, now: now)
      started_at = rows.map { |r| r["last_ok_at"] }.compact.min
      {
        "ok" => rows.any? && rows.all? { |r| r["ok"] },
        "scope" => "fred_only",
        "every" => beat["every"],
        "stale_after_seconds" => stale_after,
        "as_of_data" => as_of_data,
        "gate_started_at" => started_at,
        "gate_due_at" => started_at && iso(Time.iso8601(started_at) + GATE_SECONDS),
        "series" => rows,
        "fred_disclaimer" => Notices::FRED_DISCLAIMER
      }
    end

    def series_rows(stale_after:, now:)
      Catalog.series.select { |s| s["source"] == "fred" }.map do |spec|
        last_ok = FetchLog.last_ok("fred", native_id: spec["native_id"])
        last = FetchLog.last_for(kind: "fred", native_id: spec["native_id"])
        last_ok_at = last_ok && iso(last_ok.created_at)
        stale = last_ok.nil? || last_ok.created_at < (now - stale_after)
        {
          "name" => spec["name"],
          "native_id" => spec["native_id"],
          "last_ok_at" => last_ok_at,
          "last_outcome" => last&.outcome,
          "last_error" => last&.outcome == "failed" ? last.error_message : nil,
          "content_hash" => last_ok&.content_hash,
          "stale" => stale,
          "ok" => !stale
        }
      end
    end

    def as_of_data
      t = SeriesSnapshot.maximum(:observed_at)
      t && iso(t)
    rescue StandardError
      nil
    end

    def fred_beat
      YAML.safe_load_file(CADENCE_PATH).fetch("beats").fetch("fred")
    end

    def parse_duration(value)
      IngestBeat.parse_duration(value)
    end

    def iso(time) = time.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
  end
end
