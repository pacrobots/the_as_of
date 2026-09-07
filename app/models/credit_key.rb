# frozen_string_literal: true

require "digest"
require "securerandom"

class CreditKey < ApplicationRecord
  belongs_to :customer
  validates :key_hash, presence: true, uniqueness: true
  validates :prefix, presence: true

  def self.hash_of(plaintext) = Digest::SHA256.hexdigest(plaintext.to_s)

  def self.lookup(plaintext)
    find_by(key_hash: hash_of(plaintext))
  end

  # Returns [record, plaintext]. Plaintext is shown once.
  def self.issue!(customer)
    raw = "tao_#{SecureRandom.hex(24)}"
    rec = create!(customer: customer, key_hash: hash_of(raw), prefix: raw[0, 8])
    [rec, raw]
  end
end
