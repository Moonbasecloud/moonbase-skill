# Versions and rollback

Every upload to a mission is a new **version**. The address stays the same,
and settings and environment variables carry over.

## Ship a new version (browser)

1. Open the mission's **Mission Control** (from **Missions**, or click the
   mission on the **Dashboard**).
2. Click **Deploy new version**.
   *A window opens to drop the new ZIP, folder or files. It says it's a new
   version of your mission's address.*
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

The honest limit: moonbase keeps the stored ZIP for each mission's most
recent versions and always for the live one. Older versions stay
listed but can't be restored or downloaded. If the user may want an old
build later, they should keep that ZIP themselves.

## Download a version (your files stay yours)

1. In **Mission Log**, find the version.
2. Click **Download archive**.
3. *You get `<mission>-v<number>.zip`, exactly the ZIP that version was
   deployed from.*

- Only the mission's owner can download archives.
- Each download is recorded in the Activity log as "Data exported".
- Downloads are rate-limited; if refused, wait a few minutes.
- The archive is the original upload as-is: if it had a `.env` or secrets,
  they're in it too. Environment variables set in moonbase are **not** in it.
- Works whether the mission is live, asleep or paused.
- If a plan limits how many versions are kept, moonbase emails before older
  versions are removed.

## Deploy logs

While a deploy runs, the console streams every step. If it fails, it shows
the first error and the deploy's **TRK-ID**. The full build log isn't shown
in the app today: support can look it up from the TRK-ID.

Guide: https://moonbase.cloud/docs/export-your-mission
