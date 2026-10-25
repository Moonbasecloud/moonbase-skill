# Deploying for the user (when you can run commands)

When the user says **"deploy this to moonbase"** and you can run shell
commands (or make an HTTP request with a file), you can do the deploy
yourself with moonbase's deploy API. If you can only chat, walk the user
through the browser upload in `getting-started.md` instead.

Note: there is **no published moonbase MCP server or plugin** today. Use the
API with `curl`, as below. It's the same endpoint the browser uses, with the
same checks.

## Step 1. The user makes an API key (they do this, not you)

Tell the user, one step at a time:

1. Open **https://app.moonbase.cloud/api-keys**.
2. Click **Create API key** and give it a name (like the name of the tool
   that will deploy).
3. *You'll see the full key once, starting with `mb_live_`.* Copy it now: it
   can never be shown again.
4. Store it where I can use it without seeing it: an environment variable
   named `MOONBASE_API_KEY`, set in your own terminal (not in this chat), or
   your tool's secret storage. In a terminal:
   ```bash
   export MOONBASE_API_KEY="paste-your-key-here"
   ```

**Never ask the user to paste the key into the chat.** Never write it into a
file or the repository, and never print it. Always use `$MOONBASE_API_KEY`.
If a key was pasted into the chat by accident, tell the user to delete it on
the API Keys page and create a new one.

Facts about keys: every key has one scope, **Deploy**. A key works for every
mission on its account (it can't be limited to one mission). Up to 10 keys per
account. Each key can be deleted on its own; the others keep working.

## Step 2. Package the project

From the project's root folder, make `mission.zip` without dependencies,
build output, git data or secrets:

```bash
zip -r mission.zip . -x "node_modules/*" "*/node_modules/*" ".git/*" ".next/*" "dist/*" "build/*" ".env" ".env.*" ".DS_Store"
```

Keep `.env.example` if it exists (the `-x ".env.*"` pattern also skips it; add
it back with `zip mission.zip .env.example` when it has no secrets). Check the
rules in `building-for-moonbase.md` first: root layout, `PORT`, `start`
script.

## Step 3. New mission, or new version?

- **New mission:** don't send `redeployProjectId`. Optionally send `name` (the
  address: 3 to 32 lowercase letters, numbers, single hyphens, starting with a
  letter; random if left out) and `displayName`.
- **"Update my mission X" / redeploy by name:** look up the mission's id from
  its address first, then send it as `redeployProjectId`. **Never** send
  `name=X` to update: that tries to create a second mission and fails with
  `name_taken`.

```bash
curl -s "https://app.moonbase.cloud/api/v1/sites/<address>/status" \
  -H "Authorization: Bearer $MOONBASE_API_KEY" | jq -r .id
```

The id is also in the mission's page link in the app
(`https://app.moonbase.cloud/missions/<id>`) and in the `done` event of the
last deploy (`project_id`).

## Step 4. Deploy and read the result

```bash
API="https://app.moonbase.cloud"
curl -sN "$API/api/projects/upload/stream" \
  -H "Authorization: Bearer $MOONBASE_API_KEY" \
  -F "file=@mission.zip" \
  -F "redeployProjectId=$MOONBASE_MISSION_ID" > deploy.log

if grep -q '^event: done' deploy.log; then
  grep -A1 '^event: done' deploy.log | sed -n 's/^data: //p' | jq -r '"Live: " + .url'
elif grep -q '^event: error' deploy.log; then
  grep -A1 '^event: error' deploy.log | sed -n 's/^data: //p' | jq -r '"Deploy failed: " + (.friendly.title // .message) + " (reference " + .trace_id + ")"'
  exit 1
elif jq -e .error deploy.log > /dev/null 2>&1; then
  # No stream: a JSON error from before the stream opened.
  jq -r '"Deploy failed: " + .error + " — " + (.message // "") + (if .retry_after_sec then " (retry in \(.retry_after_sec)s)" else "" end)' deploy.log
  exit 1
else
  echo "The stream closed before done or error. Check the mission status before uploading again."
  exit 1
fi
```

For a **new** mission, remove the `redeployProjectId` line (add
`-F "name=my-idea"` if the user chose an address).

What to tell the user:
- **Success:** give them the live URL from `done.url`. If
  `self_repair_notice` is set, tell them what moonbase fixed. If
  `skipped_entries` isn't empty, say which files were left out.
- **Failure:** show `friendly.title`, `friendly.explanation` and
  `friendly.nextSteps` in plain words, plus the `trace_id` (`TRK-…`) for
  support. Look up the `code` in `troubleshooting.md`.
- **Wait-and-retry codes** (`deploy_in_progress`, `rate_limited`): wait
  `retry_after_sec` seconds, then try **once** more. Never loop.
- **Connection dropped** before `done` or `error`: don't upload again. Check
  status (Step 5).

Allow at least 10 minutes for a build before giving up on the stream. For a
ZIP over about 90 MB, send the same request to
`https://upload.moonbase.cloud/api/projects/upload/stream` (same key, same
fields).

## Step 5. Check a mission's status

```bash
curl -s "https://app.moonbase.cloud/api/v1/sites/<address>/status" \
  -H "Authorization: Bearer $MOONBASE_API_KEY"
```

Returns `id`, `slug`, `displayName`, `status`, `isPaused`, `isArchived`,
`publicUrl`, `currentVersion`, `lastDeployedAt`, `deployInProgress` and
`deployStartedAt`. To learn how a deploy ended without the stream: check every
few seconds until `deployInProgress` is `false`; if `currentVersion` went up,
the new version is live at `publicUrl`. The reason for a failed build is only
in the stream's `error` event.

A key reads only its own account's missions; any other address answers
`not_found`. There is no endpoint that lists all missions.

## Saying it simply

After a successful deploy, say something like: "Done! Your mission is live
at https://my-idea.moonbase.host. Anyone with this link can open it. Next
time just say 'deploy this to moonbase' and I'll ship a new version to the
same link."
