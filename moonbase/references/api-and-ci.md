# The deploy API, CI and GitHub Actions

If the person doesn't have a moonbase account, send them to
**https://app.moonbase.cloud/register** and wait until they confirm their
account is ready. Start with the moonbase connector in a tool that supports
it. Follow **https://moonbase.cloud/docs/deploy-from-ai-chat** and sign in
through the tool. Use **https://app.moonbase.cloud/mcp** if it asks for the
connector address.

This page covers the API key path for CI, scripts and terminal tools without
a connector. Use that path only after the person confirms their account.

## The sources of truth (send developers here)

- **OpenAPI 3.1 spec:** https://app.moonbase.cloud/api/v1/openapi.json. Every
  endpoint, form field, stream event, response field and error code. Import
  it into Postman or Insomnia, or generate a client.
- **API Reference (human-readable):** https://moonbase.cloud/docs/api-reference
- **Integration guide** with copy-paste curl, Node and Python:
  https://moonbase.cloud/docs/integrate-moonbase
- **GitHub Actions guide:** https://moonbase.cloud/docs/github-actions-ci-cd

## The endpoints

| | |
|---|---|
| `POST https://app.moonbase.cloud/api/projects/upload/stream` | Upload a ZIP (multipart), stream the deploy |
| `GET https://app.moonbase.cloud/api/v1/sites/{address}/status` | Read a mission's state |
| `GET https://app.moonbase.cloud/api/v1/sites/{address}/env` | List the env-var key names set on a mission |
| `PUT https://app.moonbase.cloud/api/v1/sites/{address}/env` | Set one or more env vars (see "Setting environment variables") |

Auth on **all four** — upload, status, and the env GET and PUT — is the same:
`Authorization: Bearer mb_live_…` (an API key from **API Keys**), same deploy
scope, scoped to the missions that key owns. Always use `app.moonbase.cloud`.
The old `app.moonbase.host` only redirects.

Passing the key with `-H "Authorization: Bearer $KEY"` puts it in the process's
**argv**, which is visible in `ps`/`/proc` on a shared host and can land in
shell traces. Where that matters, feed the header to `curl` out of band:
`-H @file` (read the header line from a file) or `--config <file>` (a curl
config file holding a `header = "Authorization: Bearer …"` line). **Not**
`--netrc` — that supplies HTTP Basic `login:password` from a `.netrc`, not an
arbitrary Bearer header, so it won't carry an API key. Such a file is the one
narrow exception to "not in a file" (Step 1 of
`deploy-for-the-user.md`): keep it `0600`, outside the repo and never committed —
a secret manager or a stdin pipe is better still. (Keep secret **values** out of
argv the same way: feed them from a file or stdin, as the env PUT below does,
not as literal arguments.)

Send a descriptive `User-Agent` header on every request (for example
`User-Agent: my-tool/1.0`). moonbase is behind a filter that blocks requests
with no client identity, so a missing or default `User-Agent` can be refused
before it reaches the API.

Form fields: `file` (required, the ZIP), `redeployProjectId` (an existing
mission's id: ship a new version), `name` (address of a new mission),
`displayName` (new missions only).

## Reading the response

1. Check `Content-Type`.
   - `application/json`: refused before it started. Body:
     `{"error": "<code>", "message", "title", "nextStep", "trkId"}` plus
     extra fields for some codes (`retry_after_sec`, `consent_url`,
     `reason`/`limit`/`current`). Take any number you show the user (a
     plan-limit's `limit`/`current`, a `retry_after_sec`) from these
     **structured fields**, never by quoting the raw `message` — the raw
     `message` is for your own diagnosis only and is never shown.
   - `text/event-stream`: running. HTTP status is 200 even if the deploy
     later fails, so read to the end.
2. Each event is an `event:` line, one `data:` line of JSON, a blank line.
   - `stage`: progress (`subdomain.reservation`, `payload.upload`,
     `ssl.provisioning`, `verification`; each `started` then `completed`).
   - `build_stage`, `build_log`: build progress for Node apps.
   - `step`: wording for moonbase's own console; ignore it.
   - Ignore events you don't know.
3. The stream ends with exactly one:
   - `done`: `url` (live URL), `project_id` (send as `redeployProjectId`
     next time), `slug`, `total_ms`, `mode` (`static` / `dynamic`),
     `framework`, `self_repair_notice`, `skipped_entries`.
   - `error`: `friendly.title` / `.explanation` / `.nextSteps` (show these),
     `friendly.culprit` (the exact offending token — a package, a file, a
     missing env-var name, a database host — already redacted; show it too),
     `friendly.code` (stable machine code for the failure class — **branch on
     this, never on the title or the raw text**), `friendly.category`
     (`user_build_error` / `platform_limitation` / `our_side` / `unknown` —
     whose fix it is), `message` (raw, don't show), `trace_id` (`TRK-…`, for
     support), `stage`. The top-level `code` mirrors `friendly.code`.

A full tested curl script is in `deploy-for-the-user.md` (Step 4).

## Build logs and build failures (including Python)

What you get while the stream is open:

- `build_log` lines carry **Node** build output (npm install / build). Python
  builds (pip install, container start) do **not** stream `build_log` lines;
  for a Python failure, the diagnosis is in the final `error` event, not a log
  feed.
- When a build or a container start fails, moonbase classifies it and gives
  you a **stable `friendly.code`** plus a `friendly.category`. **Branch on
  `friendly.code`** — it won't change wording under you the way a title or the
  raw `message` can. `friendly.culprit`, when set, is the exact token at fault
  (a package spec, a file, a missing env var, a database host), already
  redacted. Show the user `friendly.*`; read the raw `message` yourself. The
  common codes — **this section is the authoritative code list and its retry
  classification** (which codes are retryable); the user-facing fix per code is
  in `troubleshooting.md`, which points back here for the list:
  - Python deps — `python_requirement_not_found` (a bad/yanked pin),
    `pip_version_conflict` (two pins clash), `pip_requirements_file_missing`
    (a `-r`/`-c` file didn't ship), `pip_hash_mismatch`, `pip_wheel_incompatible`
    (no Linux wheel), `python_module_not_found` (not in requirements.txt),
    `python_native_compilation_unsupported` (needs a compiler). See the Python
    contract in `building-for-moonbase.md`.
  - Node deps — `missing_dependency`, `npm_install_failed` (ERESOLVE / peer
    conflict), `npm_start_script_missing`, `node_version_unsupported`,
    `native_compilation_unsupported`. Fix locally (`npm install && npm run build`)
    and redeploy.
  - Runtime & config — `app_crashed_on_boot` (threw at start),
    `health_check_timeout` (never bound `PORT`), `port_in_use`,
    `missing_env_var` (set it in Mission Control → Environment Variables),
    `database_unreachable` (your app's own DB host/port/credentials —
    missions can reach a database directly now).
  - Setup, not a build crash — `python_entrypoint_not_detected`,
    `framework_unsupported:<framework>`, `astro_ssr_not_supported`,
    `sveltekit_adapter_node_required`.
  - Genuinely moonbase's side — `deploy_timeout`, `moonserver_5xx`,
    `moonserver_unreachable`, `pypi_unreachable`. These four are retryable **by
    name** (they are the exact codes listed as retryable in the state machine
    below). Retry is keyed off those codes, never off `friendly.category` —
    `our_side` is attribution, and other `our_side` codes are deterministic and
    must NOT be retried (see the state machine). **The code wins:** when a
    recognized `friendly.code` and the `friendly.category` disagree, route on
    the code — the category never overrides a code in the authoritative list.
    With a missing or unrecognized code, route UNKNOWN regardless of category;
    the category may describe attribution only.
    `unknown_error`, or a `friendly.category` of `unknown` **with no recognized
    code present**, is unclassified — treat it as UNKNOWN (below), never as a
    user error by default.
  A bare `docker_build_failed` with no pinpointed cause is **UNKNOWN**, not a
  verdict. It usually means the uploaded app's own build failed, but don't
  assert whose fault it is — read the tail for evidence and keep it UNKNOWN
  until something identifies the cause.

There is **no API to fetch a build log after the stream closes** today — once
the connection is gone, keep the `trace_id` (`TRK-…`) you already captured.
That `TRK-…` is how you escalate: it ties your deploy to the full server-side
build log, which support can read. So always record the `trace_id` from the
`error` event before giving up, and give the user **that** for support. If you
also attach a log excerpt, **redact and bound it first**: strip API keys
(`mb_live_…`), `Authorization` headers, tokens, database URLs and any
credentialed connection string, and any other private data, and keep it to the
last ~20 lines — never paste the whole stream into a chat, a log or an artifact. (A self-service, authenticated "fetch
my build log by `TRK-…`" endpoint is a known gap, not something that exists now
— don't promise it.)

## Retries and approval: one state machine

The same policy as `deploy-for-the-user.md`. Branch on `friendly.code` in the
stream, or the `error` code + HTTP status before it — never on a title, the raw
`message`, or the `friendly.category` (that is attribution, not a retry signal).
Exactly one branch per attempt:

- **Retryable — by explicit code only.** Before the stream: `429 rate_limited`,
  `409 deploy_in_progress`, `500 internal`, `503 service_draining`,
  `scanner_unavailable`, `scan_incomplete`. In the stream: `friendly.code` is
  one of `deploy_timeout`, `moonserver_5xx`, `moonserver_unreachable`,
  `pypi_unreachable`, or `deploy_in_progress` (it can arrive in-stream too) —
  the only build/runtime codes a retry may clear. The `our_side` category is
  **not** a retry signal: `dependency_version_not_found`,
  `slug_length_out_of_range` and `moonserver_not_configured` are `our_side` but
  deterministic, so retrying them just fails again.
- `consent_required`: **not retryable by a key** — a human must approve once in
  the browser (see below).
- **Change the request first — known deterministic code only:** a `friendly.code`
  that IS in the authoritative list above (or a recognized pre-stream code) and
  is not retryable — e.g. `missing_dependency`, `npm_install_failed`,
  `app_crashed_on_boot`, the deterministic `our_side` ones. Show `friendly.*`
  and `nextStep` (not the raw `message`); fix the cause, or escalate with the
  `trace_id` if it's moonbase's to fix. (This is NOT a catch-all: a code that
  isn't in the list is UNKNOWN, next, not "change the request".)
- **UNKNOWN — don't retry blindly (this is where a missing, unrecognized or
  malformed outcome lands, never the branch above):** `unknown_error`, a
  `friendly.category` of `unknown` (with no recognized `friendly.code`),
  `stream_ended_without_complete` (UNKNOWN
  even though its category is `our_side` — the stream closed with no final
  event), a bare `docker_build_failed` with no pinpointed cause, a `friendly.code`
  not in the list above, data that isn't valid JSON, or a stream that ended with
  neither `done` nor `error`. Call the status endpoint before any re-POST
  (below). Retryability is only ever the named set above.

**The one retry policy.** Only for a retryable branch, and **counting the first
attempt**: before each retry **wait at least the server's delay** —
`retry_after_sec` (also the `Retry-After` header) when it's given, otherwise a
few seconds, growing each attempt. **Never retry sooner than the server asked.**
Stop as soon as either bound is hit: **3 attempts in total** (the first
included), or the next required wait would pass a **local deadline of a few
minutes** — then report the `trkId`/`trace_id`. There is no fixed per-wait
ceiling that would override a longer `Retry-After`; the bounds are the attempt
count and the total deadline. Never loop unboundedly.

**After an unknown outcome** — the stream dropped, timed out, or closed with
neither `done` nor `error` — do **not** re-POST the upload. Call the status
endpoint first: if `deployInProgress` is `true`, wait; if `currentVersion`
advanced, the deploy already succeeded. Only upload again once status shows it
didn't land.

**When the API asks for approval.** `consent_required` is the single
case where the owner uses the browser: moonbase proposes build changes a key
can't auto-accept, so the owner opens `consent_url`, deploys that mission once
from the browser and approves. Afterwards key deploys work again. Everything a
key *does* auto-accept before the first production deploy — empty-value env
var, start script, port rewrite, Node version, lockfile regeneration — is the
ordinary Compatibility Engine set; only the rare leftover needs the person.

Limits: a few deploys per 5 minutes and up to 100 per hour per account (plus
a per-IP limit), one build at a time per mission, and the plan's mission,
storage and per-deploy size limits. Allow at least 10 minutes for a stream.
If the connection drops, check the status endpoint before uploading again.

**Deployed is not always ready.** The final `done` event carries `app_ready`:
`true` = the app's own readiness check (`/readyz` by default, or
`MOONBASE_READINESS_PATH`) answered, so it is live; `false` = deployed and
reachable but the app reported **not ready** (it needs configuration or is still
warming up; `readiness.state` is `not_ready`, with the `path` and `http_status`
probed); `null` or missing = readiness was not determined (no endpoint, a static-file
mission, an inconclusive probe), which is treated as live. The status endpoint shows
the same thing: `status` is `"deployed_not_ready"` (distinct from `failed`) and
`appReady` is `false`; it is re-checked on read and flips to `live` once the
app answers ready. `scripts/parse-deploy-result.sh` exits `3` for this case — the
upload landed, so poll status instead of re-uploading.

An internationalised (`xn--`) live host is checked with `node`'s URL parser; a runner without node, or whose node build does not validate IDNA (the parser self-tests it first), treats such a host as unknown (exit 2) and you reconcile via status. Plain ASCII hosts (the `*.moonbase.host` default) never need node.

## GitHub Actions in five steps

1. Create a key on **API Keys** (it starts with `mb_live_`).
2. In the GitHub repo: **Settings → Secrets and variables → Actions → New
   repository secret**. Name `MOONBASE_API_KEY`, value the key.
3. Find the mission id in the mission's link
   (`https://app.moonbase.cloud/missions/<id>`) or from the status endpoint,
   and add it as `MOONBASE_MISSION_ID`.
4. **Vendor BOTH helper scripts.** Copy `scripts/package-mission.sh` **and**
   `scripts/parse-deploy-result.sh` from the skill into your repo (same paths)
   and commit them. CI runs those identical files — the quickstart, the deploy
   recipe and this job all use the same two tools, with no inline packaging or
   result-parsing to drift. The job also needs `bash`, `jq`, `zip` and `unzip`
   on the runner (`ubuntu-latest` has them); the preflight step below fails fast
   if a helper file or tool is missing, **before** any upload.
5. Add `.github/workflows/deploy.yml`:

```yaml
name: Deploy to moonbase
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Preflight — helpers and tools present
        # Fail BEFORE any upload if a helper file or tool is missing. Otherwise a
        # missing scripts/parse-deploy-result.sh surfaces as `exit 127` AFTER the
        # deploy already landed — the mission is live but the job reports failure,
        # inviting a duplicate retry. Check everything the job needs up front.
        run: |
          set -euo pipefail
          for f in scripts/package-mission.sh scripts/parse-deploy-result.sh; do
            test -f "$f" || { echo "missing helper: $f (vendor it from the skill)" >&2; exit 1; }
          done
          for t in bash jq zip unzip curl; do
            command -v "$t" >/dev/null || { echo "missing tool: $t" >&2; exit 1; }
          done
      - name: Package for moonbase
        # The one packaging tool, committed at scripts/package-mission.sh:
        # a fresh, source-only, fail-closed archive. Capture its output with
        # `|| exit 1` — `echo "$(...)" >> $GITHUB_ENV` would MASK a non-zero
        # exit (echo still succeeds) and leave MISSION_ZIP empty. Verify the
        # archive is a real non-empty file before using it.
        run: |
          set -euo pipefail
          mission="$(bash scripts/package-mission.sh)" || exit 1
          test -n "$mission" && test -f "$mission" || { echo "packager produced no archive" >&2; exit 1; }
          echo "MISSION_ZIP=$mission" >> "$GITHUB_ENV"
      - name: Deploy to moonbase
        # Keep the stream in a private, short-lived file (owner-only, deleted on
        # exit); print only sanitised, structured fields. Never `tee` the raw
        # stream into the job log or upload the log as an artifact. This calls
        # the SAME shipped script the deploy recipe uses
        # (`scripts/parse-deploy-result.sh`, deploy-for-the-user.md Step 4): it
        # passes ONLY on a complete, final `done` with a usable live URL, so a
        # truncated or unknown stream fails the job instead of going green.
        run: |
          set -euo pipefail
          log="$(mktemp)"; chmod 600 "$log"; trap 'rm -f "$log"' EXIT
          # Capture curl's own exit (don't rely on set -e): a transfer that fails
          # after a complete-looking `done` must be UNKNOWN, not a success.
          curl_rc=0
          meta="$(curl -sSN -X POST https://app.moonbase.cloud/api/projects/upload/stream \
            -H "Authorization: Bearer ${{ secrets.MOONBASE_API_KEY }}" \
            -H "User-Agent: github-actions-moonbase/1.0" \
            -F "file=@${{ env.MISSION_ZIP }}" \
            -F "redeployProjectId=${{ secrets.MOONBASE_MISSION_ID }}" \
            -o "$log" -w '%{http_code} %{content_type}')" || curl_rc=$?
          # The SAME shipped parser the deploy recipe uses — one script, no drift.
          # Exit 3 = deployed but the app is NOT READY (app_ready:false): the job
          # fails on purpose, but do not re-run the upload — poll status instead.
          # Exit 4 = the page's files don't load (asset_problem): change the project.
          bash scripts/parse-deploy-result.sh "$log" "${meta%% *}" "${meta#* }" "$curl_rc"
```

6. Push to `main`. The job passes only when the stream ends with a complete,
   valid `done` — a truncated, malformed or unknown stream fails it.

## Building moonbase into another product

Each of your users who has their own moonbase account gives you their own
key; keep keys on your server only (never in browser or mobile code, a repo
or logs). Store the `project_id` from the first `done` and send it as
`redeployProjectId` afterwards. Rotate keys by creating a new one, switching,
then deleting the old one. Full walkthrough:
https://moonbase.cloud/docs/integrate-moonbase.

## Setting environment variables over the API

An agent can finish configuring a mission — its database URL, API keys and
other secrets — without a human or a browser. Two calls, the same Bearer key
and scope as a deploy, scoped to the missions that key owns.

**List the keys that are set** (never the values — they are write-only):

```bash
curl https://app.moonbase.cloud/api/v1/sites/<slug>/env \
  -H "Authorization: Bearer $MOONBASE_API_KEY" \
  -H "User-Agent: my-agent/1.0"
```

The reply names the keys already set and the keys your build referenced but
left unset.

**Set one or more** with a `PUT`. The keys are yours to choose — whatever your
app reads at run time, not only what the build referenced — so an app that
reads its config dynamically is still fully configurable.

Build the JSON **in memory** and send it on **stdin**; never put a secret on
the command line (`curl -d '{…secret…}'` leaks it into `ps`/`/proc` and your
shell history). Keep shell tracing off and don't echo the request body or the
raw response:

```bash
# DATABASE_URL / STRIPE_SECRET come from your own secret store, already in the
# environment. jq reads them with its `env.NAME` builtin INSIDE the program, so
# no value is passed as an argument (not even via `jq --arg`, which would put it
# in argv / `ps`). `--data-binary @-` sends the body on stdin, so no value ever
# appears in argv or shell history.
set +x
jq -n '{env: {DATABASE_URL: env.DATABASE_URL, STRIPE_SECRET: env.STRIPE_SECRET}}' \
  | curl -sS -X PUT https://app.moonbase.cloud/api/v1/sites/<slug>/env \
      -H "Authorization: Bearer $MOONBASE_API_KEY" \
      -H "User-Agent: my-agent/1.0" \
      -H "Content-Type: application/json" \
      --data-binary @- \
  | jq -r '"set: " + (.set | join(", "))'   # keys only; values are never echoed
```

Send an `env` object for a batch, or a single `key`/`value` pair. The write is
**all-or-nothing**: every entry is validated before any is written, so one bad
entry fails the whole call with a `400` that names the offending `key` and why
— an invalid name, an empty value, an over-long value, or a moonbase-managed
name — and nothing is stored. A value is stored encrypted and is **never
returned or logged**; a success names only the keys it set (`set`, `count`).
moonbase-managed names (the MOONBASE_ and MOONSERVER_ prefixes, and a
\*_LIVE_URL) are refused — moonbase sets those itself.

**What a success proves — and what `GET` can and can't confirm.** A `2xx` with
`set`/`count` is the write's acknowledged receipt: those keys were accepted and
stored (the write is atomic — see below). Treat THAT as your confirmation, not a
follow-up `GET`. A `GET` lists key **names** only; values are write-only and
never read back, so a `GET`:

- confirms a **new** key now exists (its name appears), but
- **cannot confirm an overwrite**. Re-setting an existing key returns the same
  name whether the OLD or the NEW value is stored, so a `GET` can't tell you the
  value actually changed. Don't claim it does.

To be sure a changed value took effect, rely on the write receipt, then verify
at the **app level** — redeploy (values apply on the next deploy) and have the
app read the variable, or hit a health/debug route that reflects it. Set
variables before you deploy, or set them and redeploy.

The whole set is written in **one transaction**, so a mid-write fault stores
nothing and comes back as `503 env_write_failed` (not a partial write) — safe to
retry. A full mission returns `409 env_vars_limit` (with `max`); a cap that
can't be read returns `503 mission_cap_unavailable`. In every failure case
nothing is stored.

**On an unknown outcome** (the connection dropped, or a `5xx` such as
`env_write_failed`), don't assume it failed *or* succeeded. For a **new** key,
`GET` and see whether its name appeared. For an **overwrite**, `GET` can't tell
you which value is stored (the name is there either way) — the write is atomic,
so resending the same batch is safe **only when you are the single coordinated
writer** for that mission (plain last-write-wins). If another authorized writer
may also be setting env on it (a second pipeline, a teammate, a rotation job), a
blind resend can clobber a newer value written between your first attempt and
the retry; then don't blind-retry — coordinate with the other writer. (A
receipt/revision + conditional write, e.g. an `If-Match` precondition, is the
robust fix, but the env API does **not** document one today — treat it as a
future-API option, not something you can rely on now; today's supported path is
writer coordination.) Never reconcile by reading a value back (values stay
write-only); confirm at the app level — a check that shows **readiness only,
never the value** (a dependent operation that works, not the secret echoed
back). Setting a mission's
secrets this way, rather than leaving them for the owner in the browser, is what
keeps an automated deploy from going *live but not yet configured*.

## Not available in the API today

Keys limited to one mission or read-only keys (there's only the deploy
scope); redeploying by address in one call (look up the `id` first); listing
all missions; and reading why a build failed after the stream is gone. A
shipped `.env` still supplies only its non-secret values at build time — real
secrets go in with the env API above, or in **Mission Control → Environment
Variables**.
