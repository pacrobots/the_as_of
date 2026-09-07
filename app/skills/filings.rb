# frozen_string_literal: true

class Filings < Lightyear::Agents::Skill
  class FilingBrowse < Lightyear::Agents::Tool
    verb "filing/browse"
    description "Read recent Filing rows — a generated entity read (the gate rules every call)."
    disposition :read # commits nothing — every rung admits it (the Writ still gates)
    param :limit, :string, required: false, desc: "max rows (default 20, cap 50)"
    def execute(action:, ctx:)
      limit = action.params["limit"].to_i
      limit = 20 unless limit.positive?
      ::Filing.order(id: :desc).limit([limit, 50].min).map(&:attributes).to_json
    end
  end

  class FilingDescribe < Lightyear::Agents::Tool
    verb "filing/describe"
    description "Read ONE Filing in full, by id — a generated entity read."
    disposition :read # commits nothing — every rung admits it (the Writ still gates)
    param :id, :string, required: true, desc: "the Filing id"
    def execute(action:, ctx:)
      id = action.params["id"]
      record = ::Filing.find_by(accession: id) || ::Filing.find_by(id: id)
      record ? record.as_extract.to_json : "no Filing with id #{id}"
    end
  end

  provides FilingBrowse, FilingDescribe
end
