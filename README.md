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
bin/asof verify
INGEST_LIVE=1 bin/asof ingest-live   # refused unless the flag is set
```

## Operator (not a product surface)

One clock: `bin/lightyear jobs --clock`. Beats are in `config/cadence.yml`.

| Beat | Config | Rule |
|---|---|---|
| EDGAR | `config/watchlists.yaml` | Job stores raw+hash first. Extract only on a **new** source hash. No LLM on unchanged bytes. |
| FRED | `config/state_series.yaml` | Same. `vintage=official` is a Judge. |
| Federal Register | `config/agencies.yaml` | Phase A required; live poll not wired. Seeded `/v1/rule` is a pointer. |

`CONTACT_EMAIL` is required in production (SEC User-Agent `AsOf/0.1 (+email)`). Set `SEC_USER_AGENT` to override.

Edge rate limit: in-process on `/v1` and `/mcp` (`RATE_LIMIT=1`, `RATE_LIMIT_PER_MIN=120`). DID `/.well-known` is not limited. Multi-node: put the same `429 {"error":{"code":"rate_limited"}}` on the reverse proxy.

`kamal deploy` pre-deploy hook checks identity, TLS, secrets, `CONTACT_EMAIL`. Container boot runs `lightyear ledger verify --json` after `db:prepare`. Alias: `kamal ledger`.

Redirect hosts later (not this sprint): `asofrecord.com`, `asofledger.com`, `citedstate.com` → `theasof.com`.

FRED: this product uses the FRED® API but is not endorsed or certified by the Federal Reserve Bank of St. Louis. Public notices: `GET /v1/notices`. Secrets live in the Realm credentials store (`fred_api_key`), not in git.

## Skyvim staging

Host: `asof.pacrobots.com` (Kamal on `skyvim`, user `bkkriese`). HTTP Basic password in `.kamal/site_password` — any IP, no allowlist. `/v1/health` stays open for the proxy.

```
kamal deploy
```

DNS: `asof.pacrobots.com` A → `5.78.95.164`. `theasof.com` currently does not point at Skyvim.
