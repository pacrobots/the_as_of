# frozen_string_literal: true

require_relative "boot"
require "lightyear/application"

Bundler.require(*Lightyear.groups)

module AsOf
  class Application < Lightyear::Application
    config.load_defaults Lightyear::VERSION
    config.root = File.expand_path("..", __dir__)

    # The human label for your home Realm (env-invariant). The Realm's *identity*
    # — its did:web fqdn — is set PER ENVIRONMENT in config/environments/*.rb,
    # because dev/test/prod are distinct identities with distinct keys by design.
    config.realm_name = "As-Of"

    config.autoload_paths << File.expand_path("../app/models", __dir__)
    config.autoload_paths << File.expand_path("../app/agents", __dir__)
    config.autoload_paths << File.expand_path("../app/skills", __dir__)
    config.autoload_paths << File.expand_path("../app/conventions", __dir__)
    config.autoload_paths << File.expand_path("../app/jobs", __dir__)
  end
end

AsOf::Application.new.initialize!

# The app-declared seams, after boot: identity (the OIDC RP + the viewer
# resolver) and the MSV serving (the view contract on the wire).
require_relative "identity"
require_relative "msv"
