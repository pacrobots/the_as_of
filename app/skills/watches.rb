# frozen_string_literal: true

class Watches < Lightyear::Agents::Skill
  class WatchBrowse < Lightyear::Agents::Tool
    verb "watch/browse"
    description "Read recent Watch rows — a generated entity read (the gate rules every call)."
    disposition :read # commits nothing — every rung admits it (the Writ still gates)
    param :limit, :string, required: false, desc: "max rows (default 20, cap 50)"
    def execute(action:, ctx:)
      limit = action.params["limit"].to_i
      limit = 20 unless limit.positive?
      ::Watch.order(id: :desc).limit([limit, 50].min).map(&:attributes).to_json
    end
  end

  class WatchDescribe < Lightyear::Agents::Tool
    verb "watch/describe"
    description "Read ONE Watch in full, by id — a generated entity read."
    disposition :read # commits nothing — every rung admits it (the Writ still gates)
    param :id, :string, required: true, desc: "the Watch id"
    def execute(action:, ctx:)
      record = ::Watch.find_by(id: action.params["id"])
      record ? record.as_watch.to_json : "no Watch with id #{action.params['id']}"
    end
  end

  provides WatchBrowse, WatchDescribe
end
