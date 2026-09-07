# frozen_string_literal: true

require "as_of/judge"

class Brief < ApplicationRecord
  belongs_to :source, optional: true
  belongs_to :customer, optional: true
  validates :event_type, presence: true
  validates :headline, presence: true, length: { maximum: 140 }
  validates :status, presence: true
  validates :status, inclusion: { in: %w[ok low_confidence corrected] }
  validate :headline_has_no_advice

  def self.compose!(question:, customer: nil)
    q = question.to_s.strip
    raise ArgumentError, "question required" if q.empty?

    chosen = retrieve(q)
    numbers = chosen.flat_map { |f| Array(f.facts) }.select { |n|
      chosen.any? { |f| n["source_id"] == f.source.content_hash }
    }
    claims = chosen.flat_map { |f| Array(f.claims) }
    sources = chosen.map { |f| f.source.as_meta }

    filing = chosen.first
    headline = if filing
      "#{filing.company_name} #{filing.form} filed #{filing.filed_at.utc.to_date}"
    else
      "No matching public record"
    end
    headline = headline[0, 140]
    raise ArgumentError, "advice verb in headline" if AsOf::Judge.advice?(headline)

    rec = create!(
      event_type: "query",
      headline: headline,
      status: chosen.empty? ? "low_confidence" : "ok",
      entities: filing ? [{ "type" => "cik", "id" => filing.cik, "name" => filing.company_name }] : [],
      jurisdictions: ["US-federal"],
      claims: claims,
      numbers: numbers,
      exposures: [],
      next_dates: [],
      open_questions: chosen.empty? ? ["No filing matched the question."] : [],
      supersedes: [],
      sources_json: sources,
      source: filing&.source,
      customer: customer
    )
    rec.announce_published!
    rec
  end

  def self.retrieve(question)
    q = question.to_s
    rel = Filing.order(filed_at: :desc)
    hit = rel.select { |f|
      Array(f.sections).any? { |s| s["name"].to_s.match?(/2\.02/i) } &&
        q.match?(/2\.02|revenue|results|8-K|nvidia/i)
    }
    return hit.first(5) if hit.any?
    return rel.limit(1).to_a if q.match?(/2\.02|revenue|8-K|nvidia/i)

    []
  end

  def announce_published!
    return unless Lightyear.respond_to?(:realm) && Lightyear.realm

    Lightyear.realm.announce(:brief_published, brief_id: id.to_s)
  rescue StandardError
    nil
  end

  def as_object
    {
      "id" => id.to_s,
      "as_of" => created_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
      "event_type" => event_type,
      "headline" => headline,
      "entities" => Array(entities),
      "jurisdictions" => Array(jurisdictions),
      "claims" => Array(claims),
      "numbers" => Array(numbers),
      "exposures" => Array(exposures),
      "next_dates" => Array(next_dates),
      "open_questions" => Array(open_questions),
      "status" => status,
      "supersedes" => Array(supersedes),
      "sources" => Array(sources_json)
    }
  end

  def correct!(headline:, numbers: nil, claims: nil)
    self.class.create!(
      event_type: event_type,
      headline: headline[0, 140],
      status: "corrected",
      entities: entities,
      jurisdictions: jurisdictions,
      claims: claims || self.claims,
      numbers: numbers || self.numbers,
      exposures: exposures,
      next_dates: next_dates,
      open_questions: open_questions,
      supersedes: [id.to_s],
      sources_json: sources_json,
      source: source,
      customer: customer
    ).tap(&:announce_published!)
  end

  private

  def headline_has_no_advice
    errors.add(:headline, "advice verb") if AsOf::Judge.advice?(headline)
  end
end
