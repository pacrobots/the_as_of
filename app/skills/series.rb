# frozen_string_literal: true

class Series < Lightyear::Agents::Skill
  class SeriesBrowse < Lightyear::Agents::Tool
    verb "series/browse"
    description "Read recent SeriesSnapshot rows — a generated entity read (the gate rules every call)."
    disposition :read # commits nothing — every rung admits it (the Writ still gates)
    param :limit, :string, required: false, desc: "max rows (default 20, cap 50)"
    def execute(action:, ctx:)
      limit = action.params["limit"].to_i
      limit = 20 unless limit.positive?
      ::SeriesSnapshot.order(id: :desc).limit([limit, 50].min).map(&:attributes).to_json
    end
  end

  class SeriesDescribe < Lightyear::Agents::Tool
    verb "series/describe"
    description "Read ONE SeriesSnapshot in full, by id — a generated entity read."
    disposition :read # commits nothing — every rung admits it (the Writ still gates)
    param :id, :string, required: true, desc: "the SeriesSnapshot id"
    def execute(action:, ctx:)
      record = ::SeriesSnapshot.find_by(id: action.params["id"])
      record ? record.attributes.to_json : "no SeriesSnapshot with id #{action.params['id']}"
    end
  end

  provides SeriesBrowse, SeriesDescribe
end
