# The deploy API, CI and GitHub Actions

For developers, scripts, pipelines and platforms that deploy to moonbase.

## The sources of truth (send developers here)

- **OpenAPI 3.1 spec:** https://app.moonbase.cloud/api/v1/openapi.json. Every
  endpoint, form field, stream event, response field and error code. Import
  it into Postman or Insomnia, or generate a client.
- **API Reference (human-readable):** https://moonbase.cloud/docs/api-reference
- **Integration guide** with copy-paste curl, Node and Python:
  https://moonbase.cloud/docs/integrate-moonbase
- **GitHub Actions guide:** https://moonbase.cloud/docs/github-actions-ci-cd

## The two endpoints

| | |
|---|---|
| `POST https://app.moonbase.cloud/api/projects/upload/stream` | Upload a ZIP (multipart), stream the deploy |
| `GET https://app.moonbase.cloud/api/v1/sites/{address}/status` | Read a mission's state |

Auth on both: `Authorization: Bearer mb_live_…` (an API key from
**API Keys**). Always use `app.moonbase.cloud`. The old `app.moonbase.host`
only redirects.

Form fields: `file` (required, the ZIP), `redeployProjectId` (an existing
mission's id: ship a new version), `name` (address of a new mission),
`displayName` (new missions only).

## Reading the response

1. Check `Content-Type`.
   - `application/json`: refused before it started. Body:
     `{"error": "<code>", "message", "title", "nextStep", "trkId"}` plus
     extra fields for some codes (`retry_after_sec`, `consent_url`,
     `reason`/`limit`/`current`).
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
     `code` (stable, branch on it), `message` (raw, don't show), `trace_id`
     (`TRK-…`, for support), `stage`.

A full tested curl script is in `deploy-for-the-user.md` (Step 4).

## Retries: only these

- `429 rate_limited` and `409 deploy_in_progress`: wait `retry_after_sec`
  seconds (also the `Retry-After` header), then retry.
- `500 internal`, `503 service_draining`, `scanner_unavailable`,
  `scan_incomplete`: moonbase's side. Retry with a growing delay.
- Everything else means the request must change first. Show the `message`
  and `nextStep`.

Limits: a few deploys per 5 minutes and up to 100 per hour per account (plus
a per-IP limit), one build at a time per mission, and the plan's mission,
storage and per-deploy size limits. Allow at least 10 minutes for a stream.
If the connection drops, check the status endpoint before uploading again.

## GitHub Actions in five steps

1. Create a key on **API Keys** (it starts with `mb_live_`).
2. In the GitHub repo: **Settings → Secrets and variables → Actions → New
   repository secret**. Name `MOONBASE_API_KEY`, value the key.
3. Find the mission id in the mission's link
   (`https://app.moonbase.cloud/missions/<id>`) or from the status endpoint,
   and add it as `MOONBASE_MISSION_ID`.
4. Add `.github/workflows/deploy.yml`:

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
      - name: Package for moonbase
        run: zip -r deploy.zip . --exclude "node_modules/*" ".git/*" ".next/*"
      - name: Deploy to moonbase
        run: |
          curl -sN -X POST https://app.moonbase.cloud/api/projects/upload/stream \
            -H "Authorization: Bearer ${{ secrets.MOONBASE_API_KEY }}" \
            -F "file=@deploy.zip" \
            -F "redeployProjectId=${{ secrets.MOONBASE_MISSION_ID }}" \
            | tee deploy.log
          grep -q "^event: done" deploy.log
```

5. Push to `main`. The job passes only when the stream ends with `done`.

## Building moonbase into another product

Each of your users who has their own moonbase account gives you their own
key; keep keys on your server only (never in browser or mobile code, a repo
or logs). Store the `project_id` from the first `done` and send it as
`redeployProjectId` afterwards. Rotate keys by creating a new one, switching,
then deleting the old one. Full walkthrough:
https://moonbase.cloud/docs/integrate-moonbase.

## Not available in the API today

Keys limited to one mission or read-only keys (there's only the deploy
scope); redeploying by address in one call (look up the `id` first); listing
all missions; reading why a build failed after the stream is gone.
