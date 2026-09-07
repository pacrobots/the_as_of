# frozen_string_literal: true

require "test_helper"
require "lightyear/cli/commands/endpoints_command"

# The membrane drift-guard (the schema.rb pattern): `endpoints.md` is the
# COMMITTED map of this app's declared doors — every ingress/egress and what
# governs it, reviewable in a PR like any schema change. Add or change a door
# (mount an endpoint, declare a host, expose an agent via MCP) and this test
# goes red until the snapshot is honest again:
#
#   bin/lightyear endpoints --write
#
# Live rows (connections, providers) are deliberately NOT snapshotted — they
# vary per environment; `bin/lightyear endpoints` shows them at a booted app,
# and `bin/lightyear reach` shows the keys (never snapshotted: authority
# expiring is the feature).
class EndpointsSnapshotTest < Lightyear::Support::TestCase
  SNAPSHOT = File.expand_path("../endpoints.md", __dir__)

  test "endpoints.md matches the declared membrane" do
    assert File.exist?(SNAPSHOT),
           "endpoints.md is missing — generate the committed door map: bin/lightyear endpoints --write"
    assert_equal Lightyear::CLI::Commands::EndpointsReport.snapshot, File.read(SNAPSHOT),
                 "endpoints.md is STALE — a declared door changed; regenerate: bin/lightyear endpoints --write"
  end
end
