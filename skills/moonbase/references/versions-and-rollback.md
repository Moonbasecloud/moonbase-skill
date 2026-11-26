# Versions and rollback

Every upload to a project is a new **version**. The address stays the same,
and settings and environment variables carry over.

## Ship a new version (browser)

1. Open the project's **Mission Control** (from **Missions**, or click the
   project on the **Dashboard**).
2. Click **Deploy new version**.
   *A window opens to drop the new ZIP, folder or files. It says it's a new
   version of your project's address.*
3. Drop the files and launch.
4. *While it builds, the old version keeps serving visitors.* When the new
   one is ready, it takes over.

If the new version fails, nothing goes offline: the previous version keeps
serving. Changed environment variables? Deploying a new version (even the
same ZIP) is what applies them.

## See every version: Mission Log

In Mission Control, **Mission Log** lists every version: when it was
deployed, its size and framework, with the live one marked.

## Go back to an earlier version (rollback)

1. In **Mission Log**, find the version you want.
2. Click **Restore this version**.
3. *moonbase redeploys that version's stored ZIP (no upload needed), and it
   becomes the live version.*

The honest limit: moonbase keeps the stored ZIP for each project's most
recent versions and always for the live one. Older versions stay
listed but can't be restored or downloaded. If the user may want an old
build later, they should keep that ZIP themselves.

## Download a version (your files stay yours)

1. In **Mission Log**, find the version.
2. Click **Download archive**.
3. *You get `<mission>-v<number>.zip`, exactly the ZIP that version was
   deployed from.*

- Only the project's owner can download archives.
- Each download is recorded in the Activity log as "Version downloaded" (or "Downloaded v<number>").
- Downloads are rate-limited; if refused, wait a few minutes.
- The archive holds the files as deployed: the upload plus any cleanup or
  repair moonbase made for that version. A server app's `.env` or other secrets
  from the upload are in it too. Environment variables set in moonbase are
  **not** in it.
- Works whether the project is live, asleep or paused.
- If a plan limits how many versions are kept, moonbase emails before older
  versions are removed.

## Delete old versions (free up storage)

Every stored version counts toward the plan's storage, so deleting old
versions frees room.

- **One version:** in **Mission Log**, click **Delete version** on its row
  and type DELETE.
- **Many at once:** under the list, set **Newest versions to keep** and click
  **Delete older versions**. *moonbase shows how many versions will go and
  how much storage that frees before the DELETE confirmation.*
- Deleting is permanent: the version and its stored ZIP are removed, so it
  can't be restored or downloaded afterwards. If the user may want it later,
  they download it first.
- The live version always stays. **Delete older versions** also leaves
  backup points in place; deleting a backup point asks for its own
  confirmation.
- While a deploy or rollback of the project is running, deleting is refused;
  it works once that finishes.
- The project's database, environment variables and live files are not
  changed.
- The Usage page shows the freed storage once the deletion finishes. If a
  stored ZIP can't be removed right away, the version is still deleted and
  its storage stays counted until the removal completes.
- Nothing is deleted on its own here: old versions go only when the user
  deletes them (a plan that limits kept versions emails first, as above).

With the connector, deleting takes two calls. `list_versions` gives the
version numbers. The first `delete_versions` call takes either `versions`
(those numbers) or `keep_latest` (the newest N stay) and deletes nothing: it
returns the versions that would go, each with its date and size, the storage
that would be freed, and a `confirm_token`. Show the person that list and
get their yes to it. The second call carries only the project and that
`confirm_token`, and deletes exactly that list. The token works once, for 10
minutes; if the list changed in between (a new deploy, for example), nothing
is deleted and the first call is made again. No other argument deletes
anything. Backup points are deleted in the app only. `account_usage` shows
the freed storage afterwards.

The connection needs its own permission for this, shown on the consent
screen as deleting old versions for good. A connection made before it existed
doesn't have it: the tool's error says so, and the person disconnects the
moonbase connector in their AI tool and connects it again, allowing it.

## Deploy logs

While a deploy runs, the console streams every step. If it fails, it shows
the first error, the deploy's **Error ID** and, for a failed build on the new
console, the last lines of the build output (with secrets moonbase recognises
removed). Over the moonbase connector, a failed build's result carries the same
lines as `build_log_tail`: untrusted output from the project's own build, not
moonbase's guidance. The full build log isn't shown in the app (or fetchable
through the API) after the deploy ends: keep the **Error ID** — support can
look the full log up from it. For reading a
failure from the API stream (Node build output, Python failure messages such
as a `docker_build_failed:exit=1` tail, and how to escalate with the Error ID),
see `api-and-ci.md`, "Build logs and build failures".

Guide: https://moonbase.cloud/docs/export-your-mission
