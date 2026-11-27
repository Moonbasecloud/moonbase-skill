# Connector tools

Every tool the moonbase connector lists, by the permission it needs. A
connection lists only the tools its permissions allow: Read projects, Deploy
and manage projects and See plan and usage are granted by default, the others
are asked for separately when connecting. A tool error for a missing
permission carries its id in `required_scope`. Your connector's own tool list
is the live one.
Byte counts in results (`*_bytes`, and `totalBytes`, `appBytes` and
`baselineBytes` under `database.storage`) are JSON numbers; `null` means not
measured.

## No permission

- `get_build_guide`: this guide, by section. The note after each section states the content identity (the revision, its `published_at` date, `guide_sha256` of the whole published guide and `section_sha256` of the returned text) and whether queued deploys (`wait`, `idempotency_key`, `attempt_id`) are on for the connection.

## Read projects (default)

- `list_projects`: the account's projects, newest first.
- `project_info`: one project's status, address and live version.
- `deploy_status`: live status, current version, the last failed attempt and
  the newest redeploy of the live version (`last_redeploy`).
- `check_project`: checks a project before a deploy; deploys nothing.

`check_project` reports `env_vars_referenced`, `env_vars_required`, `env_vars_optional`, and `env_vars_requirement_unknown` as names only. `env_vars_needed` includes owner-supplied required or uncertain references without a detected default; it is not proof that a saved value is missing. `env_configuration_checked` is false: saved settings were not read. `env_vars_missing_from_example` means absent from `.env.example`, not absent from the deployed project. `env_vars_provided_by_platform` lists runtime defaults, and a ready managed database moves its referenced connection names to `env_vars_provided_by_moonbase`; `env_vars_reserved` are managed names and are not values for the person to supply. `env_scan_coverage` reports file limits, truncation, parse failures and dynamic access. The scan parses JavaScript/TypeScript and literal inline script blocks; environment-object aliases, computed names and unsupported syntax can leave references unknown. Inline JavaScript in HTML and external scripts use the same non-blocking localhost warning, with file and line; a server listening on `PORT` is not that warning.
- `list_versions`: versions, newest first, and which one is live.
- `list_env`: environment variable names, never values.
- `domain_status`: custom domains, their status and the TXT record.
- `deploy_logs`: recent versions and failed attempts; with `trace_id` alone,
  that failure's detail as `trace_attempt`.
- `explain_error`: what a deploy error code means and the next steps.
- `visitor_stats`: visitor numbers, top pages and where visitors came from.
- `launch_check`: what search engines and AI assistants can read on the live
  page, where moonbase has turned it on for the project.
- `list_members`: who has access, and open invitations.
- `platform_status`: whether moonbase itself is working right now.

## Deploy and manage projects (default)

- `create_project`: a new project. With the name alone, the project, its address and its database exist in seconds (`database: false` for a static project); the app then goes live in one `deploy` with `changes` (two at most). After create_project, say at most: "Your address is reserved: <url>. Deploying now." Give the link as done only after after_deploy.state is ok or ok_with_warnings (not broken, unconfirmed or suspicious); with ok_with_warnings, name the warning in one plain line.
- `deploy`: a new version of an existing project; `changes` and `deleted` send only what changed.
- `redeploy`: rebuilds the active version with the saved variables; the result
  names the rebuild (`operation_id`, `completed_at`, `config_revision`).
- `create_upload`: a single-use upload link and shell command.
- `upload_files`: sends files over the connector in batches.
- `commit_upload`: publishes the files sent with `upload_files`.
- `rollback`: makes an earlier version live again.
- `set_env`: sets environment variables.
- `delete_env`: deletes one environment variable.
- `add_domain`: adds a custom domain.
- `verify_domain`: runs moonbase's DNS check for a domain now.
- `remove_domain`: removes a custom domain.
- `pause_project`: takes a project offline.
- `resume_project`: brings a paused project back online.
- `set_password`: saves or replaces the visitor password (owner only).
- `remove_password`: deletes it and turns protection off (owner only).
- `invite_member`: asks to invite a person by email with a role; a person
  signed in to moonbase confirms it in the app before it is sent.
- `set_member_role`: changes the role of someone who accepted; a change that
  raises access (to Can edit or Can manage) is confirmed in the app first.
  Confirm is the person's own decision on moonbase; an agent that presses it
  in the person's browser skips the check this step exists for.
- `remove_member`: removes access, or cancels an invitation.
- `export_database`: the database export page and its status.

## See plan and usage (default)

- `account_usage`: the plan, each limit and its use, the payment state.
- `upgrade_link`: Returns a moonbase plan-selection link for a user who has requested information about changing their plan. Does not change billing or make a payment.
  `less_than_you_have_now` says when that plan includes less than the account
  has now.

## Start deleting a project

- `delete_project`: starts a deletion the owner finishes in the app.

## Delete old versions

- `delete_versions`: deletes old versions for good, after the person's yes.

## Download source files

- `download_source`: the project's source ZIP. Environment files (`.env`, `.env.*`, `*.env`; `.env.example` stays) are not in it: `excluded_secret_files` lists them by name, and `secret_files_note` says: "Secret files are not included: <names>. If the app reads values from these files, re-uploading this archive will leave them out — ask the user to add those values in the project's environment settings before you upload it again." Other files can still contain credentials or personal information.

Where moonbase has turned importing on, the connector also lists `import_database`, under its own permission (Replace a database), and `import_status`, under Read projects.
