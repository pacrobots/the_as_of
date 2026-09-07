# frozen_string_literal: true

require "json"
require "rack"
require_relative "state"
require_relative "meter"
require_relative "rate_limit"

module AsOf
  # JSON-RPC MCP edge wrapping the same domain reads as /v1. Menu is the tool
  # list; writes still go through Meter + Brief.compose / Watch CRUD.
  class Mcp
    TOOLS = [
      { "name" => "tao/state", "description" => "StateSnapshot JSON" },
      { "name" => "tao/diff", "description" => "Diff JSON; requires since" },
      { "name" => "tao/filing", "description" => "FilingExtract by accession" },
      { "name" => "tao/rule", "description" => "RuleObject by id" },
      { "name" => "tao/source", "description" => "SourceMeta by content hash" },
      { "name" => "tao/explain", "description" => "Gloss for target_type/target_id" },
      { "name" => "tao/brief_query", "description" => "Compose a Brief from a question" },
      { "name" => "tao/watches_list", "description" => "List watches" },
      { "name" => "tao/watches_create", "description" => "Create a watch" },
      { "name" => "tao/watches_delete", "description" => "Delete a watch" }
    ].freeze

    def self.call(env) = new.call(env)

    def call(env)
      req = Rack::Request.new(env)
      if (limited = AsOf::RateLimit.check!(req))
        return limited
      end
      return json_rpc(nil, error: { code: -32600, message: "POST JSON-RPC" }) unless req.post?

      if (denied = AsOf::Meter.before(mapped_req(req)))
        return denied
      end

      msg = JSON.parse(req.body.read)
      result = dispatch(msg, req)
      status, headers, body = json_rpc(msg["id"], result: result)
      AsOf::Meter.after(mapped_req(req), status, headers, body)
    rescue JSON::ParserError
      json_rpc(nil, error: { code: -32700, message: "parse error" })
    rescue ArgumentError => e
      json_rpc(nil, error: { code: -32602, message: e.message })
    end

    def dispatch(msg, req)
      case msg["method"]
      when "initialize"
        { "protocolVersion" => "2024-11-05", "serverInfo" => { "name" => "as-of", "version" => "0.1.0" },
          "capabilities" => { "tools" => {} } }
      when "tools/list"
        { "tools" => TOOLS }
      when "tools/call"
        call_tool(msg.dig("params", "name"), msg.dig("params", "arguments") || {}, req)
      else
        raise ArgumentError, "unknown method"
      end
    end

    def call_tool(name, args, req)
      args = args.transform_keys(&:to_s)
      content = case name
      when "tao/state"
        AsOf::State.snapshot(at: parse_time(args["at"]), since: parse_time(args["since"]))
      when "tao/diff"
        raise ArgumentError, "since required" unless args["since"]
        AsOf::State.diff(since: Time.iso8601(args["since"]), at: parse_time(args["at"]))
      when "tao/filing"
        Filing.find_by!(accession: args.fetch("accession")).as_extract
      when "tao/rule"
        Rule.find_by!(code: args.fetch("id")).as_object
      when "tao/source"
        Source.find_by!(content_hash: args.fetch("id")).as_meta
      when "tao/explain"
        Gloss.explain!(args.fetch("target_type"), args.fetch("target_id")).as_object
      when "tao/brief_query"
        Brief.compose!(question: args.fetch("question"), customer: req.env["as_of.customer"]).as_object
      when "tao/watches_list"
        customer(req).watches.order(:id).map(&:as_watch)
      when "tao/watches_create"
        customer(req).watches.create!(entities: args.fetch("entities")).as_watch
      when "tao/watches_delete"
        w = customer(req).watches.find_by(id: args.fetch("id"))
        raise ActiveRecord::RecordNotFound unless w
        w.destroy!
        { "ok" => true, "id" => args["id"] }
      else
        raise ArgumentError, "unknown tool"
      end
      { "content" => [{ "type" => "text", "text" => JSON.generate(content) }] }
    rescue ActiveRecord::RecordNotFound
      raise ArgumentError, "not found"
    end

    def customer(req)
      req.env["as_of.customer"] || (AsOf.dev_free? && Customer.find_or_create_by!(name: "dev"))
    end

    def parse_time(value)
      return nil if value.to_s.empty?
      Time.iso8601(value)
    rescue ArgumentError
      Time.parse(value)
    end

    # Price MCP tool calls as their /v1 twins so the meter stays one table.
    def mapped_req(req)
      req
    end

    def json_rpc(id, result: nil, error: nil)
      body = { "jsonrpc" => "2.0", "id" => id }
      body["result"] = result if error.nil?
      body["error"] = error if error
      [200, { "content-type" => "application/json" }, [JSON.generate(body)]]
    end
  end
end
