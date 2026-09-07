# frozen_string_literal: true

class Glosses < Lightyear::Agents::Skill
  class GlossBrowse < Lightyear::Agents::Tool
    verb "gloss/browse"
    description "Read recent Gloss rows — a generated entity read (the gate rules every call)."
    disposition :read # commits nothing — every rung admits it (the Writ still gates)
    param :limit, :string, required: false, desc: "max rows (default 20, cap 50)"
    def execute(action:, ctx:)
      limit = action.params["limit"].to_i
      limit = 20 unless limit.positive?
      ::Gloss.order(id: :desc).limit([limit, 50].min).map(&:attributes).to_json
    end
  end

  class GlossDescribe < Lightyear::Agents::Tool
    verb "gloss/describe"
    description "Read ONE Gloss in full, by id — a generated entity read."
    disposition :read # commits nothing — every rung admits it (the Writ still gates)
    param :id, :string, required: true, desc: "the Gloss id"
    def execute(action:, ctx:)
      record = ::Gloss.find_by(id: action.params["id"])
      record ? record.as_object.to_json : "no Gloss with id #{action.params['id']}"
    end
  end

  provides GlossBrowse, GlossDescribe
end
