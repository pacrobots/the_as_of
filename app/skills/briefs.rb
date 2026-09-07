# frozen_string_literal: true

class Briefs < Lightyear::Agents::Skill
  class BriefBrowse < Lightyear::Agents::Tool
    verb "brief/browse"
    description "Read recent Brief rows — a generated entity read (the gate rules every call)."
    disposition :read # commits nothing — every rung admits it (the Writ still gates)
    param :limit, :string, required: false, desc: "max rows (default 20, cap 50)"
    def execute(action:, ctx:)
      limit = action.params["limit"].to_i
      limit = 20 unless limit.positive?
      ::Brief.order(id: :desc).limit([limit, 50].min).map(&:attributes).to_json
    end
  end

  class BriefDescribe < Lightyear::Agents::Tool
    verb "brief/describe"
    description "Read ONE Brief in full, by id — a generated entity read."
    disposition :read # commits nothing — every rung admits it (the Writ still gates)
    param :id, :string, required: true, desc: "the Brief id"
    def execute(action:, ctx:)
      record = ::Brief.find_by(id: action.params["id"])
      record ? record.as_object.to_json : "no Brief with id #{action.params['id']}"
    end
  end

  provides BriefBrowse, BriefDescribe
end
