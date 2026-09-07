# frozen_string_literal: true

class Watch < ApplicationRecord
  belongs_to :customer
  validates :entities, presence: true

  def as_watch
    {
      "id" => id.to_s,
      "customer_id" => customer_id.to_s,
      "entities" => Array(entities),
      "created_at" => created_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    }
  end

  def covers?(item)
    refs = Array(entities)
    return true if refs.empty?

    ent = item["entity"] || {}
    refs.any? { |raw|
      r = raw.respond_to?(:stringify_keys) ? raw.stringify_keys : raw
      r["type"].to_s == ent["type"].to_s && r["id"].to_s == ent["id"].to_s
    }
  end
end
