# frozen_string_literal: true

require "yaml"

module AsOf
  module Catalog
    PATH = File.expand_path("../../config/state_series.yaml", __dir__)

    module_function

    def series = YAML.safe_load_file(PATH).fetch("series")

    def series_named(name) = series.find { |row| row["name"] == name }
  end
end
