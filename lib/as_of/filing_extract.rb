# frozen_string_literal: true

require_relative "judge"

module AsOf
  # Deterministic 8-K extract (headers already on Filing). LLM fallback is S7
  # later; this path is assert_no_llm_calls.
  module FilingExtract
    module_function

    def run!(filing, bytes:, store: nil)
      return filing if Array(filing.facts).any?

      sid = filing.source.content_hash
      facts = Judge.grounded_facts(detect_facts(bytes, filing, sid), bytes)
      claims = detect_claims(bytes, filing, sid)
      sections = detect_sections(bytes, sid)
      filing.update!(facts: facts, claims: claims, sections: sections)
      filing
    end

    def detect_facts(bytes, filing, sid)
      text = bytes.to_s
      facts = []
      if (m = text.match(/Revenue was ([0-9][0-9,]*(?:\.[0-9]+)?)/i))
        facts << {
          "name" => "revenue",
          "value" => m[1].delete(","),
          "unit" => "USD",
          "vintage" => "official",
          "as_of" => filing.filed_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
          "source_id" => sid
        }
      end
      facts
    end

    def detect_claims(bytes, filing, sid)
      text = bytes.to_s
      return [] unless text.match?(/Item\s+2\.02/i)

      [{
        "id" => "#{filing.accession}:item-2.02",
        "text" => "Item 2.02 Results of Operations and Financial Condition.",
        "status" => "asserted",
        "confidence" => 0.95,
        "evidence" => [sid],
        "entities" => [{ "type" => "cik", "id" => filing.cik, "name" => filing.company_name }]
      }]
    end

    def detect_sections(bytes, sid)
      return [] unless bytes.to_s.match?(/Item\s+2\.02/i)

      [{ "name" => "Item 2.02", "source_id" => sid, "fragment" => "Item 2.02" }]
    end
  end
end
