# frozen_string_literal: true

require "json"
require "net/http"
require "uri"
require "as_of/secrets"

module AsOf
  # Live FRED observations. Never logs the API key. URL in FetchLog is redacted.
  module FredClient
    HOST = "https://api.stlouisfed.org"

    module_function

    def observations(series_id)
      key = Secrets.fred_api_key
      raise "FRED API key missing (credentials store or FRED_API_KEY)" if key.to_s.empty?

      uri = URI("#{HOST}/fred/series/observations")
      uri.query = URI.encode_www_form("series_id" => series_id, "file_type" => "json", "api_key" => key)
      get(uri, series_id)
    end

    def get(uri, series_id)
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 15
      http.read_timeout = 30
      req = Net::HTTP::Get.new(uri)
      req["User-Agent"] = AsOf.sec_user_agent
      res = http.request(req)
      body = res.body.to_s
      elapsed = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000).round
      {
        status: res.code.to_i,
        bytes: body.b,
        url: redact(uri),
        native_id: series_id,
        duration_ms: elapsed
      }
    end

    def redact(uri)
      q = URI.decode_www_form(uri.query.to_s).reject { |k, _| k == "api_key" }
      u = uri.dup
      u.query = URI.encode_www_form(q)
      u.to_s
    end
  end
end
