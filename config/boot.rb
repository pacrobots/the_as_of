# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)
require "bundler/setup"
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Persist credentials across restarts. config/master.key is gitignored.
master_path = File.expand_path("master.key", __dir__)
if ENV["LIGHTYEAR_MASTER_KEY"].to_s.empty? && File.exist?(master_path)
  ENV["LIGHTYEAR_MASTER_KEY"] = File.read(master_path).strip
end
