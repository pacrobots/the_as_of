# frozen_string_literal: true

class ApplicationAgent < Lightyear::Agents::Agent
  # The app's default reasoning runtime — the provider you chose at `lightyear new`
  # (config/runtimes.yml, the operator file, or the LIGHTYEAR_LLM_* environment).
  # Every agent inherits it and can converse out of the box; any agent may override
  # with its own `runtime :…` line.
  runtime Lightyear::Runtimes.agent_adapter, **Lightyear::Runtimes.agent_runtime
end
