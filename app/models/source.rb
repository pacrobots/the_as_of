# frozen_string_literal: true

require "as_of/blob_store"

class Source < ApplicationRecord
  validates :kind, presence: true
  validates :native_id, presence: true
  validates :url, presence: true
  validates :retrieved_at, presence: true
  validates :content_hash, presence: true, uniqueness: true
  validates :bytes, presence: true
  validates :license, presence: true
  validates :kind, inclusion: { in: %w[edgar federal_register fred treasury irs fomc courtlistener other] }
  validates :license, inclusion: { in: %w[public_domain us_gov unknown] }

  # JSON SourceMeta still calls this `hash`. Column cannot be `hash` (AR reserved).
  def self.ingest(kind:, native_id:, url:, bytes:, published_at: nil, license: "unknown",
                  retrieved_at: Time.now.utc, store: AsOf::BlobStore.new)
    data = bytes.to_s.b
    digest = store.put(data)
    find_by(content_hash: digest) || create!(
      kind: kind,
      native_id: native_id,
      url: url,
      retrieved_at: retrieved_at,
      published_at: published_at,
      content_hash: digest,
      bytes: store.bytesize(digest),
      license: license
    )
  end

  def as_meta
    {
      "id" => content_hash,
      "kind" => kind,
      "url" => url,
      "retrieved_at" => iso(retrieved_at),
      "published_at" => published_at && iso(published_at),
      "hash" => content_hash,
      "bytes" => bytes,
      "license" => license
    }
  end

  private

  def iso(time) = time.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
end
