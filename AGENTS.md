# AGENTS.md — standing instructions for coding agents on as_of

This is a **Lightyear** app. Before anything else, one sentence of worldview:
**the host app stays a boring CRUD app; THIS app is the Lightyear side — the
governed operator.** If that sentence surprises you, you are not yet grounded.

## Onboard yourself first — reporting each step to the developer

Do this before your first substantive change, **narrating your progress in the
conversation as you go** (the developer is watching; each numbered step below
gets a short report line from you when you start it and when you finish it):

1. **The walkaround.** Announce you're starting it, then run `lightyear
   walkaround` and read all of it — the worldview, the loop, and the inventory
   table with every primitive's FOR/NOT-FOR intent lines. Report back the two
   or three primitives most relevant to this app's blueprint.
2. **This app.** Read `blueprint.yml` — it is the app's `schema.rb`: the
   declared agents, charters, entities, and Writs. Report what this app *is*
   in one sentence.
3. **The checkride.** Announce you're sitting it, then: `lightyear checkride`
   → answer the questions in `.lightyear/checkride/exam.yml` (closed-book —
   answer from your reading, not by grepping the bank) → write
   `.lightyear/checkride/answers.yml` → `lightyear checkride grade`.
4. **The report card.** Paste the graded REPORT CARD to the developer
   **verbatim** — the developer reads tool output, not your self-assessment.
   If it says FAIL: report the reading list, re-study those guides, re-sit
   (it's free and instant), and report each retake. **Do not start work
   unrated.**
5. **Then take the controls.** Put the trailer line from your report card on
   every PR/commit you author here (e.g. `Checkride: 18/20 (exam v1,
   lightyear 0.0.1)`). After a framework upgrade, run
   `lightyear checkride status` — STALE means re-sit before continuing.

## House rules (what review will hold you to)

- **The two-app boundary is sacred.** Never make the host/domain app
  Lightyear-aware — no gems, no vocabulary, no shared tables. It issued a
  token once; that is its entire involvement.
- **The blueprint changes by ceremony**, never by hand: Draft → plan → human
  go/no-go → reconcile. You write application code; The Engineer evolves the
  blueprint.
- **Never bypass the gate.** Every agent action is a governed reach; a
  side-effect that skips it is a bug even when it works.
- **Writs, not roles.** If you're modeling "may X do Y" with a flag, an enum,
  or an if-statement, stop and reach for a Writ.
- **Test with the shipped vocabulary.** Your `test/test_helper.rb` already
  brings it (`require "lightyear/test_help"`): `assert_reach_denied`,
  `assert_announced`, `assert_awaits_approval`, `script_reply`,
  `assert_no_llm_calls`. Hand-rolled gate probes and ledger queries in tests
  re-invent what the framework hands you — the human's side is
  `guides/source/testing-your-app.md`.
- **Intent lines, or knowing overload.** The inventory's NOT-FOR lines are
  boundaries, not fences — off-label use is welcome as a *choice*. Name the
  trade-off in your PR when you cross one.

## The reference curriculum

Once you're rated, your working reference is the Lightyear skill at
`.agents/skills/lightyear/SKILL.md` — if your tool speaks AgentSkills it has
already offered it to you; if not, read the file. It carries the working
knowledge behind the house rules: the blueprint mechanics, the ceremony, the
gate, where flesh goes, and the shipped test vocabulary.

Humans: your side of this is `guides/source/checkride.md` ("The checkride —
certifying your coding agent").
