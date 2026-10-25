# Getting started: sign up and put the first mission online

Walk the user through these one step at a time. Wait for them after each
part. moonbase is rolling out a new design, so a button may look slightly
different on their screen; the names below are the ones moonbase uses.

## Part 1. Create an account

1. Open **https://app.moonbase.cloud/register**.
   *You'll see "Create your account".*
2. Type your **First name**, **Last name**, pick your **Country**, and type
   your **Email**.
3. Choose a **Password** and type it again in **Confirm password**.
4. Tick the two boxes: you agree to the Terms of Service and Privacy Policy,
   and you're old enough (the page says the age).
5. Click **Create account**.
   *You'll see "Check your email".*

Already have an account? Use **https://app.moonbase.cloud/login** instead.
Forgot the password? Click **Forgot password?** on the login page.

## Part 2. Verify your email

1. Open the email from moonbase. (Not there? Check spam, wait a minute.)
2. Click the link inside. You can open it on any device.
   If moonbase's page asks for a **Verification code**, type the code from
   the email and click **Verify**.
3. Didn't get it? On the "Check your inbox" page click **Resend code**.
   Typed the wrong address? Click **Wrong email? Sign out and try again**.

moonbase won't deploy until the email is verified.

## Part 3. One more step before uploading

Before the first upload, moonbase may show **"One more step before
uploading"**. Confirm the terms there. If it asks for a **Phone number**,
type it, click **Send code**, then type the SMS code and click
**Verify phone**.

## Part 4. Your first mission

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

That link works for anyone, right now. Tell the user to share it.

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
**Copy Error ID** and keep it. Then open `troubleshooting.md`. A failed deploy
never takes a mission offline: the previous version keeps working.

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
