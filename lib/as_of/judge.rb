# frozen_string_literal: true

module AsOf
  # A number that is not a substring of source bytes is dropped. No model.
  module Judge
    ADVICE = /\b(buy|sell|overweight|underweight|accumulate|reduce)\b/i

    module_function

    def grounded_facts(facts, bytes)
      text = bytes.to_s
      Array(facts).select { |f|
        v = f["value"].to_s
        v.empty? || v == "null" || in_source?(v, text)
      }
    end

    def in_source?(value, text)
      needle = value.to_s
      text.include?(needle) || text.include?(needle.delete(",")) ||
        text.include?(needle.sub(/\.0+\z/, ""))
    end

    def advice?(text) = text.to_s.match?(ADVICE)

    def numbers_in(text)
      text.to_s.scan(/\d+(?:,\d{3})*(?:\.\d+)?/)
    end

    def ungrounded_numbers(text, corpus)
      numbers_in(text).reject { |n| in_source?(n, corpus) }
    end
  end
end
