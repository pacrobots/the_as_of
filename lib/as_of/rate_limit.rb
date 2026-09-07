# frozen_string_literal: true

require "json"
require "thread"

module AsOf
  # In-process sliding window for /v1 and /mcp. Multi-node: put the same
  # 429 shape on the reverse proxy. Never applied to DID/agent-card doors.
  module RateLimit
    WINDOW = 60.0
    MUTEX = Mutex.new
    BUCKETS = Hash.new { |h, k| h[k] = [] }

    module_function

    def enabled?
      ENV["RATE_LIMIT"] == "1" || (defined?(Lightyear) && Lightyear.env == "production")
    end

    def per_min = ENV.fetch("RATE_LIMIT_PER_MIN", "120").to_i

    def skip?(path)
      path == "/v1/health" || path == "/v1/catalog" || path.start_with?("/.well-known")
    end

    def check!(req)
      return nil unless enabled?
      return nil if skip?(req.path)

      now = Time.now.to_f
      key = "#{req.ip}:#{req.path.split('/').reject(&:empty?).first}"
      MUTEX.synchronize do
        BUCKETS[key].reject! { |t| now - t > WINDOW }
        if BUCKETS[key].size >= per_min
          return [429,
                  { "content-type" => "application/json", "retry-after" => "60" },
                  [JSON.generate("error" => { "code" => "rate_limited", "message" => "slow down" })]]
        end
        BUCKETS[key] << now
      end
      nil
    end

    def reset! = MUTEX.synchronize { BUCKETS.clear }
  end
end
