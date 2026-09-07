# frozen_string_literal: true

class SkuEntitlement < ApplicationRecord
  belongs_to :customer
  validates :sku, presence: true
  validates :included_cents, presence: true
  validates :sku, inclusion: { in: %w[consumer practitioner seat_pack meter_only] }
end
