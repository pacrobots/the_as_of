# frozen_string_literal: true

module AsOf
  module Secrets
    module_function

    def fred_api_key
      Lightyear::Trust::Credentials.resolve(realm: Lightyear.realm, key: :fred_api_key, env_var: "FRED_API_KEY")
    end

    def fred_api_key? = !fred_api_key.to_s.empty?
  end
end
