# frozen_string_literal: true

require "lightyear/server"
require_relative "../../lib/as_of/v1"

# Same stack `lightyear server` and config.ru serve (pacificrobots/lightyear#55).
Lightyear::Server.mount "/v1", AsOf::V1
