# frozen_string_literal: true

require_relative "prices"

module AsOf
  # CreditKey prepaid meter. Deducts after 2xx only. Not Budget, not Allowance.
  module Meter
    FREE = [%r{\A/v1/health\z}, %r{\A/v1/openapi\.json\z}, %r{\A/v1/prices\z}].freeze

    module_function

    def free?(path) = FREE.any? { |re| path.match?(re) }

    def x402_enabled? = %w[1 true yes].include?(ENV.fetch("X402_ENABLED", "false").to_s.downcase)

    def before(req)
      return nil if AsOf.dev_free? || free?(req.path)

      bearer = bearer_from(req)
      if bearer.to_s.empty?
        return x402_challenge(req) if x402_enabled?

        return error(401, "payment_required", "Authorization Bearer key required")
      end

      key = CreditKey.lookup(bearer)
      return error(401, "payment_required", "unknown key") unless key

      cents = Prices.cents_for(req.path, method: req.request_method)
      credit = key.customer.wallet!
      if cents.positive? && credit.balance_cents < cents
        return error(402, "payment_required", "insufficient credits")
      end
      if brief?(req) && key.customer.brief_quota_exceeded?
        return error(402, "quota_exceeded", "brief_cap_month exceeded")
      end

      req.env["as_of.customer"] = key.customer
      req.env["as_of.price_cents"] = cents
      nil
    end

    def after(req, status, headers, body)
      return [status, headers, body] if AsOf.dev_free? || free?(req.path)
      return [status, headers, body] unless (200..299).cover?(status)

      customer = req.env["as_of.customer"]
      cents = req.env["as_of.price_cents"].to_i
      return [status, headers, body] unless customer

      customer.wallet!.debit!(cents) if cents.positive?
      UsageEvent.create!(customer: customer, route: req.path, status: status, price_cents: cents)
      [status, headers, body]
    end

    def bearer_from(req)
      h = req.get_header("HTTP_AUTHORIZATION").to_s
      h[/\ABearer\s+(\S+)/i, 1]
    end

    def brief?(req) = req.post? && req.path == "/v1/brief/query"

    def x402_challenge(req)
      resource = req.path
      cents = Prices.cents_for(req.path, method: req.request_method)
      body = {
        "x402Version" => 1,
        "error" => { "code" => "payment_required", "message" => "x402 required" },
        "accepts" => [{
          "scheme" => "exact",
          "resource" => resource,
          "maxAmountRequired" => cents.to_s
        }]
      }
      [402, { "content-type" => "application/json" }, [JSON.generate(body)]]
    end

    def error(status, code, message)
      [status, { "content-type" => "application/json" },
       [JSON.generate("error" => { "code" => code, "message" => message })]]
    end
  end
end
