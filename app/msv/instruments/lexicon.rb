# frozen_string_literal: true

# The app's approved vocabulary — adding a component is one class
# (app/msv/instruments/*.rb) plus one line here.
require_relative "welcome_card"

LEXICON = Lightyear::MSV::Lexicon.define("as_of-v1") do
  instrument WelcomeCard
end
