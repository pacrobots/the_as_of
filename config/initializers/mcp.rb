# frozen_string_literal: true

require "lightyear/server"
require_relative "../../lib/as_of/mcp"

Lightyear::Server.mount "/mcp", AsOf::Mcp
