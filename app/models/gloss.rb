# frozen_string_literal: true

require "digest"
require "as_of/judge"
require "as_of/handles"
require "as_of/blob_store"

class Gloss < ApplicationRecord
  PROMPT = "gloss-v1"
  MODEL = "deterministic-v1"

  validates :target_type, presence: true
  validates :target_id, presence: true
  validates :text, presence: true
  validates :status, presence: true
  validates :prompt_hash, presence: true
  validates :input_hash, presence: true
  validates :model, presence: true
  validates :target_type, inclusion: { in: %w[claim number rule filing series entity brief] }
  validates :status, inclusion: { in: %w[ok low_confidence] }
  validates :target_type, uniqueness: { scope: %i[target_id prompt_hash] }
  validate :text_is_short
  validate :text_has_no_advice

  def self.prompt_hash = Digest::SHA256.hexdigest(PROMPT)

  def self.explain!(target_type, target_id, store: AsOf::BlobStore.new)
    corpus, source_ids, as_of_data = corpus_for(target_type, target_id, store: store)
    raise ActiveRecord::RecordNotFound, "no #{target_type} #{target_id}" unless corpus

    input = Digest::SHA256.hexdigest(corpus)
    cached = find_by(target_type: target_type, target_id: target_id, prompt_hash: prompt_hash)
    return cached if cached && cached.input_hash == input

    text = draft(target_type, target_id, corpus)
    text = drop_ungrounded(text, corpus)
    raise ArgumentError, "ungrounded gloss" if AsOf::Judge.ungrounded_numbers(text, corpus).any?
    raise ArgumentError, "too many sentences" if sentence_count(text) > 8

    rec = cached || new(target_type: target_type, target_id: target_id, prompt_hash: prompt_hash)
    rec.update!(
      text: text,
      source_ids: source_ids,
      status: source_ids.any? ? "ok" : "low_confidence",
      as_of_data: as_of_data,
      input_hash: input,
      model: MODEL
    )
    rec
  end

  def self.corpus_for(type, id, store:)
    case type
    when "rule"
      rule = Rule.find_by(code: id)
      return nil unless rule

      AsOf::Handles.ensure!("usc:#{id.delete_prefix('usc:')}", display: rule.title) if id.start_with?("usc:")
      AsOf::Handles.ensure!("rule:#{id}", display: rule.title)
      bytes = if rule.source && store.exist?(rule.source.content_hash)
        store.get(rule.source.content_hash).to_s.force_encoding("UTF-8")
      else
        ""
      end
      corpus = [rule.as_object.to_json, bytes].join("\n")
      [corpus, [rule.source&.content_hash].compact, rule.source&.published_at || rule.updated_at]
    when "filing"
      filing = Filing.find_by(accession: id)
      return nil unless filing

      AsOf::Handles.ensure!("accession:#{id}", display: filing.form)
      AsOf::Handles.ensure!("cik:#{filing.cik}", display: filing.company_name)
      [filing.as_extract.to_json, [filing.source.content_hash], filing.filed_at]
    else
      nil
    end
  end

  def self.draft(type, id, _corpus)
    case type
    when "rule"
      rule = Rule.find_by!(code: id)
      [
        "This record is #{rule.title}.",
        "Status is #{rule.status.tr('_', ' ')}.",
        rule.effective_date && "The pointer lists effective date #{rule.effective_date.iso8601}.",
        "This product stores a pointer, not a USC parse.",
        rule.source && "The hashed source is attached as evidence."
      ].compact.join(" ")
    when "filing"
      filing = Filing.find_by!(accession: id)
      "This is #{filing.company_name} form #{filing.form} accession #{filing.accession}."
    else
      "Unknown target."
    end
  end

  def self.drop_ungrounded(text, corpus)
    AsOf::Judge.ungrounded_numbers(text, corpus).reduce(text) { |t, n| t.gsub(n, "") }.squeeze(" ")
  end

  def self.sentence_count(text)
    text.to_s.split(/(?<=[.!?])\s+/).reject(&:empty?).size
  end

  def as_object
    {
      "id" => id.to_s,
      "target_type" => target_type,
      "target_id" => target_id,
      "text" => text,
      "as_of" => updated_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
      "source_ids" => Array(source_ids),
      "status" => status
    }
  end

  private

  def text_is_short
    errors.add(:text, "more than 8 sentences") if self.class.sentence_count(text) > 8
  end

  def text_has_no_advice
    errors.add(:text, "advice verb") if AsOf::Judge.advice?(text)
  end
end
