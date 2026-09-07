# frozen_string_literal: true

require "json"
require "rack"
require "time"
require_relative "../as_of"
require_relative "state"

module AsOf
  # Thin JSON catalog (PRD §5.1). Prefix-mounted on Server.app at `/v1`.
  # Reads project domain JSON. Writes that mutate go through Reach (S6/S7).
  class V1
    OPENAPI_PATH = File.expand_path("../../schemas/openapi.json", __dir__)

    def self.call(env) = new.call(env)

    def call(env)
      req = Rack::Request.new(env)
      case [req.request_method, req.path]
      when ["GET", "/v1/health"]
        json(200, { "ok" => true, "as_of" => now, "as_of_data" => nil, "dev_free" => AsOf.dev_free? })
      when ["GET", "/v1/openapi.json"]
        json(200, JSON.parse(File.read(OPENAPI_PATH)))
      when ["GET", "/v1/state"]
        return state(req)
      when ["GET", "/v1/diff"]
        return diff(req)
      else
        if req.get? && (m = req.path.match(%r{\A/v1/source/(.+)\z}))
          source = Source.find_by(content_hash: m[1])
          return json(404, { "error" => { "code" => "not_found", "message" => "not found" } }) unless source

          return json(200, source.as_meta.merge("as_of" => now, "as_of_data" => iso(source.published_at || source.retrieved_at)))
        end
        if req.get? && (m = req.path.match(%r{\A/v1/filing/(.+)\z}))
          filing = Filing.find_by(accession: m[1])
          return json(404, { "error" => { "code" => "not_found", "message" => "not found" } }) unless filing

          data_at = filing.source.published_at || filing.filed_at
          return json(200, filing.as_extract.merge("as_of" => now, "as_of_data" => iso(data_at)))
        end
        json(404, { "error" => { "code" => "not_found", "message" => "not found" } })
      end
    end

    private

    def state(req)
      payload = AsOf::State.snapshot(at: parse_time(req.params["at"]), since: parse_time(req.params["since"]))
      json(200, payload)
    rescue AsOf::State::LowData
      json(503, { "error" => { "code" => "low_data", "message" => "no series history at that time" } })
    end

    def diff(req)
      since = parse_time(req.params["since"])
      return json(422, { "error" => { "code" => "bad_request", "message" => "since is required" } }) unless since

      json(200, AsOf::State.diff(since: since, at: parse_time(req.params["at"])))
    rescue AsOf::State::LowData
      json(503, { "error" => { "code" => "low_data", "message" => "no series history at that time" } })
    end

    def parse_time(value)
      return nil if value.to_s.empty?

      Time.iso8601(value)
    rescue ArgumentError
      Time.parse(value)
    end

    def now = iso(Time.now)
    def iso(time) = time.utc.strftime("%Y-%m-%dT%H:%M:%SZ")

    def json(status, data)
      [status, { "content-type" => "application/json" }, [JSON.generate(data)]]
    end
  end
end
