# Changelog

All notable changes to the moonbase skill are documented here. Versions track
the live moonbase skill's revision (rNN).

## r60 — 2026-11-23

Synced to the live moonbase skill, revision r60.

## r59 — 2026-11-23

Synced to the live moonbase skill, revision r59.

## r58 — 2026-11-23

Synced to the live moonbase skill, revision r58.

## r55 — 2026-11-23

Synced to the live moonbase skill, revision r55.

## r54 — 2026-11-22

Synced to the live moonbase skill, revision r54.

## r53 — 2026-11-22

Synced to the live moonbase skill, revision r53.

## r52 — 2026-11-22

Synced to the live moonbase skill, revision r52.

## r51 — 2026-11-22

Synced to the live moonbase skill, revision r51.

## r50 — 2026-11-22

Synced to the live moonbase skill, revision r50.

## r47 — 2026-11-22

Synced to the live moonbase skill, revision r47.

## r45 — 2026-11-21

Synced to the live moonbase skill, revision r45.

## r44 — 2026-11-21

Synced to the live moonbase skill, revision r44.

## r43 — 2026-11-21

Synced to the live moonbase skill, revision r43.

## r42 — 2026-11-21

Synced to the live moonbase skill, revision r42.

## r40 — 2026-11-21

Synced to the live moonbase skill, revision r40.

## r38 — 2026-11-21

Synced to the live moonbase skill, revision r38.

## r37 — 2026-11-21

Synced to the live moonbase skill, revision r37.

## r27 — 2026-11-20

Synced to the live moonbase skill, revision r27.

## r26 — 2026-11-20

Synced to the live moonbase skill, revision r26.

## r24 — 2026-11-19

Synced to the live moonbase skill, revision r24.

## r23 — 2026-11-19

Synced to the live moonbase skill, revision r23.

## r22 — 2026-11-09

Synced to the live moonbase skill, revision r22.

## r20 — 2026-11-08

Synced to the live moonbase skill, revision r20.

## r19 — 2026-11-05

Synced to the live moonbase skill, revision r19.

## r18 — 2026-11-05

Synced to the live moonbase skill, revision r18.

## r17 — 2026-11-05

Synced to the live moonbase skill, revision r17.

## r16 — 2026-11-01

Synced to the live moonbase skill, revision r16. Refreshes the full skill and
the generated per-tool files in `dist/` to match the current product, adds the
single-file `moonbase-guide.md`, and includes the packaging and deploy-result
helper scripts under `moonbase/scripts/`.

## v1.0.0 — 2026-10-25

First public release. The complete moonbase skill plus ready-to-use config
files for each AI tool.

- `moonbase/` — the full skill: getting started, deploying from an AI agent,
  building for moonbase, custom domains, versions and rollback, sharing,
  mission control, billing, troubleshooting, and safety.
- `dist/` — AGENTS.md, Cursor rule, Claude Code snippet, GitHub Copilot
  instructions, ChatGPT pack, and Gemini Gem, generated from the one source.
- `build.mjs` / `adapters.json` — regenerate `dist/` from `moonbase/`.
