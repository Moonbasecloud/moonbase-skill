# Deploying for the user (when you can run commands)

Confirm the person has a moonbase account before setting anything up. If
they don't, send them to **https://app.moonbase.cloud/register** and wait
until they confirm.

If their AI tool supports the moonbase connector, follow
**https://moonbase.cloud/docs/deploy-from-ai-chat** first. The person signs
in to connect it. This guide is the API key fallback for CI, scripts and
tools that can run commands without a connector. For chat-only tools, guide
the person through the browser upload in `getting-started.md`.

**Send a `User-Agent` header on every request.** Each `curl` below carries
`-H "User-Agent: my-agent/1.0"`. Use your tool's name and version there.
moonbase may refuse a request without a client identity before it reaches
the API.

Use the API with the person's permission. Check for an existing key before
asking for one. The person creates any new key and takes any browser steps,
including approval if the API returns `consent_required` (see Step 4).

## Step 1. Find a key first; only ask if there isn't one

**Once the person confirms their account, check for a key that already exists** — this is
an automated flow and the user may have set one up already:

- the `MOONBASE_API_KEY` environment variable,
- your tool's own secret store or configured-secrets reference,
- the project's deployment config (never a key hardcoded in source — if you
  find one there, treat it as leaked: tell the user to delete it on the API
  Keys page and create a new one).

If a key is set, use it (always as `$MOONBASE_API_KEY`, never by reading its
value). You can also review whether the project is moonbase-ready — layout,
`PORT`, start script, secrets — **without** a key; only the deploy call itself
needs one.

**Only if no key is set,** ask the user to make one (they do this, not you):

1. Open **https://app.moonbase.cloud/api-keys**.
2. Click **Create API key** and give it a name (like the name of the tool
   that will deploy).
3. *You'll see the full key once, starting with `mb_live_`.* Copy it now: it
   can never be shown again.
4. Store it where I can use it without seeing it: your tool's secret storage or
   a secret manager is best. If you set an environment variable named
   `MOONBASE_API_KEY` in your own terminal (not in this chat), don't type the
   key as a literal — that records it in your shell history. Read it in without
   echoing instead, so nothing is logged:
   ```bash
   read -rs MOONBASE_API_KEY && export MOONBASE_API_KEY   # prompts; input hidden, not saved to history
   ```
   (or load it from your secret manager / a `0600` file). Avoid a plain
   `export MOONBASE_API_KEY="…"` with the key inline.

**Never ask the user to paste the key into the chat.** Never commit it to the
repository and never print it. Always use `$MOONBASE_API_KEY`. (The one narrow
exception to "not in a file" is a deliberate `0600` secrets file **outside** the
repo — e.g. a curl `--config`/`-H @file` header file, see `api-and-ci.md`; a
secret manager or a stdin pipe is better.) If a key was pasted into the chat by
accident, tell the user to delete it on the API Keys page and create a new one.

Facts about keys: every key has one scope, **Deploy**. A key works for every
mission on its account (it can't be limited to one mission). Up to 10 keys per
account. Each key can be deleted on its own; the others keep working.

## Step 2. Package the project (the one packaging tool)

The skill ships **one** packaging tool, `scripts/package-mission.sh`, and the
quickstart, this recipe and the CI example all run **that same file** — there
is no second, looser packaging command anywhere. It builds a **fresh,
uniquely-named** archive (it never updates or reuses one, so a stale zip can't
carry an old `.env`), takes an explicit **source allowlist** (your git-tracked
files, or `--manifest <file>` for a project that isn't in git), packages
**regular files only** (symlinks are rejected — in any path component, since a
directory symlink can point outside the project and ship its target under an
allowed name — and every path must resolve inside the project root),
**screens every source path before archiving** (so a flattening zip option like
`ZIPOPT=-j` can't smuggle a forbidden file in under a clean name — the tool also
clears `ZIPOPT`/`UNZIP`), and **fails closed**: it re-reads the real archive
and aborts with a non-zero exit (deleting the archive) on **any** forbidden
entry (a secret/`.env`, `node_modules`, a virtualenv, build output, a SQLite
file or its `-wal`/`-shm`/`-journal` sidecar, runtime/upload data, or a nested
copy), on an archived file set that doesn't **equal** the intended source list,
**or any tool/parse failure** — an unknown inspection outcome is never
treated as success. What it does **not** do: catch a secret hardcoded *inside* a
source file — that's still on you (moonbase also blocks `hardcoded_secret_detected`
server-side). A printed `unzip -l` listing is **not** a gate.

If your tool has the skill installed, run the shipped file directly
(`.claude/skills/moonbase/scripts/package-mission.sh`). Otherwise save this
exact script as `scripts/package-mission.sh` in the project (commit it, so CI
runs the identical tool — see `api-and-ci.md`). The commands below use
`S` for the folder that holds the two scripts: run them from the project
folder and set `S=.claude/skills/moonbase/scripts` (skill installed) or
`S=scripts` (saved into the project).

```bash
#!/usr/bin/env bash
# moonbase mission packager — the ONE packaging tool for the whole skill.
# The quickstart, the deploy recipe and the CI example all run THIS file.
#
# Safety contract (what the gate does and does NOT promise):
#   - FRESH, uniquely-named archive — never updates or reuses one.
#   - Explicit SOURCE allowlist: your git-tracked files, or `--manifest <file>`
#     (one path per line) for a project that isn't in git. The git file list is
#     only trusted when `git ls-files` EXITS 0 — a lister that dies mid-stream
#     (exit 128) must never yield a "successful" but INCOMPLETE archive.
#   - Regular files only: symlinks are REJECTED — not just a final-component
#     symlink, but a symlink in ANY path component (a directory symlink like
#     `alias -> .runtime` would otherwise ship `alias/secret` from an excluded
#     dir under an allowed name). Every entry's CANONICAL (realpath) path must
#     resolve INSIDE the project root and must not resolve into an excluded or
#     secret location. Submodule contents and directory symlinks are not
#     packaged.
#   - Newline/carriage-return filenames are REJECTED: the archiver (`zip -@`)
#     and the re-read gate (`unzip -Z1`) are both line-oriented, so a name with
#     an embedded newline could smuggle an unlisted file past the gate while
#     the intended file is left out (R6-02).
#   - EVERY source path is screened BEFORE archiving (not only the archived
#     member names), and the archiver's option strings (ZIPOPT/UNZIP…) are
#     cleared, so a flattening option like `ZIPOPT=-j` cannot rename
#     `.runtime/x` to a clean `x` and slip it past a gate that only reads the
#     archived names (R8-01).
#   - FAILS CLOSED: the forbidden-path gate is a pure-shell pattern match (no
#     external checker whose error exit could be misread as "nothing
#     forbidden"), the archive is re-read, and ANY tool/parse/pattern failure,
#     any forbidden entry, or an archived file set that doesn't EQUAL the
#     intended source list, ABORTS with a non-zero exit and deletes the
#     archive. An unknown outcome is never treated as success (R6-01).
# The gate stops dependencies, build output, virtualenvs, runtime data and
# obvious secrets (`.env`). It is NOT a secrets scanner: it cannot catch a
# secret a developer hardcoded inside a source file — that is the uploader's
# responsibility (moonbase also blocks `hardcoded_secret_detected` server-side).
#
# Usage:  archive="$(bash package-mission.sh)" || exit 1      # git mode
#         archive="$(bash package-mission.sh --manifest files.txt)" || exit 1
#         # ship a static build dir on purpose (secrets/deps still blocked):
#         archive="$(bash package-mission.sh --manifest files.txt --allow-build-output)" || exit 1
#         # then upload "$archive" (stdout is only the archive name on success)
set -euo pipefail

say() { printf '%s\n' "$*" >&2; }           # human output on stderr; stdout = archive name
die() { say "$@"; exit 1; }

# The hint under a BLOCKED list. Don't tell the user to re-pass a flag they
# already passed: once --allow-build-output is on, remaining blocks are the
# always-excluded set (build caches, secrets, databases, node_modules).
blocked_hint() {
  say "Remove them (git rm --cached <file>, add to .gitignore)."
  if [ "${allow_build_output:-0}" -eq 1 ]; then
    say "These stay excluded even with --allow-build-output: build caches"
    say "(e.g. .next/cache), secrets, databases, logs, node_modules and .git."
  else
    say "To ship a static build directory (dist/, build/, out/) on purpose,"
    say "re-run with --allow-build-output — it still blocks build caches"
    say "(.next/cache), secrets, databases and node_modules."
  fi
}

# Neutralise env-configured option strings. ZIPOPT=-j would make Info-ZIP
# FLATTEN directories, so `.runtime/x` would ship as `x` and slip past a gate
# that only checks archived member names; UNZIP/UNZIPOPT could likewise distort
# the validation listing. Clear them so the tool sees real paths (R8-01).
unset ZIP ZIPOPT UNZIP UNZIPOPT

# Prerequisites must exist, or we ABORT — a missing checker must never be read
# as "nothing forbidden found".
command -v zip   >/dev/null 2>&1 || die "zip is required but not installed."
command -v unzip >/dev/null 2>&1 || die "unzip is required but not installed (needed to validate the archive)."

# --- Arguments --------------------------------------------------------------
# --manifest <file>      explicit source list for a project that isn't in git
# --allow-build-output   intentionally ship a static build directory (dist/,
#                        build/, out/, .next/, coverage/). Secrets, databases,
#                        logs, node_modules, virtualenvs, caches and .git stay
#                        blocked (R6-05: without this the "ship a build dir"
#                        advice was false — every mode blocked those names).
manifest=""
allow_build_output=0
while [ "$#" -gt 0 ]; do
  arg="${1:-}"
  case "$arg" in
    --manifest)
      manifest="${2:-}"
      { [ -n "$manifest" ] && [ -f "$manifest" ]; } || die "--manifest needs a readable file listing your source paths, one per line."
      shift 2 ;;
    --allow-build-output)
      allow_build_output=1
      shift ;;
    *)
      die "Unknown argument: $arg (use --manifest <file> and/or --allow-build-output)." ;;
  esac
done

# --- Forbidden-path test (defined early: used to screen CANONICAL source paths
#     BEFORE archiving, and again on the real archive listing AFTER) ----------
# Pure-shell pattern match, so there is NO external checker whose error exit
# could be read as "nothing forbidden" (R6-01: the old `grep -Eiq` inside an
# `if` sent grep's exit 2 — a tool error — down the same "allowed" branch as
# exit 1 — no match). `[[ =~ ]]` yields 0 match / 1 no-match / 2 bad-regex; 2
# cannot happen for these constant patterns, and is_forbidden ABORTS on it.
#   ALWAYS blocked (even with --allow-build-output): secrets, databases, logs,
#   node_modules, virtualenvs, `.next/cache`, .git, runtime/upload data.
#   BUILD OUTPUT (.next|dist|build|out|coverage): blocked by default; allowed
#   only with --allow-build-output, to ship a static build on purpose — but
#   `.next/cache` stays blocked even then (a build cache, never a shippable
#   artifact).
always_re='(^|/)(node_modules|\.?venv|__pycache__|\.git|uploads|\.runtime)/|(^|/)\.next/cache/|(^|/)\.env($|\.)|\.(sqlite[0-9]?.*|db|pyc|log)$|(-journal|-wal|-shm)$'
build_re='(^|/)(\.next|dist|build|out|coverage)/'

# 0 = forbidden, 1 = allowed, 2 = pattern-engine fault (caller aborts).
is_forbidden() {
  local e=${1:-} rc
  shopt -s nocasematch
  if [[ $e =~ $always_re ]]; then rc=0; else rc=$?; fi
  if [ "$rc" -eq 0 ]; then shopt -u nocasematch; return 0; fi
  if [ "$rc" -ne 1 ]; then shopt -u nocasematch; return 2; fi
  if [ "$allow_build_output" -eq 0 ]; then
    if [[ $e =~ $build_re ]]; then rc=0; else rc=$?; fi
    if [ "$rc" -eq 0 ]; then shopt -u nocasematch; return 0; fi
    if [ "$rc" -ne 1 ]; then shopt -u nocasematch; return 2; fi
  fi
  shopt -u nocasematch
  return 1
}

# Reject a symlink in ANY component of a path, not only the final one. A
# directory symlink (e.g. `alias -> .runtime`) would otherwise let a listed
# path like `alias/customer.txt` ship a file from an excluded/secret dir under
# an allowed name. Walks components with parameter expansion (no word-splitting,
# so a name with `*` or IFS bytes can't glob or re-split).
reject_symlink_components() {
  local p="${1:-}" partial="" comp rest="${1:-}"
  while [ -n "$rest" ]; do
    comp="${rest%%/*}"
    if [ "$comp" = "$rest" ]; then rest=""; else rest="${rest#*/}"; fi
    [ -z "$comp" ] && continue
    partial="${partial:+$partial/}$comp"
    if [ -L "$partial" ]; then
      die "Refusing a path that passes through a symlink (it can ship a file from outside the project or from an excluded dir): $p"
    fi
  done
}

# --- Source allowlist -------------------------------------------------------
include=()
if [ -n "$manifest" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"                        # tolerate a CRLF-authored manifest
    case "$line" in ""|"#"*) continue ;; esac   # skip blanks and comments
    include+=("$line")
  done < "$manifest"
elif git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Capture the file list to a temp file and CHECK the producer's EXIT STATUS
  # before trusting it. A `git ls-files` that emits some names then fails (e.g.
  # exits 128) must ABORT — never yield a "successful" but INCOMPLETE archive.
  # The temp file keeps the output NUL-separated (command substitution would
  # strip the NUL bytes and mangle the names).
  gitlist="$(mktemp)" || die "Could not create a temp file for the git file list."
  if ! git ls-files -z >"$gitlist"; then
    rm -f "$gitlist"
    die "git ls-files failed — refusing to package an incomplete file list."
  fi
  # NUL-separated: a filename's exact bytes, never split or mangled (paired
  # with the newline/CR rejection below, which keeps those bytes safe to feed
  # to the line-oriented archiver and gate).
  while IFS= read -r -d '' f; do include+=("$f"); done < "$gitlist"
  rm -f "$gitlist"
else
  die "Not a git repository and no --manifest given. Either run from a git repo (git init && git add your source), or pass --manifest <file> listing the source paths to ship."
fi

# A root-level .env.example (placeholders, not secrets) is the one env file
# allowed. Add it if present and not already listed.
if [ -f .env.example ]; then
  case " ${include[*]} " in *" .env.example "*) : ;; *) include+=(".env.example") ;; esac
fi
[ "${#include[@]}" -gt 0 ] || die "No source files to package."

# --- Keep only regular files that resolve INSIDE the project root, and screen
# --- every SOURCE path against the forbidden list before it can be archived.
root="$(pwd -P)"
safe=()
blocked=""
for f in "${include[@]}"; do
  case "$f" in
    *$'\n'*|*$'\r'*) die "Refusing a path with a newline or carriage return — it could smuggle an unlisted file past the gate." ;;
    /*|../*|*/../*|*/..) die "Refusing unsafe path in the source list: $f" ;;
  esac
  [ -e "$f" ] || die "Listed source file is missing: $f"
  if [ -L "$f" ]; then
    die "Refusing to package a symlink (it can point outside the project and ship its target): $f"
  fi
  # A symlink anywhere ABOVE the file is just as dangerous as the file itself.
  reject_symlink_components "$f"
  if [ ! -f "$f" ]; then
    say "Skipping non-regular entry (directory, submodule or special file): $f"
    continue
  fi
  # Screen the CANONICAL (realpath) path. It must resolve INSIDE the project
  # root (a symlink that escaped the checks above and pointed elsewhere is
  # caught here). When the real path DIFFERS from the listed name — i.e. a
  # component redirected it — screen the real relative path against the
  # forbidden patterns too, so `alias/ok.txt -> .runtime/secret` can't ship a
  # secret under an allowed name.
  rp="$(cd "$(dirname -- "$f")" >/dev/null 2>&1 && pwd -P)/$(basename -- "$f")"
  case "$rp" in
    "$root"/*) rel="${rp#"$root"/}" ;;
    *) die "Refusing a file that resolves outside the project root: $f" ;;
  esac
  if [ "$rel" != "$f" ] && [ "$rel" != ".env.example" ]; then
    if is_forbidden "$rel"; then
      die "Refusing a file whose real path resolves into an excluded or secret location: $f (resolves to $rel)"
    else
      rc=$?
      [ "$rc" -eq 1 ] || die "Could not screen a source path (pattern-engine fault) — aborting (fail-closed)."
    fi
  fi
  # Screen the LISTED path too — this is the name the archive member carries,
  # so screening it here (not only the archive afterwards) is what stops a
  # flattening/renaming zip option from smuggling it in under a clean name.
  if [ "$f" != ".env.example" ]; then
    if is_forbidden "$f"; then
      blocked+="$f"$'\n'
      continue
    else
      rc=$?
      [ "$rc" -eq 1 ] || die "Could not screen a source path (pattern-engine fault) — aborting (fail-closed)."
    fi
  fi
  safe+=("$f")
done

if [ -n "$blocked" ]; then
  say "BLOCKED — these must not ship:"
  printf '%s' "$blocked" >&2
  blocked_hint
  exit 1
fi
[ "${#safe[@]}" -gt 0 ] || die "No regular source files to package after safety checks."

# --- Fresh, uniquely-named archive -----------------------------------------
archive="mission-$(date -u +%Y%m%d-%H%M%S)-$$.zip"
[ -e "$archive" ] && die "Refusing to reuse an existing $archive."
# From here an archive may exist but is NOT yet validated. A scoped EXIT trap
# removes it (and any temp dir) on ANY exit — a failed checker, a `set -e`
# abort, a BLOCKED exit — so an unvalidated or rejected archive is never left
# behind (R9-04). We clear the trap only after every check passes.
exdir=""
trap 'rm -f "$archive"; [ -n "$exdir" ] && rm -rf "$exdir"' EXIT
# Store symlinks as links instead of following them (defence in depth; we also
# rejected them above). Names are newline-free (checked above), so `-@` maps
# one line to exactly one intended file.
printf '%s\n' "${safe[@]}" | zip -q --symlinks "$archive" -@ || die "zip failed; no archive produced."

# --- FAIL-CLOSED content gate ----------------------------------------------
# Re-read the REAL archive. Any failure to enumerate it aborts (we never treat
# an unknown outcome as success). Forbidden-path checks run FIRST; only a
# root-level .env.example is exempt. (`unzip -Z1` renders non-ASCII names
# lossily, which is harmless here: the forbidden patterns are ASCII, and the
# real source paths were already screened by name above.)
listing="$(unzip -Z1 "$archive")" || die "Could not read the archive to validate it — aborting (fail-closed)."
[ -n "$listing" ] || die "Archive listing was empty — aborting (fail-closed)."

forbidden=""
while IFS= read -r entry; do
  [ -z "$entry" ] && continue
  case "$entry" in */) continue ;; esac       # a directory entry, not a file
  [ "$entry" = ".env.example" ] && continue   # narrow, root-only exemption
  if is_forbidden "$entry"; then
    forbidden+="$entry"$'\n'
  else
    rc=$?
    [ "$rc" -eq 1 ] || die "Could not screen an archive entry (pattern-engine fault) — aborting (fail-closed)."
  fi
done <<< "$listing"

if [ -n "$forbidden" ]; then
  say "BLOCKED — these must not ship:"
  printf '%s' "$forbidden" >&2
  blocked_hint
  exit 1
fi

# EXACT membership — nothing added, dropped or renamed. We must NOT compare
# `unzip -Z1`'s TEXT, because it renders non-ASCII names lossily (Apple shows
# UTF-8 bytes as `?`), which would falsely reject a valid Unicode name such as
# a Hebrew filename (R9-02). Instead EXTRACT the archive — extraction preserves
# the real bytes on disk — and compare the extracted paths to the intended
# list, byte-for-byte. Each `$(...)` is guarded so a checker fault aborts with a
# diagnostic (and the trap deletes the archive).
exdir="$(mktemp -d)" || die "Could not create a temp dir to validate the archive — aborting (fail-closed)."
unzip -qq -o "$archive" -d "$exdir" >/dev/null 2>&1 || die "Could not extract the archive to validate it — aborting (fail-closed)."
members="$( (cd "$exdir" && find . \( -type f -o -type l \) -print) | sed 's|^\./||' | LC_ALL=C sort )" || die "Could not enumerate the archive to validate it — aborting (fail-closed)."
intended="$(printf '%s\n' "${safe[@]}" | LC_ALL=C sort)" || die "Could not enumerate the intended source list — aborting (fail-closed)."
if [ "$members" != "$intended" ]; then
  die "Archived files do not match the intended source list — aborting (fail-closed)."
fi

# All checks passed: keep the archive (clear the trap) and report.
rm -rf "$exdir"; exdir=""
trap - EXIT
say "Packaged ${#safe[@]} source files into $archive"
printf '%s\n' "$archive"
```

Run it and capture the archive name it prints — that's what you upload (in a
non-git project, pass `--manifest files.txt` listing your source paths):

```bash
mission="$(bash "$S/package-mission.sh")" || exit 1   # fails closed; nothing to upload on error
```

Shipping a **static build on purpose** (a prebuilt `dist/`, `build/` or `out/`
is the mission)? Those directory names are blocked by default; add
`--allow-build-output` to include them (list the exact files with `--manifest`,
or run from the build folder so its `index.html` is at the root). It still
blocks secrets, databases, logs, `node_modules` and `.git`, so the safeguards
hold — it only stops treating build-output *names* as forbidden. One build-dir
exception stays blocked even with the flag: `.next/cache` is a build cache, not
a shippable artifact, so it's always excluded — ship `.next` without it.

Check the rules in `building-for-moonbase.md` first: root layout, `PORT`, start
command (Node), or the app object (Python).

## Step 3. New mission, or new version?

- **New mission:** don't send `redeployProjectId`. Optionally send `name` (the
  address: 3 to 32 lowercase letters, numbers, single hyphens, starting with a
  letter; random if left out) and `displayName`.
- **The address** is the first label of the live URL the parser prints
  (`https://<address>.moonbase.host`). Use that for every status call, not
  the `name` you asked for: the two can differ, and a wrong one answers `not_found`.
  Keep it as `MISSION_ADDRESS`.
- **"Update my mission X" / redeploy by name:** look up the mission's id from
  its address first, then send it as `redeployProjectId`. **Never** send
  `name=X` to update: that tries to create a second mission and fails with
  `name_taken`.

```bash
# <address> = first label of the live URL (keep it as MISSION_ADDRESS)
curl -sS "https://app.moonbase.cloud/api/v1/sites/<address>/status" \
  -H "Authorization: Bearer $MOONBASE_API_KEY" \
  -H "User-Agent: my-agent/1.0" | jq -re .id || { echo "No mission at that address (check the name/key)." >&2; exit 1; }
```

The id is also in the mission's page link in the app
(`https://app.moonbase.cloud/missions/<id>`) and in the `done` event of the
last deploy (`project_id`).

## Step 4. Deploy and read the result

**Read the result honestly.** The HTTP status is `200` even when the deploy
later fails, so you must parse the stream — and a half-received stream must
never read as success. Use the shipped parser, **`scripts/parse-deploy-result.sh`**
— the same one tool the quickstart and the CI example in `api-and-ci.md` call,
so no copy can drift. It exits `0` **only** on a complete, final `done` event
carrying a usable https live URL (a real DNS host, optional port 1-65535, no
userinfo; an internationalised `xn--` host is verified with `node`'s URL parser
and is treated as unknown if node isn't installed) and a string project_id and the app is not reporting itself
not-ready. It exits `3` when the deploy landed but the `done` event says
`app_ready:false` (or `readiness.state` is `not_ready`): the files are deployed
but the app needs configuration or is still warming up, so poll the status
endpoint — do not re-upload. It exits `4` when the `done` event carries an
`asset_problem`: the page's own files don't load, so waiting won't help; change
the project and upload a new version. A refusal, an `error` event, or a
truncated/malformed/unknown stream exits non-zero so you reconcile with the
status endpoint instead of lying. Run the skill's own copy if it is on disk,
otherwise save this exact script as `scripts/parse-deploy-result.sh` and commit
it so CI runs the same tool:

```bash
#!/usr/bin/env bash
# moonbase deploy-result parser — the one shipped tool that turns a deploy
# response into an HONEST outcome. The deploy recipe, the quickstart and CI all
# call this same script, so no copy can drift. It succeeds (exit 0) ONLY on a
# transfer that completed AND a stream carrying EXACTLY ONE final `done` event
# (one JSON object) with a usable https:// live URL (a real DNS hostname: 2+
# labels, alphabetic TLD, so no IP / numeric / hex hosts; optional port 1-65535,
# no userinfo; an xn-- (IDN) host must also pass Node's WHATWG URL parser, since
# Punycode decoding alone is not IDNA validation) and a non-empty string
# project_id, and its readiness is not an explicit not-ready. A failed
# transfer, a refusal, an `error`, or a truncated / duplicate / malformed /
# unknown outcome FAILS, so it is reconciled against the status endpoint rather
# than reported as a success it wasn't.
#
# Events are parsed per the WHATWG SSE spec (field = text before the first
# colon; at most one leading space stripped from the value; `data` lines
# accumulate), so `data:x` and `data: x` are the same field and nothing is
# silently dropped. Every printed server field is sanitised (control chars,
# CR/LF/ESC and U+2028/U+2029 stripped) so it can't inject CI-log commands.
#
# Usage: bash parse-deploy-result.sh <body-file> <http-status> <content-type> <curl-exit>
# Exit:  0 live   1 failed/refused   2 unknown/truncated (reconcile)
#        3 deployed but NOT READY (app_ready:false / readiness not_ready): the
#          upload landed; poll the status endpoint, do NOT re-upload.
#        4 deployed but the page's files don't load (asset_problem): waiting
#          won't help; change the project and upload a new version.
report_deploy_result() {
  body="${1:-}"; http_status="${2:-}"; curl_rc="${4:-}"
  mt="$(printf '%s' "${3:-}" | tr 'A-Z' 'a-z')"; mt="${mt%%;*}"
  mt="${mt#"${mt%%[![:space:]]*}"}"; mt="${mt%"${mt##*[![:space:]]}"}"

  # Fail CLOSED on a missing or non-numeric curl exit: only an explicit 0 is a
  # clean transfer; anything else (an empty 4th arg from a caller bug included)
  # is UNKNOWN, never a silent success.
  case "$curl_rc" in
    0) : ;;
    '') echo "Deploy transfer status missing (no curl exit code) — reconcile with the status endpoint before trusting it." >&2; return 2 ;;
    *[!0-9]*) echo "Deploy transfer status not understood (curl exit '$curl_rc') — reconcile with the status endpoint." >&2; return 2 ;;
    *) echo "Deploy transfer failed (curl exit $curl_rc) — reconcile with the status endpoint before uploading again." >&2; return 2 ;;
  esac

  [ -n "$http_status" ] || { echo "Deploy failed: no HTTP status (transfer never completed) — reconcile with the status endpoint." >&2; return 2; }
  [ -n "$mt" ]          || { echo "Deploy failed: no Content-Type (not a deploy stream) — reconcile with the status endpoint." >&2; return 2; }
  # A pre-stream JSON refusal is a DEFINITE failure (1) only when transport and
  # HTTP status are known AND the body is exactly one JSON object with a string
  # `title` or `error`; a malformed / non-object / unrecognised body is UNKNOWN (2).
  case "$mt" in
    application/json)
      rmsg="$(jq -se 'if length==1 and (.[0]|type=="object") and (((.[0].title // .[0].error)|type)=="string") then .[0] else error end' "$body" 2>/dev/null | jq -r 'def s: tostring|gsub("[[:cntrl:]\u2028\u2029]";" ");
             "Deploy refused: " + ((.title // .error // "error")|s)
             + (if .nextStep then " — " + (.nextStep|s) else "" end)
             + (if .retry_after_sec then " (retry after " + (.retry_after_sec|s) + "s)" else "" end)' 2>/dev/null)" && [ -n "$rmsg" ] || { echo "Deploy returned a JSON body that is not a recognised refusal — reconcile with the status endpoint before uploading again." >&2; return 2; }
      printf '%s\n' "$rmsg" >&2
      return 1 ;;
  esac
  case "$http_status" in 2[0-9][0-9]) : ;; *) echo "Deploy failed: HTTP $http_status before any stream." >&2; return 1 ;; esac
  case "$mt" in text/event-stream) : ;; *) echo "Deploy failed: unexpected Content-Type '$mt' (not a deploy stream)." >&2; return 1 ;; esac

  # WHATWG SSE line interpretation: split each field at the FIRST colon and strip
  # at most one leading space, so fields are recognised regardless of spacing
  # ('data: x' and 'data:x' are the same field). A line beginning ':' is a
  # comment; a blank line dispatches the event. 'data' lines accumulate (joined
  # by LF, one trailing LF removed at dispatch). Require EXACTLY ONE terminal
  # (done|error) that is the FINAL semantic frame — after it, only comment/blank
  # heartbeat framing may appear. A field still pending at EOF is a truncated tail.
  final_event=""; final_data=""; ev=""; data=""; term_count=0; terminated=0; first=1
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    # Strip a leading UTF-8 BOM on the very first line.
    [ "$first" -eq 1 ] && { line="${line#$'\xef\xbb\xbf'}"; first=0; }
    # We parse only LF / CRLF line breaks. A lone or embedded CR (a stream
    # using bare CR as a separator) is NOT interpreted per SSE, so fail CLOSED
    # rather than silently hide a frame a spec client would see.
    case "$line" in *$'\r'*) echo "The stream used bare CR line breaks (not parsed) — reconcile with the status endpoint before trusting it." >&2; return 2 ;; esac
    if [ "$terminated" -eq 1 ]; then
      case "$line" in
        "") : ;;
        :*) : ;;
        *) echo "The stream carried a further frame after the final 'done'/'error' — reconcile with the status endpoint before trusting it." >&2; return 2 ;;
      esac
      continue
    fi
    case "$line" in
      "")
        data="${data%$'\n'}"
        case "$ev" in
          done|error) term_count=$((term_count + 1)); final_event="$ev"; final_data="$data"; terminated=1 ;;
        esac
        ev=""; data="" ;;
      :*) : ;;
      *)
        case "$line" in
          *:*) field="${line%%:*}"; rest="${line#*:}"; case "$rest" in " "*) rest="${rest# }" ;; esac ;;
          *)   field="$line"; rest="" ;;
        esac
        case "$field" in
          event) ev="$rest" ;;
          data)  data="${data}${rest}"$'\n' ;;
          *) : ;;
        esac ;;
    esac
  done < "$body"
  if [ -n "$ev" ] || [ -n "$data" ]; then
    echo "The stream ended mid-event (truncated) — reconcile with the status endpoint before uploading again." >&2
    return 2
  fi
  if [ "$term_count" -ne 1 ]; then
    echo "The stream did not carry exactly one final 'done'/'error' ($term_count seen) — reconcile with the status endpoint before uploading again." >&2
    return 2
  fi

  case "$final_event" in
    done)
      obj="$(printf '%s' "$final_data" | jq -se 'if length==1 and (.[0]|type=="object") then .[0] else error end' 2>/dev/null)" || { echo "Deploy 'done' did not carry exactly one JSON object — reconcile with the status endpoint." >&2; return 2; }
      url="$(printf '%s' "$obj" | jq -re '
        def host_ok($hp):
          ($hp | ascii_downcase) as $h
          | ($h | test("@") | not)
          and ($h | test("^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+(:[0-9]{1,5})?$"))
          and ( if ($h | test(":")) then (($h | sub("^[^:]*:";"") | tonumber) as $p | $p >= 1 and $p <= 65535) else true end )
          and ( ($h | sub(":[0-9]+$";"")) as $host
                | ($host | split(".")) as $labels
                | ($labels | last) as $tld
                | ($host | length) <= 253
                  and all($labels[]; length <= 63)
                  and (($tld | test("^[a-z]{2,}$")) or ($tld | test("^xn--[a-z0-9-]*[a-z0-9]$"))) );
        .url
        | select(type=="string")
        | select(test("[[:cntrl:][:space:]\u2028\u2029]") | not)
        | select(test("^https://"))
        | (sub("^https://";"") | sub("[/?#].*$";"")) as $hp
        | select(host_ok($hp))' 2>/dev/null)" || { echo "Deploy ended with an incomplete 'done' (no usable https URL with a real host) — reconcile with the status endpoint before trusting it." >&2; return 2; }
      # An IDN host (any xn-- label) is accepted only if a real URL/IDNA parser
      # (Node's WHATWG URL) accepts it unchanged; without node it is UNKNOWN. A
      # plain ASCII host (e.g. *.moonbase.host) never needs node.
      hp="${url#https://}"; hp="${hp%%[/?#]*}"; hp="$(printf '%s' "$hp" | tr 'A-Z' 'a-z')"; hn="${hp%:*}"
      case "$hp" in *:*) : ;; *) hn="$hp" ;; esac
      case "$hn" in
        xn--*|*.xn--*)
          if ! command -v node >/dev/null 2>&1; then
            echo "Deploy 'done' has an internationalised (xn--) host that needs node to verify and node is not installed — reconcile with the status endpoint before trusting it." >&2; return 2
          fi
          # The node call first proves ITS parser validates IDNA (some releases accept
          # every xn-- host): known-bad names must throw and a known-good one must
          # round-trip, else the check is meaningless and the host is UNKNOWN.
          nout="$(node -e '
            const bad = (h) => { try { new URL("https://" + h + "/"); return false; } catch (e) { return true; } };
            let sane = false;
            try { sane = bad("xn--a.example") && bad("xn--a-xbb.example") && new URL("https://xn--p1ai.xn--p1ai/").hostname === "xn--p1ai.xn--p1ai"; } catch (e) {}
            if (!sane) process.exit(3);
            try { const u = new URL(process.argv[1]); if (u.protocol === "https:" && u.hostname === process.argv[2]) { process.stdout.write("mb-idna-ok"); process.exit(0); } process.exit(1); } catch (e) { process.exit(1); }
          ' "$url" "$hn" 2>/dev/null)"; nrc=$?
          case "$nrc" in
            0) [ "$nout" = "mb-idna-ok" ] || { echo "Deploy 'done' has an internationalised (xn--) host and the node check did not confirm it — reconcile with the status endpoint before trusting it." >&2; return 2; } ;;
            3) echo "Deploy 'done' has an internationalised (xn--) host and this node's URL parser does not validate IDNA — reconcile with the status endpoint before trusting it." >&2; return 2 ;;
            *) echo "Deploy 'done' host is not a valid internationalised hostname (rejected by the URL parser) — reconcile with the status endpoint before trusting it." >&2; return 2 ;;
          esac ;;
      esac
      printf '%s' "$obj" | jq -re '.project_id | select(type=="string") | select(test("[^[:space:][:cntrl:]]")) | select(test("[[:space:][:cntrl:]]")|not)' >/dev/null 2>&1 || { echo "Deploy 'done' carried no usable project_id string (empty, whitespace, or control chars) to bind the mission to — reconcile with the status endpoint before trusting it." >&2; return 2; }
      # app_ready is the app's own readiness: true -> live; false (or readiness
      # state "not_ready") -> deployed but NOT ready (exit 3); null / missing ->
      # not determined, which the API contract treats as live; any other type is
      # not understood -> UNKNOWN.
      ready="$(printf '%s' "$obj" | jq -r 'if (.app_ready == null or .app_ready == true or .app_ready == false) | not then "bad"
        elif .app_ready == false then "no"
        elif ((.readiness | type) == "object") and (.readiness.state == "not_ready") then "no"
        else "yes" end' 2>/dev/null)" || ready="bad"
      case "$ready" in yes|no) : ;; *) echo "Deploy 'done' carried an app_ready value that is not true/false/null — reconcile with the status endpoint before trusting it." >&2; return 2 ;; esac
      if [ "$ready" = "no" ]; then
        printf 'Deployed, NOT READY: %s\n' "$url"
      else
        printf 'Live: %s\n' "$url"
      fi
      printf '%s' "$obj" | jq -r 'def s: tostring|gsub("[[:cntrl:]\u2028\u2029]";" ");
        "project_id: " + (.project_id|s),
        (if (.self_repair_notice // "") != "" then "Self-repair: " + (.self_repair_notice|s) else empty end),
        (if (.skipped_entries|type) == "array" and (.skipped_entries|length) > 0 then "Skipped entries: " + ([.skipped_entries[]|s]|join(", ")) else empty end)' 2>/dev/null
      asset_problem="$(printf '%s' "$obj" | jq -r 'def s: tostring|gsub("[[:cntrl:]\u2028\u2029]";" "); if (.asset_problem|type) == "object" then (.asset_problem.message // "The page files are not loading.")|s else "" end' 2>/dev/null)"
      if [ -n "$asset_problem" ]; then
        printf '%s' "$obj" | jq -r 'def s: tostring|gsub("[[:cntrl:]\u2028\u2029]";" "); (if (.asset_problem.failed_paths|type) == "array" then "Files not loading: " + ([.asset_problem.failed_paths[]|s]|join(", ")) else empty end)' 2>/dev/null
        printf '%s Waiting will not fix this: change the project, then upload a new version.\n' "$asset_problem" >&2
        return 4
      fi
      if [ "$ready" = "no" ]; then
        printf '%s' "$obj" | jq -r 'def s: tostring|gsub("[[:cntrl:]\u2028\u2029]";" ");
          (if (.readiness | type) == "object" then "Readiness: " + ((.readiness.state // "not_ready")|s) + " (path " + ((.readiness.path // "unknown")|s) + ", http " + ((.readiness.http_status // "unknown")|s) + ")" else empty end)' 2>/dev/null
        echo "The files were uploaded and the mission is deployed, but the app reports it is not ready yet (needs configuration or still warming up). Do NOT re-upload: poll the status endpoint until status is 'live' (appReady true), and finish any configuration it needs." >&2
        return 3
      fi
      return 0 ;;
    error)
      eobj="$(printf '%s' "$final_data" | jq -se 'if length==1 and (.[0]|type=="object") then .[0] else error end' 2>/dev/null)" || { echo "Deploy ended with a malformed 'error' event (not one JSON object) — reconcile with the status endpoint before trusting it." >&2; return 2; }
      emsg="$(printf '%s' "$eobj" | jq -r 'def s: tostring|gsub("[[:cntrl:]\u2028\u2029]";" ");
        "Deploy failed: " + ((.friendly.title // "build error")|s)
        + " [code " + ((.friendly.code // .code // "unknown")|s) + "]"
        + (if .retry_after_sec then " (retry after " + (.retry_after_sec|s) + "s)" else "" end)
        + (if (.consent_url // .friendly.consent_url) then " — approve in the browser: " + ((.consent_url // .friendly.consent_url)|s) else "" end)
        + " (reference " + ((.trace_id // "no-TRK")|s) + ")"' 2>/dev/null)" || { echo "Deploy 'error' event could not be rendered (unexpected shape) — reconcile with the status endpoint before trusting it." >&2; return 2; }
      printf '%s\n' "$emsg" >&2
      return 1 ;;
  esac
}

report_deploy_result "$@"
```

Run the deploy, capturing the body, HTTP status and Content-Type, then hand
them to the shipped parser:

```bash
API="https://app.moonbase.cloud"
# For a REDEPLOY, record the current version FIRST, so an UNKNOWN outcome can be
# reconciled by "did currentVersion go up?" (Step 5). Empty for a new mission.
prev_version=""
if [ -n "${MOONBASE_MISSION_ID:-}" ]; then
  prev_version="$(curl -sS "$API/api/v1/sites/$MISSION_ADDRESS/status" \
    -H "Authorization: Bearer $MOONBASE_API_KEY" -H "User-Agent: my-agent/1.0" \
    | jq -r '.currentVersion // empty')"
fi
# The stream can carry build output, so keep it in a private, short-lived file
# (owner-only, deleted on exit) — never world-readable, committed, or uploaded
# as a CI artifact.
log="$(mktemp)"; chmod 600 "$log"; trap 'rm -f "$log" "$mission"' EXIT  # also remove the uploaded zip

# Capture curl's OWN exit (don't rely on ambient `set -e`): a transfer that
# fails AFTER a complete-looking `done` (e.g. timeout, exit 28) must be treated
# as UNKNOWN, never a success.
curl_rc=0
meta="$(curl -sSN "$API/api/projects/upload/stream" \
  -H "Authorization: Bearer $MOONBASE_API_KEY" \
  -H "User-Agent: my-agent/1.0" \
  -F "file=@$mission" \
  -F "redeployProjectId=$MOONBASE_MISSION_ID" \
  -o "$log" -w '%{http_code} %{content_type}')" || curl_rc=$?

bash "$S/parse-deploy-result.sh" "$log" "${meta%% *}" "${meta#* }" "$curl_rc"
case $? in
  0) : ;;                                   # live — run the success check below
  1) exit 1 ;;                              # a real failure the parser reported
  3) echo "Deployed but NOT READY — poll the status endpoint (do not re-upload)." >&2
     exit 3 ;;                              # app_ready:false — deployed, still configuring/warming
  4) echo "Deployed, but the page's files don't load — change the project, then upload a new version." >&2
     exit 4 ;;                              # asset_problem — polling won't fix this one
  *) # UNKNOWN: reconcile against status instead of re-uploading blindly.
     echo "Reconciling: was baseline version $prev_version — check status now." >&2
     exit 2 ;;
esac
```

A non-zero return that asks you to reconcile is the "unknown outcome" branch
below: check the mission status (Step 5) before uploading again — never re-POST
blindly on an uncertain result.

For a **new** mission, remove the `redeployProjectId` line (add
`-F "name=my-idea"` if the user chose an address).

Allow at least 10 minutes for a build before giving up on the stream. For a
ZIP over about 90 MB, send the same request to
`https://upload.moonbase.cloud/api/projects/upload/stream` (same key, same
fields).

### How to react to the outcome (one classification + retry policy)

This is the single state machine — `api-and-ci.md` states the same one for
pipelines. **Branch on the stable machine signal, never on a title, the raw
`message`, or `friendly.category`:** for a stream `error` event that's
`friendly.code` alone (a missing or unrecognized code is UNKNOWN, below — never
fall back to the category); for a JSON error before the stream it's the `error`
code and its HTTP status. `friendly.category` tells the *user* whose fix it is;
it is never a retry signal and never a substitute for the code. Take the FIRST
branch that matches, in this order:

- **`done`:** the source is deployed. If the parser exits `4` ("Files not
  loading"), the page's files don't load: change the project and upload again.
  If `app_ready` is `false` (parser exit `3`, "Deployed, NOT READY") the app is deployed but not serving yet: keep the
  version receipt, tell the user it still needs configuration or warming up, and
  poll the status endpoint until `status` is `live` — never re-upload and never
  call it live. `app_ready:true`, or `null`/absent (readiness not determined),
  is live. Run the success check below before you call it finished.
- **Retryable — by explicit code only** (never inferred from a category). The
  complete retryable set is:
  - *Before the stream* (JSON error): `rate_limited` (429),
    `deploy_in_progress` (409), `internal` (500), `service_draining` (503),
    `scanner_unavailable` (503), `scan_incomplete` (503).
  - *In the stream* (`error` event): `friendly.code` is one of `deploy_timeout`,
    `moonserver_5xx`, `moonserver_unreachable`, `pypi_unreachable`, or
    `deploy_in_progress` (which can arrive in-stream as well as pre-stream).
    These are the only build/runtime codes a retry may clear. **Do not retry on
    the `our_side` category** — it is attribution, not a retry signal:
    `dependency_version_not_found`, `slug_length_out_of_range` and
    `moonserver_not_configured` are also `our_side` but deterministic, so a
    retry just fails again.
- **Needs the owner** (`consent_required`): the one browser case — see below.
  Never retried by a key.
- **Change the request first** (not retryable): a **known deterministic**
  `friendly.code` — one in the authoritative code list (`api-and-ci.md`,
  "Build logs and build failures") that isn't in the retryable set above
  (including the deterministic `our_side` ones), or a recognized pre-stream
  `error` code. Show `friendly.title` / `.explanation` / `.nextSteps`, the
  `friendly.culprit` and the `trace_id` (`TRK-…`), look the fix up in
  `troubleshooting.md`, fix the cause (or escalate with the `trace_id` if it's
  moonbase's to fix), then deploy again. (NOT a catch-all: a code that isn't in
  the list is UNKNOWN, next — never "change the request".)
- **UNKNOWN — never retry blindly** (this is also where a **missing,
  unrecognized or malformed** outcome lands, never the "change the request"
  branch): `unknown_error`, a `friendly.category` of `unknown`,
  `stream_ended_without_complete` (the stream closed with no final event —
  UNKNOWN even though its category is `our_side`), a bare `docker_build_failed`
  with no identified cause, a `friendly.code` not in the authoritative list
  (`api-and-ci.md`), data that isn't valid JSON, **or** a stream that dropped
  or timed out with neither `done` nor `error`. An unknown outcome is neither a
  provider fault nor a user error until evidence says which — don't re-POST on a
  guess. Check status (Step 5) first: if `deployInProgress` is still `true`,
  wait; if `currentVersion` went up it actually succeeded; upload again only
  once status shows it didn't land.

**Retryability comes only from the named sets above — never from the
`friendly.category`.** Branch on `friendly.code`: if it's in the retryable set,
retry; `unknown_error` / `stream_ended_without_complete` / category `unknown` /
a code you don't recognise / malformed data are UNKNOWN; only a known
deterministic code means change the request. The category tells the *user*
whose fault it is, not whether to retry.

**The one retry policy** (same everywhere — `api-and-ci.md` repeats it). Only
for a *retryable* branch, and **counting the first attempt**: wait at least the
server's delay before each retry — `retry_after_sec` (also the `Retry-After`
header) when it's given, otherwise a few seconds, growing each attempt — and
**never retry sooner than the server asked**. Stop as soon as either bound is
hit: **3 attempts in total** (the first one included), or the next required wait
would push you past a **local deadline of a few minutes**. Then stop and report
the `trace_id` — never loop. (There is no per-wait ceiling that would override a
longer `Retry-After`; the bounds are the attempt count and the total deadline.)

**Diagnose safely (one rule, capture bounded and sanitized).** Show the user
`friendly.*`, never the raw `message`. Read the raw `message` yourself to work
out the cause. To escalate, give support the `trace_id` (`TRK-…`); if you
attach any log excerpt, **redact it first** — strip API keys (`mb_live_…`),
`Authorization` headers, tokens, database URLs and any connection string that
carries a credential, and any other private data — and keep it to the last ~20
lines, never the whole stream. The same rule holds whether you're logging it or
sharing it.

**The one human-in-the-browser exception (`consent_required`).** moonbase
proposes build changes it won't make under an API key alone. Don't try to
automate it: give the owner the `consent_url`, have them deploy that project
**once** from their browser and approve the changes. After that, your API
deploys to that mission work again. (An API-key deploy already auto-accepts
the ordinary Compatibility Engine fixes — empty-value env var, start script,
port rewrite, Node version, lockfile regeneration — *before* it goes live;
`consent_required` is only the rare case that still needs a person. See
*What moonbase fixes for you* in `building-for-moonbase.md`.)

### When is it actually done? (don't stop at `done`)

A `done` event means the **source is live** — it does not prove the app
*works*. "Infrastructure up" and "usable" are different things; check the real
ones before you tell the user it's ready:

1. **It responds on the route that matters.** Open `done.url` (and the
   specific path the app is meant to serve) and confirm a real `2xx` with the
   expected content — not a server-error or crash page. A dynamic app can
   start and then crash on the first request (a missing dependency, a bad
   import), still after a clean `done`.
2. **Check whether it's protected — don't assume it is.** A mission *can* have
   a password, but don't claim one is private until you've checked: a new
   mission may have no password, leaving the link open to anyone. Request the
   public URL and look at what comes back — moonbase's password gate (a `200`
   that is the gate, not your app) means it's protected, so verify behind it;
   your app's own content rendering straight away means it's open. The status
   endpoint does not report protection, so this request is the check. Tell the
   owner plainly whether the mission is currently password-protected or open,
   and never report a locked gate as a working app.
3. **Set the secrets over the env API — the deploy form can't.** The deploy
   multipart form has **no env field**, and a shipped `.env` supplies only
   non-secret values, so a fresh deploy is *live but unconfigured* until you set
   the real ones. When you can run commands, finish this yourself instead of
   handing it back: `PUT` the mission's secrets (database URL, API keys, auth
   config) to the env API (`GET`/`PUT /api/v1/sites/<slug>/env`, same key and
   scope — see `api-and-ci.md`). The `PUT`'s `set`/`count` receipt is your
   confirmation the write landed; a follow-up `GET` confirms a **new** key's
   name but can't confirm an **overwrite** (values are write-only, so the name
   shows whether the old or new value is stored). Verify a changed value at the
   app level after you redeploy so they apply. Only
   point the owner at **Mission Control → Environment Variables** when you can't
   reach the env API. Distinguish plainly: *source deployed* (done) vs
   *configured and ready* (secrets set, redeployed).
4. **Persistence is wired, if the app needs it.** Confirm data goes to an
   external database or object store (reached directly with its connection
   string — see *Data and storage*), not the container disk that's wiped each
   deploy.
5. **No public default account.** If the app has sign-in, don't leave a
   default/admin login open to the world — enroll the owner privately and
   confirm there's no public default credential.

Report honestly which stage you reached: **first deploy** (new address live),
**update** (new version of an existing mission), **locked** (deployed but
behind a password / missing secrets), or **fully working** (verified on the
real route with config and persistence in place). Also surface
`self_repair_notice` (what moonbase fixed) and a non-empty `skipped_entries`
(which files were left out).

## Step 5. Check a mission's status

```bash
curl -sS "https://app.moonbase.cloud/api/v1/sites/<address>/status" \
  -H "Authorization: Bearer $MOONBASE_API_KEY" \
  -H "User-Agent: my-agent/1.0"
```

Returns `id`, `slug`, `displayName`, `status`, `isPaused`, `isArchived`,
`publicUrl`, `currentVersion`, `lastDeployedAt`, `deployInProgress` and
`deployStartedAt`. To learn how a deploy ended without the stream: check every
few seconds until `deployInProgress` is `false`; if `currentVersion` went up,
the new version is live at `publicUrl`. The reason for a failed build is only
in the stream's `error` event.

A key reads only its own account's missions; any other address answers
`not_found`. There is no endpoint that lists all missions.

## Saying it simply

After a successful deploy, say something like: "Done! Your mission is live
at https://my-idea.moonbase.host. Anyone with this link can open it. Next
time just say 'deploy this to moonbase' and I'll ship a new version to the
same link."

The `.moonbase.host` address is created automatically and is live with HTTPS
the moment the deploy succeeds — don't wait on or set up a domain to go live.
A custom domain is an optional, **later** step, added only after the mission
exists (see `custom-domains.md`). So the order is: deploy → the mission is
immediately live on its `.moonbase.host` address → optionally, later, add a
custom domain.
