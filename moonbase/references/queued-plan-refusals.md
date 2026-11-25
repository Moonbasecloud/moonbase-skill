# Queued deploy plan refusals

A queued deploy can be refused by a plan limit after the first tool call returns.
`deploy_status` with its `attempt_id`, or the project's slug, returns the failed
receipt. When that attempt recorded enough plan-limit context and the current effective
limit and measurements still match the refusal, the receipt also
includes `next_tool`, `upgrade_url`, and any `deep_link` or `human_action`, using
the same plan guidance as a synchronous refusal.

The refusal stays attached to that attempt. Its recorded measurements describe
that attempt; the plan names, availability and links in the guidance are checked
against the owner's current account information when the receipt is read. The
guidance does not retry the deploy or change the plan. The person opens any
purchase link while signed in and chooses there; the connector cannot buy it.

Older receipts without the required context, changed or unmeasured limits and
usage, persistent overrides on the refused limit, unavailable plan data, or a
receipt whose plan guidance cannot be read, keep their original response. Missing historical measurements
are not reported as zero. A running, successful or uncertain attempt does not
receive plan-refusal guidance.
