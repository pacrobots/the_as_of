# frozen_string_literal: true

require "as_of/blob_store"

class Rule < ApplicationRecord
  belongs_to :source, optional: true
  validates :code, presence: true
  validates :title, presence: true
  validates :status, presence: true
  validates :status, inclusion: { in: ["in_force", "proposed", "withdrawn", "unknown"] }
  validates :code, uniqueness: true

  SEED = File.expand_path("../../config/rules_seed.yaml", __dir__)

  def self.seed!(store: AsOf::BlobStore.new, root: Lightyear.application.config.root)
    require "yaml"
    require "date"
    rows = YAML.safe_load_file(SEED).fetch("rules")
    rows.map { |row| upsert_seed!(row, store: store, root: root) }
  end

  def self.upsert_seed!(row, store:, root:)
    source = nil
    if (rel = row["pointer_file"])
      path = File.join(root, rel)
      bytes = File.binread(path)
      source = Source.ingest(
        kind: "other",
        native_id: row.fetch("native_id"),
        url: row.fetch("url"),
        bytes: bytes,
        license: "us_gov",
        store: store
      )
    end
    rec = find_or_initialize_by(code: row.fetch("code"))
    rec.update!(
      title: row.fetch("title"),
      status: row.fetch("status"),
      effective_date: row["effective_date"] && Date.iso8601(row["effective_date"].to_s),
      supersedes: row["supersedes"] || [],
      fragment: row["fragment"],
      exposures: row["exposures"] || [],
      open_questions: row["open_questions"] || [],
      source: source
    )
    rec
  end

  def as_object
    {
      "id" => code,
      "title" => title,
      "status" => status,
      "effective_date" => effective_date&.iso8601,
      "supersedes" => Array(supersedes),
      "text_pointer" => { "source_id" => source&.content_hash, "fragment" => fragment },
      "exposures" => Array(exposures),
      "open_questions" => Array(open_questions),
      "as_of" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    }
  end
end

