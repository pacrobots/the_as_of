# frozen_string_literal: true

module AsOf
  def self.dev_free?
    %w[1 true yes].include?(ENV.fetch("DEV_FREE", "0").to_s.downcase)
  end

  def self.x402_enabled?
    %w[1 true yes].include?(ENV.fetch("X402_ENABLED", "false").to_s.downcase)
  end

  def self.contact_email
    ENV["CONTACT_EMAIL"].to_s.strip
  end

  def self.sec_user_agent
    ua = ENV["SEC_USER_AGENT"].to_s.strip
    return ua unless ua.empty?

    mail = contact_email
    raise "CONTACT_EMAIL (or SEC_USER_AGENT) required for live EDGAR" if mail.empty?

    "AsOf/0.1 (+#{mail})"
  end
end
