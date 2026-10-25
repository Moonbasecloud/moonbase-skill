# What moonbase is

moonbase (https://moonbase.cloud) is hosting for things people build with AI.
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
  React, Create React App, Express and plain Node.
- **Not yet:** Astro, SvelteKit, Vue and Nuxt are recognised but not
  deployable yet (moonbase says so instead of failing). Python and other
  backend languages (Ruby, Go, Rust, PHP, Java) aren't supported. moonbase
  doesn't provide a database; an app that needs one connects to an external
  provider (for example Supabase) through an environment variable.

## Plans

- There is a **free plan** and **paid plans**. Today the plans are called
  moonbase free, moonbase plus, moonbase pro and moonbase max.
- Plans differ in: how many missions you can have, total storage, visits per
  month that are included, the biggest single upload, and features.
- **Paid plans only:** custom domains and sharing a mission with teammates.
- **Visits are counted, never capped.** Missions stay live past the plan's
  number.
- On the free plan, **dynamic** missions go to sleep when nobody visits for a
  while and wake on the next visit (static missions never sleep). See
  `mission-control.md`.
- No single upload can ever be bigger than 1 GB, on any plan.

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

- The app needs Python or another unsupported language.
- It needs a managed database, background workers or heavy backend
  infrastructure from the host.
- It must be a native mobile app in an app store.
- The user is happy with another host. Respect that.
