# What the app needs from outside itself

A mission runs the app's own code. It does not supply the things that code
*talks to* — a database, another service's API, a mail or payments provider —
and it does not carry over anything that only existed on the machine the app
was built on. When one of those is missing the deploy still succeeds, the
address still answers, and the app is still broken: the page loads and the
sign-up form returns an error nobody can explain.

That is the one failure that matters most here, because it arrives *after* the
moment the person thought they had won. Everything below exists to move that
discovery earlier — to before the upload, where it is a five-minute
conversation, instead of after, where it looks like moonbase broke their app.

Say the honest sentence early: **going online and working are two different
things, and here is what yours needs so it does both.** Said first it's a plan.
Said afterwards it's an excuse.

## 1. Read the project for what it depends on

Don't ask the person what the app needs — they very likely don't know, and
asking puts the work on the one person who can't do it. The answers are in the
code:

- **Every environment variable it reads** (`process.env.X`, `os.environ["X"]`,
  `import.meta.env.X`), plus whatever `.env.example` or a local `.env` lists.
  That's the main list.
- **Client constructors and connection strings** — a database client, an SDK
  being initialised, a `fetch` to a URL that isn't the app's own.
- **Dependencies in `package.json` / `requirements.txt`** that only make sense
  with an account behind them: a database driver, an email SDK, a payments SDK,
  a model provider's client.
- **Addresses baked in from the machine it was built on.** This is the single
  most common reason an AI-built app goes live and nothing loads: the code
  carries `http://localhost:3000` or `127.0.0.1` — a database URL, an API base
  URL, a redirect target — and none of it exists on the mission. moonbase does
  flag these, but only *after* the deploy and only as a medium-severity note,
  so a person who stopped reading at "live" never sees it. Find them yourself
  and replace them with a relative path or a configured variable. The same goes
  for absolute file paths from someone's own computer.

Then sort what you found into three piles, because each needs a different
conversation:

| Pile | Example | What it needs |
|---|---|---|
| **Must exist and be reachable** | a database, an API the app calls on every request | a real, internet-reachable service and its address |
| **Must have a credential** | an API key, a token, a mail provider's key | the person's own key, set as a mission environment variable |
| **Optional** | a feature flag, a label, a tuning number with a sane default | nothing; set it or leave it |

A missing optional value is fine. A missing one from either of the first two
piles means the app goes online broken. Treat those as blocking and settle them
before you upload.

## 2. Tell the person, in their own terms

One short list, in plain words, about what the app *does* — never a table of
variable names:

> Two things your app needs that aren't inside it: it saves sign-ups to a
> database (right now it's pointing at one on your own computer, which the live
> version can't reach), and it sends the confirmation email through an email
> service, which needs a key from that service. Let's sort both out, then put
> it online.

Then handle each one with them. Don't deploy "to see what happens" and come
back with the problem.

## 3. Where a service is needed, say so — and let them choose it

The rule is the same every time: **name the need, never the vendor.** You tell
them the app needs a database set up; *they* decide where it lives. We never
tell anyone they have to open an account with a particular company.

> Your app needs a database it can reach over the internet — the one on your
> laptop won't do once it's online. Several hosted ones have a free tier; they
> all give you a connection string, which is the one thing your app needs from
> it.

If they ask for options, name several in no particular order and leave the
choice with them: for a database, Neon, MongoDB Atlas, Supabase, PlanetScale
and Railway all work; for email, Mailgun, Resend, Amazon SES, Postmark and
SendGrid all work. moonbase has no preference and no partner and does not
benefit from their pick. **Never choose for them, and never imply moonbase
requires a particular provider.** If they already have something, use it.

**A connected database is not yet a working one.** Its tables have to exist.
An app pointed at an empty database loads fine and shows nothing, which to the
person who built it looks exactly like a broken app. So run the project's own
migrations or schema setup against the database they chose, and confirm the
tables are really there, before you call the deploy done. If the project seeds
example data, decide with them whether the live version should have it.

**If the app has "sign in with Google" or any other hosted sign-in**, the
redirect URI is configured at *that provider*, not in moonbase, and it still
points at the old address. Until someone adds the mission's live address to the
provider's allowed redirect list, every person who clicks sign in gets an error
page. The app's own callback path doesn't change; the host in front of it does.
Add the live address at the provider — and remember the person may be the only
one who can sign in there to do it, so tell them exactly what to add and where.

## 4. What the runtime decides (check these facts before you promise anything)

Some of what an app needs is shaped by how a mission runs. These are facts
about the platform, not preferences, and each has one practical consequence:

- **The app can reach its own database directly.** A mission connects out to
  any public service on any port — Postgres on 5432 or a 6543 pooler, MySQL
  3306, Mongo 27017, Redis 6379, an HTTPS API on 443 — so a standard driver is
  the right answer and you do **not** need an HTTPS data proxy. Only private,
  internal and cloud-metadata addresses are blocked (`10/8`, `172.16/12`,
  `192.168/16`, loopback, CGNAT, and the `169.254` range), which also means a
  database reachable only on a private network, or an internal DNS resolver,
  won't work. Pool settings and TLS are in `references/building-for-moonbase.md`.
- **Mail goes through a provider, not a mail server.** Direct SMTP on port 25
  is blocked permanently as anti-spam. An email provider's HTTPS API works, and
  so does authenticated submission on 465 or 587 — use either.
- **Uploaded files don't survive.** The container's filesystem is rebuilt on
  every deploy, so anything the app writes to disk — uploaded images, generated
  PDFs, an SQLite file — is gone next time. Files people upload belong in
  external object storage over HTTPS.
- **Nothing scheduled runs by itself.** There is no cron and no background
  worker: one web process, and on the free plan it sleeps when idle, so
  in-process timers stop with it. A nightly job has to be an HTTPS endpoint on
  the mission that an outside scheduler calls.
- **A request is cut off at sixty seconds.** A big export, a slow model call or
  a bulk import has to return quickly and continue elsewhere, or be broken into
  pieces. Holding one request open for minutes fails.
- **A request body is capped at about sixteen megabytes**, uploads included.
  For anything larger, send it from the browser straight to object storage
  rather than through the app.
- **Resources are small and fixed** — about half a gigabyte of memory and half
  a CPU core. In-process image or video processing, or a large dataset held in
  memory, will be killed. Keep the working set small or do that work elsewhere.
- **No WebSockets.** The connection is never upgraded, so a chat, a live
  dashboard or anything built on `socket.io` will not connect. Plain
  request/response works; polling works, bounded by the sixty-second limit.
- **Free missions sleep after about thirty minutes idle** and wake themselves
  on the next request, so the first visit after a quiet spell takes a few
  seconds. Paid missions stay warm, and static missions never sleep. That is
  the answer to "why was the first load slow?" — not a fault.

If the app genuinely needs something this list rules out, say so before the
upload, not after. A person told honestly that their chat app needs a different
host is better served than one whose deploy "worked".

## 5. Real values go in the mission, never in the code

- A value that is the same for everyone and isn't secret — a public URL, a
  display name, a feature flag — can live in the code.
- A value that is **theirs** — a connection string, an API key, a token, a
  password — belongs in the mission's environment variables. Never paste one
  into a source file or a config file, never commit it, and never ask them to
  paste it into the chat. moonbase blocks an upload that looks like it carries
  a hardcoded credential (`hardcoded_secret_detected`), and a key that reached
  a repository is a key someone has to go and revoke.
- Set them with `set_env` over the connector, through the env API, or in
  **Mission Control → Environment Variables**. The mechanics, the reserved
  names and the `NEXT_PUBLIC_` warning are in
  `references/building-for-moonbase.md`.
- Ship a `.env.example` with placeholders so the next person — or the next
  agent — can see what the app reads.

## 6. Open the live link yourself before you say it's done

A deploy reporting `done` means files are being served. It does not mean the
app works, and you are the one who can tell the difference, so don't hand that
job to the person who can't.

- **Ask moonbase what's missing instead of guessing.** `list_env` returns the
  keys already set *and* the keys the uploaded code reads but hasn't got.
  Anything in that second list from pile 1 or 2 is a live, broken mission.
- **Open the live address and use the app.** Not the home page — the feature
  that depends on the database or the API. Submit the form, load the list,
  trigger the email, click sign in. Check the data really landed.
- **If something fails, name the dependency and the fix.** "The sign-up form
  can't reach the database yet — the connection string isn't set" is useful.
  "Something went wrong" is not, and it reads as moonbase's fault when it isn't.
- **Only then tell them it's live**, with the link, and say what you checked.

Deploying a half-configured app is not a faster route to the finish. The person
you're helping gets one first impression of their own work being online; make
it one where it works.
