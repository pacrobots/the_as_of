# frozen_string_literal: true

require "json"
require "rack"
require "time"
require_relative "../as_of"
require_relative "state"
require_relative "meter"
require_relative "prices"
require_relative "markdown"
require_relative "../../app/msv/pages/state_page"

module AsOf
  # Thin JSON catalog (PRD §5.1). Prefix-mounted on Server.app at `/v1`.
  # Reads project domain JSON. Writes that mutate go through Reach (S6/S7).
  class V1
    OPENAPI_PATH = File.expand_path("../../schemas/openapi.json", __dir__)

    def self.call(env) = new.call(env)

    def call(env)
      req = Rack::Request.new(env)
      if (denied = AsOf::Meter.before(req))
        return denied
      end

      status, headers, body = dispatch(req)
      AsOf::Meter.after(req, status, headers, body)
    end

    def dispatch(req)
      case [req.request_method, req.path]
      when ["GET", "/v1/health"]
        json(200, { "ok" => true, "as_of" => now, "as_of_data" => nil, "dev_free" => AsOf.dev_free? })
      when ["GET", "/v1/openapi.json"]
        json(200, JSON.parse(File.read(OPENAPI_PATH)))
      when ["GET", "/v1/prices"]
        json(200, AsOf::Prices.as_json)
      when ["GET", "/v1/catalog"]
        json(200, StatePage.teaser)
      when ["GET", "/v1/state"]
        return state(req)
      when ["GET", "/v1/state.md"]
        return state_md(req)
      when ["GET", "/v1/diff"]
        return diff(req)
      when ["GET", "/v1/watches"]
        return list_watches(req)
      when ["POST", "/v1/watches"]
        return create_watch(req)
      when ["POST", "/v1/brief/query"]
        return brief_query(req)
      else
        if req.get? && (m = req.path.match(%r{\A/v1/explain/([^/]+)/(.+)\z}))
          return explain(m[1], m[2])
        end
        if req.get? && (m = req.path.match(%r{\A/v1/source/(.+)\z}))
          source = Source.find_by(content_hash: m[1])
          return json(404, { "error" => { "code" => "not_found", "message" => "not found" } }) unless source

          return json(200, source.as_meta.merge("as_of" => now, "as_of_data" => iso(source.published_at || source.retrieved_at)))
        end
        if req.get? && (m = req.path.match(%r{\A/v1/rule/(.+)\z}))
          rule = Rule.find_by(code: m[1])
          return json(404, { "error" => { "code" => "not_found", "message" => "not found" } }) unless rule

          data_at = rule.source&.published_at || rule.source&.retrieved_at || rule.updated_at
          return json(200, rule.as_object.merge("as_of" => now, "as_of_data" => iso(data_at)))
        end
        if req.delete? && (m = req.path.match(%r{\A/v1/watches/(.+)\z}))
          return delete_watch(req, m[1])
        end
        if req.get? && (m = req.path.match(%r{\A/v1/brief/(.+)\z}))
          id = m[1]
          as_md = id.end_with?(".md")
          id = id.delete_suffix(".md")
          brief = Brief.find_by(id: id)
          return json(404, { "error" => { "code" => "not_found", "message" => "not found" } }) unless brief

          payload = brief.as_object.merge("as_of_data" => iso(brief.source&.published_at || brief.created_at))
          return as_md ? markdown(AsOf::Markdown.brief(payload)) : json(200, payload)
        end
        if req.get? && (m = req.path.match(%r{\A/v1/filing/(.+)\z}))
          filing = Filing.find_by(accession: m[1])
          return json(404, { "error" => { "code" => "not_found", "message" => "not found" } }) unless filing

          data_at = filing.source.published_at || filing.filed_at
          return json(200, filing.as_extract.merge("as_of" => now, "as_of_data" => iso(data_at)))
        end
        json(404, { "error" => { "code" => "not_found", "message" => "not found" } })
      end
    end

    private

    def state(req)
      json(200, snapshot(req))
    rescue AsOf::State::LowData
      json(503, { "error" => { "code" => "low_data", "message" => "no series history at that time" } })
    end

    def state_md(req)
      markdown(AsOf::Markdown.state(snapshot(req)))
    rescue AsOf::State::LowData
      json(503, { "error" => { "code" => "low_data", "message" => "no series history at that time" } })
    end

    def snapshot(req)
      AsOf::State.snapshot(at: parse_time(req.params["at"]), since: parse_time(req.params["since"]))
    end

    def markdown(text)
      [200, { "content-type" => "text/markdown; charset=utf-8" }, [text]]
    end

    def diff(req)
      since = parse_time(req.params["since"])
      return json(422, { "error" => { "code" => "bad_request", "message" => "since is required" } }) unless since

      watch = nil
      if (wid = req.params["watch_id"])
        watch = Watch.find_by(id: wid)
        return json(404, { "error" => { "code" => "not_found", "message" => "not found" } }) unless watch

        owner = req.env["as_of.customer"]
        return json(404, { "error" => { "code" => "not_found", "message" => "not found" } }) if owner && watch.customer_id != owner.id
      end
      types = req.params["types"]&.split(",")
      entities = parse_json_param(req.params["entities"])
      json(200, AsOf::State.diff(since: since, at: parse_time(req.params["at"]),
                                 watch: watch, types: types, entities: entities))
    rescue AsOf::State::LowData
      json(503, { "error" => { "code" => "low_data", "message" => "no series history at that time" } })
    end

    def explain(target_type, target_id)
      gloss = Gloss.explain!(target_type, target_id)
      json(200, gloss.as_object.merge("as_of" => now, "as_of_data" => gloss.as_of_data && iso(gloss.as_of_data)))
    rescue ActiveRecord::RecordNotFound
      json(404, { "error" => { "code" => "not_found", "message" => "not found" } })
    rescue ArgumentError => e
      json(422, { "error" => { "code" => "bad_request", "message" => e.message } })
    end

    def brief_query(req)
      payload = parse_json_body(req)
      question = payload["question"].to_s
      return json(422, { "error" => { "code" => "bad_request", "message" => "question required" } }) if question.empty?

      brief = Brief.compose!(question: question, customer: current_customer(req))
      json(200, brief.as_object)
    rescue ArgumentError => e
      json(422, { "error" => { "code" => "bad_request", "message" => e.message } })
    end

    def list_watches(req)
      json(200, { "as_of" => now, "as_of_data" => nil, "watches" => current_customer(req).watches.order(:id).map(&:as_watch) })
    end

    def create_watch(req)
      payload = parse_json_body(req)
      entities = payload["entities"]
      return json(422, { "error" => { "code" => "bad_request", "message" => "entities required" } }) if Array(entities).empty?

      watch = current_customer(req).watches.create!(entities: entities)
      json(200, watch.as_watch)
    end

    def delete_watch(req, id)
      watch = current_customer(req).watches.find_by(id: id)
      return json(404, { "error" => { "code" => "not_found", "message" => "not found" } }) unless watch

      watch.destroy!
      json(200, { "ok" => true, "id" => id })
    end

    def current_customer(req)
      req.env["as_of.customer"] || (AsOf.dev_free? && Customer.find_or_create_by!(name: "dev"))
    end

    def parse_json_body(req)
      raw = req.body.read
      req.body.rewind if req.body.respond_to?(:rewind)
      return {} if raw.to_s.empty?

      JSON.parse(raw)
    rescue JSON::ParserError
      {}
    end

    def parse_json_param(value)
      return nil if value.to_s.empty?
      return value if value.is_a?(Array)

      JSON.parse(value)
    rescue JSON::ParserError
      nil
    end

    def parse_time(value)
      return nil if value.to_s.empty?

      Time.iso8601(value)
    rescue ArgumentError
      Time.parse(value)
    end

    def now = iso(Time.now)
    def iso(time) = time.utc.strftime("%Y-%m-%dT%H:%M:%SZ")

    def json(status, data)
      [status, { "content-type" => "application/json" }, [JSON.generate(data)]]
    end
  end
end
