# frozen_string_literal: true

require "as_of/site_gate"

# Wrap the same object `lightyear server` and config.ru serve.
module AsOf
  module ServerGate
    def app
      inner = super
      lambda do |env|
        req = Rack::Request.new(env)
        if (res = AsOf::SiteGate.challenge(req))
          return res
        end
        inner.call(env)
      end
    end
  end
end

Lightyear::Server.singleton_class.prepend(AsOf::ServerGate)
