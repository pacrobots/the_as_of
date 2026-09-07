# frozen_string_literal: true

# The starter instrument — one component as pure data; every platform
# renders the same contract. `lightyear g instrument` makes more.
class WelcomeCard < Lightyear::MSV::Instrument
  prop :title
  prop :body
end
