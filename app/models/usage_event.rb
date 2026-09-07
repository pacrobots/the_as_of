# frozen_string_literal: true

class UsageEvent < ApplicationRecord
  belongs_to :customer
  validates :route, presence: true
  validates :status, presence: true
  validates :price_cents, presence: true
end
