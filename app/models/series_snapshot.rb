# frozen_string_literal: true

class SeriesSnapshot < ApplicationRecord
  belongs_to :source
  validates :name, presence: true
  validates :value, presence: true
  validates :unit, presence: true
  validates :vintage, presence: true
  validates :observed_at, presence: true
  validates :vintage, inclusion: { in: ["official", "derived", "estimated", "delayed"] }
  validates :name, uniqueness: { scope: %i[observed_at] }

  def self.record!(name:, value:, unit:, vintage:, observed_at:, source:)
    rec = find_or_initialize_by(name: name, observed_at: observed_at)
    rec.update!(value: value, unit: unit, vintage: vintage, source: source)
    rec
  end

  def as_fact
    {
      "name" => name,
      "value" => numeric_or_string,
      "unit" => unit,
      "vintage" => vintage,
      "as_of" => observed_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
      "source_id" => source.content_hash
    }
  end

  def numeric_or_string
    Float(value)
  rescue ArgumentError, TypeError
    value
  end
end
