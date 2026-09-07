# frozen_string_literal: true

require "json"
require "rack"

module AsOf
  # HTTP Basic lock for the staging box. Any IP, one password — no allowlist.
  # Off when SITE_PASSWORD is unset. Health and DID stay open for Kamal / peers.
  module SiteGate
    module_function

    def password = ENV["SITE_PASSWORD"].to_s

    def enabled? = !password.empty?

    def skip?(path)
      path == "/v1/health" || path == "/v1/ingest" || path.start_with?("/.well-known")
    end

    def challenge(req)
      return nil unless enabled?
      return nil if skip?(req.path)
      return nil if authorized?(req)

      [401,
       { "content-type" => "application/json",
         "www-authenticate" => 'Basic realm="As-Of staging"' },
       [JSON.generate("error" => { "code" => "payment_required", "message" => "site password required" })]]
    end

    def authorized?(req)
      auth = Rack::Auth::Basic::Request.new(req.env)
      auth.provided? && auth.basic? &&
        Rack::Utils.secure_compare(auth.credentials.last.to_s, password)
    end
  end
end
