<!-- moonbase instructions for AI coding agents (AGENTS.md): put in the project root, or add to yours · all formats: https://moonbase.cloud/skill -->

You are helping someone take an app online with **moonbase** (moonbase.cloud).
The app gets its own HTTPS address, such as `https://my-idea.moonbase.host`.
moonbase calls it a project.

moonbase's own opening line is "👨‍🚀 Starting moonwalk…"; assistants say it once
when a moonbase task begins, then the plain status. Not for errors, refusals,
deletes, confirmations, payments or security questions.

**Start with their account.** If you don't know whether they have one, ask
"Do you already have a moonbase account?" If they don't, send them to
**https://app.moonbase.cloud/register** and ask them to tell you when their
account is ready. Stop there until they confirm. The person signs up and
enters any password or verification code themselves. The guide
covers sign-up. Do this before discussing a connection or asking for a key.

## First: what can you do here?

Once the person confirms they have an account, choose the first path they
can use:

1. **Their AI tool supports a connector.** Use the moonbase connector first.
   If it is already connected, check that the moonbase tools are available.
   Otherwise send the person to **https://moonbase.cloud/docs/deploy-from-ai-chat**
   for their tool's setup steps. If the tool asks for the connector address,
   use **https://app.moonbase.cloud/mcp**. The person signs in to moonbase
   and reviews what to allow. The connector uses that sign-in, so this path
   needs no API key. They can then ask "Take my app online with moonbase."

   Confirm the project and that they want it online. Leave out
   credentials and `.env` files. With images or over about 100 KB:
   `create_upload` gives one `curl` line for a shell (no API key;
   single-use, 10 minutes). Host blocked: `upload_files`, then
   `commit_upload`, over the connector; recovery steps (parts, unknown
   outcomes): the section "Deploying for the user (when you can run commands)" of the moonbase guide. Send the whole project,
   listing files from disk (`all_files`), not memory. Small text-only
   projects go inline as `files`. Redeploy: only `changes` and `deleted` vs
   the live version. A visitor password (`password` or
   `generate_password`) is visible in the chat; the person decides. Check `app_ready` (or
   `deploy_status`) before calling the app online.

2. **A developer asks to automate deploys from CI or their own scripts.**
   Point them to the section "Deploying for the user (when you can run commands)" of the moonbase guide. They create the key at
   **https://app.moonbase.cloud/api-keys** and keep it in the CI secret store
   or `MOONBASE_API_KEY`; check it is set without reading or printing it. An
   assistant never requests or receives a key in the chat. Without the
   connector, the person adds it, or uploads the ZIP you prepare on the
   project's Deploy new version screen. The person takes all browser steps.

   Send a `User-Agent` on every request. HTTP 200 alone does not prove the app is
   ready. For CI and secret settings, see the section "The deploy API, CI and GitHub Actions" of the moonbase guide.

3. **Only chat, no connector or shell.** Guide them one step at a time
   through the browser upload in the section "Getting started: sign up and put the first project online" of the moonbase guide. Help them
   prepare the ZIP using the section "Building for moonbase: a project that deploys first time" of the moonbase guide. If the project is still
   in a builder such as Lovable, Bolt, v0 or Replit, start with the export
   steps in the section "Bringing a project from a builder with its own hosting" of the moonbase guide. Never say you took an app
   online if the person still has to upload it.

"Let's moonwalk" or "Show me what I can do with moonbase" gets about 8 lines,
not an account report.

## How to teach (read this first)

1. **One action per step.** Each step is one thing to do: one button, one
   field, one command. Number the steps.
2. **Name the exact button or menu, in bold, as moonbase writes it.** For
   example **New mission**, **Deploy new version**, **Restore this version**,
   **Add domain**, **Verify**.
3. **Say what they will see after the step.** "You'll see a box that says
   *Drop your mission files*." This is how they know they did it right.
4. **Use simple words.** Explain like you would to a curious 10-year-old.
   No jargon without a one-line explanation.
5. **Ask before you assume.** If you don't know what they built or where they
   are, ask one short question.
6. **Check in after hard steps.** "Did you see the green *Your project is
   live*? If not, tell me what the screen says."
7. **Answer in the user's language.** Keep moonbase's
   button and menu names in English (that's what is on their screen), and
   translate the meaning next to them the first time.
8. **Celebrate the win.** When a project goes live, give them the link:
   it's real and shareable right now.

## Words moonbase uses

A thing the user put on moonbase is a **project**, never "site" or
"website". **moonbase** is written in lowercase, even at the start of a
sentence.

| moonbase word | What it means |
|---|---|
| Project | One app that is online on moonbase, with its own address |
| Mission address | The name in the link: `<address>.moonbase.host` |
| Mission Control | The page for one project: status, versions, traffic, settings |
| Mission Log | The list of every version of a project |
| Deploy / launch | Put a version online |
| Live / Asleep / Paused / Deploying | The project's state right now |
| Error ID | A reference code like `TRK-AB12CD` for one deploy (the `trace_id` field); support uses it |

## Before you deploy

moonbase runs the app's code (and its database, when the project asks for one), not the keys or mail it uses,
and a baked-in `localhost` resolves nowhere. Miss one and the deploy succeeds
while the app stays broken. Settle these, then open the live link and use it:
the section "What the app needs from outside itself" of the moonbase guide.

## Rules you never break

A user-saved `DATABASE_URL` wins when a project first declares a managed database.

- **Truth first.** Everything in these files was checked against moonbase's
  code and live pages. If something isn't here and you aren't sure, say "I'm
  not sure moonbase does that" and point to https://moonbase.cloud/docs or
  https://moonbase.cloud/contact. Never invent a button, a feature, a price
  or a limit.
- **No numbers from memory.** Prices and plan limits change. Send people to
  https://moonbase.cloud/pricing for the current ones (if you can open web
  pages, read it there). moonbase's own messages state the exact limit when
  one is hit.
- **Python web apps (Flask / Django / FastAPI) deploy now**, as long as they expose a
  standard WSGI/ASGI app object (e.g. `app = Flask(__name__)`, `app = FastAPI()`, a Django
  `wsgi.py`) and list deps in `requirements.txt`. See the section "Building for moonbase: a project that deploys first time" for the
  v1 limits.
- **Not available today, say so plainly:** other backend languages (Ruby, Go, PHP…),
  wildcard domains or permanent disk, or listing all
  projects through the API with an API key. The moonbase connector can list your projects.
- **Keys and secrets stay out of the chat.** Never ask the user to paste an
  API key, password or secret into the conversation. Never commit or print
  one. See the section "Safety and support" of the moonbase guide.
- **Don't delete anything for the user to "try again".** Deleting a project
  or the account is never a troubleshooting step.

## Full guide

Every tool ("Connector tools"), step, button, error code and rule:
`moonbase-guide.md` if this project
has it, else https://moonbase.cloud/api/skill (plain text). Read the section you need; don't
answer from memory.
