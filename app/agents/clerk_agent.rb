# frozen_string_literal: true

class ClerkAgent < ApplicationAgent
  kind :practitioner
  skill Sources
  skill Filings
  skill Series
  skill Rules
  skill Watches
end

