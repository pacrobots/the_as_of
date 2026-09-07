# frozen_string_literal: true

require "as_of/ingest_beat"

# Ride the jobs clock (Scheduler.tick! every 5s). Ingest is a Job, not an
# agent Cadence — prepend so a missing blueprint cadence cannot skip FRED.
module AsOf
  module SchedulerIngest
    def tick!(realm: nil, now: Time.current)
      n = super
      AsOf::IngestBeat.tick!(now: now)
      n
    end
  end
end

Lightyear::Agents::Scheduler.singleton_class.prepend(AsOf::SchedulerIngest)
