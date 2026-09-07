# As-Of — AI agent buyer personas

Humans are in `PERSONAS.md`. This file is agents that can call HTTP without a person in the loop.

An agent “buys” when a tool call returns a typed object cheaper than browsing EDGAR/FR/FRED itself *and* cheaper than a hallucinated summary. If the agent still has to scrape, we failed.

Do not invent routes. Gates refer to `PRD.md` surface only.

SKUs the agent actually hits: `meter_only` key on a human/firm account, or x402 when enabled. Quotas belong to the parent customer.

---

## A-prior — state-vector agent

**Who:** Long-running loop that conditions every other task on a board (rates, dates, official series). First call of the day.

**Parent payer:** P-alloc, P-principal, P-operator, sometimes P-reader.

**Will pay when all of these are true:**

- [ ] `GET /v1/state` returns typed `NumberFact[]` + `next_dates[]` with `vintage` and `source_id`
- [ ] `as_of` + `as_of_data` present; clock is UTC
- [ ] Optional `since` attaches `deltas[]` so it need not store the last board itself
- [ ] Cheap class; idempotent GET; no HTML
- [ ] Missing series omitted, never invented
- [ ] 401/402 machine-readable when unpaid

**Will not pay if:** narrative wrap of the same FRED page; stale unmarked `delayed` as `official`.

---

## A-watch — monitor / cron agent

**Who:** Wakes on a timer. Asks “what changed for my entities since T.” Closest to a paid habit.

**Parent payer:** P-operator, P-alloc, P-pract, P-staff.

**Will pay when all of these are true:**

- [ ] Persistent `POST /v1/watches` owned by the parent key
- [ ] `GET /v1/diff?watch_id=&since=` returns only changed paths
- [ ] Empty diff is 200, not an error
- [ ] Entity types: ticker, cik, statute, agency
- [ ] Stable `path` strings it can hash locally
- [ ] Cheap class so a 15-minute poll does not bankrupt the budget

**Will not pay if:** it must re-download every filing to learn that nothing moved.

---

## A-extract — filing agent

**Who:** Given an accession or ticker+form, must pull debt / power / buyback / guidance with evidence. Will fetch EDGAR raw if we lie.

**Parent payer:** P-operator, P-alloc, P-principal, P-cabinet (join side).

**Will pay when all of these are true:**

- [ ] `GET /v1/filing/{accession}` with `focus=`
- [ ] Each number has `source_id`; bytes hash exists at `/source/{id}`
- [ ] Ungrounded numbers stripped
- [ ] Form whitelist documented (10-K, 10-Q, 8-K, 4, 13F-HR)
- [ ] 404 on unknown accession, not a guessed extract

**Will not pay if:** summary drops the footnote it was asked for.

---

## A-rule — in-force text agent

**Who:** Tax, securities, or policy subgraph. Must not paraphrase the Code as if it were the Code.

**Parent payer:** P-pract, P-operator, P-staff.

**Will pay when all of these are true:**

- [ ] `GET /v1/rule/{id}` with seeded ids (`usc:26:174`, FR doc ids)
- [ ] `text_pointer` + `effective_date` + `supersedes`
- [ ] Gloss via `/explain/rule/{id}` does not replace the pointer
- [ ] Status `in_force|proposed|withdrawn|unknown` explicit

**Will not pay if:** the body is an essay and the pointer is missing.

---

## A-brief — decision-object agent

**Who:** Multi-hop question (“who is exposed if this 8-K is true?”). Expensive class. Should be rare.

**Parent payer:** P-reader (quota), P-alloc, P-principal, P-operator.

**Will pay when all of these are true:**

- [ ] `POST /v1/brief/query` returns Brief schema, not markdown-as-truth
- [ ] `claims[]`, `numbers[]`, `exposures[]`, `open_questions[]`, `sources[]`
- [ ] Every number appears in source bytes
- [ ] `low_confidence` still 200 with questions filled
- [ ] Quota error is `quota_exceeded`, machine-readable
- [ ] `GET /v1/brief/{id}` fetch-by-id for later turns

**Will not pay if:** headline is a call; sources empty; numbers invented.

---

## A-gloss — UX sidecar agent

**Who:** Lives next to a human UI or another agent’s message. The Grok-button.

**Parent payer:** P-reader, P-pract; anyone rendering objects.

**Will pay when all of these are true:**

- [ ] `GET /v1/explain/{type}/{id}` 
- [ ] ≤8 sentences; `source_ids` required
- [ ] Cache so repeat clicks are cheap
- [ ] Cheap class
- [ ] No new facts vs target object

**Will not pay if:** gloss contradicts `/rule` or invents a rate.

---

## A-replay — audit / research agent

**Who:** “What did the ledger know at Tuesday 16:00Z?” Compliance, PM review, staff memo trail.

**Parent payer:** P-alloc, P-principal, P-staff, P-cabinet, P-operator.

**Will pay when all of these are true:**

- [ ] `at=` on GET `/state`, `/diff`, `/rule`, `/filing`
- [ ] `503 low_data` if history missing — no fake reconstruction
- [ ] Superseded objects still fetchable by id
- [ ] Source rows immutable by hash

**Will not pay if:** only “now” exists.

---

## A-runtime — platform / catalog agent

**Who:** Not a beat agent. Claude/Codex/Cursor/MCP host, internal harness, x402 bazaar listing. Buys distribution: one tool schema, many child agents.

**Parent payer:** the platform or the firm that embeds you.

**Will pay (or list you) when all of these are true:**

- [ ] Stable OpenAPI at `/v1/openapi.json`
- [ ] `/v1/prices` machine-readable
- [ ] Bearer works without x402; x402 spec-faithful when flagged
- [ ] Error codes enumerated
- [ ] No HTML login wall in front of JSON
- [ ] Tool names map 1:1 to routes (`state`, `diff`, `rule`, `filing`, `brief_query`, `explain`)
- [ ] Redistribution terms in prices/SKU text (internal use vs resale)

**Will not list if:** schema changes weekly without version; 402 dialect is private.

---

## A-ingest-competitor — other data agents

**Who:** Another vendor’s agent checking whether to wrap you. Not a target. Do not optimize for them.

**Do not build:** bulk dump, firehose, or free replay of the whole corpus.

---

## Crossover matrix

| Requirement | A-prior | A-watch | A-extract | A-rule | A-brief | A-gloss | A-replay | A-runtime |
|---|---|---|---|---|---|---|---|---|
| JSON + `as_of` / `as_of_data` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Hashed `source_id` on facts | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Machine errors (402/404/422/quota) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| No invented series/numbers | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| OpenAPI + `/prices` | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ✓ |
| Bearer key (x402 optional) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `GET /state` typed board | ✓ | ○ | | | ○ | | ✓ | ✓ |
| `GET /diff` + empty-200 | ○ | ✓ | ○ | ○ | ○ | | ✓ | ✓ |
| Persistent watches | | ✓ | | | | | ○ | ○ |
| `GET /filing` + focus | | ○ | ✓ | | ✓ | | ○ | ✓ |
| `GET /rule` + pointer | | ○ | | ✓ | ✓ | ○ | ○ | ✓ |
| `POST /brief/query` + GET by id | | | ○ | ○ | ✓ | | ○ | ✓ |
| `GET /explain` cached gloss | | | | ○ | ○ | ✓ | | ✓ |
| `at=` replay / `low_data` | ○ | ○ | ○ | ○ | ○ | | ✓ | ○ |
| Cheap class for polls | ✓ | ✓ | | | | ✓ | | ○ |
| Expensive class isolated to brief | | | | | ✓ | | | ○ |
| Immutable source rows + supersedes | ○ | ○ | ✓ | ✓ | ✓ | ○ | ✓ | ○ |

**Read of the table:**

1. Every agent shares: JSON, hashes, errors, no invention, bearer.
2. Habit revenue = **A-watch + A-prior** (cheap, frequent).
3. Willingness-to-pay spike = **A-extract + A-rule + A-brief** (standard/expensive).
4. Human-adjacent = **A-gloss** (cheap, high click).
5. Trust = **A-replay**.
6. Distribution = **A-runtime** (OpenAPI/prices/version). Ship schema stability for them; do not custom-build a marketplace.

If a proposed agent feature is not a ✓ for A-prior or A-watch **and** at least one of A-extract / A-rule / A-brief, it waits.

Parent mapping (who pays the key):

| Agent | Typical human parent |
|---|---|
| A-prior | P-alloc, P-principal, P-operator |
| A-watch | P-operator, P-pract, P-alloc |
| A-extract | P-operator, P-alloc, P-principal |
| A-rule | P-pract, P-operator, P-staff |
| A-brief | P-reader (cap), P-alloc, P-principal |
| A-gloss | P-reader, P-pract |
| A-replay | P-alloc, P-staff, P-principal |
| A-runtime | platform or firm IT |
