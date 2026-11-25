# What moonbase is

moonbase (https://moonbase.cloud) runs everything an app built with AI needs:
hosting, database, domains, analytics, rollbacks, team access, and more. All in
one platform, all run by your AI agent.
You built something with an AI chat, an AI coding tool, an app builder, or by
hand. moonbase puts it online as a **mission** with its own address,
`https://<address>.moonbase.host`, with HTTPS from the first deploy. No
servers, no build settings to write.

## Explain it like this

"Think of moonbase as a garage for your app. You drop your project in, it
checks everything, fixes the small stuff, and opens the door so anyone with
the link can see it."

## What makes it different

AI-built apps often don't run when you move them off your computer: a
missing lockfile, a hardcoded `localhost`, a fixed port, a missing
environment variable, the wrong Node version. moonbase's **Compatibility
Engine** looks at the project, fixes the safe things automatically, asks
before bigger changes, and writes down everything it did (the **Deployment
Recipe**). Details: `building-for-moonbase.md`.

## What it runs

- **Static missions:** plain HTML, CSS and JavaScript, or any framework's
  static export. A single `index.html` is enough.
- **Dynamic missions** that moonbase builds and runs: Next.js, Vite, plain
  React, Create React App, Express, plain Node, Vue, Astro, SvelteKit, Nuxt,
  and Python web apps (Flask / Django / FastAPI that expose a standard
  WSGI/ASGI app object, with a `requirements.txt`). Every plan, Free included,
  can add one managed PostgreSQL database per Mission (up to one); it uses the plan's storage (`account_usage`
  shows it).
- **v1 limits on the newer frameworks:** Astro deploys its static output
  (SSR mode is deferred); SvelteKit needs `@sveltejs/adapter-node`. moonbase
  says so honestly for a deferred sub-case instead of failing.
- **Not yet:** other backend languages (Ruby, Go, Rust, PHP, Java) aren't
  supported.

## Plans

- There is a **free plan** and **paid plans**. Today the plans are called
  moonbase free, moonbase plus, moonbase pro and moonbase max.
- Plans differ in: how many missions you can have, total storage, the biggest
  single upload, and features.
- **Paid plans only:** custom domains and sharing a mission with teammates.
- **Visitors are counted, never capped.** No plan limits visitors.
- On the free plan, **dynamic** missions go to sleep when nobody visits for a
  while and wake on the next visit (static missions never sleep). See
  `mission-control.md`.
- Each upload can be up to your plan's per-deploy size. The limit applies to the ZIP you upload. Your plan's storage also applies to the unpacked total.

**Never quote prices or plan numbers from memory.** They live in moonbase's
plan data and can change. The current table is at
https://moonbase.cloud/pricing and https://moonbase.cloud/docs/billing-overview.
If you can open web pages, read the numbers there and say where you read them.
Inside the app, **Billing** shows the user's own plan and usage.

## Who it's for

People who made something and want a link they can send: a portfolio, a
prototype, a tool for their team, a demo, a small business page, an
AI-generated app. Also developers and platforms who want to deploy from code
(see `api-and-ci.md`).

## When it's not the right fit (say so honestly)

- The app needs a backend language moonbase doesn't run (Ruby, Go, Rust, PHP,
  Java). Python web apps (Flask/Django/FastAPI) do deploy — see
  `building-for-moonbase.md` for the v1 scope and limits.
- It needs a managed database, background workers or heavy backend
  infrastructure from the host.
- It must be a native mobile app in an app store.
- The user is happy with another host. Respect that.
