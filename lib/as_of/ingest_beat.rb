# frozen_string_literal: true

require "yaml"
require "thread"
require_relative "catalog"
require_relative "secrets"

module AsOf
  # Operator beat on the jobs clock. Enqueues IngestFredJob for catalog series.
  # Not a Lightyear agent Cadence — those tick LLM turns; ingest must never.
  module IngestBeat
    CADENCE_PATH = File.expand_path("../../config/cadence.yml", __dir__)
    MUTEX = Mutex.new
    @queued_at = {}

    module_function

    def tick!(now: Time.now.utc)
      return 0 unless enabled?

      n = 0
      Catalog.series.select { |s| s["source"] == "fred" }.each do |spec|
        next unless due?(spec, now)

        mark_queued(spec["name"], now)
        IngestFredJob.perform_later(name: spec["name"])
        n += 1
      end
      n
    rescue StandardError => e
      Lightyear.logger&.error("[as_of] ingest beat: #{e.class}: #{e.message}")
      0
    end

    def enabled?
      return false unless beat["live"]
      return false unless Secrets.fred_api_key?
      return true if ENV["INGEST_LIVE"] == "1"

      defined?(Lightyear) && Lightyear.env == "production"
    end

    def due?(spec, now)
      name = spec["name"]
      return false if recently_queued?(name, now)

      last = FetchLog.last_for(kind: "fred", native_id: spec["native_id"])
      return true if last.nil?
      return false if last.created_at > now - retry_after
      return true if last.outcome == "failed"

      last.created_at <= now - interval
    end

    def beat
      YAML.safe_load_file(CADENCE_PATH).fetch("beats").fetch("fred")
    end

    def interval = parse_duration(beat["every"] || "6h")
    def retry_after = parse_duration(beat["retry_after"] || "15m")

    def parse_duration(value)
      case value
      when Integer then value
      when Numeric then value.to_i
      when String
        m = value.strip.match(/\A(\d+)\s*(s|m|h|d)\z/i)
        raise ArgumentError, "bad duration #{value.inspect}" unless m

        n = m[1].to_i
        case m[2].downcase
        when "s" then n
        when "m" then n * 60
        when "h" then n * 3600
        when "d" then n * 86_400
        end
      else
        raise ArgumentError, "bad duration #{value.inspect}"
      end
    end

    def recently_queued?(name, now)
      MUTEX.synchronize do
        t = @queued_at[name]
        t && (now - t) < retry_after
      end
    end

    def mark_queued(name, now)
      MUTEX.synchronize { @queued_at[name] = now }
    end

    def reset_queue!
      MUTEX.synchronize { @queued_at = {} }
    end
  end
end
