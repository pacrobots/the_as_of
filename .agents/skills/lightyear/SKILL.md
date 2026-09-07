---
name: lightyear
description: >-
  Working knowledge for coding agents on a Lightyear app: the blueprint (the
  app's schema.rb), the governed gate, where flesh goes and where it doesn't,
  structure changes by ceremony, and how to run the linter, tests, and
  console. Load this when writing or changing code anywhere in this app.
metadata:
  lightyear_version: "0.0.1"
---

# Working on a Lightyear app

Entry protocol first: if you haven't onboarded — the walkaround, the
checkride, the report card — stop and read `AGENTS.md`. That file is the
ceremony; this skill is the reference you work from once you're rated.

One trust note. This skill reached you because `lightyear new` scaffolded it
into the repo and *your* client discovered it — that's your tool's trust
model, and it's fine for a file born with the app. Lightyear's own resident
agents never load skills ambiently: theirs arrive by declaration (`skill x`
on the agent class), vetted at install. Don't read this scaffold as license
to drop skill folders into a Realm.

## The blueprint is the app's schema.rb

`blueprint.yml` declares the app's structure — agents, charters, entities,
Writs. Read it before your first change the way you'd read `schema.rb`: it
answers "what is this app?" in one file. To see how the declaration differs
from the live app: `bin/lightyear blueprint diff`.

## The dev loop — "did my edit take?" is a poll, not a guess

In development, `bin/lightyear server` watches `app/` and `config/` and
replaces itself on save (boot-before-kill: a broken edit never takes the
server down — the last good server keeps serving while the error reports).
After editing, do NOT restart anything; instead confirm your change took:
read `tmp/dev-status.json` (or `GET /dev/status`) — `"state": "green"` with
a fresh `boot_seconds` means your edit is live; `"state": "red"` carries the
boot error to fix. Gemfile changes are the exception: stop the loop and
`bundle install`.

## Structure changes by ceremony — never hand-edited migrations

The loop is: edit the draft → `bin/lightyear blueprint plan` (the approval
summary a human reads — grants foregrounded, blast radius named) → human
go/no-go → `bin/lightyear blueprint apply` (the additive reconcile; it never
clobbers your code). The human go/no-go is not optional for you: ALWAYS
surface the plan to your human and get an explicit yes before any apply —
when you drive the ceremony, your human's name signs the genesis, so the
decision must be his. Do not write migrations by hand — the migration
classifier polices the ceremony, and a hand-rolled structural migration is
exactly what it exists to catch. If you already changed code that should
have been structure, that isn't a conflict, it's *drift*, and drift is a
first-class state: `bin/lightyear blueprint reflect` folds it back into the
blueprint for the human to approve.

## The gate is the only path to the world

Every agent action is a governed reach: verb-checked against Writs,
recorded on the Ledger, subject to approval holds. Never let agent code
call a connection, an API, or a side-effect directly — a reach that skips
the gate is a bug even when it works. And "may X do Y" is a Writ, never a
flag, an enum, or an if-statement: if you're modeling permission in
application code, stop and reach for a Writ.

When you implement a Tool, declare its nature: `disposition :read` if it
only observes, `disposition :advise` if it only changes what the agent
presents (a Situation revision, a recommendation — nothing the world acts
on without a human deciding), and nothing at all if it commits the business
— the default is `:act`, the most guarded reading. Don't mislabel to slip a
rung: the advise boundary is a fence, and a world-write under it refuses
with the fix named.

## Where flesh goes

Flesh — application code, judgment, prose — belongs in `app/`: agents in
`app/agents`, skills in `app/skills`, conventions in `app/conventions`,
charters in `app/agents/charters`. Structure — a new entity, a new agent, a grant,
a schedule — belongs in the blueprint, arriving by the ceremony above.
When in doubt: if it changes what the app *is*, it's blueprint; if it
changes what the code *does within that shape*, it's yours.

## Before you add or change an entity

Pull the nearest craft exemplar from the shelf and copy its discipline.
Answer the four questions in the blueprint's own words: what identifies ONE
of these (`unique:` — or the deliberate `unique: []`), which relationships
are required (`belongs_to` enforces by default; `optional: true` is a
decision), does it change state over its life (a flow is a CONVENTION and
the status column is its mirror; a fixed set is `one_of:`), and where does
each computed number live (`derived:` — one home; a copy-at-a-moment is a
snapshot and carries its own name). Then run `bin/lightyear blueprint lint`
and treat findings as your review. If the domain fits no exemplar, say so
in your proposal and compose from mechanics — never force the nearest
template onto a new shape.

## Run the checks

- Lint the blueprint: `bin/lightyear blueprint validate`
- Tests: `rake test` (or `bin/lightyear test` where wired)
- The console: `bin/lightyear console` — the inhabited room; `>` drops to
  the metal for Realm/Ledger inspection

## Test with the shipped vocabulary

`test/test_helper.rb` already brings it (`require "lightyear/test_help"`):
`assert_reach_denied`, `assert_awaits_approval`, `assert_announced`,
`script_reply`, `assert_no_llm_calls`. Hand-rolled gate probes and ledger
queries re-invent what the framework hands you.

## The division of labor, verbatim

> Structure and governance flow through the blueprint — via The Engineer or
> the CLI, the developer's choice; flesh belongs to the developer and their
> coding agent; the gate is law for everyone.

This skill steers; the deterministic fitness functions enforce — the
linter, the drift diff, the gate, the migration classifier. You don't have
to remember everything here perfectly, because the machinery will catch
you; you do have to stop fighting it when it does.
