# frozen_string_literal: true

class Sources < Lightyear::Agents::Skill
  class SourceBrowse < Lightyear::Agents::Tool
    verb "source/browse"
    description "Read recent Source rows — a generated entity read (the gate rules every call)."
    disposition :read # commits nothing — every rung admits it (the Writ still gates)
    param :limit, :string, required: false, desc: "max rows (default 20, cap 50)"
    def execute(action:, ctx:)
      limit = action.params["limit"].to_i
      limit = 20 unless limit.positive?
      ::Source.order(id: :desc).limit([limit, 50].min).map(&:attributes).to_json
    end
  end

  class SourceDescribe < Lightyear::Agents::Tool
    verb "source/describe"
    description "Read ONE Source in full, by id — a generated entity read."
    disposition :read # commits nothing — every rung admits it (the Writ still gates)
    param :id, :string, required: true, desc: "the Source id"
    def execute(action:, ctx:)
      id = action.params["id"]
      record = ::Source.find_by(content_hash: id) || ::Source.find_by(id: id)
      record ? record.as_meta.to_json : "no Source with id #{id}"
    end
  end

  provides SourceBrowse, SourceDescribe
end
