# frozen_string_literal: true

require_relative "catalog"
require_relative "notices"

module AsOf
  # Assembles StateSnapshot and Diff from SeriesSnapshot history.
  # `at=` is observation calendar (observed_at <= at), not Ledger folding.
  module State
    module_function

    def snapshot(at: nil, since: nil)
      facts = facts_at(at)
      raise LowData if at && facts.empty?

      data_at = facts.map { |f| Time.parse(f["as_of"]) }.max
      {
        "as_of" => clock,
        "as_of_data" => data_at && iso(data_at),
        "series" => facts,
        "next_dates" => [],
        "deltas" => since ? series_diff_items(since: since, at: at) : [],
        "notices" => AsOf::Notices.public_payload
      }
    end

    def diff(since:, at: nil, watch: nil, types: nil, entities: nil)
      raise ArgumentError, "since required" if since.nil?

      items = series_diff_items(since: since, at: at) + filing_diff_items(since: since, at: at)
      items = items.select { |i| watch.covers?(i) } if watch
      if entities
        wanted = Array(entities)
        items = items.select { |i|
          wanted.any? { |raw|
            r = raw.respond_to?(:stringify_keys) ? raw.stringify_keys : raw
            r["type"].to_s == i.dig("entity", "type").to_s && r["id"].to_s == i.dig("entity", "id").to_s
          }
        }
      end
      if types
        wanted = Array(types).map(&:to_s)
        items = items.select { |i| wanted.include?(i.dig("entity", "type").to_s) }
      end
      { "since" => iso(since), "as_of" => clock, "items" => items }
    end

    def facts_at(at)
      Catalog.series.filter_map { |row|
        snap = latest(row["name"], at: at)
        snap&.as_fact
      }
    end

    def latest(name, at: nil)
      rel = SeriesSnapshot.where(name: name)
      rel = rel.where("observed_at <= ?", at) if at
      rel.order(observed_at: :desc).first
    end

    def series_diff_items(since:, at: nil)
      before = facts_at(since).to_h { |f| [f["name"], f] }
      after = facts_at(at).to_h { |f| [f["name"], f] }
      names = (before.keys + after.keys).uniq.sort
      names.filter_map { |name|
        b, a = before[name], after[name]
        if b.nil? && a
          item("add", name, nil, a)
        elsif a.nil? && b
          item("remove", name, b, nil)
        elsif b && a && b["value"] != a["value"]
          item("replace", name, b, a)
        end
      }
    end

    def filing_diff_items(since:, at: nil)
      rel = Filing.where("filed_at > ?", since)
      rel = rel.where("filed_at <= ?", at) if at
      rel.order(:filed_at).map { |f|
        {
          "op" => "add",
          "path" => "/filing/#{f.accession}",
          "entity" => { "type" => "cik", "id" => f.cik, "name" => f.company_name },
          "before" => {},
          "after" => { "accession" => f.accession, "form" => f.form },
          "source_id" => f.source.content_hash
        }
      }
    end

    def item(op, name, before, after)
      {
        "op" => op,
        "path" => "/series/#{name}/value",
        "entity" => { "type" => "series", "id" => name, "name" => nil },
        "before" => before ? { "value" => before["value"] } : {},
        "after" => after ? { "value" => after["value"] } : {},
        "source_id" => (after || before)["source_id"]
      }
    end

    def clock = iso(Time.now)
    def iso(time) = time.utc.strftime("%Y-%m-%dT%H:%M:%SZ")

    class LowData < StandardError; end
  end
end
