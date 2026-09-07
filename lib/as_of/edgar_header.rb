# frozen_string_literal: true

require "time"

module AsOf
  # Deterministic SEC submission header. No model. Unknown required field → raise.
  class EdgarHeader
    Header = Struct.new(:accession, :form, :cik, :company_name, :filed_at, keyword_init: true)

    def self.parse(bytes)
      text = bytes.to_s
      accession = text[/ACCESSION NUMBER:\s*(\S+)/, 1]
      form = text[/CONFORMED SUBMISSION TYPE:\s*(\S+)/, 1]
      cik = text[/CENTRAL INDEX KEY:\s*(\d+)/, 1]
      company = text[/COMPANY CONFORMED NAME:\s*(.+)/, 1]&.strip
      filed = text[/FILED AS OF DATE:\s*(\d{8})/, 1]
      missing = { accession:, form:, cik:, filed: }.select { |_, v| v.to_s.empty? }.keys
      raise ArgumentError, "EDGAR header missing #{missing.join(', ')}" if missing.any?

      Header.new(
        accession: accession,
        form: form,
        cik: cik,
        company_name: company,
        filed_at: Time.utc(filed[0, 4].to_i, filed[4, 2].to_i, filed[6, 2].to_i)
      )
    end
  end
end
