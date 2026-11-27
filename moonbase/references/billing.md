# Plans and billing

Never quote a price or a plan allowance from memory. account_usage reports current account usage and limits.

Account usage shows your current entitlements.

## When the person asks about plans

- A free plan and paid plans (today: moonbase free, plus, pro and max), with
  monthly and yearly prices on the pricing page.
- Plans differ in projects, storage and features; the size of one upload is currently the same on every plan. Visitors are counted, never capped. Custom domains and sharing need a paid plan.
- Payments go through **Paddle**. Billing is self-serve.

## When the person asks to change their plan

Plan selection and payment take place in the signed-in moonbase website. The connector does not purchase or change a subscription.

`upgrade_link` returns a plan-selection link for a person who has asked about changing their plan, with the plan, its price, billing interval and what it includes. Cancelling is **End your plan** in **Account → Danger Zone**, and the payment method is updated on **Billing**.

## Billing and usage pages

- **Billing**: your plan and its cost, next billing date, payment method and
  **Invoices**.
- **Usage**: storage, projects and visitors against your plan.

How usage counts:
- **Storage**: files, versions and databases count toward one storage
  allowance. That is the live files of every
  project, the earlier versions kept in each Mission Log and a project's managed
  database. `account_usage` shows the parts where each is
  measured; a part it reports as not measured is not zero. Versions count
  toward the limit but only live files are billed.
- **Visitors** are counted across all projects together, per calendar month
  (UTC), and reset on the 1st; on a plan with no included number, Usage
  shows the last 30 days. Visitors are counted per day: someone who visits
  on 5 different days counts as 5. They're **never capped**: projects stay
  live past the plan's number. `account_usage` lists the visitor count as a
  plain usage line (`usage_notes`: "Visitors (this calendar month): N.
  Counted for your information; visitors are never blocked."), never among
  the limits reached.
- **What `account_usage` shows is the account, not only the plan.** Each
  limit line is what this account has today. An account can have its own
  number of projects, apart from its plan's standard number; the Missions
  line then says so and names what the plan includes by itself. Say the plan
  by its name (the `plan` field). The plan id beside it is moonbase's own
  identifier and means nothing to the person. The storage number given in
  bytes is the same amount as the Storage line shows as used.

## What happens at a limit

- **Storage:** an upload that would exceed the account's storage allowance is refused. account_usage reports current storage usage and limits. Deleting stored content is permanent and requires the person's decision.
- **Missions:** **New mission** is disabled while the project limit is reached. Shipping a new version of an existing project still works.
- **One upload's size:** one ZIP can be up to the per-deploy size, which is currently the same on every plan, so upgrading does not raise it; storage is what differs. The limit applies to the ZIP you upload, and your plan's storage also applies to the unpacked total. `account_usage` shows the live per-deploy size.

## Refunds

Refunds are available within a set number of days of a charge (the pricing
docs say how many); contact support to ask. Full policy:
https://moonbase.cloud/terms

If a payment fails, moonbase notifies the user: check the payment method in
**Billing**.
