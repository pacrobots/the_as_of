# frozen_string_literal: true

require "test_helper"
require "rack/mock"
require "as_of/judge"

class GlossTest < Lightyear::Support::TestCase
  setup { Rule.seed! }

  test "GET /v1/explain/rule/usc:26:174 returns Gloss with grounded sentences" do
    status, _h, body = assert_no_llm_calls {
      Lightyear::Server.app.call(
        Rack::MockRequest.env_for("https://as-of.test/v1/explain/rule/usc:26:174"))
    }
    assert_equal 200, status
    payload = JSON.parse(body.join)
    assert_equal "rule", payload["target_type"]
    assert_equal "usc:26:174", payload["target_id"]
    refute_empty payload["source_ids"]
    sentences = payload["text"].split(/(?<=[.!?])\s+/)
    assert_operator sentences.size, :<=, 8
    rule = Rule.find_by!(code: "usc:26:174")
    corpus = rule.as_object.to_json
    assert_empty AsOf::Judge.ungrounded_numbers(payload["text"], corpus + payload["source_ids"].join)
    refute AsOf::Judge.advice?(payload["text"])
  end

  test "explain is cached on the same prompt and input" do
    a = Gloss.explain!("rule", "usc:26:174")
    b = Gloss.explain!("rule", "usc:26:174")
    assert_equal a.id, b.id
  end

  test "unknown target is 404" do
    status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/explain/rule/nope"))
    assert_equal 404, status
    assert_equal "not_found", JSON.parse(body.join).dig("error", "code")
  end
end
