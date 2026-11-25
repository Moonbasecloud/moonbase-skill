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
