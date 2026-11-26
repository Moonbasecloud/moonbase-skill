# Building for moonbase: a project that deploys first time

Use this while the project is being built or right before it's zipped. Most
failed uploads are layout or settings mistakes that are free to avoid now.

## Assess fit first — before you package or deploy

Take a few seconds to see what the project actually is, and tell the user
honestly **up front** whether moonbase is a fit — don't shoehorn a poor fit
into a broken deploy. (This is the honest-errors principle applied *before* the
deploy, not after.)

- **Good fit, proceed normally:** a static project, or a web app in a supported
  framework (Next.js, Vite/React/Vue, Astro, SvelteKit, Nuxt, plain
  Node/Express, or Python Flask/Django/FastAPI — see below).
- **Poor fit — say so before uploading, and why.** Signals:
  - a **desktop / GUI app**, anything that needs the user's own machine, or a
    server that **can't be made to read the `PORT` env var** (moonbase binds the
    app to `PORT`; a hardcoded port it won't give up won't be reachable);
  - a backend language moonbase doesn't run (**Ruby, Go, Rust, PHP, Java**);
  - something that needs **WebSockets or other real-time / persistent
    connections**;
  - **heavy or GPU compute**;
  - a required **persistent local disk** — moonbase's filesystem is
    **ephemeral**, so data lives in the project's managed database (see *Data
    and storage* below), not in files.

  A static export is often the way around a near-miss. Keep it short and
  natural: a quick "here's what I see, and whether moonbase fits," then proceed
  or explain the mismatch.

## Static or dynamic? moonbase decides

- **Static:** a ready-to-serve `index.html` at the root, no build step, and
  no Node server in `package.json`. moonbase serves the files as they are. A
  ZIP with just one `index.html` works. Static projects never sleep.
- **Dynamic:** a `package.json` with a Node server (Express, plain Node), or a
  project that needs building (Vite, Next.js, React, Create React App).
  moonbase installs, builds and runs it.

Supported and auto-detected, with no build config to write: static
HTML/CSS/JS, Next.js, Vite, Create React App, plain React, plain
Node/Express (a valid `package.json` with a `start` script), and Python web
apps.

Python (v1): Flask, Django and FastAPI deploy when the project exposes a
standard app object. moonbase picks gunicorn (WSGI) or uvicorn (ASGI)
automatically and binds it to `PORT` — you do **not** write a start command.
List dependencies in `requirements.txt`. The full contract (entry points,
dependencies, the app-factory rule, what to verify) is in **Python web apps:
the full contract** below; read it before you deploy a Python project. If
moonbase can't find a startable app it says so
(`python_entrypoint_not_detected`) instead of producing a broken deploy.

Also supported: **Vue** (Vite — static build), **Astro** (static output,
`astro build` → `dist/`), **SvelteKit** (with `@sveltejs/adapter-node`), and
**Nuxt** (default `nuxt build` → Nitro node server). v1 limits: Astro **SSR**
(an SSR adapter or `output: 'server'/'hybrid'`) isn't deployable yet — build
static instead; SvelteKit needs the **Node adapter** specifically
(`@sveltejs/adapter-node`), not adapter-static/auto. Each needs a `build`
script in `package.json`. moonbase tells you honestly when a project is a
deferred sub-case instead of producing a broken deploy.

**Not supported:** other backend languages (Ruby, Go, PHP, Java…). In those
cases moonbase says so instead of producing a broken deploy; a static export
is the way around it.

## Python web apps: the full contract

Read this whole section before deploying a Python project; the checklist at
the end assumes it.

**Runtime.** The app runs on `python:3.12-slim-bookworm` (Python 3.12, Debian
bookworm). gunicorn and uvicorn are both installed; moonbase detects which to
use and starts the app bound to `0.0.0.0:$PORT` with a sixty-second request
timeout. There is **no Procfile and no custom start command** for Python
(unlike Node, you do not write a `start` script) — moonbase derives the start
command itself from the app object it finds. The only lever you have is
*where you put that app object*.

**The entry point (first match wins).** moonbase looks, in order, for:

1. **Django** — a root `manage.py` plus a `<project>/wsgi.py` that exposes
   `application` → started with gunicorn.
2–3. **FastAPI / Starlette (ASGI) or Flask (WSGI)** — the first root module,
   in the order `app.py`, `main.py`, `server.py`, `wsgi.py`, `asgi.py`,
   `application.py`, with a **top-level** `app = FastAPI()` (or
   `Starlette(...)`) → started with uvicorn, or `app = Flask(__name__)` →
   started with gunicorn. Inside one file, FastAPI / Starlette is checked
   first.
4. **Generic WSGI** — a root `wsgi.py` whose top level exposes `application`
   (or `app`) → gunicorn.
5. **Generic ASGI** — a root `asgi.py` whose top level exposes `app` (or
   `application`) → uvicorn.

**The app object must be created at module top level** (column 0), because
moonbase imports it as `module:name`. An app built **inside** a function —
the app-factory pattern, `def create_app(): ...` — is not importable and will
fail detection. If you use a factory, call it at module top level in a root
`wsgi.py` or `asgi.py` and assign the result to `app` or `application`:

```python
# wsgi.py at the project root — the module-level-via-factory case that works
from myapp import create_app
application = create_app()   # top-level name moonbase can import: wsgi:application
```

A direct constructor also works, e.g. an `app.py` at the root:

```python
# app.py at the project root
from flask import Flask
app = Flask(__name__)        # moonbase starts: gunicorn app:app
```

**Dependencies.** List them in `requirements.txt` at the project root.

- Install happens on the slim image with **no C/C++ build toolchain**, so each
  dependency must provide a prebuilt Linux wheel (manylinux) or be pure
  Python. A package that only ships an sdist needing compilation will fail the
  build — pin a version that publishes wheels.
- A `requirements.txt` that **references a root-level file named
  `requirements*.txt`, `requirements*.lock` or `constraints*.txt`** works:
  `-r requirements.lock` and `-c constraints.txt` both install (those files
  are packaged with the app). An include with another name, or in a
  **subdirectory** such as `-r requirements/base.txt`, does **not** work yet —
  keep the referenced file at the root with one of those names.
- A hash-pinned `requirements.txt` installs (pip enforces `--require-hashes`:
  once any line has a hash, every dependency needs one).
- Lockfiles from **poetry, pipenv or uv are not read**. Export to
  `requirements.txt` (for example `pip freeze > requirements.txt`).

**Not in v1 for Python:** background workers / Celery, non-HTTP apps,
WebSockets (see *Limits and runtime*), and anything that needs a native build
toolchain to install.

**Verify a Python deploy really works** (not just that it went live): open the
project's intended route and confirm the app answers with real content, not a
server-error page. A missing dependency or an import error lets the container
start and then crash on the first request, so a deploy that reports `done`
still needs this check. See *Before you call it done*.

## The ZIP: what goes in, what stays out

Put the project's own files at the **top of the ZIP**: `package.json` (for
Node apps) or `index.html` (for static ones) at the root. One wrapper folder
(the way Bolt and Lovable downloads come) is fine, moonbase finds the root.

Wrong (two folders deep):
```
my-app.zip
  downloads/
    my-app/
      package.json
```
Right:
```
my-app.zip
  package.json
  src/
  package-lock.json
```

**Include:** source files; for Node, `package.json` and the lockfile
(`package-lock.json`, `pnpm-lock.yaml` or `yarn.lock`) if there is one; for
Python, `requirements.txt` (and any root-level lockfile/constraints it
references). A `.env.example` with placeholder, non-secret values is good to
include — it's the one env file that's safe to ship.

**Leave out** (the skill's one packaging tool, `scripts/package-mission.sh` in
`deploy-for-the-user.md`, keeps all of these out for you; use it):
- `node_modules` (moonbase installs dependencies itself),
- Python virtualenvs and caches (`.venv/`, `venv/`, `__pycache__/`, `*.pyc`),
- build output (`.next/`, `dist/`, `build/`; moonbase builds fresh),
- `.git`,
- **every real `.env`** — `.env`, `.env.local`, `.env.production` and the like
  (secrets; see below). Keep only `.env.example`.
- runtime data the app wrote while running: SQLite/other DB files and their
  sidecars (`*.sqlite*`, `*.db`, `*-wal`, `*-shm`, `*-journal`), uploaded files,
  and logs (`*.log`). These don't belong in source and are wiped on each deploy
  anyway (see *Data and storage*).
- the same things in **nested** folders, not just the root — a `*/node_modules`,
  a `*/.venv`, a buried `*/.env` all have to go too.
- OS junk (`.DS_Store`, `__MACOSX`); moonbase skips these anyway.

Two things make this reliable, and the one packaging tool does both: it builds
a **fresh, uniquely-named** archive (never reusing one that could still hold an
old `.env`), and it runs an **automated gate** that *fails* the upload if
anything forbidden is in the archive — rather than trusting a human to eye a
`unzip -l`. Use the tool; don't hand-roll a shorter exclude list.

Size: one ZIP can be up to the per-deploy size, currently the same on every plan (`account_usage` shows the live value). The limit applies to the ZIP you upload, and your plan's storage also applies to the unpacked total. Leaving out `node_modules` and build output keeps a normal app
far below that. If the project really is huge (videos, big datasets), say so
before uploading.

**Monorepo:** zip only the one app folder you want online, so its
`package.json` is at the ZIP's root.

## Paths and ports

- Your app **must listen on the `PORT` environment variable**, not a fixed
  port. moonbase sets `PORT` for you.
  - Express: `app.listen(process.env.PORT || 3000)`
  - Next.js: `"start": "next start -p $PORT"`
- `package.json` needs a production `start` script (not a dev server).
- Use relative paths (or paths starting with `/`) for scripts, styles and
  images. Never hardcode `http://localhost:3000` in the app's own code:
  moonbase can rewrite port wiring in build config and start scripts, but a
  `localhost` URL inside your own `fetch` calls is yours to fix.
- Node version: moonbase uses Node.js 22 by default (18 and 20 are also
  available). If the app needs another, declare it in `package.json`
  (`"engines": { "node": "^20" }`). A range runs on the newest available
  version it allows: `">=18"` and `"18 || 20 || 22"` run on Node 22, `"^20"`
  and `"20.x"` on Node 20, and only an exact `"18"` (or `"^18"`) runs on
  Node 18, which is past its end of life.

## Environment variables (settings and secrets)

- Make every variable the app reads discoverable: ship a `.env.example` (or
  a `.env` with placeholder, non-secret values).
- moonbase reads a shipped `.env` file and applies the **non-secret** values
  automatically. Anything that looks like a real credential (API key, token,
  password, database URL with a password) is **never** applied from the file:
  the user is asked to set it in moonbase instead, in a write-only field.
- An upload containing what looks like a hardcoded credential is stopped
  (`hardcoded_secret_detected`) so it never goes public.
- Real values go in **Mission Control → Environment Variables**
  (`mission-control.md`), or, when you deploy over the API, straight through
  the env API (`api-and-ci.md`) — any key your app reads, even one the build
  never referenced. Values set either way always win over the `.env` file.
- Reserved names: never ask the user for a variable starting with
  `MOONBASE_` or `MOONSERVER_`, or ending in `_LIVE_URL`. moonbase sets those
  itself. Rename your own variable if it collides.
- Next.js: `NEXT_PUBLIC_*` values end up in the browser. Never put a secret
  in one.

## Data and storage (where your data lives)

moonbase **runs** the app and **provides its database**. There is **no
permanent disk**. Every deploy builds a fresh
container, so anything the app writes to local disk while it runs — an
SQLite file, uploaded images, a `data/` folder — is **gone on the next
deploy**. Don't count on writing to the app's own folder at all: the
filesystem can be read-only, and the only place to rely on for temporary files
is a small `/tmp`, which can be cleared whenever the project restarts or
sleeps. Never treat local disk as the place the real data lives.

To keep data between deploys, the app keeps it in **the project's managed
PostgreSQL database**, which moonbase creates and runs:

- **Every plan, Free included, can add one managed PostgreSQL database per
  project** (up to one). It uses the
  plan's storage; there is no separate database allowance.
  It needs a **dynamic** project (one moonbase builds and runs): on a static
  project a `database` entry stops the deploy.
- **You create it by declaring it.** Put a `database` entry in the
  `moonbase.json` at the project's root, with the command that creates the
  tables, and deploy:

  ```json
  { "database": { "engine": "postgresql", "migrate": "node migrate.js" } }
  ```

  On that deploy, moonbase creates the database, runs the migrate command before the new
  version goes live and sets `DATABASE_URL` for the app. Nobody types a
  connection string, and the person opens no account anywhere else. A
  `DATABASE_URL` the person saved before is kept, and no managed database is
  created over it. No app gets a database automatically.
- **The app reads `DATABASE_URL` from the environment**, with a standard
  PostgreSQL driver. Verified TLS is required and is the app's to configure
  in its driver. The connection code, the migrate
  command's rules, the limits and what the status tools report are in
  `references/mission-control.md`, section *Managed database: one per project,
  inside the plan's storage*. Read it before you write database code.
- **Uploaded files or media** don't belong on the container's disk either:
  keep them in object storage the app reaches over HTTPS, with its
  credentials set as environment variables.

So when the user asks "will my data survive a redeploy?", the answer is always
the same: data in the project's managed database survives; the
container's own filesystem does not. You do **not** need to ask the user about
this — it is always true. If the project genuinely needs to keep data and has
no database yet, declare the managed database and write the app against
`DATABASE_URL`; don't ask the user whether moonbase has a disk, and don't send
them to another provider for a database.

## Limits and runtime (know these before you build)

A running project is one small web container. These limits are always true;
build within them instead of shipping something that fails for the user and
then asking moonbase about it.

- **Outbound network reaches public services on any port** (the live policy as
  of 2026-10-30; verified in production). The app can make normal outbound
  connections to the public internet — an HTTPS API on 443, a service on its
  own port, anything public — plus DNS. Only two kinds of destination are blocked, and always
  will be: **private, internal and cloud-metadata addresses** (RFC1918
  `10/172.16/192.168`, loopback, and the `169.254.x` metadata range — this
  protects moonbase and other projects), and **direct SMTP on port 25**
  (anti-spam). Authenticated mail submission on **465 and 587 is allowed**, so
  send through your email provider's submission port or its HTTPS API, not a
  raw port-25 mail server.
- **No WebSockets.** The server does not upgrade connections, so a WebSocket
  app (live chat, collaborative editing, `socket.io`) will not connect. Plain
  request/response works; long-polling and server-sent events are bounded by
  the request timeout below.
- **A request is cut off after about sixty seconds.** For slow work (heavy
  processing, a slow model call), return a response quickly and continue the
  work elsewhere, or stream partial output within the window — don't hold one
  request open for minutes.
- **Request and upload size is modest** — a request body, including a file
  upload, above roughly sixteen megabytes is rejected. For large files, upload
  straight from the browser to object storage instead of through the
  app.
- **Resources per project are small and fixed** — about half a gigabyte of
  memory, a fraction of a CPU core, and a capped number of processes. A
  memory-hungry app (large in-memory datasets, heavy image or video
  processing) can be killed; keep the working set small.
- **One web process, no background runtime.** There is no separate worker,
  cron, or job-queue service, and a free project sleeps when idle (below), so
  in-process timers and schedulers stop. For scheduled or background work,
  trigger it from an outside scheduler that calls an HTTPS endpoint on the
  project.
- **Free projects sleep when idle.** A dynamic project on the free plan stops
  after about thirty minutes with no traffic and wakes automatically on the
  next request, so the first request after it slept is slow (a cold start of a
  few seconds); after that it is fast again. Paid projects stay running. That
  is the answer to "why was the first load slow?" and "does my app stay up?" —
  free sleeps and cold-starts, paid stays warm.

## What moonbase fixes for you (self-repair)

The **Compatibility Engine** checks the project and repairs it on a copy.
**Your original ZIP is never changed.**

- **Fixed automatically (safe):** for example a missing environment variable
  that can safely be empty, most port problems, and small project problems
  like a broken `.gitignore`. When moonbase changed the copy it deployed (a
  project file, or how the project is installed, built or started), it says
  what it changed: in the API and in a connector deploy's result, the `done`
  event's `self_repair_notice`. Its own run settings, such as the port it
  gives the app, are in the Deployment Recipe and not in that notice.
- **Asks first (build-level changes):** setting an environment variable,
  setting the start script, rewriting the port, setting the Node version,
  regenerating the lockfile. In the browser each one is proposed with a plain
  explanation and the user approves or declines. Deploys made with an API
  key or through the connector accept these automatically, and
  `self_repair_notice` then names each change moonbase made to the copy,
  for example the start command it added to `package.json`. Make the same change in the project's
  source, so the next upload matches what is live. In the rare case moonbase
  still needs the owner's OK, it answers `consent_required` with a link.
- **Writes everything down:** the **Deployment Recipe** records what moonbase
  detected and changed, so nothing is silent.
- **Doesn't do:** fix bugs in the app's own logic or
  turn an unsupported framework into a supported one.

## Before you call it done (checklist)

**Every project:**
- [ ] The entry point is at the ZIP's root (or one folder in): `index.html`
      (static), `package.json` (Node), or a Python app object (below).
- [ ] No `node_modules`, no virtualenv, no build output, no `.git`, no
      database/log files. The packaging tool's gate confirmed this and would
      have failed the upload otherwise.
- [ ] No real secrets in the ZIP; every variable is listed in `.env.example`.
- [ ] No `localhost` URLs in the app's own code.
- [ ] Data the app keeps goes to the project's managed database, declared in
      `moonbase.json` and read from `DATABASE_URL` (see *Data and storage*),
      never to the container's disk and never through a hardcoded address.

**Node / JS projects:**
- [ ] The lockfile is included if there is one.
- [ ] The app listens on `PORT` and `package.json` has a production `start`
      script.
- [ ] It builds on your machine: `npm install && npm run build && npm start`.
      If it fails locally, it will fail on moonbase too.

**Python projects** (no `start` script — moonbase derives the command):
- [ ] A startable app object is at module top level in a root file (see
      *Python web apps: the full contract*).
- [ ] `requirements.txt` lists every dependency; referenced lockfiles /
      constraints are at the root, and the deps install as Linux wheels.
- [ ] It runs locally the same way moonbase will start it, e.g.
      `pip install -r requirements.txt` then `gunicorn app:app` (WSGI) or
      `uvicorn main:app` (ASGI).
- [ ] After deploy, you opened the live route and saw real content, not a
      crash page.
