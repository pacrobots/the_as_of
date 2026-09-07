# frozen_string_literal: true

# Rack entry point: `rackup`, `puma`, or any Rack server serves
# Lightyear::Server.app here. `lightyear server` runs the SAME object
# (not this file) — host mounts (MCP, /v1) register via Server.mount at
# boot so both entry points see them.
require_relative "config/lightyear"
require "lightyear/server"

run Lightyear::Server.app
