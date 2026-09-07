# frozen_string_literal: true

module AsOf
  # Required public notices. FRED API TOS: disclaimer must be prominent;
  # series must cite FRED and the original source; no Fed endorsement.
  module Notices
    FRED_DISCLAIMER =
      "This product uses the FRED® API but is not endorsed or certified by the Federal Reserve Bank of St. Louis."

    FRED_ATTRIBUTION =
      "FRED® is a registered trademark of the Federal Reserve Bank of St. Louis. " \
      "Series values that originate in FRED are attributed to FRED and the original source on each fact."

    FRED_TOS = "https://fred.stlouisfed.org/docs/api/terms_of_use.html"
    FRED_LEGAL = "https://fred.stlouisfed.org/legal/"

    module_function

    def public_payload
      {
        "fred" => {
          "disclaimer" => FRED_DISCLAIMER,
          "attribution" => FRED_ATTRIBUTION,
          "terms" => FRED_TOS,
          "legal" => FRED_LEGAL
        }
      }
    end

    def footer_lines
      [FRED_DISCLAIMER, FRED_ATTRIBUTION, "Terms: #{FRED_TOS}"]
    end
  end
end
