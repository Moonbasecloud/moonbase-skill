# Mission Control: status, sleep, pause, password, environment variables, analytics

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
| **Paused** | You paused it. Visitors see a "Mission Paused" page | Resume it from Mission Control |
| **Deploying** | A new version is building | Wait. The old version keeps serving. |

## Sleep and wake (free plan)

- On the free plan, **dynamic** missions (Node.js, Next.js) go to sleep after
  about 30 minutes without visitors, to save resources.
- **Static missions never sleep.**
- The next visitor wakes it in a second or two, behind a short loading
  screen ("Mission Warming Up" / "Loading…"). Nothing is broken.
- Explain it simply: "Your app takes a nap when nobody's around and wakes up
  as soon as someone knocks."

## Pause and resume

You can pause a mission yourself from **Mission Control**. Visitors then see
a branded **"Mission Paused"** page until you resume it, also from Mission
Control.

## Environment variables (settings and secrets for the app)

1. Open the mission's **Mission Control**.
2. Go to **Environment Variables**.
3. Add each name (like `OPENAI_API_KEY`) and its value, and save.
   *Values are write-only: after saving, only the names are shown, never the
   values. They're stored encrypted.*
4. Click **Deploy new version** (the same ZIP is fine). **Changes only take
   effect on the next deploy.**

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
| **Visitors** | Different people that day. Someone who comes back another day counts again. |
| **Requests** | Every request to the mission (pages, images, scripts…), except known bots. Always bigger than visitors. |
| Days | Counted in UTC (world time), not your local time. |
| Freshness | Updated every 15 minutes, from the server's access logs. |
| "Just launched" | No traffic figures have arrived yet for this new mission. That's not a zero. |
| A day showing 0 | A real, measured zero: nobody visited. |
| "Couldn't load" | The figures couldn't be fetched right now. The mission itself is fine; try later. |

Traffic is per mission, not per custom domain. On paid plans, visits beyond
the plan's monthly number are still counted and the mission stays live.

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

- **Change it:** click **Change password**. Anyone already signed in to the
  mission is signed out.
- **Remove it:** switch it off and confirm **Remove**. Anyone with the link
  can view the mission again.
- moonbase never shows the saved password again (it stores it scrambled); you
  can only replace it.
- It can be set only **after the first launch**, and can't be removed while
  the mission is **paused**.
- The **New mission** window can also have a **Password protection** card,
  applied as soon as the mission exists.
- If the page says "Password protection is unavailable right now", moonbase
  has it switched off for new passwords for the moment; existing passwords
  keep working and can still be changed or removed.
- **Deploying through the API can't set a password** (a `password` form
  field is refused with `password_protection_coming_soon`). Deploy, then set
  the password in Mission Control.
