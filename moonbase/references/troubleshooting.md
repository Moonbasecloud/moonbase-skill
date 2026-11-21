# Troubleshooting

First rule: **a failed deploy never takes a working mission offline.** If the
mission already had a live version, that version keeps serving while you fix
the new one — stay calm and tell the user that. On a **first** deploy it's
different: there's no earlier version to fall back to, so a failed first deploy
means the mission isn't up yet. Don't reassure the user that "the old version
is still live" when there isn't one.

Second rule: read moonbase's own message first. Every failure shows a plain
title, an explanation, a next step and a **TRK-ID** (`TRK-…`, also called
Error ID or trace ID). Prefer moonbase's words over guessing, and never
delete a mission to "start fresh".

## "My deploy failed"

1. Read the first red line in the deploy console, and copy the **Error ID**
   (**Copy Error ID**).
2. Find its title or code in the table below and do what it says.
3. If it's a build problem, reproduce it on your own computer **the way your
   app is built** — if it fails there, fix it there first:
   - **Node / JS:** `npm install && npm run build && npm start`.
   - **Python:** `pip install -r requirements.txt`, then start it the way
     moonbase will — `gunicorn app:app` (WSGI) or `uvicorn main:app` (ASGI).
4. Check the usual suspects **for your stack**: the app listens on `PORT`;
   **Node** has a production `start` script in `package.json`; **Python**
   exposes a top-level app object and lists every dependency in
   `requirements.txt`; every environment variable it needs is set. (See
   `building-for-moonbase.md`.)
5. Deploy a new version. Still stuck? Send the TRK-ID to support.

Common console lines: "npm install failed" (a dependency problem), "npm run
build failed" (a build error in the code), "Port not bound" (the app isn't
listening on `PORT`), "Container exited" (the app crashed when starting).

### When the build itself fails (the raw message)

A build crash comes back as an `error` event whose raw `message` starts with
`docker_build_failed:exit=1`, followed by the real cause. The code is a plain
build failure (not a setup code from the table below); read the tail:

Every build or container-start failure carries a **stable `friendly.code`**
(branch on it, not on the wording) and often a `friendly.culprit` naming the
exact token at fault. The full code list and its retry classification live in
`api-and-ci.md` ("Build logs and build failures") — the single source of truth
for which codes exist and which are retryable; the fix per code is in the
tables on this page. The common tails:

| Tail of the message | What it is → fix |
|---|---|
| `npm error` / `ETARGET` / `ERESOLVE` | Node dependency or version clash. Run `npm install` locally, fix the pin, redeploy. |
| `npm run build` error | A real build error in the code. Reproduce with `npm run build` locally and fix it. |
| "Unsupported engine" / "EBADENGINE" | The project pins a Node version moonbase's image doesn't provide. Widen `engines.node` in `package.json` to a current LTS. |
| `Missing script: "start"` | No production `start` script. Add one to `package.json` (e.g. `node server.js`). |
| `pip` / "Could not find a version" / "No matching distribution" | Python dependency: a package with no Linux wheel, a bad pin, or a `-r`/`-c` reference that isn't at the project root. See the Python contract in `building-for-moonbase.md`. |
| "ResolutionImpossible" / "conflicting dependencies" | Two Python pins demand incompatible versions. Align the pins in `requirements.txt`. |
| "Could not open requirements file" | A `-r`/`-c` file referenced from `requirements.txt` wasn't included. Ship it, or drop the line. |
| "ModuleNotFoundError" at start | A dependency the app imports is missing from `requirements.txt` (or `package.json`). Add it and redeploy. |
| "could not connect to server" / "Connection refused" to a DB port | The app couldn't reach its database (missions can reach a database directly now). Check the host, port and credentials; set the connection string in Mission Control → Environment Variables. |
| "KeyError" / "environment variable … not set" | A required environment variable isn't set. Set it in Mission Control → Environment Variables, then deploy a new version. |

Node build steps stream as `build_log` lines while they run; Python build
output isn't streamed, so for a Python failure the `message` on the `error`
event is the diagnosis. Read it yourself; show the user `friendly.*`, and if
you share a log excerpt, redact and bound it first (`api-and-ci.md`). There's
no way to fetch the full build log once the stream closes — keep the **TRK-ID**
and give it to support to read the full log. (`api-and-ci.md`, "Build logs and
build failures", has the detail.)

## "It deployed but the page is blank or broken"

Usually inside the app, not the deploy:
- a `fetch` to `http://localhost:…` in the app's code: change it to the real
  address, upload a new version;
- a needed environment variable is empty: set it in Mission Control →
  Environment Variables, then **Deploy new version**.

## "It says deployed, but not ready"

The deploy landed and the app answered its readiness check with "not ready" (the
deploy result shows `app_ready: false`; the status endpoint shows
`"deployed_not_ready"` and `appReady: false`). It is **not** a failed deploy and
you should **not** upload again. It usually means the app still needs
configuration (a missing environment variable or secret) or is warming up:
- set what it needs in Mission Control → Environment Variables, then **Deploy new
  version** only if the app needs a restart to read it;
- check the app's readiness endpoint (`/readyz` by default, or the path in
  `MOONBASE_READINESS_PATH`) returns 2xx once it is configured;
- poll the status endpoint: it re-checks readiness and flips to `live` when the
  app answers ready.

## "It's online, but the page is blank"

The page answered, but the files that draw it did not load. The deploy result
shows `app_ready: false` and an `asset_problem` listing the files, and exit 4
from the parser prints them. Waiting won't help. moonbase already repairs the
usual leftovers (a Vite `base` or a Create React App `homepage` from GitHub
Pages), so this is a path it couldn't read, such as one set from an environment
variable. Make the app work from the root of its address, then upload it again.

## "My mission is offline"

1. Open the mission's `<mission>.moonbase.host` address in a new tab.
2. Works there but not on your domain? It's the domain: check the DNS record
   and status on **Domains** (`custom-domains.md`).
3. Neither works? Open **Mission Control**: is it **Paused** (resume it) or
   **Asleep** (the first visit wakes it in a second or two)?
4. Try another network, to rule out your connection.
5. Still down? Contact support with the mission's name, address, when it
   started and the exact browser error. Don't delete the mission.

## Other symptoms

| Symptom | Cause → fix |
|---|---|
| "Mission Warming Up" / loading screen | A sleeping free-plan mission waking up. Wait a second or two. |
| Changed an environment variable but nothing changed | Changes apply on the next deploy. Click **Deploy new version**. |
| Domain won't verify | Record must match exactly; A for main domain, CNAME for subdomain; Cloudflare grey cloud; wait up to 48h; click **Verify** again. |
| Adding a domain says another account added it but never proved it (`domain_held_unverified`) | Add the TXT record moonbase shows (name and value) at the DNS provider, then add the domain again. Over the connector, open the returned `domain_page` link for the person. See `custom-domains.md`. |
| Traffic numbers don't load | A missing data source, not a broken mission. Try later. |
| A script or CI job stopped authenticating | Its API key was probably deleted. Check **API Keys**; create a new key and update the secret. |
| moonbase's own error page (not your mission's) | Part of the app failed to load. Use the way back it offers; missions aren't affected. Repeated? Contact support. |
| A shared invite won't accept | See the table in `sharing.md`. |

## Every error moonbase can show at deploy time

Title = what moonbase shows in the browser. Code = what the API returns (in
`error` before the stream, or in the `error` event's `code`). Retry ✓ =
safe to try again after waiting.

### Your account

| Code | Title | What it means → what to do |
|---|---|---|
| `auth_required` | Sign in required | Not signed in (API: no `Authorization` header). Sign in, or send `Authorization: Bearer mb_live_…`. |
| `email_not_verified` | Verify your email first | The email isn't verified. Click the link in the verification email, then try again. |
| `identity_required` | Finish setting up your account | Onboarding isn't finished. Complete the "one more step" page, then try again. |
| `terms_reconsent_required` | Terms of Service updated | The terms changed. Sign in, accept the current terms, try again. |
| `user_not_found` | Account not found | moonbase could not find the account this request belongs to. Reconnect moonbase in the assistant's connector settings, then try again; if the account was deleted, the person signs up again. |
| `forbidden` | | Signed in as someone the mission is shared with as View. Ask the owner or an admin for Edit access. |

A payment problem on the account shows as a banner across the signed-in app,
and with the connector `account_usage` and `platform_status` return it as
`payment`: its `state` (`ok`, `payment_failed` or `past_due`), for
`past_due` the `grace_ends_at` when its grace period ends, and `billing_url`.
When the state isn't `ok`, tell the person plainly and give them the
`billing_url` link, where they can see what happens next and update their
payment method. It's their own account only, and it has no card or amount in
it.

### API keys

| Code | Title | What it means → what to do |
|---|---|---|
| `invalid_key` | API key not accepted | Wrong, revoked or no deploy scope. A password reset, a password change or an email change on the account can turn off all its API keys as a precaution. Ask the person to create a new key in **API keys** (https://app.moonbase.cloud/api-keys), open that link for them, and have them put the key in the CI secret store, not in the chat. |
| `key_expired` | API key expired | Ask the person to create a new key in **API keys** (https://app.moonbase.cloud/api-keys) and use it. |
| `no_key` | | Status endpoint called without a key. Send `Authorization: Bearer mb_live_…`. |
| `not_found` | | Status endpoint: no mission with this address on the key's account. Check the address and the account. |

### The upload itself

| Code | Title | What it means → what to do |
|---|---|---|
| `no_file` | No file selected | The upload request had no file in its file field, so nothing was uploaded. Send the ZIP as a multipart/form-data field named file; with an upload link, get a new one from create_upload first. |
| `invalid_body` | Upload didn't come through | Usually a network hiccup. Upload again. |
| `not_zip` | We couldn't turn this into a mission | Not a ZIP or a single HTML file. Zip the project with `index.html` or `package.json` at the root. |
| `too_large` | File too large | Over the biggest size moonbase accepts. Leave out `node_modules`, build output, unused assets. |
| `too_large_for_now` | Too large for now | Over the size we can take for now while large-upload support is finished, even if your plan allows more. Make the ZIP smaller and try again. |
| `too_many_files` | Too many files | Too many files to package (browser). Remove `node_modules` and build output. |
| `empty_selection` | Nothing to upload | Shown only in the moonbase web app; tools never receive it. |
| `drop_without_file` | That was a link, not a file | Shown only in the moonbase web app; tools never receive it. |
| `file_read_failed` | Couldn't read that file | Shown only in the moonbase web app; tools never receive it. |
| `zip_unsafe` | Upload rejected for safety | This upload's structure tripped one of our safety checks (an unusual file count, size, or path) and was rejected before we opened it. If this is a legitimate project, the person can contact moonbase support with the trace ID from this result (trace_id, or trkId in an upload link's response), or the attempt_id. |
| `no_html_or_package_json_found` | We couldn't find anything to launch | No `index.html` or `package.json` anywhere. Add one. |
| `no_html_found` | No HTML found | Looks static but has no `.html` file. Include one. |
| `classification_error` | We couldn't read this upload | Something about this upload's structure confused our inspector. The person can contact moonbase support with the trace ID from this result (trace_id, or trkId in an upload link's response), or the attempt_id. |
| `go_not_supported` | Go apps can't run on moonbase yet | moonbase doesn't run Go. If the project has a web frontend, build it and upload those files. |
| `python_entrypoint_not_detected` | We couldn't find where your Python app starts | Python web apps deploy now, but moonbase needs a standard app object — a top-level `app = Flask(__name__)`, `app = FastAPI()`, or a Django `manage.py` + `wsgi.py`. Add one and re-upload. |
| `python_runtime_not_supported` | We couldn't find where your Python app starts | Legacy code — Python web apps now deploy (see `python_entrypoint_not_detected` above and `building-for-moonbase.md`). A current upload won't return this. |
| `framework_unsupported:<framework>` | Framework not supported yet | A recognised framework moonbase can't build yet (a backend language, or a framework not on the supported list). Deploy a static build. |
| `astro_ssr_not_supported` | Astro SSR isn't supported yet | Astro deploys its **static** output in v1. Remove the SSR adapter / set `output: 'static'` so `astro build` produces `dist/`, then re-upload. |
| `sveltekit_adapter_node_required` | SvelteKit needs the Node adapter | moonbase runs SvelteKit with `@sveltejs/adapter-node`. Switch `svelte.config.js` to that adapter and re-upload. |
| `hardcoded_secret_detected` | Possible secret found in your upload | A possible key or credential was found in the files and the upload was stopped. Remove the credential from the uploaded files, use environment variables, and upload again. If the credential is real, rotate it with its provider. When all matches are in test or fixture files, the refusal suggests leaving them out of the ZIP or source after confirming that the app builds and runs without them. A Firebase web config's `apiKey` (in an object with `authDomain` and `projectId`) is not refused; any other `AIza` Google key is, so move it to an environment variable read by server code. |
| `malware_detected` | Upload blocked — malware detected | Our malware scanner found something harmful in this upload and blocked it before deploying. If the person believes this is a false positive, they can contact moonbase support with the trace ID from this result (trace_id, or trkId in an upload link's response), or the attempt_id. |
| `scanner_unavailable` | Upload paused — scanner temporarily unavailable | Retry ✓ in a few minutes. |
| `scan_incomplete` | Upload paused — scan didn't finish | Retry ✓ in a few minutes. |
| `scan_too_large` | Upload paused — file too large to scan | Make it smaller, or contact support. |

### Names and missions

| Code | Title | What it means → what to do |
|---|---|---|
| `invalid_name` | Mission name isn't valid | Use 3–32 lowercase letters, numbers and single hyphens, starting with a letter. |
| `name_taken` | Name already taken | Pick another name. To update **your own** mission at that address, ship a new version (API: `redeployProjectId`). |
| `name_recently_used` | Name recently used | Belonged to a recently deleted mission and is on hold. Pick another. |
| `mission_slug_unusable` | | This mission's address is too short to deploy to now. Contact support to rename it. |
| `project_not_found` | Mission not found | The mission you're updating isn't found or isn't yours. Pick the right mission (API: look up the id with the status endpoint). |
| `upload_token_slug_mismatch` | | Internal upload token used for another mission. API users: use the API key. |

### Plan limits

| Code | Title | What it means → what to do |
|---|---|---|
| `plan_limit_exceeded` (`reason`: `max_deploy_size`) | Deploy size limit reached | Over the plan's per-upload size. Make it smaller or upgrade. |
| `plan_limit_exceeded` (`reason`: `max_sites`) | Mission limit reached | No free mission slot. Ship a new version of an existing mission, delete one, or upgrade. |
| `plan_limit_exceeded` (`reason`: `max_storage`) | Storage limit reached | Would pass total storage. Delete older versions or missions, or upgrade. |
| `weight_overage` | Storage upgrade needed | Would pass the free storage. Upgrade or free up storage. |
| `upgrade_required` | Upgrade required | This needs a paid plan. Upgrade. |

Show the exact limit from the **structured fields** (`reason`, and
`limit`/`current`/`max` where present), not by quoting the raw `message` (see
`api-and-ci.md`, "Build logs and build failures").

### Timing and approvals

| Code | Title | What it means → what to do |
|---|---|---|
| `deploy_in_progress` | A deploy is already running | One build per mission at a time. Retry ✓ after `retry_after_sec` seconds. |
| `superseded_by_newer_version` (a `deploy_status` result code) | Replaced by a newer version | Not an error. A newer deploy or upload of the same project replaced this one; deploy_status with the newer attempt_id shows its progress. |
| `source_unavailable` (a `deploy_status` result code) | Stored upload could not be read | moonbase could not read back the stored upload after maintenance, so this version was not published. The current live version is unchanged. Upload this version again. |
| `expired_during_maintenance` (a `deploy_status` result code) | Waited past its maintenance deadline | This version was still waiting at its expires_at and was not published. The live version is unchanged. Deploy again. |
| `auth_required` (a `deploy_status` result code) | Deploy's access was not accepted | This deploy's access was missing or not accepted: the upload token was absent, mistyped, already used or expired, or the connection's access had expired or was revoked. It was not published, and the live version is unchanged. Deploy again; with a create_upload link, send its x-upload-token header exactly as given; if moonbase asks for approval, reconnect it in the assistant's connector settings. |
| `async_deploy_unavailable` (a `deploy_status` result code) | Queued deploy couldn't run | moonbase couldn't run this queued deploy safely just now, so it was not published. The live version is unchanged. Deploy again shortly. |
| `deploy_history_pending` (a `deploy_status` result code) | Published, still being recorded | This version was published, but moonbase is still recording it in the project's history, and a new deploy of this project is refused, or waits in the queue until that finishes or the queued deploy expires. Check deploy_status with the attempt_id; it is not necessary to deploy again. If it then reports the history entry missing, contact moonbase support with the attempt ID. |
| `deploy_interrupted_before_dispatch` (a `deploy_status` result code) | Deploy stopped before publishing | This deploy was interrupted before publishing began and was not published. The live version is unchanged. Deploy again. |
| `project_not_found` (a `deploy_status` result code) | Project not available | The project this version was for was deleted, archived or renamed, or is not this account's, so it was not published. list_missions shows the projects this account can deploy to. |
| `deploy_failed` | Deploy failed | This deploy did not finish normally, and the new version may or may not be live. Check deploy_status before deploying again (with the attempt ID if the deploy returned one); deploy_logs for the project shows each version's status and any error moonbase recorded. |
| `queue_expired` | Queued deploy never started | This deploy waited in the queue for 15 minutes without starting and was not published. The live version is unchanged. Deploy again; if it keeps happening, check platform_status. |
| `deploy_queue_full` | Too many deploys waiting | This account, or moonbase as a whole, already has as many deploys waiting as moonbase holds at once. Wait a few minutes, then try again; deploy_status for a project shows its waiting deploy. |
| `mission_downgrade_locked` | This project is locked because your plan ended | Your plan ended, and this project is over the Free plan's limit, so it's locked. It keeps working, but it can't be deployed, rolled back, resumed or renamed, and its password, environment variables and domains can't be changed. You can still pause, export, archive or delete it. Upgrade to unlock it. If you don't, it will be paused and later deleted; we'll email you before it's deleted. (`downgrade_state` is `locked` or `paused`.) Not retryable, and nothing in the code needs changing: only the owner can upgrade or delete missions so the account fits. |
| `upload_check_busy` | Couldn't check this upload just now | moonbase is busy and couldn't check this upload just now. Nothing was published. Try again in a minute. |
| `rate_limited` | Too many launches in a row | Too many deploys in a short time. Retry ✓ after `retry_after_sec` seconds. Don't loop. |
| `consent_required` | This deploy needs your OK in moonbase | moonbase suggested changes to this project that need the person's approval before it can deploy. Give the person the consent_url from this result; they deploy this project once from the browser and review the changes. After that, deploys from tools work again. |
| `consent_invalid_json` | Something went wrong with your confirmation | The confirmation for the suggested fixes was not in the expected format, so nothing changed. Send the upload again with the consent field fixed; with an upload link, get a new one from create_upload first. Leaving consent out applies moonbase's suggested fixes, so leave it out only if the person agrees. |

### Password at deploy time

A password can't be set as part of a deploy request. Deploy first, then set
it in Mission Control → **Password protection** (`mission-control.md`).

| Code | Title | What it means → what to do |
|---|---|---|
| `password_protection_coming_soon` | Set the password in Mission Control | A visitor password can be given only with a project's first launch, not with a new version. Deploy the new version without a password, then use set_password if the project has no password yet; an existing password is changed on the project's page in the moonbase app. |
| `password_protection_disabled` | Password protection is switched off right now | moonbase paused new password protection, so a launch with a password was refused. Try later. Launch without one only if the mission doesn't need to be protected from its first version. |
| `password_protection_unavailable` | We couldn't protect the mission | The password couldn't be turned on before launch, so nothing was published. If moonbase couldn't confirm the password is off the address again, the address stays reserved to your account as a failed project until it is checked. Tell the person the version isn't live and the password isn't on. Deploy again in a minute. If the address now shows as a failed project in your account, it keeps its password: ship a new version to that project (deploy with its slug; API: redeployProjectId), without a password, and it goes live protected. A new launch with the same name is refused as name_taken. If the person agrees the first version may be public for a moment, deploy without a password, then use set_password. If it keeps failing, they can contact moonbase support with the trace_id. |
| `invalid_password` | Password isn't valid | The deploy's `password` field had the wrong length. Leave it out and set the password in Mission Control. |

### moonbase's side

| Code | Title | What it means → what to do |
|---|---|---|
| `internal` | Something went wrong | Something went wrong on moonbase's side, and this version is not live. Try again; if it keeps happening, the person can contact moonbase support with the trace ID from this result (trace_id, or trkId in an upload link's response), or the attempt_id. |
| `deployment_maintenance` | | New deployments are temporarily paused. Existing missions keep serving. Wait and retry later; do not change database settings or start duplicate deploys. |
| `waiting_for_maintenance` (a `deploy` result phase, status `in_progress`) | | Not an error. moonbase is in a maintenance window and accepted this version instead of refusing it; it starts publishing it automatically when maintenance ends, and the current live version keeps serving until then. Tell the person it is waiting. Poll `deploy_status` with the `attempt_id` about once a minute; do not start duplicate deploys. A newer deploy of the same project replaces the waiting one. Past `expires_at` it is not published (`expired_during_maintenance`): deploy again. Only new versions of an existing project wait this way: a `deploy` with `files` or `zip_base64`, and, where moonbase has it switched on, a ZIP sent to a `create_upload` link or the app's upload screen (the upload answers HTTP 202 with this receipt). Other sources and new projects still get `deployment_maintenance`. |
| `service_draining` | | moonbase is restarting. Retry ✓ under the same bounded policy (wait the server's delay first). |

moonbase may also publish a service notice to its customers, such as planned
maintenance or a known incident. It shows as a banner across the signed-in
app until the time moonbase set, and with the connector `platform_status`
returns it as `service_notice` (its `message` and `expires_at`). When there is
one, tell the person what it says, as moonbase's words. Its `expires_at` is
when the notice comes down, not a promise of when any work ends. The notice
alone does not stop deploys; a refusal still says why in its own code.

## When nothing here fits

Say you're not sure, point to https://moonbase.cloud/docs/troubleshooting and
https://moonbase.cloud/docs/deploy-wont-work, and to support with the TRK-ID
(`safety-and-support.md`). A confident wrong answer is worse than "let's ask
support".
