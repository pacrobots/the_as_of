# frozen_string_literal: true

# This file is not loaded. Host Rack apps join the serving stack — the same
# object `lightyear server` and config.ru run — via Lightyear::Server.mount
# at boot (config/initializers/). ActionDispatch was not adopted.
#
#   # config/initializers/mcp.rb  — add `gem "mcp"` to the Gemfile
#   Lightyear::Server.mount "/mcp",
#     Lightyear::Agents::Mcp::Endpoint.new(realm: Lightyear.realm, at: "/mcp")
