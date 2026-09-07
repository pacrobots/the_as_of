# frozen_string_literal: true

require "as_of/catalog"
require "as_of/notices"

# Human 5%: series names only, never live paid numbers. JSON for MSV; pixels
# live in clients/. Deleting clients/ leaves this standing.
class StatePage
  def self.teaser
    {
      "goal" => "The agents' ledger of public record",
      "series_names" => AsOf::Catalog.series.map { |s| s["name"] },
      "hint" => "GET /v1/state.md with a Bearer key for values. Explain via /v1/explain.",
      "fred_disclaimer" => AsOf::Notices::FRED_DISCLAIMER
    }
  end
end
