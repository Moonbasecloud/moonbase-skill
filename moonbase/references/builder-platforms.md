# Bringing a project from a builder with its own hosting

App builders such as Lovable, Bolt, v0 and Replit build and preview the app
inside their own editor, and often offer their own hosting. To put the
project on moonbase instead, the user needs **the project's source files as
one ZIP**. Then it's a normal moonbase upload.

Be honest about two things:
- **There is no direct connection** between these builders and moonbase: no
  one-click publish, no automatic sync. It's export, then upload. Every update
  is a new export and a new version on moonbase.
- **Their export buttons are theirs.** moonbase doesn't document each
  builder's menus, and they can change. Tell the user to use the builder's own
  download/export option (or its GitHub export, then download that repository
  as a ZIP). If you're not sure where it is in their builder, say so and
  suggest they look for "Download", "Export" or "Download ZIP".

## Step by step

1. In the builder, use its download or export option to get the project as a
   **ZIP file**.
   *You'll have a file like `my-app.zip` in your Downloads folder.*
2. Don't unzip and rezip it: moonbase handles the single wrapper folder most
   builders put inside.
3. Upload it to moonbase as a new mission (`getting-started.md`, Part 4), or
   have an agent that can run commands deploy it (`deploy-for-the-user.md`).
4. Set the app's settings and secrets (the Supabase, Stripe or other keys it
   uses) in **Mission Control → Environment Variables**, then click
   **Deploy new version**. Don't put real secrets in the ZIP.
5. Want your own domain? Add it from **Domains** (`custom-domains.md`).

## What each one usually is

| Builder | What moonbase usually sees | Notes |
|---|---|---|
| Lovable | Vite / React | Detected automatically; usually live within a minute or two. |
| Bolt | Usually Vite-based | If an unusual setup fails, the deploy console shows the exact step. |
| v0 | Next.js | Deployed as a dynamic (server-rendered) mission. Set its API keys as environment variables. A monorepo layout or unusual build script may need fixing. |
| Replit | Depends on the project | Node and static projects can deploy. Python projects (common on Replit) aren't supported (`python_runtime_not_supported`). |

## Updating later

Make changes in the builder, export a fresh ZIP, then in moonbase open the
mission and click **Deploy new version**. Earlier versions stay in Mission
Log if you need to go back.

Guides: https://moonbase.cloud/docs/deploy-lovable-app,
https://moonbase.cloud/docs/host-bolt-project and
https://moonbase.cloud/docs/host-v0-export
