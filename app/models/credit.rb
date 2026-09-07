# frozen_string_literal: true

class Credit < ApplicationRecord
  belongs_to :customer
  validates :balance_cents, presence: true

  def credit!(cents)
    return self if cents.to_i <= 0

    with_lock { update!(balance_cents: balance_cents + cents.to_i) }
    self
  end

  def debit!(cents)
    return self if cents.to_i <= 0

    with_lock do
      raise ArgumentError, "insufficient credits" if balance_cents < cents.to_i

      update!(balance_cents: balance_cents - cents.to_i)
    end
    self
  end
end
