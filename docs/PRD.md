# As-Of (TAO) — PRD + build order

Audience: coding agent implementing this repo. If a feature is not in this file, do not build it. Do not invent a CMS, magazine, Opinion desk, or marketing site.

Canonical host (v1 public): `theasof.com`  
JSON reads: `https://theasof.com/v1`  
MCP: `https://theasof.com/mcp`  
Product string: `As-Of` — `The agents' ledger of public record. Dated, hashed, diffable.`  
User-Agent for fetchers: `AsOf/0.1 (+CONTACT_EMAIL)`  
Do not use hostname `agentledger.com` / `agentledger.io`.

Owned aliases (redirect only): `asofrecord.com`, `asofledger.com`, `citedstate.com` if pointed here.

## 0. Mission (constraints)

- Customer #1: software agents, pay per request (credits + x402).
- Customer #2: humans reading a derived render of the same JSON. Same facts. No spicier homepage.
- Object: dated, hashed, diffable state over US public text (filings, rules, official series) + briefs + gloss bound to those objects.
- Honesty: no unnamed sources as load-bearing facts; no issuer-sponsored objects; no selling query logs; no preferential `as_of` by customer; corrections append (`supersedes`), never silent rewrite.
- Forecasts belong in `open_questions[]`, never as asserted claims. A sentence that predicts (“will peak”, “buy”, “overweight”) is a bug. Drop it or move it to `open_questions`.
- Deterministic index first. LLM only on hash-changed extract/gloss/brief, behind a Judge.

## 1. Non-goals

- Real-time exchange ticks / SIP / licensed market data.
- General web crawl or paywalled news ingest.
- Opinion, world desk, lifestyle, strategy notes, ELT memos, weekly essays.
- Comments, social, events, merch, “village” graphs.
- Investment-advice verbs.
- Multi-jurisdiction boil-the-ocean.
- Fine-tuning a foundation model.
- FedRAMP / air-gapped .gov instance (post-MVP; query logs are not a product).
- Building for students, free-scoop journalists, or scene traffic.
- Putting the public record in Lightyear Memory, or blobs on the Ledger.

## 2. Personas (GTM constraints, not extra features)

Implement SKUs in §7. Do not add persona-specific content types.

| Code | Who | Consume | Do not build |
|---|---|---|---|
| P-agent | External LLM agent | MCP tools + `/v1` reads + explain | Custom narrative |
| P-operator | FP&A, treasury, IR, GC, tax | watches + diffs + filings + rules + explain | Weekly strategy essay |
| P-reader | Human | `state.md` / MSV StatePage, explain, small brief quota | Opinion, unlimited briefs |
| P-pract | Tax/audit/counsel | `/rule`, rule diffs, explain | Paraphrase without pointer |
| P-alloc | Junior allocator / small fund | same as operator | Rate calls |
| P-staff | Agency analyst | same JSON, later instance | x402 from .gov; query-log resale |

Public MVP sells: **P-agent credits**, **P-reader consumer**, **P-operator seat pack** (N keys + watch list). P-staff is schema-compatible only.

## 3. Substrate

Standalone Lightyear app. Realm = TAO. `lightyear new` from `pacificrobots/lightyear`. Ruby, ActiveRecord, Postgres 16 in production (SQLite ok in test). Blob: `BLOB_DIR` or `s3://`. IDs: ULID. Time: UTC ISO-8601 `Z`. Hash: `sha256:` + hex of raw bytes. Config: env + `config/*.yaml`.

Lightyear primitives used as-is: Agents, Charters, Writs, Reach, Jobs, Cadence, Initiative, Workflow, Memory, Ledger, Connections, MCP membrane, A2A/MTP, Commerce (x402 + Stripe), MSV, Eval. Do not reimplement them.

Host Rack apps join `Lightyear::Server.app` via `Server.mount` (same stack as `lightyear server` and `config.ru`; see pacificrobots/lightyear#55). No ungoverned write controllers. Writes are Reach or MCP `tools/call` (same gate).

### 3.1 Three stores (invariant)

| Store | Owns | May not own |
|---|---|---|
| Domain AR (`app/models`) | Public record: Source, Blob, Filing, SeriesSnapshot, Rule, Brief, Gloss, Watch, CreditKey | Staff opinions |
| Memory | Staff beliefs about entities (`cik:…`, `ticker:…`, `usc:…`), `derived_from` Ledger/source hashes, beat notes | What `/v1/state` returns |
| Ledger | Who ingested/extracted/published/approved/superseded, under which Writ | Raw filings, series values |

Public JSON is assembled from domain rows only. Memory is how staff know. Ledger is how acts prove.

### 3.2 App tree

```
app/
  agents/          # EdgarReporter, MacroReporter, RulesReporter, GlossWriter, BriefDesk
  models/          # domain SoR
  jobs/            # ingest fetch+hash only (no LLM)
  workflows/       # extract/judge/publish
  skills/
  conventions/     # tao.state.v1, tao.brief.v1 (post-MVP ok to defer; MCP tools ship first)
  msv/             # StatePage + explain verb
config/
  sources.yaml
  state_series.yaml
  rules_seed.yaml
  watchlists.yaml
  agencies.yaml
  routes.rb        # stub until framework composes it
config.ru          # run Lightyear::Server.app
config/initializers/v1.rb   # Server.mount "/v1"
db/migrate/
schemas/           # JSON Schema copies of §4
test/fixtures/{edgar,fred,fr}/
docs/PRD.md
```

### 3.3 Staff (commission these; do not add desks)

| Agent | Beat | Trigger | LLM? |
|---|---|---|---|
| EdgarReporter | whitelist issuers; 10-K, 10-Q, 8-K, 4, 13F-HR | Cadence; Workflow only on new source hash | extract claims only |
| MacroReporter | `state_series.yaml` + Treasury refunding | Cadence on calendar/daily | no; vintage=official is a Judge |
| RulesReporter | FR agencies.yaml + rules_seed.yaml | daily FR poll | no on seed; LLM only for gloss |
| GlossWriter | explain cache | on demand | yes, task `gloss` |
| BriefDesk | `brief/query` | Initiative per question | yes, after retriever Tool |

Charter floor (every agent; Policy > Charter > Character):

```
Only use provided source text. Unknown → open_questions.
Never invent numbers. A number not present as substring/regex in source bytes is dropped.
No advice verbs. No forecasts as asserted claims.
Corrections append supersedes; never rewrite a published row.
```

`requires_approval` on publish of `status=low_confidence` claims/briefs. Unattended approval = deny.

### 3.4 Ingest vs turns

- **Job**: HTTP GET via Connection, write blob, hash, insert Source. Hash unchanged → stop. Never call a model.
- **Workflow**: extract → Judge → domain write + Ledger announce. Fan-out per accession. Crash-resume.
- **Cadence**: fires the Job; enqueues Workflow only when Job reports a new hash.
- **Initiative**: BriefDesk one-shot goals, `block!` when a human must answer.

Connections (onboard once): `:edgar`, `:fred`, `:treasury`, `:federal_register` as `source_kind: :http`. UA from env. Retry 429/5xx. Unique `(source_kind, native_id)`. Hash change → new `source_id`, keep old row.

### 3.5 Memory

Entity handles: `cik:{cik}`, `ticker:{sym}`, `usc:{title}:{section}`, `accession:{acc}`, `series:{name}`, `rule:{id}`. Optional `resource:` `lightyear://host/Issuer/{id}` etc. Exact handle only; no fuzzy merge. Org recall: `realm.knowledge_of(entity)` for desk, never as the public `/state` payload.

Gloss cache key: `(target_type, target_id, as_of_data, prompt_hash)`. Persist `model`, `prompt_hash`, `input_hash` on generated domain rows.

## 4. Wire schemas

JSON object field names are contract. Write JSON Schema under `/schemas`. Domain models serialize to these. Every list response includes:

```json
{ "as_of": "datetime", "as_of_data": "datetime" }
```

`as_of` = server assemble time. `as_of_data` = max source `published_at`/`filed_at` used.  
Optional query `at` (ISO): assemble the object **as it was known at `at`** from snapshot/history tables. If history missing, `503` `low_data` — do not invent. Implement `at=` on domain history, not by folding the Ledger.

### 4.1 EntityRef

```json
{
  "type": "ticker|cik|agency|statute|docket|series|cusip|lei|other",
  "id": "string",
  "name": "string|null"
}
```

### 4.2 NumberFact

```json
{
  "name": "string",
  "value": "string|number|null",
  "unit": "string",
  "vintage": "official|derived|estimated|delayed",
  "as_of": "datetime",
  "source_id": "string"
}
```

### 4.3 Claim

```json
{
  "id": "string",
  "text": "string",
  "status": "asserted|retracted|superseded|disputed",
  "confidence": 0.0,
  "evidence": ["source_id or source_id#fragment"],
  "entities": ["EntityRef"]
}
```

`confidence` in [0,1]. Deterministic extract ≥ 0.9. LLM-only cap 0.75 until `verified_by` set.

### 4.4 SourceMeta

```json
{
  "id": "string",
  "kind": "edgar|federal_register|fred|treasury|irs|fomc|courtlistener|other",
  "url": "string",
  "retrieved_at": "datetime",
  "published_at": "datetime|null",
  "hash": "sha256:hex",
  "bytes": 0,
  "license": "public_domain|us_gov|unknown"
}
```

### 4.5 StateSnapshot

```json
{
  "as_of": "datetime",
  "as_of_data": "datetime",
  "series": ["NumberFact"],
  "next_dates": [{"date": "date", "why": "string", "source_id": "string"}],
  "deltas": ["DiffItem"]
}
```

v1 series — only if a fetcher exists in `config/state_series.yaml`:

- `fed.funds_upper`
- `ust.10y` `ust.2y` `ust.3m`
- `fred.unrate` `fred.cpi_u`
- `treasury.refunding_next` (date)
- `eia.wti` `eia.hhub` (Phase C)
- omit `fx.dxy` unless a first-party public series exists

Never invent a series.

### 4.6 Diff

```json
{
  "since": "datetime",
  "as_of": "datetime",
  "items": [
    {
      "op": "add|replace|remove",
      "path": "string",
      "entity": "EntityRef|null",
      "before": {},
      "after": {},
      "source_id": "string|null"
    }
  ]
}
```

`path` examples: `/series/ust.10y/value`, `/rule/usc:26:174/effective_date`, `/filing/{acc}/facts/0`.

### 4.7 RuleObject

```json
{
  "id": "string",
  "title": "string",
  "status": "in_force|proposed|withdrawn|unknown",
  "effective_date": "date|null",
  "supersedes": ["string"],
  "text_pointer": {"source_id": "string", "fragment": "string|null"},
  "exposures": ["string"],
  "open_questions": ["string"],
  "as_of": "datetime"
}
```

v1 `/rule` may be `config/rules_seed.yaml` + FR pointer. Full USC parse is not MVP.

### 4.8 FilingExtract

```json
{
  "accession": "string",
  "cik": "string",
  "form": "string",
  "filed_at": "datetime",
  "facts": ["NumberFact"],
  "claims": ["Claim"],
  "sections": [{"name": "string", "source_id": "string", "fragment": "string"}],
  "as_of": "datetime"
}
```

### 4.9 Brief

```json
{
  "id": "string",
  "as_of": "datetime",
  "event_type": "string",
  "headline": "string",
  "entities": ["EntityRef"],
  "jurisdictions": ["US-federal"],
  "claims": ["Claim"],
  "numbers": ["NumberFact"],
  "exposures": ["string"],
  "next_dates": [{"date": "date", "why": "string"}],
  "open_questions": ["string"],
  "status": "ok|low_confidence|corrected",
  "supersedes": ["string"],
  "sources": ["SourceMeta"]
}
```

`headline` ≤ 140 chars. No advice verbs.

### 4.10 Gloss

```json
{
  "id": "string",
  "target_type": "claim|number|rule|filing|series|entity|brief",
  "target_id": "string",
  "text": "string",
  "as_of": "datetime",
  "source_ids": ["string"],
  "status": "ok|low_confidence"
}
```

`text` ≤ 8 sentences. Every sentence supportable by `source_ids`. No new numbers not in the target object or its sources.

### 4.11 Watch

```json
{
  "id": "string",
  "customer_id": "string",
  "entities": ["EntityRef"],
  "created_at": "datetime"
}
```

`GET /v1/diff?watch_id=` is the operator product.

## 5. Surfaces

Auth: `Authorization: Bearer <credit_key|lym_>` or x402 when `X402_ENABLED=true`. Same JSON either way. MCP callers are governed Agents (Writ-filtered menu). Walk-up registration is opt-in, parks on the approval desk.

### 5.1 JSON reads (must ship; curl + CI)

| Method | Path | Price class | Notes |
|---|---|---|---|
| GET | `/v1/health` | free | |
| GET | `/v1/openapi.json` | free | generated from `/schemas` |
| GET | `/v1/prices` | free | §7 |
| GET | `/v1/state` | cheap | `since`, `at` |
| GET | `/v1/state.md` | cheap | render from JSON only |
| GET | `/v1/diff` | cheap | `since` required; `entities`, `types`, `watch_id`, `at` |
| GET | `/v1/rule/{id}` | standard | |
| GET | `/v1/filing/{accession}` | standard | `focus=debt\|power\|buyback\|guidance\|risk\|officers\|all` |
| GET | `/v1/source/{source_id}` | cheap | meta + hash + url, not bytes by default |
| GET | `/v1/brief/{id}` | cheap | |
| GET | `/v1/brief/{id}.md` | cheap | |
| POST | `/v1/brief/query` | expensive | body `{question, entities, max_sources}` — implement as Reach/BriefDesk, not a raw controller |
| GET | `/v1/explain/{target_type}/{target_id}` | cheap | Gloss; generate+cache if missing |
| POST | `/v1/watches` | cheap | body `{entities}` — Reach |
| GET | `/v1/watches` | cheap | |
| DELETE | `/v1/watches/{id}` | cheap | Reach |

`/v1` is a thin Rack map over domain queries. Do not add a second write stack.

### 5.2 MCP (P-agent door)

Expose tools that return the §4 objects: `tao/state`, `tao/diff`, `tao/filing`, `tao/rule`, `tao/source`, `tao/explain`, `tao/brief_query`, `tao/watches_*`. Menu = caller Writs. Price via `Commerce.price`. x402 Gate: declared price, never the request’s claimed amount; verify then settle then credit; no model on the money path.

### 5.3 Other doors

- MSV: one StatePage that fetches the same snapshot JSON; explain control calls `/explain` / `tao/explain` and displays `Gloss.text` unedited. No CMS.
- A2A/MTP: did:web + Agent Card on. TAO Conventions (`tao.state.v1`, `tao.brief.v1`) post-MVP unless a peer needs them to ship §14.
- Operator: Lightyear Surfaces (approvals, roster, ledger tail). Do not build a parallel admin API.

### 5.4 Post-MVP (do not start before §14 public gate)

- x402 live (flag exists in MVP as stub if facilitator not configured)
- HTML beyond MSV StatePage / `state.md`
- EIA / CourtListener / FOMC full text
- Gov instance / SSO
- Preferential feeds (never)

## 6. Ingest order

Fetcher contract: store raw + hash + url + retrieved_at **before** parse.

**Phase A — required for public MVP**

1. SEC EDGAR (`data.sec.gov`, company_tickers.json). Forms: `10-K`, `10-Q`, `8-K`, `4`, `13F-HR`. Rate-limit.
2. FRED (`FRED_API_KEY`) for `state_series.yaml`.
3. Treasury Fiscal Data or documented Treasury JSON/CSV for yields + refunding next date. Prefer API.
4. Federal Register API. Agency filter in `config/agencies.yaml` default: SEC, IRS, Treasury, Federal Reserve System, CFTC, FTC, DOE.

**Phase B — public+1, not gate**

5. `rules_seed.yaml` expanded + eCFR/govinfo pointers.
6. IRS notices index (HTML hashed).
7. FOMC calendar + statement URLs.
8. Default watchlist seed: tech-industrial tickers in `config/watchlists.yaml` (capex/power/174 relevant). Short list.

**Phase C**

9. EIA WTI / HH.
10. CourtListener for configured docket ids only.

## 7. Billing and SKUs

`GET /v1/prices`:

```json
{
  "currency": "USD",
  "routes": [
    {"path": "/v1/state", "class": "cheap", "usd": "0.03"},
    {"path": "/v1/diff", "class": "cheap", "usd": "0.05"},
    {"path": "/v1/rule/{id}", "class": "standard", "usd": "0.15"},
    {"path": "/v1/filing/{accession}", "class": "standard", "usd": "0.20"},
    {"path": "/v1/explain/{t}/{id}", "class": "cheap", "usd": "0.02"},
    {"path": "/v1/brief/query", "class": "expensive", "usd": "0.25"}
  ],
  "skus": [
    {"id": "consumer", "usd_month": "20", "included_usd": "5", "brief_cap_month": 10},
    {"id": "practitioner", "usd_month": "80", "included_usd": "20", "brief_cap_month": 40},
    {"id": "seat_pack", "usd_year": "3000", "seats": 10, "included_usd": "200", "brief_cap_month": 200},
    {"id": "meter_only", "usd_month": "0", "included_usd": "0", "brief_cap_month": null}
  ]
}
```

Domain tables: `customers`, `keys` (`key_hash`), `credits` (`balance_usd`), `sku_entitlements`, `usage_events` (`route, status, price, customer_id, created_at`). Deduct after 2xx only. `brief_cap_month` on `brief/query` and `tao/brief_query`. `DEV_FREE=1` skips charge. `X402_ENABLED=false` by default; if true, missing pay → HTTP 402 per current x402 spec (use `Commerce::X402::Gate`). Stripe `charge!` funds SKU credit grants. Do not blur: Budget = LLM tokens; Allowance = Realm money; CreditKey = customer prepaid. Never sell `usage_events`. Never give customer A an earlier `as_of_data` than customer B.

SKU is a credit grant + cap. Same routes/tools.

## 8. LLM

```
extract_llm(task: "claim"|"section"|"brief"|"gloss", text: str, schema: dict) -> dict
```

Implemented as Counsel inside the relevant Workflow/agent, not a global helper that bypasses the gate. Prompt floor = §3.3 Charter floor. Number check in a Judge: value must appear as substring/regex in source bytes or drop. `LLM_MAX_USD_PER_DAY` is a Realm Budget; at limit pause + escalate, never silent overrun. Gloss uses task `gloss` only. Tests: `script_reply` / `assert_no_llm_calls` on deterministic paths.

## 9. Render

- `GET /v1/state.md` and `GET /v1/brief/{id}.md` — from JSON. Zero extra facts.
- MSV StatePage (or `GET /` static shell) fetches `/v1/state.md` with a key prompt or public teaser of series names only (no live paid numbers without auth).
- Explain displays `Gloss.text`. Do not edit it.

## 10. Errors

```json
{"error": {"code": "not_found|payment_required|rate_limited|bad_request|upstream|low_data|quota_exceeded", "message": "string"}}
```

HTTP: 401/402 auth, 404, 422, 429, 503 upstream/low_data. Rate limits at the edge (Rack/proxy), not a second permission system.

## 11. Acceptance tests (CI)

Fixtures only. No live SEC in CI. Nightly `INGEST_LIVE=1` is separate. HTTP and MCP tools must return the same §4 objects.

1. Ingest fixture 8-K → stable hash → `GET /v1/filing/{acc}` has fact or claim whose evidence source exists. Job path: `assert_no_llm_calls`.
2. FRED fixture → `/v1/state` has `fred.unrate` `vintage=official`.
3. Mutate series → `/v1/diff?since=` `replace` on that path.
4. `POST /v1/brief/query` on fixture Item 2.02 → every `numbers[].value` in fixture bytes; `sources` nonempty.
5. No auth → 401 or 402.
6. Balance 0 → 402.
7. Same bytes re-ingest → no duplicate hash.
8. OpenAPI lists MVP routes including explain + watches. MCP menu for a granted caller includes the matching tools.
9. `GET /v1/explain/rule/usc:26:174` returns Gloss; sentences have `source_ids`; no number absent from target/sources.
10. Consumer key with `brief_cap_month=1`: second `brief/query` → 402/429 `quota_exceeded`.
11. Create watch on fixture CIK → `/v1/diff?watch_id=&since=` 200.
12. Correction: insert brief B `supersedes` A, `GET` A still exists unchanged. Ledger has both publish events.

## 12. Build order (do not skip)

Each sprint: tests for that sprint green before next.

**S0** `lightyear new`. Realm, genesis, SQLite locally, `Server.mount "/v1"`, `/v1/health`, `/v1/openapi.json` stub, `DEV_FREE`.

**S1** Source + blob CAS + hash uniqueness. Put/get bytes. Re-ingest same bytes → one row.

**S2** EDGAR Connection + ingest Job + fixture 8-K → FilingExtract headers (company, form, date). `/v1/filing/{acc}`.

**S3** FRED Connection + SeriesSnapshot history + `/v1/state` + `/v1/diff` + `at=` for series.

**S4** `rules_seed.yaml` + `/v1/rule`. `usc:26:174` + optional FR fixture pointer.

**S5** CreditKey, prices, SKUs, quota. Bearer keys. x402 Gate behind `X402_ENABLED`. Stripe charge funds SKUs.

**S6** Watch CRUD + diff filter.

**S7** Commission EdgarReporter + FilingExtract Workflow (deterministic then LLM + number Judge). BriefDesk + `brief/query`. Cadence on new hashes only.

**S8** GlossWriter + cache + `/v1/explain`. Memory entity handles for fixture CIKs/rules.

**S9** `state.md` / `brief.md`. MSV StatePage. CLI: ingest fixture, snapshot, ingest-live (guarded). MCP membrane tools wrapping the same reads.

**S10** Cron/Cadence docs in README (operator-only): EDGAR whitelist + FRED + FR. Edge rate limits. `CONTACT_EMAIL`. Redirect hosts later. `ledger verify` on deploy.

Stop. Phase B/C after public gate. Do not add desks, Conventions, or A2A product flows before the gate unless a §11 test requires them.

## 13. Env

```
DATABASE_URL
BLOB_DIR
FRED_API_KEY
SEC_USER_AGENT
CONTACT_EMAIL
DEV_FREE
X402_ENABLED
LLM_API_KEY
LLM_MAX_USD_PER_DAY
CREDIT_DEFAULT_USD
PUBLIC_BASE_URL=https://theasof.com
```

Plus Lightyear Realm/credentials store (LLM provider, Stripe, x402 wallet) — never plaintext in production.

## 14. Success and public MVP gate

Ship publicly when **all** are true:

1. Agent with a consumer, meter, or `lym_` key can call state/diff/filing/brief_query/explain (MCP or `/v1`) and get hashed sources.
2. Operator can set a watch and pull a diff without a human writing copy.
3. Reader can open `/v1/state.md` (authenticated) or StatePage and tap explain on one rule or claim.
4. Ingest Jobs for Phase A run unattended for 7 days in staging with no silent hash overwrite. Staging week is FRED-only (`GET /v1/ingest` 503 when stale); live EDGAR/FR wait.
5. Tests 1–12 green.
6. `usage_events` exist and are not exposed by any route/tool.
7. No Opinion, no ungrounded numbers in fixtures or live smoke.
8. Cadences do not LLM-turn on unchanged hashes.

Persona success:

- P-agent: pays a meter call without a human account UI (x402 or Bearer).
- P-operator: one watch + Monday diff is enough to expense a pack.
- P-reader: 12-minute board + gloss; still no forecast claims.
- P-pract: `/rule` pointer works for seeded ids.
- P-alloc / P-staff: same JSON; no extra surface.

Not success: pageviews, anti-WSJ positioning, podcast tone.

## 15. Definition of done (v1 public)

Phase A ingest live (Jobs). Five original reads + explain + watches + credits. MCP tools for the same. Markdown/MSV render. Corrections via `supersedes`. Replay `at=` at least for series. Staff: the five agents in §3.3, Charters loaded, low-confidence publish held.

That is the product. Everything else waits.
