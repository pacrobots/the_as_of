# frozen_string_literal: true

require "test_helper"
require "rack/mock"
require "as_of/prices"

class BillingTest < Lightyear::Support::TestCase
  def call(path, headers: {}, method: "GET")
    env = Rack::MockRequest.env_for("https://as-of.test#{path}", method: method)
    headers.each { |k, v| env[k] = v }
    Lightyear::Server.app.call(env)
  end

  def paid_key(cents: 1000)
    customer = Customer.create!(name: "meter")
    customer.wallet!.credit!(cents)
    _rec, raw = customer.issue_key!
    [customer.reload, raw]
  end

  setup do
    @prev_free = ENV["DEV_FREE"]
    @prev_x402 = ENV["X402_ENABLED"]
    ENV["DEV_FREE"] = "0"
    ENV["X402_ENABLED"] = "false"
  end

  teardown do
    ENV["DEV_FREE"] = @prev_free
    ENV["X402_ENABLED"] = @prev_x402
  end

  test "GET /v1/prices is free and lists SKUs" do
    status, _h, body = call("/v1/prices")
    assert_equal 200, status
    payload = JSON.parse(body.join)
    assert_equal "USD", payload["currency"]
    assert payload["skus"].any? { |s| s["id"] == "consumer" }
    assert payload["routes"].any? { |r| r["path"] == "/v1/state" }
  end

  test "no auth on a priced route is 401" do
    status, _h, body = call("/v1/state")
    assert_equal 401, status
    assert_equal "payment_required", JSON.parse(body.join).dig("error", "code")
  end

  test "zero balance is 402" do
    customer = Customer.create!(name: "broke")
    _rec, raw = customer.issue_key!
    status, _h, body = call("/v1/state", headers: { "HTTP_AUTHORIZATION" => "Bearer #{raw}" })
    assert_equal 402, status
    assert_equal "payment_required", JSON.parse(body.join).dig("error", "code")
    assert_equal 0, customer.wallet!.balance_cents
  end

  test "2xx deducts cents and writes a usage event; 404 does not" do
    customer, raw = paid_key(cents: 500)
    status, = call("/v1/state", headers: { "HTTP_AUTHORIZATION" => "Bearer #{raw}" })
    assert_equal 200, status
    assert_equal 497, customer.wallet!.reload.balance_cents
    assert_equal 1, customer.usage_events.where(route: "/v1/state", status: 200, price_cents: 3).count

    status, = call("/v1/nope", headers: { "HTTP_AUTHORIZATION" => "Bearer #{raw}" })
    assert_equal 404, status
    assert_equal 497, customer.wallet!.reload.balance_cents
  end

  test "X402_ENABLED with no bearer returns 402 challenge" do
    ENV["X402_ENABLED"] = "true"
    status, _h, body = call("/v1/state")
    assert_equal 402, status
    payload = JSON.parse(body.join)
    assert_equal 1, payload["x402Version"]
    assert payload["accepts"]
  end

  test "charge! grants included_usd for a SKU" do
    customer = Customer.create!(name: "reader")
    customer.charge!(sku: "consumer")
    assert_equal 500, customer.wallet!.balance_cents
    assert_equal 10, customer.sku_entitlements.last.brief_cap_month
  end

  test "usage_events are not exposed on /v1" do
    status, _h, body = call("/v1/usage_events")
    assert_equal 401, status
    _customer, raw = paid_key
    status, _h, body = call("/v1/usage_events", headers: { "HTTP_AUTHORIZATION" => "Bearer #{raw}" })
    assert_equal 404, status
    refute_includes JSON.parse(body.join).to_s, "balance"
  end

  test "brief_cap_month blocks a second brief in the month" do
    customer, raw = paid_key(cents: 10_000)
    customer.sku_entitlements.create!(sku: "consumer", brief_cap_month: 1, included_cents: 0)
    UsageEvent.create!(customer: customer, route: "/v1/brief/query", status: 200, price_cents: 25)
    assert customer.brief_quota_exceeded?
    status, _h, body = call("/v1/brief/query", method: "POST",
                            headers: { "HTTP_AUTHORIZATION" => "Bearer #{raw}" })
    assert_equal 402, status
    assert_equal "quota_exceeded", JSON.parse(body.join).dig("error", "code")
  end

  test "plaintext key is not stored" do
    customer = Customer.create!(name: "k")
    rec, raw = customer.issue_key!
    refute_equal raw, rec.key_hash
    assert_equal CreditKey.hash_of(raw), rec.key_hash
    assert CreditKey.lookup(raw)
  end
end
