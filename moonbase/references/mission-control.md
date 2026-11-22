# Mission Control: status, sleep, pause, password, environment variables, analytics, database export

**Mission Control** is the page each mission opens to. Open it from
**Missions** (the list of all your missions, with status, latest version,
size and recent visitors) or by clicking a mission on the **Dashboard**.

It shows: the live status, the latest deployment and every version
(**Mission Log**), traffic for the last 30 days, **Environment Variables** and
domains. Each mission has its own link in the app (`/missions/<id>`), so
refreshing or sharing that link keeps you on the same mission.

## Status: what each one means

| Status | Meaning | What to do |
|---|---|---|
| **Live** | Online and serving visitors | Nothing. Share the link. |
| **Asleep** | A free-plan dynamic mission resting after no visits | Nothing. The next visit wakes it. |
| **Paused** | You paused it. Visitors see a "This app is paused" page | Resume it from Mission Control |
| **Deploying** | A new version is building | Wait. The old version keeps serving. |

## Sleep and wake (free plan)

- On the free plan, **dynamic** missions (Node.js, Next.js) go to sleep after
  about 30 minutes without visitors, to save resources.
- **Static missions never sleep.**
- The next visitor wakes it in a second or two, behind a short loading
  screen ("Waking up your app"). Nothing is broken.
- Explain it simply: "Your app takes a nap when nobody's around and wakes up
  as soon as someone knocks."

## Pause and resume

You can pause a mission yourself from **Mission Control**. Visitors then see
a branded **"This app is paused"** page until you resume it, also from Mission
Control.

## Environment variables (settings and secrets for the app)

1. Open the mission's **Mission Control**.
2. Go to **Environment Variables**.
3. Add each name (like `OPENAI_API_KEY`) and its value, and save.
   *Values are write-only: after saving, only the names are shown, never the
   values. They're stored encrypted.*
4. Click **Deploy new version** (the same ZIP is fine). **Changes only take
   effect on the next deploy.**

**Replacing or deleting a saved value.** Each saved name has **Replace** and
**Delete**. **Replace** opens an empty field: the old value is never shown or
filled in, so the new value is typed in full. **Delete** asks for confirmation
first; the version that is live keeps running with its existing settings, and
the next deploy may fail if the app still needs that value. Both apply on the
next deploy, and both are recorded in the Activity log by name only (never the
value). Names moonbase manages itself show no Replace or Delete. Anyone who
can edit the mission can replace or delete a value.

**Names moonbase manages.** moonbase sets some names itself: its own
`MOONBASE_*`, `MOONSERVER_*` and `*_LIVE_URL` names, and any saved name whose
source is `engine`, such as the `DATABASE_URL` of a moonbase database, which
moonbase refreshes at each deploy. These rows are listed (by name, like every
other) but can't be replaced or deleted from this screen, from the API or from
the connector: `set_env`, `delete_env` and the env API refuse them with
`platform_var_managed`. The connector's refusal names the screens to open:
`env_page` (this screen, where the name shows as managed) and, for a moonbase
database, `database_page` (the mission's **Database** section). A
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

Mission Control shows each mission's traffic for the **last 30 days, day by
day**.

| What you see | What it means |
|---|---|
| **Visitors** | Different people who opened a page that day. Someone who comes back another day counts again. Errors, robots.txt, favicons and moonbase's own checks are not visitors. |
| **Requests** | Every request to the mission (pages, images, scripts, errors…), except known bots and moonbase's own checks. Always bigger than visitors. |
| Days | Counted in UTC (world time), not your local time. |
| Freshness | Updated every 15 minutes, from the server's access logs. |
| "Just launched" | No traffic figures have arrived yet for this new mission. That's not a zero. |
| A day showing 0 | A real, measured zero: nobody visited. |
| "Couldn't load" | The figures couldn't be fetched right now. The mission itself is fine; try later. |

Traffic is per mission, not per custom domain. Visitors are counted, never
capped, on every plan.

## The "Hosted by moonbase" badge

Missions can show a small "hosted by moonbase" badge. On the free plan it's
always shown. On paid plans the owner can turn it off in the mission's
**Badge** setting (**Show the hosted badge**). Only the owner can change it,
and it applies right away.

## Password protection (only people with the password can open it)

Each mission can have its own password. Only the mission's owner can set it.

1. Open the mission's **Mission Control**.
2. Find **Password protection** (in the **Visibility** card) and switch it on.
   *A **Password** field opens: "Turns on once you save a password."*
3. Type a password (the page says the minimum length: "Use at least …
   characters") and click **Save**.
   *The card now shows **Active**. Visitors must type the password to see
   the mission.*

- **Change it:** click the saved password field, type the new one and
  **Save**. Anyone already signed in to the mission is signed out.
- **Turn it off:** switch it off. The password is kept, and switching on again
  reuses it.
- **Remove it:** click **Remove**. The saved password is deleted, and anyone
  with the link can view the mission again.
- moonbase never shows the saved password again (it stores it scrambled); you
  can only replace it.
- In Mission Control's **Settings**, it can be set once the mission exists
  (after its first launch), and can't be removed while the mission is
  **paused**. To protect a mission from its very first version, give the
  password when you create it (below).
- The **New mission** window can also have a **Password protection** card.
  The password goes with the launch: moonbase's server asks for it before
  the first version is published. Static files (JavaScript, CSS, images)
  can still be served from Cloudflare's cache once a visitor who knows the
  password has loaded them, so keep secrets out of browser files.
- If the page says "Password protection is unavailable right now", moonbase
  has it switched off for new passwords for the moment; existing passwords
  keep working and can still be changed or removed.
- **A new mission can be launched with a password**: `create_mission`'s
  `password`, or a `password` form field on the first deploy. moonbase's
  server asks for it before the first version is published (the same
  static-file caching caveat applies). For an **existing**
  mission a `password` on a deploy is refused with
  `password_protection_coming_soon`: set it in Mission Control (or with
  `set_password`, which refuses a mission that already has a saved password),
  and change it in Mission Control.
- **Through the connector:** `create_mission` and `create_upload` take
  `password`, or `generate_password: true` (moonbase makes one and returns it);
  `set_password` sets one on an existing mission. A visitor password keeps
  people out of the mission; it is not an account secret, so it may go
  through the chat. Its value is visible in the conversation, and the person
  decides. API keys and other credentials are different: they are typed only
  on moonbase's own page.

## Launch check: search engines and AI assistants

The **Launch check** in Mission Control reads the mission's live page the
way search engines and AI assistants do, and lists what to change. It only
reads; it changes nothing. It runs on missions where moonbase has turned the
check on; elsewhere the connector answers `not_available`.

Through the connector, `launch_check` returns the same report, plus
`review_url`, which opens the Launch check for this mission in moonbase. Give
the person that link as it is; where the check sits on the page can differ
between missions. Each address can be checked a few times per 10 minutes,
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

`offers` holds drafts written from the mission's own pages: a robots.txt, a
line for an existing robots.txt, a sitemap.xml or the entries it leaves out,
and an llms.txt. Each one has `ownerApprovalRequired: true`. The owner sees
the draft and decides; with their yes, the file goes into the app's source
and a new version is deployed, then the check runs again. A sitemap draft
carries no dates, because the check doesn't know when each page changed. An
llms.txt is optional, and no AI assistant promises to read one.

The check reports what a reader can see. It doesn't promise a ranking or a
mention in any AI assistant's answers.

## Managed database export (closed pilot)

Database exports are part of the closed managed-database pilot, with no date for wider availability. A mission's page or the presence
of a connector tool does not mean new export requests are available.

If the connected moonbase tools include `export_database`, use it for a
mission the person owns, identified by its address or project ID. The tool
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

A database export is separate from downloading a mission's source files or
backing up those files. Returning a page link is not evidence that an export
was created, downloaded, restored or captured by a scheduled backup.

## Managed database status (closed pilot)

Use `mission_info` or `deploy_status` with the owned project's `project_id` or
`slug`. These existing read tools return `database`, `database_page` and
`database_next_steps`. Polling `deploy_status` with an `attempt_id` returns
that deployment attempt rather than database status.

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
project; default pilot eligibility and an explicit catalog rollout mode
still require actual generation-bound enrollment. A connected database alone does not establish backup
enrollment, a successful backup, restore readiness or general availability.
No retention or recovery guarantee follows from this status response.

When human action needs the database card, **open the exact `database_page`**
(`/missions/<project_id>#database`) for the person. If the client cannot open
URLs, explain that limitation and provide the exact returned link. Only say
it is open after opening it. The person enters secrets directly in moonbase;
never request them in chat, CLI or clipboard. Database status is read-only;
use `export_database` and its separate export page for the owner export flow
described above.

## Managed database allowance and storage (closed pilot)

Managed databases are a closed pilot: customers cannot create one today, and
there is no date for wider availability. The planned allowance is one managed
database in each paid plan. Actual availability and the configured allowance
still govern creation; the presence of a tool or guide is not proof that a
project is enrolled. Existing
databases remain subject to their account's resource and storage limits.

Use `account_usage` for the account's storage report. Managed database bytes
count together with live files and retained source archives. A missing, stale
or unverified database measurement leaves storage unknown; do not report it
as zero or claim that the account has spare capacity. An unknown total can
refuse a new upload until moonbase can establish the storage measurement.
This accounting does not introduce a new charge or change billing prices.

Creation reserves the configured database allowance across all Missions in
the account, including provisioning and failed resources. Two simultaneous
requests do not each receive the same remaining allowance. An existing
resource can recover without creating another allowance. A quota refusal is
not permission to remove another database, backup or recovery record; follow
the returned account guidance and ask support about unresolved resources.
