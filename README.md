# moonbase skill

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) [![Deploy with your AI agent](https://img.shields.io/badge/deploy%20with-your%20AI%20agent-6E40C9.svg)](https://moonbase.cloud/docs/deploy-from-ai-chat?utm_source=github&utm_medium=moonbase-skill&utm_campaign=gh-launch)

**AI built your app. moonbase runs everything else.**
Hosting, database, domains, analytics, rollbacks, team access — and more. All in one platform, all run by your AI agent.

This repository is the **moonbase Skill**: instructions that teach any AI coding agent how to work with moonbase. With it, your agent can deploy a project, read why a deploy failed, set environment variables, connect a custom domain, roll back to an earlier version, invite teammates, read visitor stats, and download a mission's source. Each mission can have a managed PostgreSQL database (up to one per mission, on every plan, Free included).

**Quick install:** add the connector `https://app.moonbase.cloud/mcp` to your AI tool ([setup per tool](https://moonbase.cloud/docs/deploy-from-ai-chat?utm_source=github&utm_medium=moonbase-skill&utm_campaign=gh-launch)), or get the Skill file for your tool at [moonbase.cloud/connect](https://moonbase.cloud/connect?utm_source=github&utm_medium=moonbase-skill&utm_campaign=gh-launch). Details in [Install the Skill](#install-the-skill).

**Current revision:** `r74` (2026-11-24) · [What changed](CHANGELOG.md) · [All releases](https://github.com/Moonbasecloud/moonbase-skill/releases)

### → [moonbase.cloud](https://moonbase.cloud/?utm_source=github&utm_medium=moonbase-skill&utm_campaign=gh-launch)

## Two ways your agent works with moonbase

1. **The moonbase connector (MCP): recommended.** Add a connector with this address to Claude, ChatGPT, Cursor or another assistant that supports connectors:

   ```text
   https://app.moonbase.cloud/mcp
   ```

   You sign in to moonbase in the browser and approve access. No API key is needed on this path, and nothing secret goes into the chat. Setup steps per tool: [Deploy from any AI chat](https://moonbase.cloud/docs/deploy-from-ai-chat?utm_source=github&utm_medium=moonbase-skill&utm_campaign=gh-launch).
2. **This Skill.** It gives the agent the full guide: how to prepare a project, what each result means and what to tell you. Use it alongside the connector, or on its own in tools without connectors.

An API key is only for your own automation, such as CI or a script that calls the moonbase API. Keep it in a secret manager or an environment variable. Never paste it into a chat.

## Tools with a setup guide

Step-by-step setup for the connector: Claude, ChatGPT, Cursor, VS Code with GitHub Copilot, Gemini CLI and Devin Desktop (formerly Windsurf), in [Deploy from any AI chat](https://moonbase.cloud/docs/deploy-from-ai-chat?utm_source=github&utm_medium=moonbase-skill&utm_campaign=gh-launch). Codex and other agents that read `AGENTS.md` can use the Skill file from `dist/`.

## What the connector can do, and what it may touch

| Permission | What it covers | Tools |
|---|---|---|
| Read (granted by default) | See projects, versions, logs, domains, members, status | `list_missions` `mission_info` `deploy_status` `check_project` `list_versions` `list_env` `domain_status` `deploy_logs` `explain_error` `visitor_stats` `launch_check` (per project) `list_members` `platform_status` |
| Write (granted by default) | Deploy, change settings, domains, variables, members, password protection; open the database export page | `create_mission` `deploy` `create_upload` `rollback` `set_env` `delete_env` `add_domain` `verify_domain` `remove_domain` `pause_mission` `resume_mission` `set_password` `remove_password` `invite_member` `set_member_role` `remove_member` `export_database` |
| Account (granted by default) | Plan and usage, read-only | `account_usage` `upgrade_link` |
| Delete a project (asked for separately) | Starts a deletion; the person finishes it in the moonbase app | `delete_mission` |
| Download source (asked for separately) | The raw source ZIP, which may contain secrets | `download_source` |
| No permission | The build guide | `get_build_guide` |

Your client sends the permissions it wants; you approve them in the browser, and you can review connected apps in your account. An assistant that asks for nothing gets only the first three rows, plus the build guide. Some tools are available only on accounts or projects where moonbase has switched them on. Other abilities, such as deleting old versions for good or importing a database, are separate permissions too.

## Install the Skill

- **Easiest:** [moonbase.cloud/connect](https://moonbase.cloud/connect?utm_source=github&utm_medium=moonbase-skill&utm_campaign=gh-launch) has the right file for your tool.
- **From this repo:** take the file for your tool from `dist/`, or drop the whole `moonbase/` folder into a Claude-compatible assistant:
  - `AGENTS.md`: the cross-tool standard
  - `moonbase.mdc`: Cursor rule
  - `CLAUDE-snippet.md`: Claude Code
  - `copilot-instructions.md`: GitHub Copilot
  - `chatgpt-instructions.txt`: ChatGPT custom GPT
  - `gemini-gem-instructions.md`: Gemini Gem
- **From a release:** each [release](https://github.com/Moonbasecloud/moonbase-skill/releases) carries the `.skill` bundle, the kit ZIP and the single-file guide.
- **For agent builders:** the discovery index is at `https://moonbase.cloud/.well-known/agent-skills/index.json`.

Example: *"Build me a booking app for my yoga studio, with a database for clients and classes, and put it live on moonbase."* Your agent writes the app, moonbase creates its PostgreSQL database on deploy, and you get a live HTTPS link. Then keep going in the same chat: *"Add a page for monthly passes."* *"Connect my domain."* *"Roll back to yesterday's version."*

## Staying up to date

The Skill is versioned with the product (`rNN`). The revision you have is in [`VERSION`](VERSION) and in the "Skill version" section of `moonbase/SKILL.md`. The current published revision is always at:

```text
https://moonbase.cloud/skill/version.json
```

If its `revision` is higher than yours, download the new files from [moonbase.cloud/connect](https://moonbase.cloud/connect) or the latest release. Agents connected through the moonbase connector read the current guide from moonbase itself (the connector's `get_build_guide` tool), so they never depend on an old local copy.

## What's in this repo

- **`moonbase/`**: the Skill: `SKILL.md` plus `references/` (what moonbase is, getting started, deploying for you, building for moonbase, what your app needs, builder platforms, API and CI, custom domains, versions and rollback, sharing and team access, Mission Control, account, billing, troubleshooting, safety and support) and the helper `scripts/`.
- **`dist/`**: ready-made files per tool, generated from `moonbase/` for each release.
- **`moonbase-guide.md`**: the whole Skill as one file, for chats that take a single file.
- **`build.mjs` / `adapters.json`**: the build that makes every format from `moonbase/` (`node build.mjs kit <folder>`).

## Safe by default

This repo is documentation, helper scripts and a build script. It holds no secrets. When the helper script packages a project, `.env` files, `node_modules` and `.git` are always left out.

## More

[Docs](https://moonbase.cloud/docs/getting-started) · [llms.txt](https://moonbase.cloud/llms.txt) · [Changelog](https://moonbase.cloud/changelog) · [Status](https://moonbase.cloud/status) · [Security](https://moonbase.cloud/security) · [Support](https://app.moonbase.cloud/support)

Found a security issue? Please don't open a public issue. Report it as described at [moonbase.cloud/security](https://moonbase.cloud/security).

## Contributing

Issues and pull requests are welcome. Keep facts accurate against the live product. The files here are published from moonbase's own copy of the Skill at each release, so an accepted change is carried into that copy and comes back in the next revision.

## License

MIT. See [LICENSE](LICENSE).
