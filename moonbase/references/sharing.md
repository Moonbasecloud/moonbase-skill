# Sharing a project with teammates

You can invite people to a project so they can see it, deploy it, or manage
it. This is about working **on** a project together. (To show the finished
project to anyone, just send them its link; no invite needed.)

Sharing is available on **paid plans**. On a free plan the connector reports: "Sharing is not included in the project owner's current plan."

## The roles

| Role in the menu | Name | What they can do |
|---|---|---|
| **Can view** | View | See everything. Change nothing. |
| **Can edit** | Edit | Deploy, roll back, change settings and environment variables. |
| **Can manage** | Admin | Everything in Edit, plus inviting people (as Can view or Can edit) and re-checking an existing domain (**Verify**). Adding, removing or changing a domain stays with the owner. |
| | Owner | The account the project belongs to. |

Someone with View who tries to deploy gets "forbidden": ask the owner or an
admin for Edit access.

## Invite someone (owner or admin)

1. Open the project and click **Share**.
   *A "Share mission" window opens.*
2. Under **Invite people**, type their **Email address**.
3. Pick their **Access** (Can view / Can edit / Can manage).
4. Click **Invite**.
   *You'll see "Invite sent to <email>."* They appear under **People with
   access** as "Pending".

Managing people, in the same window:
- **Resend** or **Cancel invite** for pending invitations (an expired one
  shows "Expired").
- Change someone's role from the menu next to their name.
- **Remove** someone: they lose access immediately.
- Each plan allows a maximum number of people per project (pending invites
  count too). moonbase says so when it's reached.

## Manage people from an AI agent (connector)

The moonbase connector has the same list and actions as the **Share**
window, with the same rules (owner or admin, paid plan):

| Tool | What it does |
|---|---|
| `list_members` | The people with access and the open invitations: role, Pending or active, and whether this account may change or remove each one (each has a `person_id`). |
| `invite_member` | Asks to invite an address with a `role`: `view`, `edit` or `admin`. Nothing is sent until a person signed in to moonbase confirms it in the app (see below), and nothing is granted until the invited person accepts. |
| `set_member_role` | Changes an accepted person's role (`person_id` from `list_members`). A change that raises access (to `edit` or `admin`) waits for the same confirmation in the app; a change to `view`, or one that lowers access, is made by the call. |
| `remove_member` | Removes someone's access, or cancels a pending invitation. |

- The invite answer is the same whether or not the address already has a
  moonbase account.
- Inviting, changing a role and removing someone are run only after the
  person names the project, the address or person, and the role.
- Inviting someone, and raising someone's access (to Can edit or Can
  manage), can't be finished from chat. The tool answers
  `status: "confirmation_required"` with `confirm_url` and
  `confirm_expires_at`: the project's **Share** window
  with that change shown and waiting. Open that exact link for the person
  (or give it to them). Nothing happens until someone signed in to moonbase
  who may make the change clicks **Confirm invitation** or **Confirm
  access** there, within 30 minutes; after that the link has expired and the
  tool is called again for a new one. Say the change is done only after
  `list_members` shows it.
- Confirm is the person's own decision on moonbase; an agent that presses it
  in the person's browser skips the check this step exists for.
- Accepting is always done by the invited person, from the email, signed in
  with that address. No tool accepts for them.
- Every result includes the project's page with the **Share** window open:
  `https://app.moonbase.cloud/missions/<id>#share`. A person who wants
  to see or change the list themselves opens that link.

## Accept an invite (the invited person)

1. Open the email "<name> invited you to <mission> on moonbase" and click
   **Open invitation**. The link expires after some days; the email says how
   many.
2. If you're signed in with **the same email** the invite was sent to:
   *you'll see "Join <mission>".* Click **Accept invitation**.
3. Not signed in? *You'll see "Sign in to accept".* Click **Sign in**, or
   **Create account** using that same email address.
4. *You'll see "You've joined <mission>".* It's under **Shared with me** on
   your dashboard.

## When accepting doesn't work

| What the page says | What it means → what to do |
|---|---|
| "This invitation is for another address" | You're signed in with a different email. Click **Sign out**, then sign in with the invited email. |
| "Verify your email first" | Verify that address (check the inbox), then come back. |
| "This invitation has expired" | Ask the person who invited you to send it again. |
| "This invitation isn't valid" | It was cancelled, already accepted, or replaced by a newer one. Ask for a new one. |
| "Sharing isn't available for this mission right now" | The project's owner needs a paid plan to share it. |
| "This mission already has the most people it can have" | Ask the inviter to make room, then try again. |

If you weren't expecting an invite, you can ignore it. Nothing changes until
you accept.
