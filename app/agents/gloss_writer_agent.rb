# frozen_string_literal: true

class GlossWriterAgent < ApplicationAgent
  kind :practitioner
  skill Glosses
  skill Rules
  skill Filings
  skill Sources
end
