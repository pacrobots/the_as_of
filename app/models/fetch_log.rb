# frozen_string_literal: true

class FetchLog < ApplicationRecord
  OUTCOMES = %w[new kept skipped failed].freeze

  validates :source_kind, presence: true
  validates :url, presence: true
  validates :outcome, presence: true, inclusion: { in: OUTCOMES }

  def self.record!(**attrs)
    create!(attrs)
  end

  def self.last_ok(kind = nil, native_id: nil)
    rel = where(outcome: %w[new kept])
    rel = rel.where(source_kind: kind) if kind
    rel = rel.where(native_id: native_id) if native_id
    rel.order(id: :desc).first
  end

  def self.last_for(kind:, native_id:)
    where(source_kind: kind, native_id: native_id).order(id: :desc).first
  end

  def self.stale?(kind:, max_age:, native_id: nil)
    row = last_ok(kind, native_id: native_id)
    return true unless row

    row.created_at < max_age.ago
  end

  def as_public
    {
      "id" => id,
      "source_kind" => source_kind,
      "native_id" => native_id,
      "url" => url,
      "http_status" => http_status,
      "bytes" => bytes,
      "content_hash" => content_hash,
      "outcome" => outcome,
      "error_class" => error_class,
      "error_message" => error_message,
      "duration_ms" => duration_ms,
      "created_at" => created_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    }
  end
end
