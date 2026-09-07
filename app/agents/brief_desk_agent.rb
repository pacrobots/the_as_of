# frozen_string_literal: true

class BriefDeskAgent < ApplicationAgent
  kind :practitioner
  skill Briefs
  skill Filings
  skill Sources
  skill Rules
  skill Series
end
