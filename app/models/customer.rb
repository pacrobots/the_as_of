# frozen_string_literal: true

require "as_of/prices"

class Customer < ApplicationRecord
  has_many :credit_keys, dependent: :destroy
  has_one :credit, dependent: :destroy
  has_many :sku_entitlements, dependent: :destroy
  has_many :usage_events, dependent: :destroy
  has_many :watches, dependent: :destroy

  def wallet!
    credit || create_credit!(balance_cents: 0)
  end

  def issue_key!
    CreditKey.issue!(self)
  end

  # SKU grant. Stripe (or any rail) calls this after funds move. No network here.
  def charge!(sku:)
    spec = AsOf::Prices.sku(sku) or raise ArgumentError, "unknown sku #{sku}"
    included = AsOf::Prices.included_cents(sku)
    wallet!.credit!(included)
    sku_entitlements.create!(
      sku: sku,
      brief_cap_month: spec["brief_cap_month"],
      included_cents: included
    )
    self
  end

  def brief_quota_exceeded?
    cap = sku_entitlements.where.not(brief_cap_month: nil).maximum(:brief_cap_month)
    return false if cap.nil?

    start = Time.now.utc.beginning_of_month
    used = usage_events.where("route LIKE ?", "%/brief/query%").where("created_at >= ?", start).count
    used >= cap
  end
end
