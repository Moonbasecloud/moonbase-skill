# moonbase skill

Teach any AI assistant to deploy and manage apps on [moonbase](https://moonbase.cloud) — the hosting platform for apps built with AI.

Ask your AI *"deploy this to moonbase"* and it ships your project to a live HTTPS URL in minutes. This repo is the open guide that makes that work across tools, plus ready-to-use config files for each one.

## What's here

- **`moonbase/`** — the full moonbase skill: `SKILL.md` plus `references/` covering getting started, deploying from an AI agent, building for moonbase, custom domains, versions and rollback, sharing, mission control, billing, troubleshooting, and safety.
- **`dist/`** — ready-made files for each tool, generated from the one source above:
  - `AGENTS.md` — the cross-tool standard
  - `moonbase.mdc` — Cursor rule
  - `CLAUDE-snippet.md` — Claude Code
  - `copilot-instructions.md` — GitHub Copilot
  - `chatgpt-instructions.txt` — ChatGPT custom GPT
  - `gemini-gem-instructions.md` — Gemini Gem
- **`build.mjs` / `adapters.json`** — regenerate `dist/` from the source.

## Use it

Pick the file for your tool from `dist/` (or drop the `moonbase/` skill into a Claude-compatible assistant), then ask your AI to deploy your project to moonbase. You'll need a moonbase API key from your account — the tooling reads it from your environment or your tool's secure storage, and never puts it in chat, a file, or a log.

## Safe by default

Everything here is documentation and a build script. It only ever uses moonbase's public API with **your own** API key. Your `.env` files, `node_modules`, and `.git` are never uploaded. No secrets live in this repo.

## Contributing

Issues and pull requests welcome. Keep facts accurate against the live product, and run `node build.mjs` so `dist/` stays in sync with `moonbase/`.

## License

MIT — see [LICENSE](LICENSE).
