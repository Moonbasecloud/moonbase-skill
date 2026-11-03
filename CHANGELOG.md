# Changelog

All notable changes to the moonbase skill are documented here. Versions track
the live moonbase skill's revision (rNN).

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
