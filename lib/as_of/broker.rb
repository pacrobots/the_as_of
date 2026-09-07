# frozen_string_literal: true

module AsOf
  # Completes blueprint connection stubs. Seeds call this; apply clobbers seeds,
  # so keep the flesh here.
  module Broker
    module_function

    def ensure!(realm)
      edgar(realm)
      fred(realm)
    end

    def edgar(realm)
      upsert(realm, "edgar", :http, {
        "base_url" => "https://data.sec.gov",
        "user_agent" => ENV["SEC_USER_AGENT"],
        "endpoints" => {
          "edgar/fetch" => {
            "method" => "get",
            "path" => "/Archives/edgar/data/{cik}/{accession_nodash}/{accession}.txt",
            "resource" => "accession",
            "impact" => "low",
          },
        },
      })
    end

    def fred(realm)
      upsert(realm, "fred", :http, {
        "base_url" => "https://api.stlouisfed.org",
        "api_key" => ENV["FRED_API_KEY"],
        "endpoints" => {
          "fred/observations" => {
            "method" => "get",
            "path" => "/fred/series/observations",
            "resource" => "series_id",
            "impact" => "low",
          },
        },
      })
    end

    def upsert(realm, system, source_kind, config)
      existing = realm.connections.find_by(system: system)
      if existing
        existing.update!(config: config) if existing.config.to_h["base_url"] == "TODO"
        existing
      else
        realm.connect(system.to_sym, source_kind: source_kind, config: config)
      end
    end
  end
end
