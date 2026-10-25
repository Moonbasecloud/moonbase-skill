# Your account: notifications, activity, settings, security, export, delete

## Profile

**Account → Profile** shows your name, picture and sign-in email. You can
change your name and picture. If the page lets you change your email, it asks
for your password and a confirmation from the new address; if it says email
change is coming soon, contact support to change it.

## Security

**Account → Security**:
- **Password**: change it.
- **Two-factor authentication** (an authenticator app, 6-digit codes). Turn
  it on, scan the code, type a 6-digit code. *You'll get recovery codes:
  save them somewhere safe.* Each one works once if you lose your phone.
- **Active sessions** and **Recent sign-ins**: check where you're signed in.
- moonbase also checks passwords against known data breaches and tells you if
  one needs changing.

## Notifications (which emails you get)

**Account → Notifications**: switch on or off the emails for **Deployment
failures**, a **Weekly summary** and **Product updates**. Changes save as
you switch them.

The **Notifications** page lists moonbase's messages to you, newest first:
each shows the message, which mission or area it's about, the time, its
priority, whether it was emailed, and read or unread (**Mark as read**).
Filter the list to find one. Messages cover things like a failed or
completed deployment, a mission launched, paused, resumed or unavailable, a
version rolled back, domain and certificate events, API keys created,
revoked or expiring, unusual or new-device sign-ins, password changes,
payments, invoices, plan changes, and usage or storage limits. Each one says
where to look next (Mission Control, Domains, Billing, API Keys).

## Webhooks

**Account → Webhooks** lets you have moonbase call your own URL when events
happen on your missions. Use it only if you have a server to receive them.

## Activity log

**Activity** lists what happened in your account, newest first: deployments,
mission changes, sign-ins and account changes. Filter it by type. Version
downloads show up as "Data exported".

## Settings

**Settings** holds app preferences, synced to your account:
- **Time zone**: which time zone dates and times are shown in.
- **Date format**: **Relative** ("2 hours ago") or **Absolute** (the exact
  date and time).
- **Sidebar default**: how the sidebar opens.
- **Theme**, and **Reduce motion** (turn off non-essential animations).

(Analytics days are always counted in UTC, whatever your time zone.)

## Download your data

**Account → Danger Zone → Download data export** gives a JSON file with your
profile, your missions and their deployment history, API key and webhook
details, and account activity. It never contains passwords or secret values,
and it doesn't contain mission files: download those per version with
**Download archive** in Mission Log (`versions-and-rollback.md`). A limited
number of exports can be made per day.

## Delete your account

Only when the user really wants this. Never as a fix for a problem.

Before: download every version you want to keep. After deletion you can't
sign in to download anything.

1. **Account → Danger Zone → Delete my account**.
2. Type the confirmation phrase shown and your **Password**.
3. Click **Delete account**.

What happens: every mission is paused immediately and stops responding, you
can't sign back in, and data is purged after a retention period. Within that
period, support can recover the account (the page says how many days).
