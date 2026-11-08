# Getting started: sign up and put the first mission online

Walk the user through these one step at a time. Wait for them after each
part. moonbase is rolling out a new design, so a button may look slightly
different on their screen; the names below are the ones moonbase uses.

## Part 1. Create an account

If they don't have a moonbase account, start here. Give them
**https://app.moonbase.cloud/register** and ask them to tell you when their
account is ready. Wait for that confirmation before bringing up the connector
or an API key.

1. Open **https://app.moonbase.cloud/register**.
   *You'll see "Create your account".*
2. Choose **Continue with Google** if it appears and you want to use Google.
   To use email, enter your **First name**, **Last name**, **Email** and
   **Password**. Choose **Create account**.
3. If moonbase asks you to check your email, follow Part 2.

Already have an account? Open **https://app.moonbase.cloud/login** if you need
to sign in. Choose **Forgot password?** if you need a new password. The person
always enters their own password and verification codes.

## Part 2. Verify your email

1. Open the email from moonbase. (Not there? Check spam, wait a minute.)
2. Click the link inside. You can open it on any device.
   If moonbase's page asks for a **Verification code**, type the code from
   the email and click **Verify**.
3. Didn't get it? On the "Check your inbox" page click **Resend code**.
   Typed the wrong address? Click **Wrong email? Sign out and try again**.

Verify the email before taking the app online.

## Part 3. Choose how to take the app online

1. If their AI tool supports a connector, start with the **moonbase
   connector**. Open **https://moonbase.cloud/docs/deploy-from-ai-chat** and
   choose the guide for that tool. If it asks for an address, use
   **https://app.moonbase.cloud/mcp**. Sign in and review what the connector
   can do. Once it is connected, ask "Take my app online with moonbase."
2. For CI, a script or a terminal tool without a connector, use an API key.
   See `api-and-ci.md`. Keep the key in the tool's secret store.
3. If they want to upload the app themselves, or their AI tool can only chat,
   continue to Part 4.

## Part 4. Upload your first mission

If moonbase shows **"One more step before uploading"**, finish the account
steps it asks for. If it asks for a phone number, enter it, choose
**Send code** and use **Verify phone** with the code from the text message.

What can you upload? Any of these:
- a **ZIP file** of your project (most common),
- a **folder** from your computer (moonbase zips it for you),
- **files**, even **one single HTML file** (moonbase uses it as the
  homepage, renaming it to `index.html`).

Steps:

1. Click **New mission** (top of the page; it may show as **+ New mission**).
   *A window opens that says "Drop your mission files" (or "Pick a ZIP
   file").*
2. Drag your ZIP, folder or files into that box. Or click **Choose files** /
   **Choose a folder** to pick them.
   *You'll see your file listed, or "Preparing your files…" for a folder.*
3. Look at **Mission name** and **Mission address**. moonbase suggests a name;
   keep it or type your own. The address becomes your link:
   `https://<address>.moonbase.host`.
   - Address rules: 3 to 32 characters, lowercase letters, numbers and single
     hyphens, starting with a letter.
   - *You'll see "This address is available"* when it's free. If it's taken,
     try another (or click the button that makes a random name).
4. Click the launch button (**Initiate launch sequence** or **Launch**).
   *A console shows each step: reserving the address, uploading, the
   security certificate, and a health check. For apps moonbase builds you
   also see unpacking, building and starting.*
5. Wait. A static mission is usually live in seconds; an app moonbase builds
   is usually live in a minute or two (a big one can take longer).
6. *You'll see "Your mission is live" (or "<name> is online").* Click
   **Open project** to see it, or **Go to mission control** to manage it.

That link works for anyone, right now. Tell the user to share it. This
`<address>.moonbase.host` link is automatic — the mission is live on it with
HTTPS the moment it deploys. A custom domain is an optional, later step
(`custom-domains.md`), set up only after the mission already exists.

### If moonbase asks a question during the launch

Sometimes moonbase finds something it wants to fix that needs the user's OK
(like the Node version or the start command), or the app needs settings
(environment variables). A window explains each one in plain words.
- Fixes: approving is normal and safe for most AI-built apps.
- Environment variables: type the values, or drag the project's `.env` file
  into that window to fill them in. Secret values are write-only (never shown
  again).

### If it fails

The console shows the first problem and an **Error ID** (`TRK-…`). Click
**Copy Error ID** and keep it. Then open `troubleshooting.md`. This is a first
deploy, so nothing is live yet — fixing the error and uploading again is all
that's needed; you're not taking anything down. (Once a mission has a working
version, a later failed deploy never replaces it — the live version keeps
serving.)

## What the user has now

- A **mission** with its own page, **Mission Control**: status, versions
  (**Mission Log**), traffic, environment variables and domains.
- A list of all missions under **Missions**, and an overview on the
  **Dashboard**.
- Next ideas, only if they fit: a custom domain (`custom-domains.md`), a new
  version (`versions-and-rollback.md`), letting their AI deploy for them
  (`deploy-for-the-user.md`).

## The mission limit

If **New mission** is disabled or says "Mission limit reached", the plan's
mission count is used up. Options: ship a **new version** of an existing
mission instead, delete a mission you don't need, or upgrade (`billing.md`).
