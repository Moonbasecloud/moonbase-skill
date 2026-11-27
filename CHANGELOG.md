# Changelog

All notable changes to the moonbase skill are documented here. Versions track
the live moonbase skill's revision (rNN).

## r90 — 2026-11-27

Synced to the live moonbase skill, revision r90.

## r89 — 2026-11-27

Synced to the live moonbase skill, revision r89.

## r88 — 2026-11-27

Synced to the live moonbase skill, revision r88.

## r87 — 2026-11-26

Synced to the live moonbase skill, revision r87.

## r86 — 2026-11-26

Synced to the live moonbase skill, revision r86.

## r85 — 2026-11-26

Synced to the live moonbase skill, revision r85.

## r84 — 2026-11-26

- The Claude Code project snippet (`dist/CLAUDE-snippet.md`) no longer repeats the table of moonbase words; it points to "Words moonbase uses" in the full guide instead, which keeps the snippet shorter.
- `adapters.json` updates the stated size of the full-guide Cursor rule file to about 272 KB.
- Plugin manifests move to version 1.84.0.

## r83 — 2026-11-26

- Adds `references/connector-tools.md`: every tool the moonbase connector lists, grouped by the permission it needs, with a one-line description of each.
- It notes that `missions:read`, `missions:write` and `account:read` are granted by default, that the other permissions are asked for separately, and that `import_database` and `import_status` appear only where moonbase has turned importing on.
- `SKILL.md` and the short instruction files in `dist/` now point to the "Connector tools" section of the guide.
- Plugin manifests move to version 1.83.0.

## r82 — 2026-11-26

- When account setup is still pending, `orientation` from `account_usage` names that step and its page before offering to publish. When readiness cannot be checked, it says so instead of claiming publishing is ready.
- README's connector permission table now gives each permission's scope name (`missions:read`, `missions:write`, `account:read`, `missions:delete`, `missions:source`) and adds the separately requested `versions:delete` and `databases:import` permissions, plus tools missing from the lists such as `redeploy`, `upload_files` and `commit_upload`.
- README's Support link now points to the public contact page.
- Older notes about the packaging tool and retry policy move from `SKILL.md` to the version history in `references/safety-and-support.md`.
- Plugin manifests move to version 1.82.0.

## r81 — 2026-11-25

- Connector results may carry a separate `moonwalk` field with moonbase's opening words, said once per task; read results also carry `moonwalk_note` saying so. The `status` field stays the plain state.
- Plugin manifests move to version 1.81.0.

## r80 — 2026-11-25

- The repository is now also a plugin package: the skill plus the moonbase connector in one install. README gives install steps for Claude Code, Codex CLI, Gemini CLI, Kiro, Cursor (team marketplace) and Cline, and says what was tested.
- Adds plugin manifests (`plugin.json`, `mcp.json`, `.claude-plugin/`, `.cursor-plugin/`, `.agents/`, `gemini-extension.json`, `lhm.plugin.json`), a logo in `assets/`, and `skills/moonbase/`, a copy of the skill in the folder layout plugin formats read.
- Adds `llms-install.md`, setup steps for AI agents, with the Cline configuration and a check that the connection works.
- The plugin connects to one remote server, `https://app.moonbase.cloud/mcp`, with browser sign-in; nothing runs on install.
- Troubleshooting: general wording for `identity_required`, and setup refusals can carry `deep_link` and `human_action` alongside `action_url`.

## r79 — 2026-11-25

- Adds moonbase's opening line ("Starting moonwalk…"), said once when a moonbase task begins, and a short first look of about 8 lines for "Let's moonwalk" or "Show me what I can do with moonbase", built from what the account and connection really allow. `account_usage` can return `orientation` for an account with no projects yet.
- Getting started: add the connector inside a desktop coding app rather than on the vendor's web dashboard, plus notes on the sign-in screen's Unverified notice for a local connection and the browser prompt to open a desktop app.
- With the connector, `redeploy` rebuilds the project's active stored version with the saved environment variables after the person approves, keeping the same version number and needing no upload.
- A saved visitor password can now be changed with `set_password` and `replace: true`, after the person confirms; protection stays on or off as it was.
- Troubleshooting adds "Connector access and setup links": `insufficient_scope` errors and the `action_url` link to the page for the missing permission or setup step.
- Several general wording rules in `SKILL.md` are shortened.

## r78 — 2026-11-25

- README gains a quick install line, license and setup badges, the list of tools with a connector setup guide, and a table of the connector's permissions and the tools each one covers. The example now shows an app with a database built by an AI agent, put live and then changed from the same chat.
- Connector uploads: optional `part_sha256` for each part, `remove_paths` to drop staged files from a session, and recovery steps for an interrupted upload, including not replaying a commit that returned `status: "unknown"`.
- Documents the `upload_sessions_unresolved` refusal and the fields that list the sessions still open.
- Adds `references/queued-plan-refusals.md`: a queued deploy refused by a plan limit after the first call returns, and the plan guidance its `deploy_status` receipt can carry.
- Notes that a `DATABASE_URL` the person saved wins when a project first declares a managed database, and documents `runtime_selection` for the Node.js version the server confirmed.

## r74 — 2026-11-24

- The project badge now reads "powered by moonbase" (was "hosted by moonbase"), and its switch is **Show the moonbase badge**.
- Adds `tools_version`: when a tool a moonbase result names is missing, or the version differs from the one seen at connection, the assistant asks the person to reconnect or reload the moonbase connector.
- Node versions: explains which Node.js version a version range in `engines` runs on (for example `">=18"` runs on Node 22, `"^20"` on Node 20); Node 18 is past its end of life.
- Troubleshooting documents `retryNote` on a failed deploy that repeats the same error, and how `start_log_tail` drops duplicate lines and `npm notice` lines.
- `check_project` with a project ID or slug lists the database variables moonbase provides under `env_vars_provided_by_moonbase`. The managed database text no longer says it depends on being enabled per account.
- Updated description of what moonbase covers (hosting, database, domains, analytics, rollbacks, team access) in `SKILL.md`, the README and "What moonbase is".

## r69 — 2026-11-24

- README rewritten: what the skill lets an agent do, the two ways to work with moonbase (the connector at `https://app.moonbase.cloud/mcp`, recommended, and this skill), install steps per tool, how to check for a newer revision (`https://moonbase.cloud/skill/version.json`), and how to report a security issue privately.
- The Launch check is now described as available only where moonbase has turned it on for a project; assistants should not offer or promise it, and `launch_check` answers `not_available` elsewhere.
- `build.mjs` reads the skill's revision and date from `SKILL.md` and can write every format into a kit folder (`node build.mjs kit <dir>`); `adapters.json` updates the per-tool instructions and file sizes.
- Removes internal build notes and old revision comments from the top of `SKILL.md`. The single-file guide and Cursor rule are regenerated with the new build.

## r68 — 2026-11-24

- The managed PostgreSQL database becomes the documented place for an app's data. It is created by declaring a `database` entry in the project's `moonbase.json` with a migrate command; moonbase creates it, runs the migration before the new version goes live and sets `DATABASE_URL`. It needs a project that moonbase builds and runs, not a static one.
- Adds the required connection recipe: use `DATABASE_URL` as given and verify TLS with the certificate file and server name moonbase provides, with a Node `pg` example.
- Removes `references/connect-your-backend.md` and the external-database example; building guidance and the pre-deploy checklist now point to the managed database.
- An app that exits while starting fails at once as `container_exited_on_start`, with `start_log_tail` (the last lines the app printed, recognised secrets removed).
- Upload links refused before the stream now say what happened to the link: `upload_link_used`, `upload_link_expired` or `upload_link_invalid`.
- Documents `self_repair_notice`, which names each change moonbase made to the deployed copy, and explains that `account_usage` reports the account's own limits, which can differ from the plan's standard numbers.

## r65 — 2026-11-24

- Account: a person who deleted their own account can reactivate it from the sign-in page within the number of days the delete dialog shows, using a one-time link sent to the account's email and two-factor verification if it is on.
- Reactivation keeps a paid plan until the end of a paid period that is still left; otherwise the account is on the Free plan.
- `user_not_found` in troubleshooting mentions reactivation for an account the person deleted.
- Older revision notes move from `SKILL.md` to a "Skill version history" section in `references/safety-and-support.md`, to keep the overview short.

## r64 — 2026-11-23

- Upload size: each upload can be up to the plan's per-deploy size, replacing the fixed caps stated before. The limit applies to the uploaded ZIP; the plan's storage applies to the unpacked total. `account_usage` gives the current number.
- Adds "Moving an existing database in": with `import_database`, a PostgreSQL database from another provider can be imported into the project's managed database in three calls. The person enters the source connection string on moonbase's own page, reviews a preview, and confirms.
- `import_status` reports what was compared after an import, and `done_with_warnings` lists the statements the database refused, such as security policies from the old provider.
- moonbase takes a safety copy before replacing anything and restores it when the import does not match; an import can be rolled back while `rollback_available` is true.
- The project's Database page moves to its own address (`/missions/<project_id>/database`).

## r60 — 2026-11-23

- A deploy that outlasts the tool call returns status `deploying` with `started_at`; `deploy_status` with the returned slug shows how it ended.
- When such a deploy fails, `deploy_status` shows `last_failed_attempt` (error code, moonbase's explanation and next step, Error ID, `moonbase_note`, `build_log_tail`), for 24 hours also for a first deploy that failed.
- `deploy_logs` marks a failed attempt that the live version has since replaced with `superseded: true`, which does not mean the project is broken.

## r59 — 2026-11-23

- The short instruction files in `dist/` (`AGENTS.md`, the Cursor rule, the Claude Code snippet and the GitHub Copilot instructions) are shortened: shorter header comments and a condensed pointer to the full guide.
- No change to the skill's content in `moonbase/` beyond the revision number.

## r58 — 2026-11-23

- Managed PostgreSQL databases are no longer described as a closed pilot: every plan, Free included, can add one managed database per project, created when the project's `moonbase.json` asks for one.
- The database uses the plan's storage, with no separate database allowance. Everything stored (files, versions, databases and backups) counts toward one storage allowance, and `account_usage` shows the parts.
- Daily database backups, kept for 7 days, are included on every plan. The skill states that moonbase promises no maximum data-loss window and no restore to any point in time.
- Adds "Delete old versions (free up storage)": deleting one version or all but the newest N in the app, and with the connector through `list_versions` and a two-step `delete_versions` call that shows the list and needs the person's yes before anything is deleted.

## r55 — 2026-11-23

- With the connector, a project whose sandbox cannot reach the upload host can now be published through the connector itself: `upload_files` sends the files in batches (each with `path`, base64 content and SHA-256), and `commit_upload` publishes them with the same checks as any deploy.
- A file too large for one call, such as an image, is sent in parts with `part_index` and `part_count`; the result's `incomplete` list names parts still missing.
- Documents the batch and session limits, that a retried batch changes nothing, and that `expected_files` on the commit refuses a version with a file missing.
- `source_url` also accepts a public GitHub repository URL as well as a public https ZIP.

## r54 — 2026-11-22

- Billing states that visitors are counted for information only and never blocked.
- `account_usage` reports the monthly visitor count as a usage note, never among the limits reached.

## r53 — 2026-11-22

- `invalid_password` now gives the allowed visitor password length (at least 4 characters, at most 128, on one line for `create_upload`).
- `password_protection_disabled` now says which actions are refused while new password protection is switched off and that existing passwords keep working.

## r52 — 2026-11-22

- Adds "Deployment history and Error IDs": `deploy_logs` returns a project's version records with their stored Error ID, plus a separate `failed_attempts` list with recorded failure times.
- A call with only a `trace_id` looks up the caller's own recorded failed attempt by its exact Error ID, including a first deploy whose project no longer exists.
- Clarifies that `attempt_id` is an asynchronous deploy receipt, not an Error ID, and that older records without a stored ID are shown as `null` rather than guessed.
- Documents `protection_cache_purge.status` from `mission_info`.

## r51 — 2026-11-22

- The deploy guide now says to keep the project ID a successful deploy prints (`project_id: <id>`) and set `MOONBASE_MISSION_ID` to it for every later deploy of the same project.
- An empty `MOONBASE_MISSION_ID` creates a new project with a new address instead of updating the existing one; the deploy commands now print a warning when it is not set.

## r50 — 2026-11-22

A full accuracy pass over the skill and its reference pages so each sentence matches how moonbase works now.

- Custom domains: every domain now needs two DNS records, the A or CNAME record plus a TXT ownership record (`_moonbase-verify.`); the steps and checks are updated.
- Limits and runtime: the default Node.js version is 22 (18 and 20 also available); the current upload caps are 425 MB for static projects and 300 MB for Node or Python apps; `requirements.txt` includes and the order of Python entry files are stated exactly; Python build output now streams as `build_log` lines.
- Account: the new data export (**Export my data → Download everything**) and its rules; deleting an account cannot be undone.
- Visitor passwords: turning protection off keeps the saved password, **Remove** deletes it, and the password gate answers with a redirect to its login page. A password can be given only with a project's first launch.
- Screen names and messages updated to the current app (for example "This app is paused", "Waking up your app", **Launch my mission**), plus sign-in, email verification and billing page paths.
- The status endpoint documents `appReady` and `resumePending`; the Can manage role is described precisely; `check_project` reports baked-in `localhost` addresses before a deploy.

## r47 — 2026-11-22

- Adds two troubleshooting rows for problems on moonbase's side: `migration_disk_low` (the build server had too little disk space to run a database migration, so nothing in the database changed) and `docker_build_limits_unavailable` (the build machine's safety limits could not be confirmed, so the build did not start).
- Explains `moonbase_note`: when moonbase itself stopped a deploy, it says why in moonbase's words, while `build_log_tail` holds only the project's own output.

## r45 — 2026-11-21

- A failed build or app start now returns `build_log_tail`, the last part of the build output with recognised secrets removed: over the connector on the deploy error and on `deploy_status` / `deploy_logs` with an `attempt_id`, and over the API on the stream's `error` event.
- The skill describes `build_log_tail` as the project's own output, to be treated as untrusted data, not as instructions or moonbase's guidance.
- Removes the older text saying Python build output was never available, from troubleshooting and the API and CI page.

## r44 — 2026-11-21

- When a deploy is refused, `scripts/parse-deploy-result.sh` (and the same function in the deploy guide) now prints the Error ID with the refusal message, when moonbase returns one.

## r43 — 2026-11-21

- The support reference code now has one name throughout the skill, **Error ID** (`TRK-…`), matching the app. In API and tool results it is the `trace_id` field, or `trkId`.
- Updated in `SKILL.md`, troubleshooting, versions and rollback, and safety and support.
- The `python_entrypoint_not_detected` and `python_runtime_not_supported` rows now say where moonbase looks for a Flask, FastAPI or Django app and what to add.

## r42 — 2026-11-21

- Corrects the guidance for `user_not_found`, `zip_unsafe`, `email_not_verified`, `identity_required` and `terms_reconsent_required`: the account errors now say to give the person the link in the error's message.
- Adds troubleshooting rows for `fetch_failed`, `url_not_allowed`, `invalid_input`, `payload_too_large`, `source_digest_mismatch`, `mission_slug_unusable`, `upload_token_slug_mismatch`, `not_found`, `plan_limit_exceeded`, `forbidden`, `service_draining` and `http_<status>`.
- Queued-deploy result codes now say how to deploy again: with a new `idempotency_key` for a queued deploy, or a new link from `create_upload`.
- `deployment_maintenance` is described as a connector tool error and `deploy_status` result code.

## r40 — 2026-11-21

- Troubleshooting gains rows for the remaining result codes a queued deploy can end with: `expired_during_maintenance`, `auth_required`, `async_deploy_unavailable`, `deploy_history_pending`, `deploy_interrupted_before_dispatch` and `project_not_found`, plus the general `deploy_failed` and `queue_expired`.
- Rewrites the guidance for several upload errors (`no_file`, `zip_unsafe`, `classification_error`, `malware_detected`, `consent_required`, `consent_invalid_json`, `internal`) so each says what happened and what the assistant or person does next.
- Marks `empty_selection`, `drop_without_file` and `file_read_failed` as shown only in the web app; tools never receive them.
- `user_not_found` now points the person to reconnect moonbase in the assistant's connector settings.

## r38 — 2026-11-21

- Adds the `upload_check_busy` refusal to troubleshooting: moonbase was busy and could not check the upload, nothing was published, and trying again in a minute is the fix.

## r37 — 2026-11-21

- Adds `references/connect-your-backend.md`: connecting a project to Supabase, Firebase or its own API, which values are public and which stay on the server, and how values reach a static, built or server app.
- Environment variables: replacing and deleting a saved value (in the app, over the env API and with `delete_env`), the `env_page` link that opens the right screen so the person can type a secret there, and the names moonbase manages itself, which are refused with `platform_var_managed`.
- Sharing: the connector tools `list_members`, `invite_member`, `set_member_role` and `remove_member`, with the same rules as the Share window.
- Account: a password reset, password change or email change can turn off all API keys, and `invalid_key` now says so and links to the API keys page.
- Troubleshooting: a payment problem on the account (`payment` from `account_usage` and `platform_status`), service notices (`service_notice`), and new deploy result codes such as `superseded_by_newer_version`, `source_unavailable`, `deploy_queue_full` and `waiting_for_maintenance`.

## r27 — 2026-11-20

- Custom domains: a domain that another account added but never proved can be connected by proving ownership with one TXT record that moonbase shows.
- Over the connector, `add_domain` refuses with `domain_held_unverified` and returns the record plus `domain_page`, a link to the project's domain section, which the assistant opens for the person.
- A domain another account has already proved stays with that account.
- Adds a matching row to troubleshooting.

## r26 — 2026-11-20

- Documents the Launch check (`launch_check`): a read-only review of how search engines and AI assistants see the project's live page, covering crawler access, sitemap, main text in the HTML, page basics and structured data. Draft files it offers wait for the owner's approval.
- Adds sections on managed database export, database status and the database allowance, all marked as a closed pilot.
- Adds "Files moonbase does not serve, and default headers": paths that always answer 404, files left out of a static upload, and the security headers moonbase adds when the app does not send them.
- Clarifies how visitors are counted (per day, per calendar month in UTC) and that they are never capped.
- Notes that an app's own folder can be read-only and only a small `/tmp` is reliably writable.
- Adds the `mission_downgrade_locked` and `deployment_maintenance` errors to troubleshooting.

## r24 — 2026-11-19

- The connector path is described as needing no API key at all.
- API keys are now described as being for a developer's own automation, such as CI or scripts, kept in a secret manager or environment variable and never pasted into a chat.
- An assistant without the connector no longer asks for a key: the person adds the connector, or uploads the ZIP the assistant prepares on the project's Deploy new version screen.
- The connector troubleshooting note no longer names an old test connector; any address other than the official one no longer works.
- Adds the `too_large_for_now` upload error to troubleshooting.

## r23 — 2026-11-19

- With the connector, a project with images or over about 100 KB publishes through `create_upload`, a single-use upload link valid for 10 minutes, sent with one `curl` line and no API key. Small text-only projects can go inline as `files`. The upload result lists fallbacks in order when the upload host is blocked.
- A new project can be launched with a visitor password (`create_mission`, `create_upload`, or `generate_password`), and `set_password` sets one later. A visitor password may go through the chat; API keys and other credentials still never do.
- Adds a "Connector not working" section with the correct connector address and status page links.
- Custom domains document the `verify_domain` connector tool. The env API documents `DELETE` for one variable, and the connector `delete_env`.
- API examples now pass the key to `curl` through stdin instead of on the command line, and `env_write_failed` is described as an unconfirmed outcome.
- Billing states that visits are counted, never capped, on every plan. New password errors are added to troubleshooting.

## r22 — 2026-11-09

- Adds `references/what-your-app-needs.md`, a pre-deploy checklist for what an app needs from outside itself.
- It covers dependencies, `localhost` addresses baked in at build time, a database that exists but has no tables yet, sign-in redirect URIs set at the sign-in provider, keys and mail services, and what the runtime decides.
- Real values go into the project's environment variables, never into the code.
- The assistant opens the live link and tries the features that depend on outside services before saying the deploy is done.
- `SKILL.md` gains a "Before you deploy" section pointing to the checklist.

## r20 — 2026-11-08

- The skill now starts by confirming the person has a moonbase account, with the sign-up link, before discussing any connection or key.
- The moonbase connector (at `https://app.moonbase.cloud/mcp`) becomes the first choice in AI tools that support connectors. It uses the person's moonbase sign-in, so no API key is needed.
- The API key path is now described as the option for CI, scripts and terminal tools without a connector. The terminal quickstart moves to its own section.
- The browser upload remains the path for tools that can only chat.
- Getting started reflects the current sign-up form, including **Continue with Google**.

## r19 — 2026-11-05

- The deploy result parser gains exit code 4 for an `asset_problem`: the page answered, but its own files (scripts, styles, images) do not load. Waiting does not fix this; the project has to change.
- Adds a troubleshooting section, "It's online, but the page is blank", with the cause and the fix.
- The deploy and CI guides describe the new exit code.

## r18 — 2026-11-05

- The quickstart runs the two helper scripts from the skill's own folder (`.claude/skills/moonbase/scripts`), or from `./scripts` when they were saved into the project.
- Clarifies that the project's address is the first label of the live URL the deploy prints, not the name that was requested, and that every status call uses that address.

## r17 — 2026-11-05

- README now opens with what the skill is, how to install it, and an example prompt.
- Adds the `go_not_supported` error: moonbase does not run Go apps; a web frontend can be built and uploaded as files instead.
- Corrects what a downloaded version archive contains: the files as deployed, including any cleanup moonbase made. Environment variables set in moonbase are not in it.
- Rewords the titles of the two Python entry-point errors.

## r16 — 2026-11-01

- Adds two helper scripts: `scripts/package-mission.sh`, which builds a fresh ZIP from the project's tracked files and refuses dependencies, build output, `.env` files and other excluded paths, and `scripts/parse-deploy-result.sh`, which reads the deploy result and reports whether the project is actually live.
- Adds `moonbase-guide.md`, the whole skill in a single file.
- The deploy guide now checks for an existing API key before asking the person for one, and explains how to tell a finished deploy from one that is deployed but not ready yet.
- Building guidance gains a fit check before packaging, the full contract for Python web apps (Flask, Django, FastAPI), a section on data and storage with a database connection example, and a section on limits and runtime.
- The API and CI page documents setting environment variables over the API, build logs and build failures, and one retry and approval policy for CI pipelines.
- Getting started and custom domains say that every project is live on its own `moonbase.host` address with HTTPS right after it deploys; a custom domain is an optional, later step.

## v1.0.0 — 2026-10-25

Initial public release of the moonbase skill, a guide that teaches AI assistants to put a project online with moonbase and manage it.

- The skill (`moonbase/SKILL.md`) with reference pages for getting started, deploying from an AI agent, building a project that deploys first time, builder platforms with their own hosting, custom domains, versions and rollback, sharing, project settings, account, billing, troubleshooting, and safety and support.
- Ready-made instruction files for other tools in `dist/`: `AGENTS.md`, a Cursor rule, a Claude Code snippet, GitHub Copilot instructions, ChatGPT custom GPT instructions and Gemini Gem instructions.
- `build.mjs` and `adapters.json`, which regenerate the `dist/` files from the skill source.
- Deploys use moonbase's public API with the person's own API key, read from the environment or the tool's secret storage, never from the chat.
