# Connecting a backend: Supabase, Firebase or your own API

Read this when the app already talks to Supabase, Firebase or an API the person
runs elsewhere, and you need to say which value goes in which environment
variable, what is public, what stays on the server, and how the values reach
the app on moonbase. The public guides, to send the person to:

- https://moonbase.cloud/docs/connect-supabase
- https://moonbase.cloud/docs/connect-firebase
- https://moonbase.cloud/docs/connect-your-api

**moonbase's own database.** Every plan, Free included, can add one managed
PostgreSQL database per mission; it uses the plan's storage. `account_usage`
shows where this account stands. When a mission has one, `mission_info`
returns its status and `database_page` (open that exact link for the person).
The details are in `references/mission-control.md`. When the app already uses
a service, connect that service; a moonbase database is a separate choice the
person makes.

## Where the values go

Every value goes on the mission's **Environment Variables** screen in Mission
Control (the mission's page, https://app.moonbase.cloud/missions/<project_id>).
If the moonbase tools return a link to that screen, open that exact link for
the person rather than describing where to click.

- **Public values** (a Supabase URL and anon or publishable key, the Firebase
  web config, a public API address) ship to the browser anyway. You may save
  them with `set_env`.
- **Secrets** (a Supabase service role or secret key, a Firebase service
  account, an API key or token, a database connection string) are typed by the
  person on that screen. Never ask for one in the chat, never write one into the
  code or the ZIP, and never give one a public prefix.
- Values are write-only: `list_env` returns names, never values. A change
  applies on the next deploy (Save and redeploy, or a new version).
- moonbase refuses a value that contains a line break. A multi-line secret,
  such as a Firebase service account JSON file, is saved base64-encoded as one
  line and decoded by the server code.

## How a value reaches the app

What kind of mission it is decides this (`references/building-for-moonbase.md`
says how moonbase picks static or dynamic):

- **Served as it is** (a browser-ready `index.html` at the root, no build):
  moonbase passes it **no environment variables at all**. Every file is public,
  so it can hold only public values, written straight into the page.
- **A front end moonbase builds** (Vite, Vue, Create React App, Astro,
  SvelteKit, Next.js): the build gets **only** the variables with the
  framework's public prefix (`NEXT_PUBLIC_` for Next.js, `VITE_` for Vite and
  Vue, `REACT_APP_` for Create React App, `PUBLIC_` for Astro and SvelteKit),
  and the framework writes them into the browser files. A Vite, Vue or Create
  React App mission has no server of its own, so it can never use a secret.
- **Server code** (a Next.js server, Express, Nuxt, SvelteKit with the Node
  adapter, Python): every saved variable is in the environment when the app
  starts (`process.env`, `os.environ`). Secrets are read here.
- The build can download packages but can't reach other services, so the app
  loads data when a visitor opens a page, not during the build. In a Next.js
  route handler that reads a secret, `export const dynamic = "force-dynamic"`
  keeps it out of the build.

## Supabase

| Value | Usual variable | Public? |
|---|---|---|
| Project URL | `NEXT_PUBLIC_SUPABASE_URL` / `VITE_SUPABASE_URL` | yes |
| anon or publishable key | `NEXT_PUBLIC_SUPABASE_ANON_KEY` / `VITE_SUPABASE_ANON_KEY` | yes |
| service role or secret key | `SUPABASE_SERVICE_ROLE_KEY` | no: server only |
| Postgres connection string (server talks to Postgres directly) | `DATABASE_URL` | no: server only |

Use the names the code already reads. The anon key is public by Supabase's
design; Row Level Security policies are what protect the data, so tell the
person to turn them on for every table the browser touches. The service role
key skips those policies.

No build step: the URL and anon key go into the page, with the client loaded
from a URL (a bare package import needs a build). The script is pinned to one
exact version and carries a Subresource Integrity hash:

```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.119.2/dist/umd/supabase.js"
  integrity="sha384-A97u3Qnt9GZHURO9YJZRe7VQgGUeFzcv6I1oIGnUTxQrCxnpQMwR0/G8F2zt9abZ"
  crossorigin="anonymous"></script>
<script type="module">
  const client = window.supabase.createClient("https://your-project-ref.supabase.co", "your-anon-or-publishable-key");
  const { data, error } = await client.from("notes").select("*");
</script>
```

When updating, pin the new exact version and replace the integrity hash with
the one for that exact file; never drop either.

Next.js: browser code uses
`createClient(process.env.NEXT_PUBLIC_SUPABASE_URL, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY)`;
a route handler (with `force-dynamic`) creates a second client with
`process.env.SUPABASE_SERVICE_ROLE_KEY` for work that needs it. The full
example is on the public guide.

If people sign in, the mission's live address (and any custom domain) goes in
the redirect URLs of the Supabase project's authentication settings
(`references/what-your-app-needs.md`, sign-in redirects).

## Firebase

| Value | Usual variable | Public? |
|---|---|---|
| Web config: apiKey, authDomain, projectId, storageBucket, messagingSenderId, appId | `VITE_FIREBASE_API_KEY` … `VITE_FIREBASE_APP_ID` (or `NEXT_PUBLIC_FIREBASE_…`) | yes |
| Service account JSON (Admin SDK) | `FIREBASE_SERVICE_ACCOUNT_BASE64`, base64 of the file, one line | no: server only |

The web config is public by Firebase's design; Security Rules protect the
data, so tell the person to write rules for every collection and bucket the
browser uses.

**A Firebase web app publishes with or without a build step.** The standard
web config object (`apiKey`, `authDomain` ending in `.firebaseapp.com`,
`projectId` and the rest, as the Firebase console gives it) can sit straight in
the HTML or JavaScript; moonbase lets its `apiKey` through. Real Google API keys
share the `AIza` prefix and are still refused (`hardcoded_secret_detected`): a
Maps or Places key, an `AIza` key anywhere outside a Firebase config,
and any `AIza` key in a `.env` file. Those keys go in an environment variable
read by server code. With a Vite build you can also keep the web config on the
Environment Variables screen with the `VITE_` prefix: the code reads
`import.meta.env.VITE_FIREBASE_API_KEY` and the rest, and moonbase writes them
into the browser files when it builds. Upload the source, not a built `dist/`.

Server code with the Admin SDK decodes the one-line value:

```js
const json = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64, "base64").toString("utf8");
initializeApp({ credential: cert(JSON.parse(json)) });
```

If people sign in, the mission's live address (and any custom domain) goes in
the authorized domains of Firebase Authentication.

## Your own API

| Value | Usual variable | Public? |
|---|---|---|
| The API's address | `VITE_API_URL` / `NEXT_PUBLIC_API_URL` (browser calls), `API_URL` (server calls) | yes |
| API key or token | `API_KEY`, or the name the code reads | no: server only |

- The address is a public `https` one; a baked-in `localhost` resolves nowhere.
- A mission reaches public addresses on any port except outgoing mail on 25;
  private and internal ranges are blocked (`references/what-your-app-needs.md`),
  so an API on a private network won't answer.
- When browser code calls the API directly, the API must allow the mission's
  live address (and any custom domain) as a CORS origin.
- A key never goes to the browser. A mission served as it is, or a Vite app,
  can call only an API that needs no key. With a key, the app needs server
  code that adds it, for example an Express route:

```js
app.get("/api/items", async (req, res) => {
  const upstream = await fetch(process.env.API_URL + "/items", {
    headers: { Authorization: "Bearer " + process.env.API_KEY },
  });
  res.status(upstream.status).json(await upstream.json());
});
app.listen(process.env.PORT || 3000);
```

## After it is live

Open the live link and use the part of the app that needs the backend: load
the list, submit the form, sign in. A page that loads is not proof the
connection works (`references/what-your-app-needs.md`).
