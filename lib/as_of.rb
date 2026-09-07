# frozen_string_literal: true

module AsOf
  def self.dev_free?
    %w[1 true yes].include?(ENV.fetch("DEV_FREE", "0").to_s.downcase)
  end
end
