# frozen_string_literal: true

class Rules < Lightyear::Agents::Skill
  class RuleBrowse < Lightyear::Agents::Tool
    verb "rule/browse"
    description "Read recent Rule rows — a generated entity read (the gate rules every call)."
    disposition :read # commits nothing — every rung admits it (the Writ still gates)
    param :limit, :string, required: false, desc: "max rows (default 20, cap 50)"
    def execute(action:, ctx:)
      limit = action.params["limit"].to_i
      limit = 20 unless limit.positive?
      ::Rule.order(id: :desc).limit([limit, 50].min).map(&:attributes).to_json
    end
  end

  class RuleDescribe < Lightyear::Agents::Tool
    verb "rule/describe"
    description "Read ONE Rule in full, by id — a generated entity read."
    disposition :read # commits nothing — every rung admits it (the Writ still gates)
    param :id, :string, required: true, desc: "the Rule id"
    def execute(action:, ctx:)
      id = action.params["id"]
      record = ::Rule.find_by(code: id) || ::Rule.find_by(id: id)
      record ? record.as_object.to_json : "no Rule with id #{id}"
    end
  end

  provides RuleBrowse, RuleDescribe
end
