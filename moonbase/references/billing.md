# Plans, upgrading and billing

**Never quote a price or a plan number from memory.** Read them live at
https://moonbase.cloud/pricing (or https://moonbase.cloud/docs/billing-overview)
if you can open web pages, and say that's where they came from. Otherwise send
the user there.

## What's live today

- A free plan and paid plans (today: moonbase free, plus, pro and max), with
  monthly and yearly prices on the pricing page.
- Plans differ in missions, storage, the biggest single upload, and
  features. Visitors are counted, never capped. Custom domains and sharing need a paid plan.
- Payments go through **Paddle**. Billing is self-serve.

## Upgrade, step by step

1. Open **https://app.moonbase.cloud/upgrade** (or **Plans** / **Upgrade**
   in the app).
2. Pick the plan.
3. Pay in the Paddle checkout window.
4. *Access unlocks right after payment.* No waiting on support.

Change plans on **Plans** (https://app.moonbase.cloud/upgrade), cancel with **End your plan** in **Account → Danger Zone**, and update the payment method on **Billing**, any time.

## Billing and usage pages

- **Billing**: your plan and its cost, next billing date, payment method and
  **Invoices**.
- **Usage**: storage, missions and visitors against your plan.

How usage counts:
- **Storage** = the live files of every mission **plus** the earlier versions
  kept in each Mission Log. Versions count toward the limit but only live
  files are billed.
- **Visitors** are counted across all missions together, per calendar month
  (UTC), and reset on the 1st; on a plan with no included number, Usage
  shows the last 30 days. Visitors are counted per day: someone who visits
  on 5 different days counts as 5. They're **never capped**: missions stay
  live past the plan's number. `account_usage` lists the visitor count as a
  plain usage line (`usage_notes`: "Visitors (this calendar month): N.
  Counted for your information; visitors are never blocked."), never among
  the limits reached.

## What happens at a limit

- **Storage:** an upload that would go past the plan's storage is refused,
  and the message says how much room is needed. Free space (delete older
  versions or missions) or move to a bigger plan. On the largest plan, live
  files past the allowance are billed at the overage rate shown on the
  pricing page instead.
- **Missions:** **New mission** is disabled until a mission is deleted or the
  plan is upgraded. Shipping a new version of an existing mission still works.
- **One upload's size:** each plan has a per-upload limit, separate from
  total storage, and nothing over 1 GB on any plan. moonbase's message says
  the exact number.

## Refunds

Refunds are available within a set number of days of a charge (the pricing
docs say how many); contact support to ask. Full policy:
https://moonbase.cloud/terms

If a payment fails, moonbase notifies the user: check the payment method in
**Billing**.
