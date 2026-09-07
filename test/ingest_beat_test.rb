# frozen_string_literal: true

require "test_helper"
require "rack/mock"
require "fileutils"
require "as_of/ingest_beat"
require "as_of/ingest_status"
require "as_of/fred_client"

class IngestBeatTest < Lightyear::Support::TestCase
  setup do
    @prev_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    AsOf::IngestBeat.reset_queue!
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear if ActiveJob::Base.queue_adapter.respond_to?(:enqueued_jobs)
    @prev_live, @prev_key = ENV["INGEST_LIVE"], ENV["FRED_API_KEY"]
  end

  teardown do
    ActiveJob::Base.queue_adapter = @prev_adapter
    AsOf::IngestBeat.reset_queue!
    @prev_live ? ENV["INGEST_LIVE"] = @prev_live : ENV.delete("INGEST_LIVE")
    @prev_key ? ENV["FRED_API_KEY"] = @prev_key : ENV.delete("FRED_API_KEY")
  end

  def enable_live!
    ENV["INGEST_LIVE"] = "1"
    ENV["FRED_API_KEY"] = "test-not-a-real-key"
  end

  test "beat is off in test without INGEST_LIVE" do
    refute AsOf::IngestBeat.enabled?
    assert_equal 0, AsOf::IngestBeat.tick!
  end

  test "clock tick enqueues one live FRED job per catalog series when due" do
    enable_live!
    assert AsOf::IngestBeat.enabled?
    assert_no_llm_calls {
      n = AsOf::IngestBeat.tick!(now: Time.now.utc)
      assert_equal 3, n
    }
    jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
    assert_equal 3, jobs.size
    classes = jobs.map { |j| j[:job] || j["job_class"] || j[:job_class] }
    assert_equal [IngestFredJob], classes.uniq
    names = jobs.map { |j|
      args = j[:args] || j["arguments"]
      arg = args.first
      arg.is_a?(Hash) ? (arg["name"] || arg[:name]) : arg
    }
    assert_equal %w[fred.unrate fred.cpi_u fed.funds_upper], names
    assert_equal 0, AsOf::IngestBeat.tick!(now: Time.now.utc), "in-flight guard"
  end

  test "successful fetch makes /v1/ingest 200 and health stays 200" do
    %w[UNRATE CPIAUCSL DFEDTARU].each do |id|
      FetchLog.record!(source_kind: "fred", native_id: id, url: "fred://#{id}",
                       http_status: 200, outcome: "kept", content_hash: "sha256:test")
    end
    status, _h, body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/ingest"))
    assert_equal 200, status
    payload = JSON.parse(body.join)
    assert_equal true, payload["ok"]
    assert payload["gate_started_at"]
    assert payload["gate_due_at"]

    health_status, _, health_body = Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/health"))
    assert_equal 200, health_status
    health = JSON.parse(health_body.join)
    assert_equal true, health["ok"]
    assert_equal true, health.dig("ingest", "ok")
  end

  test "stale last_ok turns ingest 503 while health stays 200" do
    travel_to 9.hours.ago do
      FetchLog.record!(source_kind: "fred", native_id: "UNRATE", url: "fred://UNRATE",
                       http_status: 200, outcome: "new", content_hash: "sha256:old")
      FetchLog.record!(source_kind: "fred", native_id: "CPIAUCSL", url: "fred://CPI",
                       http_status: 200, outcome: "new", content_hash: "sha256:old")
      FetchLog.record!(source_kind: "fred", native_id: "DFEDTARU", url: "fred://FUNDS",
                       http_status: 200, outcome: "new", content_hash: "sha256:old")
    end
    ingest = JSON.parse(Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/ingest"))[2].join)
    assert_equal false, ingest["ok"]
    health = JSON.parse(Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/health"))[2].join)
    assert_equal true, health["ok"]
    assert_equal 200, Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/health"))[0]
    assert_equal 503, Lightyear::Server.app.call(
      Rack::MockRequest.env_for("https://as-of.test/v1/ingest"))[0]
  end

  test "live FRED receipt is kept when the body hash is unchanged" do
    raw = File.binread(File.expand_path("fixtures/fred/unrate.json", __dir__))
    dir = Dir.mktmpdir("tao-fred-live")
    kl = AsOf::FredClient.singleton_class
    kl.alias_method :observations_orig, :observations
    kl.define_method(:observations) do |_series_id|
      { bytes: raw, url: "https://api.stlouisfed.org/fred/series/observations?series_id=UNRATE", status: 200 }
    end
    first = IngestFredJob.perform_now(name: "fred.unrate", store_root: dir)
    second = IngestFredJob.perform_now(name: "fred.unrate", store_root: dir)
    assert_equal first.id, second.id
    assert_equal first.content_hash, second.content_hash
    assert_equal "kept", FetchLog.order(:id).last.outcome
  ensure
    if kl
      kl.alias_method :observations, :observations_orig
      kl.remove_method :observations_orig
    end
    FileUtils.remove_entry(dir) if dir && File.exist?(dir)
  end

  test "Scheduler.tick! rides the ingest beat without an LLM turn" do
    enable_live!
    assert_no_llm_calls {
      Lightyear::Agents::Scheduler.tick!(now: Time.now.utc)
    }
    jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
    assert jobs.any? { |j| (j[:job] || j["job_class"] || j[:job_class]) == IngestFredJob || j["job_class"] == "IngestFredJob" }
  end
end
