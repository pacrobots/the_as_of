# frozen_string_literal: true

require "as_of/handles"

class Filing < ApplicationRecord
  belongs_to :source
  validates :accession, presence: true
  validates :cik, presence: true
  validates :form, presence: true
  validates :filed_at, presence: true
  validates :accession, uniqueness: true

  def self.record_headers!(source:, headers:)
    rec = find_or_initialize_by(accession: headers.accession)
    rec.update!(
      cik: headers.cik,
      form: headers.form,
      filed_at: headers.filed_at,
      company_name: headers.company_name,
      source: source
    )
    AsOf::Handles.ensure!("cik:#{rec.cik}", display: rec.company_name)
    AsOf::Handles.ensure!("accession:#{rec.accession}", display: rec.form)
    rec
  end

  def as_extract
    {
      "accession" => accession,
      "cik" => cik,
      "form" => form,
      "filed_at" => filed_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
      "facts" => Array(facts),
      "claims" => Array(claims),
      "sections" => Array(sections),
      "as_of" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    }
  end
end

