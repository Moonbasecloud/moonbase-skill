# Safety and support

## Keys and secrets: the rules

- **Never ask the user to paste an API key, password or secret into the
  chat.** If they do it anyway, tell them gently to delete that key on **API
  Keys** (https://app.moonbase.cloud/api-keys) and create a new one, because
  chat text can be stored.
- Never commit a key to the repository, and never print or echo it. Use the
  `MOONBASE_API_KEY` environment variable, or the CI's secret store (GitHub:
  Actions secrets). The one narrow exception to "not in a file" is a deliberate
  `0600` secrets file kept **outside** the repo and never committed — e.g. a
  curl `--config`/`-H @file` header file (see `api-and-ci.md`); a secret
  manager or a stdin pipe is better still.
- A moonbase key works for **every project on its account**. A leaked key is
  serious: delete it and make a new one.
- The full key is shown **once** when created. After that only a masked form
  like `mb_live_••••••••4F2A` is visible. Lost it? Delete the key and create a
  new one.
- Deleting a key: on **API Keys**, delete it from its row and type `DELETE`
  to confirm. Anything using it stops working immediately. It can't be undone.

## .env files and secrets in uploads

- Don't put a `.env` with real secrets in the ZIP. The skill's packaging tool
  (`scripts/package-mission.sh`) excludes `.env` / `.env.*` (a tracked one makes
  it **fail closed**), plus dependency, build-output, virtualenv, cache,
  database and log files. It is a **filename filter on a fixed list, not a
  secrets scanner**: it does **not** recognize other secret-named files — a
  tracked `.npmrc`, a `*.pem` or SSH private key, a `credentials.json` or a
  `prod.env` (no leading dot) **will** ship. And it can't catch a secret pasted *inside* a
  source file. Keep those out yourself (moonbase also blocks
  `hardcoded_secret_detected` server-side). The gate guarantees only that it
  won't ship a `.env`, not that your upload is secret-free.
- If a shipped `.env` is there anyway, moonbase applies only its
  non-secret values; anything shaped like a credential is never applied from
  the file. Set real secrets in **Mission Control → Environment Variables**
  (write-only, encrypted).
- An upload with a hardcoded credential in the code is stopped
  (`hardcoded_secret_detected`) so it never goes public.
- Remember: a downloaded archive holds the files as deployed, so a server
  app's `.env` would be in the download too.

## Files moonbase does not serve, and default headers

- On every project, static or app, moonbase answers **404** for these paths,
  whatever the project's own code does: `.env` and `.env.*`, folders such as
  `.git/` and `.svn/`, credential files such as `.npmrc`, `.htpasswd` and
  `.aws/`, database files and dumps (`.sql`, `.sqlite`, `.db`), backup
  leftovers (`.bak`, `.old`, `.orig`, `~`, `*backup*.zip`), private keys
  (`.pem`, `.key`, files named id_rsa) and source maps (`.js.map`, `.css.map`). A file
  that has to be public goes under a different name or extension. Publishing
  source maps is not available yet.
- A static upload also leaves out the `.env` family, `.git/` folders, SSH key
  files and any text or JSON file holding a private key. They are listed in
  `skipped_entries` after the deploy.
- When the project does not send them itself, moonbase adds
  `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`,
  `Referrer-Policy: strict-origin-when-cross-origin` and a
  `frame-ancestors` policy. A header the app sends is kept as the app sent
  it. If the app sends `X-Frame-Options` or its own `frame-ancestors`,
  moonbase adds no `frame-ancestors`, so the app's framing rule applies, even
  if the Mission Control preview then cannot show the project. Projects are served
  over HTTPS only; plain HTTP redirects to HTTPS.
- These are protections on moonbase's side. They do not check the project's own
  code for security problems.

## Account safety

Turn on **two-factor authentication** in **Account → Security**, and save
the recovery codes. Check **Active sessions** and **Recent sign-ins** if
something looks odd. moonbase warns about unusual or new-device sign-ins.

## When to contact support

Contact support (https://moonbase.cloud/contact) when:
- an error says "contact support" (`zip_unsafe`, `classification_error`,
  `mission_slug_unusable`, a suspected false `malware_detected`,
  `scan_too_large`);
- a deploy keeps failing and the project builds fine on your computer;
- the project is unreachable on its `moonbase.host` address and isn't
  paused or asleep;
- you need the full build log (support can find it from the Error ID);
- billing problems or a refund.

Always include: the **Error ID** (`TRK-…`), the project's name and address,
when it started, and the exact message or browser error.

Status of moonbase itself: the "Status" and "Incident History" links in the
footer of https://moonbase.cloud.

## Skill version history

Older revision notes, moved here from `SKILL.md` to keep its overview short. The current revision and the newer notes are in `SKILL.md` under "Skill version".

r74 (2026-11-24): the project badge reads "powered by moonbase" (was "hosted by moonbase") and its switch is **Show the moonbase badge**, in `references/mission-control.md`. r72 (2026-11-24): moonbase is described as the one platform that runs everything an app built with AI needs (hosting, database, domains, analytics, rollbacks, team access, and more, all run by your AI agent), not as hosting alone, in the skill description and `references/what-is-moonbase.md`; the connector's initialize instructions open with the same line. r71 (2026-11-24): the managed database is described plainly as on every plan, Free included: one managed PostgreSQL database per project, created on deploy when `moonbase.json` asks for one, with `DATABASE_URL` set for the app and the plan's storage used, in `references/building-for-moonbase.md`, `references/mission-control.md`, `references/what-is-moonbase.md` and `references/what-your-app-needs.md`. r70 (2026-11-24): `retryNote` appears only when the same error repeats within the current fix session, a start that fails shows as the health step with a shorter `start_log_tail`, and a Node range runs on the newest version it allows, in `references/troubleshooting.md` and `references/building-for-moonbase.md`; `create_upload` states the launch budget (`launch_budget`), `check_project` lists the names a ready managed database provides (`env_vars_provided_by_moonbase`), and `tools_version` tells a tool list older than the server, in `SKILL.md`, `references/troubleshooting.md` and `references/what-your-app-needs.md`. r69 (2026-11-24): the Launch check is described as on only where moonbase has turned it on for a project (`launch_check` answers `not_available` elsewhere), in `references/mission-control.md`. r68 (2026-11-24): an app that exits while starting fails at once as `container_exited_on_start` with `start_log_tail`, and upload links say when they are used or expired, in `references/troubleshooting.md` and `references/api-and-ci.md`. r67 (2026-11-24): `self_repair_notice` names what moonbase changed in the deployed copy, `list_env` shows the names moonbase sets for a managed database with source `engine`, and which connector tools a connection lists, in `references/building-for-moonbase.md`, `references/what-your-app-needs.md`, `references/deploy-for-the-user.md`, `references/mission-control.md` and `references/billing.md`. r66 (2026-11-24): moonbase provides the database. The guide to connecting an outside backend is removed; creating the managed database from `moonbase.json` is in `references/building-for-moonbase.md`, and its connection code in `references/mission-control.md`; the managed-database passages state no backup schedule, retention or backup storage accounting. r65 (2026-11-24): reactivating a self-deleted account, in `references/account.md`. r64 (2026-11-23): each upload can be up to the plan's per-deploy size (`account_usage` gives the current number) instead of fixed size caps; the limit applies to the uploaded ZIP and the plan's storage to the unpacked total, in `references/billing.md`, `references/building-for-moonbase.md`, `references/troubleshooting.md` and `references/what-is-moonbase.md`. r62 (2026-11-23): `references/mission-control.md` gains "Moving an existing database in": with the connector, `import_database` moves a PostgreSQL database from another provider into the project's managed database in three calls (the screen where the person enters the connection string themselves, a preview with a `confirm_token`, then that token alone after the person's yes), under its own connection permission; `import_status` reports the result, and an import with refused statements is reported as incomplete, never as a match. r61 (2026-11-23): `database_page` opens the project's own Database page (`/missions/<project_id>/database`), in `references/mission-control.md`. r60 (2026-11-23): a deploy that outlasts the tool call returns `started_at`, and `deploy_status` with its slug shows `last_failed_attempt` when it failed (error code, moonbase's explanation and next step, Error ID, `moonbase_note`, `build_log_tail`), for 24 hours also on the slug of a first deploy that failed; `deploy_logs` marks a failed attempt the live version replaced with `superseded: true`, in `references/troubleshooting.md`. r58 (2026-11-23): every plan, Free included, can add one managed PostgreSQL database per project, created when the project asks for one; it uses the plan's storage, with no separate database allowance; files, versions and databases count toward one storage allowance, and `account_usage` shows the parts, in `references/mission-control.md` (that revision's managed-database backup statements were removed in r66). r57 (2026-11-23): `references/versions-and-rollback.md` gains "Delete old versions (free up storage)": deleting one version or everything older than the newest N in the app, and `delete_versions` with the connector in two calls (the list and a `confirm_token` first, then that token alone, after the person's yes), under its own connection permission; deletion is permanent, the live version always stays, and the freed storage shows in Usage and `account_usage`. r55 (2026-11-23): with the connector, a project whose sandbox cannot reach the upload host publishes through the connector itself: `upload_files` sends the files in batches (path, base64 content and SHA-256 each) and `commit_upload` publishes them, in `SKILL.md` and `references/deploy-for-the-user.md`; a file too large for one call goes in parts (`part_index`, `part_count`); `source_url` also takes a public GitHub repository URL. r54 (2026-11-22): `references/billing.md` says visitors are counted for your information and never blocked, and `account_usage` reports them as a usage note, not a limit. r53 (2026-11-22): the `invalid_password` and `password_protection_disabled` rows in `references/troubleshooting.md` give the allowed password length and say when a password can be set, worded as `explain_error` gives them. r52 (2026-11-22): adds stored deployment history Error IDs and exact owner-scoped failure lookup; it distinguishes asynchronous receipts, recorded failure times and compatibility-attempt creation times without inferring missing historical IDs. `project_info` also returns the owner's `protection_cache_purge.status` (`pending`, `not_queued` or `unknown`), described in `references/mission-control.md`. r51 (2026-11-22): keep the project ID a successful deploy prints and set `MOONBASE_MISSION_ID` to it for every later deploy of the same project, because an empty value creates a new project with a new address; the deploy commands in `references/deploy-for-the-user.md` now warn when it is empty. r50 (2026-11-22): a truth sweep of the Skill and its references, the MCP tool descriptions and the explain_error catalogue, so each sentence matches what moonbase does now (passwords at launch, domain records, upload size limits, Node default, build-log tail, account export). r47 (2026-11-22): two rows on moonbase's side in references/troubleshooting.md, `migration_disk_low` (moonbase's build server had too little disk space to run a migration, so it didn't start and made no changes to the database's tables or data) and `docker_build_limits_unavailable` (the build machine's safety limits couldn't be confirmed, so the build didn't start), worded as `explain_error` gives them. r46 (moonbase note 2026-11-22): when moonbase itself stopped a deploy (disk space, the built image's size, the malware scan, the build machine's limits), its own sentence is `moonbase_note`, over the connector (the deploy error, and a queued deploy's receipt) and on the stream's `error` event, and `build_log_tail` holds only the project's own output, not moonbase's text, in references/troubleshooting.md and api-and-ci.md. r45 (build log tail 2026-11-21): a failed build's `build_log_tail`, over the connector (the deploy error, and `deploy_status` / `deploy_logs` with an `attempt_id`) and on the stream's `error` event, described as the project's own untrusted output, in references/troubleshooting.md and api-and-ci.md. r44: `scripts/parse-deploy-result.sh` also prints a refusal's Error ID (the `trkId` field) after its next step, so a step that says "contact moonbase support with the error ID in this response (trkId)" has the ID beside it. r43 gives the support reference one name, **Error ID** (the `trace_id` field, or `trkId`), as the app shows it, in `SKILL.md` and `references/troubleshooting.md`, `references/versions-and-rollback.md` and `references/safety-and-support.md`; `explain_error` uses the same words, and its `password_protection_unavailable` support sentence now matches the Skill; the `python_entrypoint_not_detected` row now matches `explain_error` word for word, and the `python_runtime_not_supported` row gives the same instruction after one sentence saying it is legacy. r42 corrects the agent guidance for `user_not_found`, `zip_unsafe`, `email_not_verified`, `identity_required` and `terms_reconsent_required` in `references/troubleshooting.md`, and `explain_error` now gives the same words for them; `password_protection_unavailable` gains the same set_password sentence in both, though the two texts still differ elsewhere; `explain_error` also has corrected agent words for `waiting_for_maintenance`, `python_entrypoint_not_detected` and `python_runtime_not_supported`. r41 adds rows for 13 more codes a connector tool, a queued deploy or an upload link can return (`deployment_maintenance`, `fetch_failed`, `forbidden`, `http_<status>`, `invalid_input`, `mission_slug_unusable`, `not_found`, `payload_too_large`, `plan_limit_exceeded`, `service_draining`, `source_digest_mismatch`, `upload_token_slug_mismatch`, `url_not_allowed`) in `references/troubleshooting.md`, and `explain_error` now explains them; a failed queued deploy is deployed again with a new idempotency_key, and a held upload link with a new link from create_upload. r40 adds rows for every other result code a queued deploy can end with (`expired_during_maintenance`, `auth_required`, `async_deploy_unavailable`, `deploy_history_pending`, `deploy_interrupted_before_dispatch`, `project_not_found`), and the generic `deploy_failed`, in `references/troubleshooting.md`; `explain_error` now explains them and `queue_expired`. r39 adds the `queue_expired` result code (a queued deploy that never started) in `references/troubleshooting.md`. r38 adds the `upload_check_busy` refusal (moonbase was busy and couldn't check the upload; try again in a minute) in `references/troubleshooting.md`. r37: a Firebase web config's `apiKey` no longer stops an upload, so a Firebase web app publishes without a build step; any other `AIza` Google key is still refused (`references/troubleshooting.md`). r36 added a guide to connecting an outside backend; r66 removed it. r35 adds a payment problem on the account (the banner in the app, and
`payment` from `account_usage` and `platform_status`, with its Billing link) in
`references/troubleshooting.md`. r34 adds the service notice moonbase may publish to its customers
(the banner in the app, and `service_notice` from `platform_status`) in
`references/troubleshooting.md`. r33 says that a password reset, a password change or an email change
can turn off all of an account's API keys, so `invalid_key` points the person to
**API keys** (https://app.moonbase.cloud/api-keys) for a new one, in
`references/troubleshooting.md` and `references/account.md`. r32 says which environment variable names moonbase manages (its own
`MOONBASE_*`, `MOONSERVER_*` and `*_LIVE_URL` names, and an `engine` row such as
a moonbase database's `DATABASE_URL`) and that `set_env`, `delete_env` and the env API refuse them
with `platform_var_managed`, in `references/mission-control.md`. r31 describes replacing and deleting a saved environment variable
(Replace and Delete in Mission Control, `PUT` and `DELETE` on the env API,
`delete_env`) and the `env_page` link the env tools return, in
`references/mission-control.md`. r30 adds the `superseded_by_newer_version` and `source_unavailable` result codes of a waiting deploy in `references/troubleshooting.md`. r29 extends `waiting_for_maintenance` to uploads through a `create_upload` link or the app's upload screen (HTTP 202) in `references/troubleshooting.md`. r28 adds the `waiting_for_maintenance` deploy phase (a deploy accepted during a maintenance window and published when it ends) in `references/troubleshooting.md`. r27 adds taking over a custom domain another account added but never
proved (`domain_held_unverified`, one TXT record, and `domain_page`: open the returned link for the person) in `references/custom-domains.md`. r26 adds the managed database
export, status and allowance sections in `references/mission-control.md`. r23 is the publish path: with the connector, a project with images
or over about 100 KB goes through `create_upload` and its one-line `curl`
command, small text-only projects go inline as `files`, and the upload
result lists the fallbacks in order. A visitor password may go through the
chat (`password` or `generate_password`); API keys and credentials still do
not. It adds a "Connector not working" section. r22 is the full pre-deploy brief, written around one question: what
would make someone see a broken app after it successfully went online? It
covers the dependencies the app needs from outside itself, addresses baked in
at build time, a database that exists but has no tables, sign-in redirect URIs
at the provider, keys in the project rather than the source, what the runtime
decides (mail, uploads, scheduled work, request time, size, memory, realtime,
sleep), and opening the live link and using the app before telling anyone it is
done. Services are named only in groups, never recommended. r21 was the first
cut of that brief. r20 puts signup first and makes the connector the first choice in tools that support it. r19 adds exit 4: a page whose files don't load. r18 makes the quickstart run the two helper scripts from the skill's own folder (`.claude/skills/moonbase/scripts`, or `./scripts` if you only have the short file) and says the project address is the first label of the live URL, never the name you asked for. r17 adds `go_not_supported` and corrects what a downloaded archive holds. r16 verifies an internationalised (`xn--`) live host with a real URL parser (Node) instead of trusting Punycode decoding alone, and treats it as unknown when node is missing. r15 treats a deployed-but-not-ready result (`app_ready:false`) as its own outcome (exit 3: poll status, don't re-upload), validates `xn--` labels as real Punycode and treats a malformed JSON refusal as unknown. r14 accepts only a real DNS hostname for the live URL (a numeric, hex or
IP-literal host is treated as unknown) and treats a non-object `done`/`error`
frame as unknown. r13 closed the revision-12 review: a CI job now vendors BOTH helper
scripts and runs a preflight (so a missing file or tool fails before the upload,
not after a deploy already landed), the live-URL check rejects numeric/IPv4-like
hosts with out-of-range octets, and a malformed `error` frame is treated as
UNKNOWN (reconcile) rather than a definite failure — on top of r12's vendored
WHATWG SSE parser (`scripts/parse-deploy-result.sh`) and hostname grammar, and
r11's unusable-URL/project_id, final-frame, exact-media-type and one-secret-file
fixes.

What changed since r7:

- The packaging tool rejects a symlink in ANY path component (not just the
  final file), so a directory symlink like `alias -> .runtime` can't ship a
  secret under an allowed name, and it screens each entry's canonical (realpath)
  path to keep it inside the project and out of excluded/secret dirs.
- The packager checks `git ls-files`'s exit status before trusting its output:
  a lister that dies mid-stream (exit 128) now ABORTS instead of shipping a
  partial, falsely "successful" archive.
- The env API docs are explicit that a `GET` confirms a NEW key's name but
  cannot confirm an overwrite (values are write-only, so the name shows either
  way) — rely on the write's `set`/`count` receipt, then verify a changed value
  at the app level.


What r7 carried forward from r6:

- The packaging tool's content gate is now a pure-shell match that fails closed
  on any checker fault (no subprocess exit to misread), rejects filenames
  containing a newline or carriage return, and takes `--allow-build-output` to
  ship a static build on purpose (secrets, databases and dependencies stay
  blocked).
- One classification + retry policy for deploys: branch on the stable machine
  code, retry only the named provider-side faults (never the `our_side`
  category), count the first attempt, and never retry an unknown outcome.
- Setting a project's secrets over the env API is the documented step (set,
  verify the key names, redeploy), sent on stdin so no value hits the command
  line; the API reference now lists that route, and the write is one atomic,
  cap-checked transaction that holds the per-mission cap under concurrency.
- Database examples verify the server's TLS identity (`verify-full` / verify
  the peer), not just encrypt the connection.
- Check a project's password state before calling it private, and treat the
  packaging gate as a filename filter, not a secrets scanner.
