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
- A moonbase key works for **every mission on its account**. A leaked key is
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

- On every mission, static or app, moonbase answers **404** for these paths,
  whatever the mission's own code does: `.env` and `.env.*`, folders such as
  `.git/` and `.svn/`, credential files such as `.npmrc`, `.htpasswd` and
  `.aws/`, database files and dumps (`.sql`, `.sqlite`, `.db`), backup
  leftovers (`.bak`, `.old`, `.orig`, `~`, `*backup*.zip`), private keys
  (`.pem`, `.key`, files named id_rsa) and source maps (`.js.map`, `.css.map`). A file
  that has to be public goes under a different name or extension. Publishing
  source maps is not available yet.
- A static upload also leaves out the `.env` family, `.git/` folders, SSH key
  files and any text or JSON file holding a private key. They are listed in
  `skipped_entries` after the deploy.
- When the mission does not send them itself, moonbase adds
  `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`,
  `Referrer-Policy: strict-origin-when-cross-origin` and a
  `frame-ancestors` policy. A header the app sends is kept as the app sent
  it. If the app sends `X-Frame-Options` or its own `frame-ancestors`,
  moonbase adds no `frame-ancestors`, so the app's framing rule applies, even
  if the Mission Control preview then cannot show the mission. Missions are served
  over HTTPS only; plain HTTP redirects to HTTPS.
- These are protections on moonbase's side. They do not check the mission's own
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
- the mission is unreachable on its `moonbase.host` address and isn't
  paused or asleep;
- you need the full build log (support can find it from the Error ID);
- billing problems or a refund.

Always include: the **Error ID** (`TRK-…`), the mission's name and address,
when it started, and the exact message or browser error.

Status of moonbase itself: the "Status" and "Incident History" links in the
footer of https://moonbase.cloud.

## Skill version history

Older revision notes, moved here from `SKILL.md` to keep its overview short. The current revision and the newer notes are in `SKILL.md` under "Skill version".

r55 (2026-11-23): with the connector, a project whose sandbox cannot reach the upload host publishes through the connector itself: `upload_files` sends the files in batches (path, base64 content and SHA-256 each) and `commit_upload` publishes them, in `SKILL.md` and `references/deploy-for-the-user.md`; a file too large for one call goes in parts (`part_index`, `part_count`); `source_url` also takes a public GitHub repository URL. r54 (2026-11-22): `references/billing.md` says visitors are counted for your information and never blocked, and `account_usage` reports them as a usage note, not a limit. r53 (2026-11-22): the `invalid_password` and `password_protection_disabled` rows in `references/troubleshooting.md` give the allowed password length and say when a password can be set, worded as `explain_error` gives them. r52 (2026-11-22): adds stored deployment history Error IDs and exact owner-scoped failure lookup; it distinguishes asynchronous receipts, recorded failure times and compatibility-attempt creation times without inferring missing historical IDs. `mission_info` also returns the owner's `protection_cache_purge.status` (`pending`, `not_queued` or `unknown`), described in `references/mission-control.md`. r51 (2026-11-22): keep the project ID a successful deploy prints and set `MOONBASE_MISSION_ID` to it for every later deploy of the same project, because an empty value creates a new project with a new address; the deploy commands in `references/deploy-for-the-user.md` now warn when it is empty. r50 (2026-11-22): a truth sweep of the Skill and its references, the MCP tool descriptions and the explain_error catalogue, so each sentence matches what moonbase does now (passwords at launch, domain records, upload size limits, Node default, build-log tail, account export). r47 (2026-11-22): two rows on moonbase's side in references/troubleshooting.md, `migration_disk_low` (moonbase's build server had too little disk space to run a migration, so it didn't start and made no changes to the database's tables or data) and `docker_build_limits_unavailable` (the build machine's safety limits couldn't be confirmed, so the build didn't start), worded as `explain_error` gives them. r46 (moonbase note 2026-11-22): when moonbase itself stopped a deploy (disk space, the built image's size, the malware scan, the build machine's limits), its own sentence is `moonbase_note`, over the connector (the deploy error, and a queued deploy's receipt) and on the stream's `error` event, and `build_log_tail` holds only the project's own output, not moonbase's text, in references/troubleshooting.md and api-and-ci.md. r45 (build log tail 2026-11-21): a failed build's `build_log_tail`, over the connector (the deploy error, and `deploy_status` / `deploy_logs` with an `attempt_id`) and on the stream's `error` event, described as the project's own untrusted output, in references/troubleshooting.md and api-and-ci.md. r44: `scripts/parse-deploy-result.sh` also prints a refusal's Error ID (the `trkId` field) after its next step, so a step that says "contact moonbase support with the error ID in this response (trkId)" has the ID beside it. r43 gives the support reference one name, **Error ID** (the `trace_id` field, or `trkId`), as the app shows it, in `SKILL.md` and `references/troubleshooting.md`, `references/versions-and-rollback.md` and `references/safety-and-support.md`; `explain_error` uses the same words, and its `password_protection_unavailable` support sentence now matches the Skill; the `python_entrypoint_not_detected` row now matches `explain_error` word for word, and the `python_runtime_not_supported` row gives the same instruction after one sentence saying it is legacy. r42 corrects the agent guidance for `user_not_found`, `zip_unsafe`, `email_not_verified`, `identity_required` and `terms_reconsent_required` in `references/troubleshooting.md`, and `explain_error` now gives the same words for them; `password_protection_unavailable` gains the same set_password sentence in both, though the two texts still differ elsewhere; `explain_error` also has corrected agent words for `waiting_for_maintenance`, `python_entrypoint_not_detected` and `python_runtime_not_supported`. r41 adds rows for 13 more codes a connector tool, a queued deploy or an upload link can return (`deployment_maintenance`, `fetch_failed`, `forbidden`, `http_<status>`, `invalid_input`, `mission_slug_unusable`, `not_found`, `payload_too_large`, `plan_limit_exceeded`, `service_draining`, `source_digest_mismatch`, `upload_token_slug_mismatch`, `url_not_allowed`) in `references/troubleshooting.md`, and `explain_error` now explains them; a failed queued deploy is deployed again with a new idempotency_key, and a held upload link with a new link from create_upload. r40 adds rows for every other result code a queued deploy can end with (`expired_during_maintenance`, `auth_required`, `async_deploy_unavailable`, `deploy_history_pending`, `deploy_interrupted_before_dispatch`, `project_not_found`), and the generic `deploy_failed`, in `references/troubleshooting.md`; `explain_error` now explains them and `queue_expired`. r39 adds the `queue_expired` result code (a queued deploy that never started) in `references/troubleshooting.md`. r38 adds the `upload_check_busy` refusal (moonbase was busy and couldn't check the upload; try again in a minute) in `references/troubleshooting.md`. r37: a Firebase web config's `apiKey` no longer stops an upload, so a Firebase web app publishes without a build step; any other `AIza` Google key is still refused (`references/troubleshooting.md`). r36 added a guide to connecting an outside backend; r66 removed it.

What r7 carried forward from r6:

- The packaging tool's content gate is now a pure-shell match that fails closed
  on any checker fault (no subprocess exit to misread), rejects filenames
  containing a newline or carriage return, and takes `--allow-build-output` to
  ship a static build on purpose (secrets, databases and dependencies stay
  blocked).
- One classification + retry policy for deploys: branch on the stable machine
  code, retry only the named provider-side faults (never the `our_side`
  category), count the first attempt, and never retry an unknown outcome.
- Setting a mission's secrets over the env API is the documented step (set,
  verify the key names, redeploy), sent on stdin so no value hits the command
  line; the API reference now lists that route, and the write is one atomic,
  cap-checked transaction that holds the per-mission cap under concurrency.
- Database examples verify the server's TLS identity (`verify-full` / verify
  the peer), not just encrypt the connection.
- Check a mission's password state before calling it private, and treat the
  packaging gate as a filename filter, not a secrets scanner.
