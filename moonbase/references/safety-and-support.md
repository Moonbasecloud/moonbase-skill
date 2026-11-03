# Safety and support

## Keys and secrets: the rules

- **Never ask the user to paste an API key, password or secret into the
  chat.** If they do it anyway, tell them gently to delete that key on **API
  Keys** (https://app.moonbase.cloud/api-keys) and create a new one, because
  chat text can be stored.
- Never commit a key to the repository, and never print or echo it. Use the
  `MOONBASE_API_KEY` environment variable, or the CI's secret store (GitHub:
  Actions secrets). The one narrow exception to "not in a file" is a deliberate
  `0600` secrets file kept **outside** the repo and never committed — e.g. a
  curl `--config`/`-H @file` header file (see `api-and-ci.md`); a secret
  manager or a stdin pipe is better still.
- A moonbase key works for **every mission on its account**. A leaked key is
  serious: delete it and make a new one.
- The full key is shown **once** when created. After that only a masked form
  like `mb_live_••••••••4f2a` is visible. Lost it? Delete the key and create a
  new one.
- Deleting a key: on **API Keys**, delete it from its row and type `DELETE`
  to confirm. Anything using it stops working immediately. It can't be undone.

## .env files and secrets in uploads

- Don't put a `.env` with real secrets in the ZIP. The skill's packaging tool
  (`scripts/package-mission.sh`) excludes `.env` / `.env.*` (a tracked one makes
  it **fail closed**), plus dependency, build-output, virtualenv, cache,
  database and log files. It is a **filename filter on a fixed list, not a
  secrets scanner**: it does **not** recognize other secret-named files — a
  tracked `.npmrc`, a `*.pem` or SSH private key, a `credentials.json` or a
  `prod.env` (no leading dot) **will** ship. And it can't catch a secret pasted *inside* a
  source file. Keep those out yourself (moonbase also blocks
  `hardcoded_secret_detected` server-side). The gate guarantees only that it
  won't ship a `.env`, not that your upload is secret-free.
- If a shipped `.env` is there anyway, moonbase applies only its
  non-secret values; anything shaped like a credential is never applied from
  the file. Set real secrets in **Mission Control → Environment Variables**
  (write-only, encrypted).
- An upload with a hardcoded credential in the code is stopped
  (`hardcoded_secret_detected`) so it never goes public.
- Remember: a downloaded archive is the original upload as-is, so a `.env`
  inside it would be in the download too.

## Account safety

Turn on **two-factor authentication** in **Account → Security**, and save
the recovery codes. Check **Active sessions** and **Recent sign-ins** if
something looks odd. moonbase warns about unusual or new-device sign-ins.

## When to contact support

Contact support (https://moonbase.cloud/contact) when:
- an error says "contact support" (`zip_unsafe`, `classification_error`,
  `mission_slug_unusable`, a suspected false `malware_detected`,
  `scan_too_large`);
- a deploy keeps failing and the project builds fine on your computer;
- the mission is unreachable on its `moonbase.host` address and isn't
  paused or asleep;
- you need the full build log (support can find it from the TRK-ID);
- billing problems or a refund;
- recovering a deleted account (within the retention period).

Always include: the **TRK-ID** (Error ID), the mission's name and address,
when it started, and the exact message or browser error.

Status of moonbase itself: the "Status" and "Incident History" links in the
footer of https://moonbase.cloud.
