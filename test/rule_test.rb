# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "rack/mock"
require "as_of/blob_store"

class RuleTest < Lightyear::Support::TestCase
  setup { @dir = Dir.mktmpdir("tao-rule-blobs") }
  teardown { FileUtils.remove_entry(@dir) }

  test "seed loads usc:26:174 as a pointer with a hashed source" do
    rule = assert_no_llm_calls {
      Rule.seed!(store: AsOf::BlobStore.new(root: @dir)).find { |r| r.code == "usc:26:174" }
    }
    assert rule
    obj = rule.as_object
    assert_equal "usc:26:174", obj["id"]
    assert_equal "in_force", obj["status"]
    assert_equal "2022-01-01", obj["effective_date"]
    assert obj["text_pointer"]["source_id"].start_with?("sha256:")
    assert_equal "26 USC 174", obj["text_pointer"]["fragment"]
    refute_includes obj["title"].downcase, "will "
  end

  test "GET /v1/rule/usc:26:174 returns RuleObject" do
    Rule.seed!(store: AsOf::BlobStore.new(root: @dir))
    status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/rule/usc:26:174"))
    assert_equal 200, status
    payload = JSON.parse(body.join)
    assert_equal "usc:26:174", payload["id"]
    assert payload["text_pointer"]["source_id"]
  end

  test "GET /v1/rule/unknown is not_found" do
    status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/rule/nope"))
    assert_equal 404, status
    assert_equal "not_found", JSON.parse(body.join).dig("error", "code")
  end
end
