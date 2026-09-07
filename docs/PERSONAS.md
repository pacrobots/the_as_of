# As-Of — human buyer personas

Agents are customer #1 and are specified in `PRD.md`. This file is humans only.

JSON is source of truth. Nothing here authorizes a magazine, Opinion desk, or a spicier human homepage. A “requirement” is something that makes a card come out, not a feature request to staff writers.

SKUs from PRD: `consumer` · `practitioner` · `seat_pack` · `meter_only` · (later) `instance`.

---

## P-reader — dissatisfied former WSJ subscriber

**Who:** Mid-career tech/finance human. Pays for context and a private forecast. Entertainment = tightness of the object, not takes.

**SKU:** `consumer` ($15–30/mo).

**Will buy when all of these are true:**

- [ ] 12-minute morning board: `/state.md` with series, next dates, and a short delta list
- [ ] Tap-to-explain on a claim, number, rule, or ticker (`/explain`) — ≤8 grounded sentences, no new facts
- [ ] Sunday replay: `/diff?since=-7d` readable as a list
- [ ] Tech-industrial watchlist available (chips, power, §174, export rules, named 10-K capex) — not scene gossip
- [ ] Small brief quota (≤10/mo) in English that still returns `claims[]` + `sources[]`
- [ ] Same facts as the API; homepage not “spicier”
- [ ] Public corrections file (`supersedes`); product is wrong in the open
- [ ] No lecture, no culture-war plot, no “will peak in Q2” as an asserted claim

**Will not buy / will cancel if:** explain becomes a column; forecasts are sold as facts; the board is empty and the lede is spicy.

---

## P-operator — company operator (primary human revenue)

**Who:** FP&A, corp treasury, controller, IR, chief of staff, GC / legal ops, in-house tax. Surprise is expensive. Card is corporate.

**SKU:** `seat_pack` ($2–8k/yr typical; PRD list $3k/10 seats).

**Will buy when all of these are true:**

- [ ] Named entity watches (ticker / CIK / statute / agency) persist across seats
- [ ] `/diff?watch_id=&since=` is the Monday artifact — no “strategy note”
- [ ] 8-K / 10-Q extracts for watched names with hashes and focus filters (`debt|power|buyback|guidance|…`)
- [ ] `/rule` for seeded tax/sec ids with effective date + pointer
- [ ] Explain on a rule or footnote without leaving the object
- [ ] Replay `at=` so last week’s board can be reconstructed
- [ ] Seat keys + shared credit pool + brief cap the CFO can see
- [ ] Expenseable invoice; no issuer payola; no query-log resale
- [ ] SLA-ish freshness on Phase A sources (EDGAR, FR, FRED, Treasury series)

**Will not buy if:** the homepage is clever and the watchlist is empty; ELT essay is the product; they cannot show a hash to the GC.

---

## P-pract — practitioner (tax, audit, outside counsel)

**Who:** Lives in notices and effective dates. Sells memos; will not let you replace the memo.

**SKU:** `practitioner` or sits on `seat_pack`.

**Will buy when all of these are true:**

- [ ] `/rule/{id}` for seeded statutes/notices with `text_pointer`, `effective_date`, `supersedes`
- [ ] Diffs typed to `rule` and `filing` only, filterable
- [ ] Gloss that points; never a substitute opinion letter
- [ ] Hash + URL for the FR / IRS / EDGAR bytes
- [ ] Correction objects leave the old row intact
- [ ] No advice verbs in headlines or claims

**Will not buy if:** IRC is paraphrased without a pointer; confidence is performed instead of sourced.

---

## P-alloc — junior allocator / small-fund analyst

**Who:** RIA, family office, small fund. Needs a prior the PM can audit. Chamath without the podcast.

**SKU:** `consumer` plus meter, or a seat on `seat_pack`.

**Will buy when all of these are true:**

- [ ] `/state` + `/diff` before the morning meeting
- [ ] Filing extracts with evidence ids a PM can click
- [ ] Briefs that list `exposures[]` and `open_questions[]` instead of a call
- [ ] `at=` replay for “what did we know Tuesday”
- [ ] Same timestamp as every other customer (no faster private tape)
- [ ] Meter or pack that does not require Bloomberg procurement

**Will not buy if:** you call rates; you cannot replay; hashes are missing.

---

## P-staff — public-sector analyst (not the Secretary)

**Who:** Treasury/committee/agency or state budget shop. Needs a join across official text and private filings.

**SKU:** later `instance`. Schema-compatible at MVP; do not block MVP on procurement.

**Will buy when all of these are true:**

- [ ] Dated join: Treasury/FRED series + FR/IRS + corporate capex footnotes
- [ ] Official series marked `vintage=official` vs `delayed`
- [ ] Replay and `supersedes` that survive FOIA-style scrutiny
- [ ] Bearer credits or invoice; **no** x402 from a .gov laptop in v1
- [ ] Query logs not sold; no preferential `as_of`
- [ ] Briefs that do not tell Treasury what to do

**Will not buy if:** you are a prettier wrap of Fiscal Data alone; logs leak who queried which CUSIP.

---

## P-principal — fund principal (Chamath-shaped)

**Who:** Decision-maker with a fleet. Buys a prior for a model and a show. Not the mass market.

**SKU:** `seat_pack` + `meter_only` for agents.

**Will buy when all of these are true:**

- [ ] Hashed extracts of hyperscaler / industrial 10-K capex and power sentences
- [ ] Minutes-scale `/state` update when Fed/Treasury prints; vintage labeled
- [ ] Worked correction: object after `supersedes`, who got the new id
- [ ] Replay of a dated board
- [ ] Explicit non-coverage list (depth over fake breadth)
- [ ] Same JSON/timestamp as competitors’ agents
- [ ] Unit cost + LLM budget cap visible; no payola
- [ ] No advice clause a fund counsel would flag
- [ ] Five historical “filing date vs media date” examples, not hypotheticals

**Will not buy if:** you sound like his podcast; you are late official series with adjectives.

---

## P-cabinet — institutional debt manager (Bessent-shaped)

**Who:** Principal who already publishes half the board. Buys the *other* half and the join.

**SKU:** `instance` only. Not an MVP revenue plan.

**Will buy when all of these are true:**

- [ ] Auction/refunding/buyback dates as typed `next_dates`, not a recap of his speech
- [ ] Cross-department diffs (IRS, CBO-adjacent public text, Fed, OFAC/BIS later, FR tariffs)
- [ ] Private-sector demand side he does not print (corporate issuance, capex)
- [ ] Reconstruct board morning vs afternoon of an unexpected notice
- [ ] Identical public timestamp; no private faster feed
- [ ] Records-friendly correction trail
- [ ] Procurement path: no wallet micropay from a cabinet office
- [ ] Kill test passed: not only a wrap of Fiscal Data + FRED

**Will not buy if:** you editorialize issuance policy; you cannot show three hashes that jointly change the borrowing picture.

---

## Crossover matrix

Rows = requirement. Check = that persona will not pay without it (or equivalent).  
`○` = wants it, not a dealbreaker for first purchase.  
blank = not that persona’s gate.

| Requirement | P-reader | P-operator | P-pract | P-alloc | P-staff | P-principal | P-cabinet |
|---|---|---|---|---|---|---|---|
| Same JSON for humans and agents | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Hashed primary source on load-bearing facts | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| No unnamed sources / no payola / no log resale | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| No advice verbs; forecasts only in `open_questions` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Corrections append (`supersedes`), no silent rewrite | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `as_of` + `as_of_data` on every object | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `/state` board (official series + next dates) | ✓ | ✓ | ○ | ✓ | ✓ | ✓ | ✓ |
| `/diff` since T (field-level) | ○ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Replay `at=` (point-in-time board) | ○ | ✓ | ○ | ✓ | ✓ | ✓ | ✓ |
| `/explain` gloss on object | ✓ | ○ | ✓ | ○ | ○ | ○ | ○ |
| Human `state.md` / 12-minute render | ✓ | ○ | ○ | ○ | | | |
| Entity **watches** + diff-by-watch | ○ | ✓ | ○ | ✓ | ○ | ✓ | ○ |
| `/filing` extract + focus filters | ○ | ✓ | ○ | ✓ | ○ | ✓ | ✓ |
| `/rule` pointer + effective date | ○ | ✓ | ✓ | ○ | ✓ | ○ | ✓ |
| `POST /brief/query` (quota) | ✓ | ○ | ○ | ✓ | ○ | ✓ | ○ |
| Tech-industrial default watch seed | ✓ | ○ | | ○ | | ✓ | ○ |
| Sunday / weekly replay pack | ✓ | ✓ | ○ | ○ | ○ | ○ | ○ |
| Seat keys + shared credits + invoice | | ✓ | ○ | ✓ | ✓ | ✓ | ✓ |
| Identical timestamp for all customers | ○ | ○ | ○ | ✓ | ✓ | ✓ | ✓ |
| Freshness SLA on Phase A ingest | ○ | ✓ | ○ | ○ | ✓ | ✓ | ✓ |
| No x402 required (bearer/invoice works) | ✓ | ✓ | ✓ | ✓ | ✓ | ○ | ✓ |
| Air-gapped / instance / no wallet | | | | | ✓ | | ✓ |
| Explicit non-coverage list | ○ | ○ | ○ | ○ | ○ | ✓ | ✓ |
| Join across Treasury series + private 10-Ks | | ○ | | ✓ | ✓ | ✓ | ✓ |

**Read of the table (build priority):**

1. Shared core (every checked column): hashed objects, no payola, no advice, `supersedes`, `as_of`, `/state`. Already PRD MVP.
2. Highest crossover *beyond* the core: `/diff`, watches, `/filing`, `/rule`, replay `at=`.
3. Reader-specific but cheap: `/explain` + `state.md`. Do these; they also help P-pract and P-operator.
4. Low crossover, do not staff: cabinet instance, private faster feeds, strategy notes, Opinion.

If a proposed feature is not a ✓ in at least two MVP personas (P-reader, P-operator, P-pract, P-alloc), it waits.
