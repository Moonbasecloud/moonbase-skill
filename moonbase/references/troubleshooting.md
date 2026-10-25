# Troubleshooting

First rule: **a failed deploy never takes a mission offline.** The previous
version keeps serving. Stay calm, and tell the user that.

Second rule: read moonbase's own message first. Every failure shows a plain
title, an explanation, a next step and a **TRK-ID** (`TRK-…`, also called
Error ID or trace ID). Prefer moonbase's words over guessing, and never
delete a mission to "start fresh".

## "My deploy failed"

1. Read the first red line in the deploy console, and copy the **Error ID**
   (**Copy Error ID**).
2. Find its title or code in the table below and do what it says.
3. If it's a build problem, check on your own computer:
   `npm install && npm run build && npm start`. If it fails there, fix it
   there first.
4. Check the usual suspects: the app listens on `PORT`, `package.json` has a
   production `start` script, every environment variable it needs is set.
   (See `building-for-moonbase.md`.)
5. Deploy a new version. Still stuck? Send the TRK-ID to support.

Common console lines: "npm install failed" (a dependency problem), "npm run
build failed" (a build error in the code), "Port not bound" (the app isn't
listening on `PORT`), "Container exited" (the app crashed when starting).

## "It deployed but the page is blank or broken"

Usually inside the app, not the deploy:
- a `fetch` to `http://localhost:…` in the app's code: change it to the real
  address, upload a new version;
- a needed environment variable is empty: set it in Mission Control →
  Environment Variables, then **Deploy new version**.

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
| `user_not_found` | Account not found | The account no longer exists. Sign out and in; for the API, use a key from a current account. |
| `forbidden` | | Signed in as someone the mission is shared with as View. Ask the owner or an admin for Edit access. |

### API keys

| Code | Title | What it means → what to do |
|---|---|---|
| `invalid_key` | API key not accepted | Wrong, revoked or no deploy scope. Create a new key on **API Keys**. |
| `key_expired` | API key expired | Create a new key and use it. |
| `no_key` | | Status endpoint called without a key. Send `Authorization: Bearer mb_live_…`. |
| `not_found` | | Status endpoint: no mission with this address on the key's account. Check the address and the account. |

### The upload itself

| Code | Title | What it means → what to do |
|---|---|---|
| `no_file` | No file selected | Nothing attached. Choose the file (API: send it as `file`). |
| `invalid_body` | Upload didn't come through | Usually a network hiccup. Upload again. |
| `not_zip` | We couldn't turn this into a mission | Not a ZIP or a single HTML file. Zip the project with `index.html` or `package.json` at the root. |
| `too_large` | File too large | Over the biggest size moonbase accepts. Leave out `node_modules`, build output, unused assets. |
| `too_many_files` | Too many files | Too many files to package (browser). Remove `node_modules` and build output. |
| `empty_selection` | Nothing to upload | The folder or files had nothing deployable. Pick the right folder. |
| `drop_without_file` | That was a link, not a file | You dropped a link. Drag the file from Finder/Downloads, or click to choose it. |
| `file_read_failed` | Couldn't read that file | The browser couldn't open it. Click to choose it; move AirDrop files into a normal folder first. |
| `zip_unsafe` | Upload rejected for safety | Unusual file count, size or paths. If it's a normal project, contact support with the TRK-ID. |
| `no_html_or_package_json_found` | We couldn't find anything to launch | No `index.html` or `package.json` anywhere. Add one. |
| `no_html_found` | No HTML found | Looks static but has no `.html` file. Include one. |
| `classification_error` | We couldn't read this upload | moonbase couldn't work out how to deploy it. Contact support with the TRK-ID. |
| `python_runtime_not_supported` | Python isn't supported yet | Python isn't supported. Deploy a static export instead. |
| `framework_unsupported:<framework>` | Framework not supported yet | Recognised framework moonbase can't build yet (e.g. Astro, SvelteKit, Vue, Nuxt). Deploy a static build. |
| `hardcoded_secret_detected` | Possible secret found in your upload | A key or password is in the files. Remove it, use environment variables, upload again. |
| `malware_detected` | Upload blocked — malware detected | Something harmful was found. Remove it; false positive? Contact support with the TRK-ID. |
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

The `message` always states the exact limit; pass it on.

### Timing and approvals

| Code | Title | What it means → what to do |
|---|---|---|
| `deploy_in_progress` | A deploy is already running | One build per mission at a time. Retry ✓ after `retry_after_sec` seconds. |
| `rate_limited` | Too many launches in a row | Too many deploys in a short time. Retry ✓ after `retry_after_sec` seconds. Don't loop. |
| `consent_required` | This deploy needs your OK in moonbase | moonbase wants to change the build and needs the owner's OK. Open `consent_url`, deploy once from the browser and review the changes. Then tool deploys work again. |
| `consent_invalid_json` | Something went wrong with your confirmation | A hiccup sending your approval. Try again from the start. |

### Password at deploy time

A password can't be set as part of a deploy request. Deploy first, then set
it in Mission Control → **Password protection** (`mission-control.md`).

| Code | Title | What it means → what to do |
|---|---|---|
| `password_protection_coming_soon` | Password protection isn't available yet | A `password` was sent with the deploy. Leave it out, deploy, then set the password in Mission Control. |
| `invalid_password` | Password isn't valid | The deploy's `password` field had the wrong length. Leave it out and set the password in Mission Control. |

### moonbase's side

| Code | Title | What it means → what to do |
|---|---|---|
| `internal` | Something went wrong | Retry ✓ once. Keeps happening? Support with the TRK-ID. |
| `service_draining` | | moonbase is restarting. Retry ✓ in a few seconds. |

## When nothing here fits

Say you're not sure, point to https://moonbase.cloud/docs/troubleshooting and
https://moonbase.cloud/docs/deploy-wont-work, and to support with the TRK-ID
(`safety-and-support.md`). A confident wrong answer is worse than "let's ask
support".
