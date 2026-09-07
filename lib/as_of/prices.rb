# frozen_string_literal: true

require "yaml"
require "bigdecimal"

module AsOf
  module Prices
    PATH = File.expand_path("../../config/prices.yaml", __dir__)

    module_function

    def catalog
      @catalog ||= YAML.safe_load_file(PATH)
    end

    def as_json
      {
        "currency" => catalog.fetch("currency"),
        "routes" => catalog.fetch("routes").map { |r| r.transform_keys(&:to_s) },
        "skus" => catalog.fetch("skus").map { |s| s.transform_keys(&:to_s) }
      }
    end

    def cents_for(path, method: "GET")
      usd = usd_for(path, method: method)
      return 0 if usd.nil?

      (BigDecimal(usd.to_s) * 100).round.to_i
    end

    def usd_for(path, method: "GET")
      row = catalog.fetch("routes").find { |r| match_path?(r["path"] || r[:path], path, method) }
      return nil unless row

      row["usd"] || row[:usd]
    end

    def sku(id)
      catalog.fetch("skus").find { |s| (s["id"] || s[:id]) == id }
    end

    def included_cents(id)
      spec = sku(id) or raise ArgumentError, "unknown sku #{id}"
      (BigDecimal((spec["included_usd"] || spec[:included_usd]).to_s) * 100).round.to_i
    end

    def match_path?(pattern, path, method)
      pattern = pattern.to_s
      return false if pattern == "/v1/brief/query" && method != "POST"
      return path == pattern unless pattern.include?("{")

      path.match?(/\A#{pattern.gsub(/\{[^}]+\}/, "[^/]+")}\z/)
    end
  end
end
