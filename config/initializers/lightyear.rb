# frozen_string_literal: true

# Module-level switchboard for backend choices.
# Per-deployment switches go here; per-app identity lives in config/lightyear.rb.
Lightyear.configure do |c|
  c.writ_backend = :stub
end
