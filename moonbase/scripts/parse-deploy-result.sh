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
