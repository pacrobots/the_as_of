# frozen_string_literal: true

require_relative "notices"

module AsOf
  # Render markdown from the JSON object only. Zero extra facts.
  module Markdown
    module_function

    def state(payload)
      lines = ["# As-Of", "",
               "as_of: #{payload['as_of']}",
               "as_of_data: #{payload['as_of_data']}",
               "", "## Series"]
      Array(payload["series"]).each do |f|
        lines << "- #{f['name']}: #{f['value']} #{f['unit']} (#{f['vintage']}) source #{f['source_id']}"
      end
      lines << ""
      lines << "## Next dates"
      Array(payload["next_dates"]).each do |d|
        lines << "- #{d['date']}: #{d['why']} source #{d['source_id']}"
      end
      Array(payload["series"]).each do |f|
        next if f["citation"].to_s.empty?

        lines << ""
        lines << f["citation"]
        break
      end
      lines << ""
      Notices.footer_lines.each { |n| lines << "_#{n}_" }
      lines.join("\n") + "\n"
    end

    def brief(payload)
      lines = ["# #{payload['headline']}", "",
               "id: #{payload['id']}",
               "as_of: #{payload['as_of']}",
               "event_type: #{payload['event_type']}",
               "status: #{payload['status']}",
               "", "## Numbers"]
      Array(payload["numbers"]).each do |n|
        lines << "- #{n['name']}: #{n['value']} #{n['unit']} source #{n['source_id']}"
      end
      lines << ""
      lines << "## Claims"
      Array(payload["claims"]).each do |c|
        lines << "- #{c['text']} (#{c['status']})"
      end
      lines << ""
      lines << "## Sources"
      Array(payload["sources"]).each do |s|
        lines << "- #{s['id'] || s['hash']} #{s['url']}"
      end
      lines.join("\n") + "\n"
    end
  end
end
