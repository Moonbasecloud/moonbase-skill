# Queued deploy plan refusals

A queued deploy can be refused by a plan limit after the first tool call returns.
`deploy_status` with its `attempt_id`, or the project's slug, returns the failed
receipt. A queued deployment blocked by an account limit reports the affected limit and relevant usage.
When that attempt recorded enough plan-limit context and the current effective
limit and measurements still match the refusal, the receipt carries the same
neutral fields as a synchronous refusal (`limit_reached`, `next_step`,
`next_tool`: `account_usage`, and `current_usage` and `limit` when known),
checked against the owner's current account information when the receipt is
read. The guidance does not retry the deploy or change the plan.

Older receipts without the required context, changed or unmeasured limits and
usage, persistent overrides on the refused limit, unavailable plan data, or a
receipt whose plan guidance cannot be read, keep their original response. Missing historical measurements
are not reported as zero. A running, successful or uncertain attempt does not
receive plan-refusal guidance.
