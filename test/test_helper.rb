# frozen_string_literal: true

ENV["LIGHTYEAR_ENV"] ||= "test"
# The deterministic LLM: in tests your agents reason on the scripted TestFake —
# no key, no network, no bill. Script it per-test with `script_reply`.
ENV["LIGHTYEAR_LLM_ADAPTER"] ||= "test_fake"

require_relative "../config/lightyear"

# The shipped test vocabulary (the rails/test_help cousin): assert_announced,
# assert_reach_denied, assert_awaits_approval, assert_remembered, script_reply,
# travel_to, assert_queries_count, … — see the "Testing your app" guide.
require "lightyear/test_help"
require "minitest/autorun"
require "logger"

ActiveJob::Base.logger = Logger.new(IO::NULL)

Lightyear::Support::TestCase.fixture_paths           = [File.expand_path("fixtures", __dir__)]
Lightyear::Support::TestCase.use_transactional_tests = true
