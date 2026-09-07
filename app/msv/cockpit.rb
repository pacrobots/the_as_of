# frozen_string_literal: true

# Attention allocation + the standing fences. `admit:` is relevance;
# `never … unless:` is safety — a high-stakes panel enters only when the
# predicate holds (e.g. a STATED intent: s.channel(:intent) == :stated).
require_relative "panels/welcome_panel"

class Cockpit < Lightyear::MSV::Cockpit
  panel WelcomePanel
end
