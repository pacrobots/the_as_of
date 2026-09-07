# frozen_string_literal: true

require "as_of/filing_extract"

# Declared procedure: facts → Judge → persist. Cadence should enqueue this
# only when IngestEdgarJob reports a new source hash.
class ExtractFilingWorkflow < Lightyear::Agents::Workflow
  step :facts do |run|
    AsOf::FilingExtract.run!(run[:filing], bytes: run[:bytes])
  end
end
