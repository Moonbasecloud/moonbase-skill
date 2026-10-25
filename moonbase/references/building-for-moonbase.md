# Building for moonbase: a project that deploys first time

Use this while the project is being built or right before it's zipped. Most
failed uploads are layout or settings mistakes that are free to avoid now.

## Static or dynamic? moonbase decides

- **Static:** a ready-to-serve `index.html` at the root, no build step, and
  no Node server in `package.json`. moonbase serves the files as they are. A
  ZIP with just one `index.html` works. Static missions never sleep.
- **Dynamic:** a `package.json` with a Node server (Express, plain Node), or a
  project that needs building (Vite, Next.js, React, Create React App).
  moonbase installs, builds and runs it.

Supported and auto-detected, with no build config to write: static
HTML/CSS/JS, Next.js, Vite, Create React App, plain React, plain
Node/Express (a valid `package.json` with a `start` script).

Recognised but **not deployable yet**: Astro, SvelteKit, Vue, Nuxt. **Not
supported:** Python (Django, Flask…) and other backend languages. In those
cases moonbase says so instead of producing a broken deploy; a static export
is the way around it.

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

**Include:** source files, `package.json`, and the lockfile
(`package-lock.json`, `pnpm-lock.yaml` or `yarn.lock`) if there is one.

**Leave out:**
- `node_modules` (moonbase installs dependencies itself),
- build output (`.next/`, `dist/`, `build/`; moonbase builds fresh),
- `.git`,
- any `.env` with real secrets (see below),
- OS junk (`.DS_Store`, `__MACOSX`); moonbase skips these anyway.

Size: every plan has a per-upload limit, and nothing over 1 GB is accepted
on any plan. Leaving out `node_modules` and build output keeps a normal app
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
- Node version: moonbase uses Node.js 20 by default. If the app needs
  another, declare it in `package.json` (`"engines": { "node": ">=18" }`) or
  an `.nvmrc`.

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
  (`mission-control.md`). Values set there always win over the `.env` file.
- Reserved names: never ask the user for a variable starting with
  `MOONBASE_` or `MOONSERVER_`, or ending in `_LIVE_URL`. moonbase sets those
  itself. Rename your own variable if it collides.
- Next.js: `NEXT_PUBLIC_*` values end up in the browser. Never put a secret
  in one.

## What moonbase fixes for you (self-repair)

The **Compatibility Engine** checks the project and repairs it on a copy.
**Your original ZIP is never changed.**

- **Fixed automatically (safe):** for example a missing environment variable
  that can safely be empty, most port problems, and small project problems
  like a broken `.gitignore`. When moonbase fixed something by itself, it
  tells you (in the API, the `done` event's `self_repair_notice`).
- **Asks first (build-level changes):** setting an environment variable,
  setting the start script, rewriting the port, setting the Node version,
  regenerating the lockfile. In the browser each one is proposed with a plain
  explanation and the user approves or declines. Deploys made with an API
  key accept these automatically; in the rare case moonbase still needs the
  owner's OK, it answers `consent_required` with a link.
- **Writes everything down:** the **Deployment Recipe** records what moonbase
  detected and changed, so nothing is silent.
- **Doesn't do:** fix bugs in the app's own logic, provide a database, or
  turn an unsupported framework into a supported one.

## Before you call it done (checklist)

- [ ] `package.json` or `index.html` is at the ZIP's root (or one folder in).
- [ ] No `node_modules`, no build output, no `.git`.
- [ ] Lockfile included if there is one.
- [ ] The app listens on `PORT` and has a production `start` script.
- [ ] No `localhost` URLs in the app's own code.
- [ ] Every environment variable is listed in `.env.example`; no real
      secrets in the ZIP.
- [ ] It builds on your machine: `npm install && npm run build && npm start`.
      If it fails locally, it will fail on moonbase too.
