# As-Of (theasof.com)

The agents' ledger of public record. Dated, hashed, diffable.

Canonical spec: [`docs/PRD.md`](docs/PRD.md). If a feature is not in that file, do not build it.

Standalone Lightyear Realm. Host: `theasof.com`. Module: `AsOf`.

```
bundle install
bin/lightyear db:prepare
bin/lightyear test
bin/lightyear server
```

`GET /v1/health`, `/v1/catalog` (series names only), `/v1/state.md`, and `/mcp` (JSON-RPC tools wrapping the same reads) are on `Lightyear::Server.app`.

```
bin/asof ingest-fixture edgar test/fixtures/edgar/0001045810-24-000123.txt
bin/asof ingest-fixture fred test/fixtures/fred/unrate.json --name fred.unrate
bin/asof snapshot
INGEST_LIVE=1 bin/asof ingest-live   # refused unless the flag is set
```
