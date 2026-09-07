# frozen_string_literal: true

module AsOf
  # Memory entity handles. Not the public record.
  module Handles
    module_function

    def ensure!(handle, display: nil, resource: nil)
      realm = Lightyear.realm
      return unless realm&.respond_to?(:entity)

      realm.entity(handle, display: display, resource: resource)
    rescue StandardError
      nil
    end
  end
end
