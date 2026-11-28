# moonbase skill

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) [![Deploy with your AI agent](https://img.shields.io/badge/deploy%20with-your%20AI%20agent-6E40C9.svg)](https://moonbase.cloud/docs/deploy-from-ai-chat?utm_source=github&utm_medium=moonbase-skill&utm_campaign=gh-launch)

**AI built your app. moonbase runs everything else.**
Hosting, database, domains, analytics, rollbacks, team access — and more. All in one platform, all run by your AI agent.

This repository is the **moonbase Skill**: instructions that teach any AI coding agent how to work with moonbase. With it, your agent can deploy a project, read why a deploy failed, set environment variables, connect a custom domain, roll back to an earlier version, invite teammates, read visitor stats, and download a project's source. Each project can have a managed PostgreSQL database (up to one per project, on every plan, Free included).

**Quick install:** add the connector `https://app.moonbase.cloud/mcp` to your AI tool ([setup per tool](https://moonbase.cloud/docs/deploy-from-ai-chat?utm_source=github&utm_medium=moonbase-skill&utm_campaign=gh-launch)), or get the Skill file for your tool at [moonbase.cloud/connect](https://moonbase.cloud/connect?utm_source=github&utm_medium=moonbase-skill&utm_campaign=gh-launch). Details in [Install](#install).

**Current revision:** `r99` (2026-11-28) · [What changed](CHANGELOG.md) · [All releases](https://github.com/Moonbasecloud/moonbase-skill/releases)

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
| Read projects (granted by default) | See projects, versions, logs, domains, members, visitor numbers, status; check a project before a deploy | `list_projects` `project_info` `deploy_status` `check_project` `list_versions` `list_env` `domain_status` `deploy_logs` `explain_error` `visitor_stats` `launch_check` (per project) `list_members` `import_status` (only where switched on) `platform_status` |
| Deploy and manage projects (granted by default) | Deploy, change settings, domains, variables, members, password protection; open the database export page | `create_project` `deploy` `redeploy` `create_upload` `upload_files` `commit_upload` `rollback` `set_env` `delete_env` `add_domain` `verify_domain` `remove_domain` `pause_project` `resume_project` `set_password` `remove_password` `invite_member` `set_member_role` `remove_member` `export_database` |
| See plan and usage (granted by default) | Plan and usage, read-only | `account_usage` `upgrade_link` |
| Start deleting a project (asked for separately) | Starts a deletion; the person finishes it in the moonbase app | `delete_project` |
| Delete old versions (asked for separately) | Deletes old versions for good, after the person says yes to the exact list | `delete_versions` |
| Replace a database (asked for separately) | Replaces a project's moonbase database with a copy of another PostgreSQL database, after the person says yes to a preview | `import_database` (only where switched on) |
| Download source files (asked for separately) | The raw source ZIP, which may contain secrets | `download_source` |
| No permission | The build guide | `get_build_guide` |

Your client sends the permissions it wants; you approve them in the browser, and you can review connected apps in your account. An assistant that asks for nothing gets only the first three rows, plus the build guide. Some tools are available only on accounts or projects where moonbase has switched them on. Other abilities, such as deleting old versions for good or importing a database, are separate permissions too.

## Install

This repository is also a plugin package: the Skill plus the moonbase connector, in one install. Pick your tool. On first use you sign in to moonbase in the browser and approve access; there is no API key to paste.

**Claude Code** (inside a session):

```text
/plugin marketplace add Moonbasecloud/moonbase-skill
/plugin install moonbase@moonbase
```

**Codex CLI**: run this, then open `/plugins` and install moonbase.

```bash
codex plugin marketplace add Moonbasecloud/moonbase-skill
```

**Gemini CLI:**

```bash
gemini extensions install https://github.com/Moonbasecloud/moonbase-skill
```

**Kiro:** Powers panel, Add Custom Power, Import power from a repository URL, then enter `https://github.com/Moonbasecloud/moonbase-skill`.

**Cursor:** a team admin can import this repository as a team marketplace (Dashboard, Plugins & MCPs, Add Marketplace, Import from Repo). For one person, add the connector: [connect Cursor](https://moonbase.cloud/docs/connect-cursor?utm_source=github&utm_medium=moonbase-skill&utm_campaign=gh-launch).

**Cline:** ask Cline to set up the moonbase MCP server from this repository; the steps it needs are in [`llms-install.md`](llms-install.md).

**Claude and ChatGPT in the browser, VS Code and others:** add the connector `https://app.moonbase.cloud/mcp`, as in [Deploy from any AI chat](https://moonbase.cloud/docs/deploy-from-ai-chat?utm_source=github&utm_medium=moonbase-skill&utm_campaign=gh-launch).

What was tested: on 2026-11-25 a local copy of this package passed `claude plugin validate` and installed with Claude Code 2.1.251 (the Skill and the connector were both listed; sign-in was not part of that test). The Codex, Gemini CLI, Kiro, Cursor and Cline steps follow each tool's published documentation read on that date and have not been run by us yet.

### What the plugin connects to

- **One remote server:** `https://app.moonbase.cloud/mcp`, run by moonbase, with OAuth sign-in. What it may do is in [What the connector can do](#what-the-connector-can-do-and-what-it-may-touch).
- **Nothing else runs on install:** no hooks, no install scripts, no local server, no telemetry in the plugin. The Skill's two helper scripts run only when your agent runs them.
- [Privacy](https://moonbase.cloud/privacy) · [Terms](https://moonbase.cloud/terms) · [Contact](https://moonbase.cloud/contact)

## Install the Skill

The Skill alone, without the plugin:

- **Easiest:** [moonbase.cloud/connect](https://moonbase.cloud/connect?utm_source=github&utm_medium=moonbase-skill&utm_campaign=gh-launch) has the right file for your tool.
- **From this repo:** take the file for your tool from `dist/`, or drop the whole `moonbase/` folder into a Claude-compatible assistant:
  - `AGENTS.md`: the cross-tool standard, for Codex and other agents that read it
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
- **`skills/moonbase/`**: the same Skill, in the folder plugin formats read. Generated at each release; identical to `moonbase/`.
- **Plugin manifests** (version `1.99.0`, from the Skill revision): `plugin.json` and `mcp.json` ([Agent Plugins](https://agent-plugins.org)), `.agents/`, `.claude-plugin/`, `.cursor-plugin/`, `gemini-extension.json`, `lhm.plugin.json`, with `llms-install.md` and `assets/`.
- **`dist/`**: ready-made files per tool, generated from `moonbase/` for each release.
- **`moonbase-guide.md`**: the whole Skill as one file, for chats that take a single file.
- **`build.mjs` / `adapters.json`**: the build that makes every format from `moonbase/` (`node build.mjs kit <folder>`).

## Safe by default

This repo is documentation, plugin manifests, helper scripts and a build script. It holds no secrets. When the helper script packages a project, `.env` files, `node_modules` and `.git` are always left out.

## More

[Docs](https://moonbase.cloud/docs/getting-started) · [llms.txt](https://moonbase.cloud/llms.txt) · [Changelog](https://moonbase.cloud/changelog) · [Status](https://moonbase.cloud/status) · [Security](https://moonbase.cloud/security) · [Support](https://moonbase.cloud/contact)

Found a security issue? Please don't open a public issue. Report it as described at [moonbase.cloud/security](https://moonbase.cloud/security).

## Contributing

Issues and pull requests are welcome. Keep facts accurate against the live product. The files here are published from moonbase's own copy of the Skill at each release, so an accepted change is carried into that copy and comes back in the next revision.

## License

MIT. See [LICENSE](LICENSE).
