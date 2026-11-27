# Mission Control: status, sleep, pause, password, environment variables, analytics, database export

After saving environment variables, the running app changes on its next
deploy. If `redeploy` is in the connected tool list, it rebuilds this
account’s active stored archive with the saved values after the person
approves the live change. It keeps the same version number. See
`references/mission-control.md` for archive refusals and unconfirmed outcomes.

**Mission Control** is the page each project opens to. Open it from
**Missions** (the list of all your projects, with status, latest version,
size and recent visitors) or by clicking a project on the **Dashboard**.

It shows: the live status, the latest deployment and every version
(**Mission Log**), traffic for the last 30 days, **Environment Variables** and
domains. Each project has its own link in the app (`/missions/<id>`), so
refreshing or sharing that link keeps you on the same project.

## Status: what each one means

| Status | Meaning | What to do |
|---|---|---|
| **Live** | Online and serving visitors | Nothing. Share the link. |
| **Asleep** | A free-plan dynamic project resting after no visits | Nothing. The next visit wakes it. |
| **Paused** | You paused it. Visitors see a "This app is paused" page | Resume it from Mission Control |
| **Deploying** | A new version is building | Wait. The old version keeps serving. |

## Sleep and wake (free plan)

- On the free plan, **dynamic** projects (Node.js, Next.js) go to sleep after
  about 30 minutes without visitors, to save resources.
- **Static projects never sleep.**
- The next visitor wakes it in a second or two, behind a short loading
  screen ("Waking up your app"). Nothing is broken.
- Explain it simply: "Your app takes a nap when nobody's around and wakes up
  as soon as someone knocks."

## Pause and resume

You can pause a project yourself from **Mission Control**. Visitors then see
a branded **"This app is paused"** page until you resume it, also from Mission
Control.

## Environment variables (settings and secrets for the app)

1. Open the project's **Mission Control**.
2. Go to **Environment Variables**.
3. Add each name (like `OPENAI_API_KEY`) and its value, and save.
   *Values are write-only: after saving, only the names are shown, never the
   values. They're stored encrypted.*
4. **Changes take effect on the next deploy.** With the connector, after the
   person approves the live change, call `redeploy` with the project_id or
   slug to rebuild its active stored archive with the current saved values.
   This keeps the same version number and needs no file upload. The result
   names this rebuild: `operation_id`, `completed_at` and `config_revision`
   (built from the saved variables' names and change times, never their
   values; `null` for a static project). `deploy_status` and `deploy_logs`
   show the newest as `last_redeploy`, while `last_deployed_at` keeps the
   version's own time. `config_revision` does not confirm what the running
   app loaded. It requires
   a live stored version; `no_active_deployment` or `archive_parity_pending`
   means there is no usable archive for this path. A new upload can deploy
   the project instead. An unconfirmed outcome is checked with `deploy_status`
   before another attempt. In the app, the person can deploy a new version.

**Replacing or deleting a saved value.** Each saved name has **Replace** and
**Delete**. **Replace** opens an empty field: the old value is never shown or
filled in, so the new value is typed in full. **Delete** asks for confirmation
first; the version that is live keeps running with its existing settings, and
the next deploy may fail if the app still needs that value. Both apply on the
next deploy, and both are recorded in the Activity log by name only (never the
value). Names moonbase manages itself show no Replace or Delete. Anyone who
can edit the project can replace or delete a value.

**Names moonbase manages.** moonbase sets some names itself: its own
`MOONBASE_*`, `MOONSERVER_*` and `*_LIVE_URL` names, and any saved name whose
source is `engine`, such as the `DATABASE_URL` of a moonbase database, which
moonbase refreshes at each deploy. These rows are listed (by name, like every
other) but can't be replaced or deleted from this screen, from the API or from
the connector: `set_env`, `delete_env` and the env API refuse them with
`platform_var_managed`. The connector's refusal names the screens to open:
`env_page` (this screen, where the name shows as managed) and, for a moonbase
database, `database_page` (the project's **Database** section). A
`DATABASE_URL` the person saved themselves is theirs to replace or delete.
The runtime defaults `PORT`, `NODE_ENV` and `NEXT_TELEMETRY_DISABLED` can still
be set or replaced with `set_env` or the env API; this screen shows them without
Replace or Delete, and they can't be deleted.

The link `https://app.moonbase.cloud/missions/<id>#env-vars` opens this
screen directly. Over the connector, `list_env`, `set_env` and `delete_env`
return it as `env_page`, so a person who would rather type a secret themselves
than give it to the assistant can be sent straight to the right screen.
For a secret value, such as an API key, password or connection string, the person types it on that screen through `env_page` rather than in chat.

During an upload you can also drag your `.env` file into the settings
window to fill everything in. moonbase applies non-secret values from a
shipped `.env` automatically, but never applies anything that looks like a
real credential from the file: you set those here. Values set in moonbase
always win over the file. Keep your own copy of the values: moonbase can't
show them again, and they aren't in downloaded archives.

Guide: https://moonbase.cloud/docs/environment-variables

## Analytics: what the traffic numbers mean

Mission Control shows each project's traffic for the **last 30 days, day by
day**.

| What you see | What it means |
|---|---|
| **Visitors** | Different people who opened a page that day. Someone who comes back another day counts again. Errors, robots.txt, favicons and moonbase's own checks are not visitors. |
| **Requests** | Every request to the project (pages, images, scripts, errors…), except known bots and moonbase's own checks. Always bigger than visitors. |
| Days | Counted in UTC (world time), not your local time. |
| Freshness | Updated every 15 minutes, from the server's access logs. |
| "Just launched" | No traffic figures have arrived yet for this new project. That's not a zero. |
| A day showing 0 | A real, measured zero: nobody visited. |
| "Couldn't load" | The figures couldn't be fetched right now. The project itself is fine; try later. |

Traffic is per project, not per custom domain. Visitors are counted, never
capped, on every plan.

## The "Made with moonbase" badge

Projects can show a small "made with moonbase" badge. On the free plan it's
always shown. On paid plans the owner can turn it off in the project's
**Badge** setting (**Show the moonbase badge**). Only the owner can change it,
and it applies right away.

## Password protection (only people with the password can open it)

Each project can have its own password. Only the project's owner can set it.

1. Open the project's **Mission Control**.
2. Find **Password protection** (in the **Visibility** card) and switch it on.
   *A **Password** field opens: "Turns on once you save a password."*
3. Type a password (the page says the minimum length: "Use at least …
   characters") and click **Save**.
   *The card now shows **Active**. Visitors must type the password to see
   the project.*

- **Change it:** click the saved password field, type the new one and
  **Save**. Anyone already signed in to the project is signed out.
- **Turn it off:** switch it off. The password is kept, and switching on again
  reuses it.
- **Remove it:** click **Remove**. The saved password is deleted, and anyone
  with the link can view the project again.
- moonbase never shows the saved password again (it stores it scrambled); you
  can only replace it.
- In Mission Control's **Settings**, it can be set once the project exists
  (after its first launch), and can't be removed while the project is
  **paused**. To protect a project from its very first version, give the
  password when you create it (below).
- The **New mission** window can also have a **Password protection** card.
  The password goes with the launch: moonbase's server asks for it before
  the first version is published. Static files (JavaScript, CSS, images)
  can still be served from Cloudflare's cache once a visitor who knows the
  password has loaded them, so keep secrets out of browser files.
- If the page says "Password protection is unavailable right now", moonbase
  has it switched off for new passwords for the moment; existing passwords
  keep working and can still be changed or removed.
- **A new project can be launched with a password**: `create_project`'s
  `password`, or a `password` form field on the first deploy. moonbase's
  server asks for it before the first version is published (the same
  static-file caching caveat applies). For an **existing**
  project a `password` on a deploy is refused with
  `password_protection_coming_soon`: set it in Mission Control (or with
  `set_password` without `replace`, which refuses a project that already has a saved password).
  To change a saved password, call `set_password` with `replace: true` or change it in Mission Control.
  Replacement keeps protection on or off as it was; `password_changed: true` confirms the change and does not report the current protection state.
- **Through the connector:** `create_project` and `create_upload` take
  `password`, or `generate_password: true` (moonbase makes one and returns it);
  `set_password` sets the first password on an existing project; `replace: true` changes a saved password while preserving whether protection is on or off. Ask the person to confirm the replacement before calling it. A visitor password keeps
  people out of the project; it is not an account secret, so it may go
  through the chat. Its value is visible in the conversation, and the person
  decides. API keys and other credentials are different: they are typed only
  on moonbase's own page.

## Launch check (only where moonbase has turned it on)

The Launch check is not available on most projects. moonbase turns it on
project by project, so don't offer it, list it among what moonbase does, or
promise it to the person. If they ask about it, say moonbase turns it on per
project and it may not be on for theirs. On a project without it,
`launch_check` answers `not_available`. That answer is not a fault in the
project, and waiting or deploying again does not change it. The project's
live state is in `deploy_status`, and you can open the live address and read
it directly.

Where it is on, the **Launch check** in Mission Control reads the project's
live page the way search engines and AI assistants do, and lists what to
change. It only reads; it changes nothing. Through the connector,
`launch_check` returns the same report, plus
`review_url`, which opens the Launch check for this project in moonbase. Give
the person that link as it is; where the check sits on the page can differ
between projects. Each address can be checked a few times per 10 minutes,
counted across all accounts, so moonbase never floods anyone's server; past
that the connector answers `checked_recently` and says when to try again.
What it covers:

- **AI crawler access.** robots.txt and the AI search and training crawlers
  it allows, by their robots.txt names (the report's messages list them).
  Blocking a training crawler is the owner's choice and is reported as
  information only. The check also asks for the home page as each AI crawler
  and reports any that a firewall or bot protection turns away while a
  browser gets the page.
- **Sitemap.** A sitemap.xml exists, robots.txt names it, its entries have
  real `<lastmod>` dates, and it lists the home page and the pages the home
  page links to.
- **Main text in the HTML.** The words in the HTML the server sends, without
  JavaScript, compared with the text that only appears once JavaScript runs.
- **Page basics.** Title, description, one h1, canonical link and Open Graph
  tags, on the home page and on up to four pages it links to (`pages` in the
  report says which page lacks what).
- **Structured data.** schema.org JSON-LD that fits the page's own content
  (Organization or LocalBusiness, Product, FAQPage), built only from facts
  already on the page. No reviews, ratings or details the page doesn't have.

`offers` holds drafts written from the project's own pages: a robots.txt, a
line for an existing robots.txt, a sitemap.xml or the entries it leaves out,
and an llms.txt. Each one has `ownerApprovalRequired: true`. The owner sees
the draft and decides; with their yes, the file goes into the app's source
and a new version is deployed, then the check runs again. A sitemap draft
carries no dates, because the check doesn't know when each page changed. An
llms.txt is optional, and no AI assistant promises to read one.

The check reports what a reader can see. It doesn't promise a ranking or a
mention in any AI assistant's answers.

## Managed database export

New export requests are turned on separately from database creation. A project's page or the presence
of a connector tool does not mean new export requests are available.

If the connected moonbase tools include `export_database`, use it for a
project the person owns, identified by its address or project ID. The tool
needs write permission; a read-only connection is refused. It returns the
owner's export page and status, not a database file or a download credential.

- **export_page** is the exact page URL you open for the owner.
- **state** is the latest export's status, or **none** when there is no export.
- **request_available** says whether a new request is available for this
  project. When it is false, explain that new requests are unavailable; the
  page can still show existing exports. Do not treat an existing ready export
  as permission to create another one.
- **expires_at** reports a ready export's expiry when present. Use the
  returned status and instructions; do not invent a fixed download period.

Open the exact returned **export_page** URL for the person, whether new
requests are available or the page is showing existing exports. Do not send
them searching for the export screen. If your client cannot open URLs, say
so and give that exact link; only say you opened it after doing so.

When a new request is available, the owner confirms their password on that
page and enters their two-factor code there if their account requires it.
The person completes those steps themselves; never ask for a password or
code in chat or submit it for them. An available file is
downloaded on that page, in the browser that requested it, subject to its
expiry and single-download conditions. The connector does not bypass those
checks or fetch the database contents into the conversation.

If the tool reports **no_database**, the project has no managed database
available to export. **not_found** means no project owned by that connection
matched the identifier. Do not retry with another person's project or
suggest a hidden download endpoint.

A database export is separate from downloading a project's source files or
backing up those files. Returning a page link is not evidence that an export
was created, downloaded, restored or captured by a scheduled backup.

## Moving an existing database in

A person who already has a PostgreSQL database with another provider (any
PostgreSQL server reachable on the internet) can move it into the project's
managed database through the connector. The project needs its managed
database first; it gets one at a deploy that declares it.

Moving a database in is not switched on everywhere yet. `import_database`
and `import_status` are in the connection's tools only where it is; where
they are not listed, this move is not available through the assistant, and
reconnecting does not change that. Where `import_database` is listed, it
takes three calls. The connection needs the database import permission; a connection
without it is refused and says how to reconnect with it.

1. **Call it with the project only.** It returns `import_id` and
   `import_page`, the project's Database page
   (`/missions/<project_id>/database`) at its import card. Open the exact
   `import_page` URL for the person. They sign
   in and enter the source database's connection string on that screen
   themselves. The connection string holds a password: never ask for it,
   read it back or paste it in chat, a terminal or a file. If your client
   cannot open URLs, say so and give the exact link.
2. **Call it with `import_id`** once the person says it is entered. It
   returns a preview (the source's PostgreSQL version, tables, estimated rows
   and size), `storage` (whether that fits the storage the project has left
   on its plan), how the connection to the source is protected, and a
   `confirm_token`. Show the person the preview and say plainly that the
   import replaces everything in the project's moonbase database and that
   the app can't use its database while it runs. When `tls` is
   **encrypted_unverified**, tell them the source server's certificate could
   not be verified. When **skipped_schemas** is not empty, tell them those
   provider service schemas are not copied.
3. **Call it with `confirm_token` alone** after the person's yes to that
   preview. The token works once and expires at `confirm_token_expires_at`.
   The import then runs in the background.

Follow it with `import_status`. A finished import reports the source and the
project side by side: tables, exact row counts and a sentinel (every row of
one table compared). That is all that is checked.

When the state is **done_with_warnings**, the import is not complete: the
project's database refused some statements. **warnings** gives the real
number, and **refused_objects** names them (up to 25; **list_truncated** says
when there are more). These are usually security policies, foreign keys,
indexes, views or extensions tied to the other provider. Never tell the
person such an import matches the source. Say what was checked, how many
statements were not applied, and name them. The common case from Supabase:
row-level security is on for a table but its policies were refused, so the
app reads no rows from that table, with no error. The fix is a database
migration in the next deploy that adds what is missing (new policies, or
row-level security turned off on those tables), or a roll back.

moonbase takes a safety copy of the project's database before replacing
anything, and puts it back by itself when the tables, rows or sentinel do not
match the source; a failed import then leaves the database as it was. The
source database is only read and is left as it is.

While **rollback_available** is true, the import can be rolled back:
`import_database` with `import_id` and `rollback: true` returns a
`confirm_token` for the roll back, and a call with that token starts it.
Changes made in the database after the import are lost by a roll back; say
so before the person agrees.

The source has to offer an encrypted (TLS) connection, and a connection
through a transaction pooler is refused with **source_snapshot_unavailable**:
the provider's direct or session connection string works. **does_not_fit**
and **import_exceeds_storage** mean the source is larger than the storage
left on the plan; `account_usage` shows it. **import_unavailable** means
imports are not open on this moonbase right now. After an import the app
keeps the `DATABASE_URL` moonbase already sets; nothing has to be changed in
its environment values.

## Managed database status

Use `project_info` or `deploy_status` with the owned project's `project_id` or
`slug`. These existing read tools return `database`, `database_page` and
`database_next_steps`. Polling `deploy_status` with an `attempt_id` (an input only where queued
deploys are on) returns that deployment attempt rather than database status.

`database` is the same owner-only metadata view used by Mission Control:
connection, storage measurements and freshness, backup evidence, and access
state. It contains no connection string, password, database identifier or
export download credential. Missing measurements stay null. Backup `state`
can be `available`, `pending`, `failed`, `disabled`, `no_schedule` or
`unavailable`. Report `checkedAt`, `lastSucceededAt`, `latestAttemptFailed` and
`nextScheduledAt` together: an older verified success does not hide a newer
failed attempt. Unavailable evidence does not mean backups are disabled or
successful. Stale or mismatched-generation backup evidence is unavailable.

Backup evidence requires a configured, installed trusted feed for that
project, and each database still requires actual generation-bound enrollment, whatever the account's plan.
A connected database alone does not establish backup
enrollment, a successful backup, restore readiness or general availability.
No retention or recovery guarantee follows from this status response.

`recovery_state` (in `project_info`, `deploy_status` and `export_database`)
keeps six facts apart: `connected`, `export_available` (a new export can be
requested), `export_completed` (an export of this database was built),
`backup_enrolled`, `backup_verified` and `restore_demonstrated`. Each has a
`state` of `yes`, `no` or `unknown`, a `reason` and `evidence`. It is `yes`
only with its evidence; `unknown` means no evidence reached moonbase, so do
not report it as yes or no. `backup_verified` means a backup file's checksum
was checked when it was written, not that a restore works.
`restore_demonstrated` is `no` (`no_non_destructive_restore_tool`): moonbase
has no tool that restores a database without replacing it. Never turn these
into a backup schedule, retention period, recovery point or recovery time.

When human action needs the database screen, **open the exact `database_page`**
(`/missions/<project_id>/database`, the project's Database page, for its owner) for the person. If the client cannot open
URLs, explain that limitation and provide the exact returned link. Only say
it is open after opening it. The person enters secrets directly in moonbase;
never request them in chat, CLI or clipboard. Database status is read-only;
use `export_database` and its separate export page for the owner export flow
described above.

## Managed database: one per project, inside the plan's storage

Every plan, Free included, can add one managed PostgreSQL database per
project; it uses the plan's storage. It is created only when the project's
`moonbase.json` asks for one, and there is no separate database allowance.
moonbase decides per account when creation is open: `account_usage`'s Managed
database line shows where this account stands. The presence of a tool or
guide is not proof that a project is enrolled.

Files, versions and databases count toward one storage allowance. Use `account_usage` for the account's storage report;
it shows the plan's storage and what is using it, part by part, where each
part is measured. A missing, stale or unverified database measurement leaves
storage unknown; do not report it as zero or claim that the account has spare
capacity. A part reported as not measured is not zero either. An unknown
total can refuse a new upload until moonbase can establish the storage
measurement. This accounting does not introduce a new charge or change
billing prices.

For a project's managed database, do not infer a backup schedule, retention
period, maximum data-loss window or restore capability from plan eligibility
or from a tool being present. Report only the backup status evidence returned
for that database and point its owner to the Database page.

A project never holds two databases. An existing database, including one
whose setup failed, is set up again in place rather than a new one being
created, and a project whose earlier database is still
waiting to be removed is refused a new one until that finishes. A refusal is
not permission to remove another database, backup or recovery record; follow
the returned account guidance and ask support about unresolved resources.

### Creating it and connecting to it

Declare the database in the `moonbase.json` at the project's root and deploy.
This needs a dynamic project, one moonbase builds and runs; on a static
project (plain files, no build step, no server) the declaration stops the
deploy. A `DATABASE_URL` the person saved before the project ever had a
managed database is kept, and no managed database is created over it.

```json
{ "database": { "engine": "postgresql", "migrate": "node migrate.js" } }
```

On that deploy, moonbase creates the database, runs the migrate command and
gives the migrate command and the running app the same three environment
variables. Nobody types a connection string.

- `DATABASE_URL`: user, password, host, port and database. It carries no TLS
  settings. Use it exactly as given: **do not add `sslmode`** or any other
  parameter to it. moonbase manages it and refreshes it at each deploy.
- `PILOT_DB_CA_FILE`: the path of a certificate file (PEM), the authority
  that signed the database server's certificate.
- `PILOT_DB_SERVER_NAME`: the name on the database server's certificate.
  Verify against this name; the host inside `DATABASE_URL` can be different.

This is the required connection recipe, and the app has to apply it: the
variables alone configure no driver. The managed database refuses a
connection that is not encrypted. With Node
and the `pg` package, in the migration script and in the app:

```js
const fs = require("node:fs");
const tls = require("node:tls");
const { Pool } = require("pg");

const serverName = process.env.PILOT_DB_SERVER_NAME;
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 3,
  ssl: {
    ca: fs.readFileSync(process.env.PILOT_DB_CA_FILE, "utf8"),
    servername: serverName,
    checkServerIdentity: (_host, cert) => tls.checkServerIdentity(serverName, cert),
    rejectUnauthorized: true,
  },
});
```

For every language and driver: give the driver the CA file and the server
name through its own TLS options, with full verification, and never turn
verification off. An ORM or migration tool that only takes a URL needs the
same TLS options in its own configuration, not in the URL. The app's database
login allows 4 connections at once and stops a statement after 5 seconds, so
keep the pool at 3 or fewer.

The migrate command runs once per deploy, inside the built app, before the
new version goes live, and the whole command has 30 seconds. It must exit 0
on success and non-zero on failure, and be safe to run again on a database
that already has the tables. If it fails, the previous version stays live.
A failed migration can leave changes in the database even though the new
version is not published, so keep migrations compatible with the version
still running. With the connector, `get_build_guide` returns
this section with the account's own storage limit and what happens past it.

### Pending protection purge

`project_info` returns `protection_cache_purge.status` for the owner: `pending` means a protection purge is queued or in progress; `not_queued` means no pending job was found; `unknown` means the status could not be read. No pending job is not proof that every cached copy has been cleared.
