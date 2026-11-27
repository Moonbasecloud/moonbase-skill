# Connector tools

Every tool the moonbase connector lists, by the permission it needs. A
connection lists only the tools its permissions allow: missions:read,
missions:write and account:read are granted by default, the others are asked
for separately when connecting. Your connector's own tool list is the live one.

## No permission

- `get_build_guide`: this guide, by section.

## missions:read (default)

- `list_missions`: the account's projects, newest first.
- `mission_info`: one project's status, address and live version.
- `deploy_status`: live status, current version and the last failed attempt.
- `check_project`: checks a project before a deploy; deploys nothing.
- `list_versions`: versions, newest first, and which one is live.
- `list_env`: environment variable names, never values.
- `domain_status`: custom domains, their status and the TXT record.
- `deploy_logs`: recent versions and failed attempts.
- `explain_error`: what a deploy error code means and the next steps.
- `visitor_stats`: visitor numbers, top pages and where visitors came from.
- `launch_check`: what search engines and AI assistants can read on the live
  page, where moonbase has turned it on for the project.
- `list_members`: who has access, and open invitations.
- `platform_status`: whether moonbase itself is working right now.

## missions:write (default)

- `create_mission`: a new project. With the name alone, the project, its address and its database exist in seconds (`database: false` for a static project); the app then goes live in one `deploy` with `changes` (two at most).
- `deploy`: a new version of an existing project; `changes` and `deleted` send only what changed.
- `redeploy`: rebuilds the active version with the saved variables.
- `create_upload`: a single-use upload link and shell command.
- `upload_files`: sends files over the connector in batches.
- `commit_upload`: publishes the files sent with `upload_files`.
- `rollback`: makes an earlier version live again.
- `set_env`: sets environment variables.
- `delete_env`: deletes one environment variable.
- `add_domain`: adds a custom domain.
- `verify_domain`: runs moonbase's DNS check for a domain now.
- `remove_domain`: removes a custom domain.
- `pause_mission`: takes a project offline.
- `resume_mission`: brings a paused project back online.
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

## account:read (default)

- `account_usage`: the plan, each limit and its use, the payment state.
- `upgrade_link`: a link to the plans page; the person pays there.

## missions:delete

- `delete_mission`: starts a deletion the owner finishes in the app.

## versions:delete

- `delete_versions`: deletes old versions for good, after the person's yes.

## missions:source

- `download_source`: the project's source ZIP (it may contain secrets).

Where moonbase has turned importing on, the connector also lists `import_database`, under its own permission (databases:import), and `import_status`, under missions:read.
