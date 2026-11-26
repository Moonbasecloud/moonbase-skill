# Custom domains

Every project is **automatically** live at `<mission>.moonbase.host` with HTTPS
the moment it deploys — that is its shareable address right away, so you never
need a custom domain to go live. A custom domain (like `example.com` or
`app.example.com`) is an **optional, later** step: add it only **after** the
project already exists and is live, and it needs a **paid plan**.

Explain DNS simply: "DNS is the internet's address book. You'll add two lines
to your domain's address book: one that says 'send visitors to moonbase', and
one that proves the domain is yours."

The user needs: a domain they already own, and access to where they bought
it (the "registrar": GoDaddy, Namecheap, Cloudflare, etc.). moonbase
never changes anything at the registrar; the user adds the record.

## Step by step

1. In moonbase, open **Domains** (in the sidebar, or from the project's Mission Control).
2. Click **Add domain**.
3. Type the domain (`example.com` or `app.example.com`) and pick which
   project it should show.
   *moonbase shows the exact DNS records to add. Keep this page open.*
4. In a new tab, sign in to your registrar and open the DNS settings for that
   domain.
5. Add the records exactly as moonbase shows them:
   - **Main domain** (`example.com`, called "apex"): an **A** record.
     - Type: `A`
     - Name: `@` (or leave it blank)
     - Value: the IP address shown on moonbase's Domains page
     - TTL: `300` (or the lowest the registrar allows)
     A main domain can't use a CNAME (that's a DNS rule).
   - **Subdomain** (`www.example.com`, `app.example.com`): a **CNAME** record.
     - Type: `CNAME`
     - Name: `www` (or `app`, etc.)
     - Value: your project's own address shown on the Domains page, like
       `your-mission.moonbase.host` (never a `*.` wildcard: registrars reject
       it)
     - TTL: `300`
   - **Ownership** (every domain): a **TXT** record.
     - Type: `TXT`
     - Name: the name shown on the Domains page (it starts with
       `_moonbase-verify.`)
     - Value: the value shown there (it starts with `moonbase-verification=`)
   Add both: an A or CNAME record alone does not prove the domain is yours.
6. Save the records at the registrar.
7. Back in moonbase, click **Verify**.
   *First the domain waits for DNS until moonbase sees both records. Then
   moonbase gets the HTTPS certificate (from Let's Encrypt), usually within a
   few minutes, and the domain shows as active.*

   An AI connected through the moonbase connector can run the same check with
   the `verify_domain` tool (project plus domain). It returns the domain's
   status, what was found and expected for each DNS record, and the link to
   the Domains page (https://app.moonbase.cloud/domains), which the person can
   open to see the same result. It changes only moonbase's stored status (and
   starts the certificate once both records are in place); it does not change
   DNS.

**Cloudflare users:** set the record to **DNS only (grey cloud)**, not
proxied (orange). The orange proxy blocks moonbase's certificate.

**How long?** Usually under an hour, sometimes up to 48 hours. moonbase checks
from its own server, which may see the change before your computer does. A
tool like dnschecker.org shows progress around the world.

Use the IP address and target that moonbase's Domains page shows. Don't type
one from memory.

## If it won't verify

1. Open the domain on **Domains** and compare the record letter by letter.
2. Both records are there: the TXT record (`_moonbase-verify.`…) and the A record for a main domain or CNAME for a subdomain.
3. Make sure no other old record (another host's A or CNAME) is still there
   for the same name.
4. Cloudflare: grey cloud.
5. Wait a bit, then click **Verify** again (or, over the connector, call
   `verify_domain` again; its `records` list shows which record still differs).

If moonbase says another account added the domain but never proved it owns
it, the domain can still be connected here by proving it is yours: moonbase
shows one TXT record (its name and value). Add it at the DNS provider, wait
for it to be seen, then add the domain again. Over the connector,
`add_domain` refuses with `domain_held_unverified` and gives the same record
and `domain_page`, the exact link to this project's domain section in
moonbase. Open the returned link for the person (or, if this client cannot
open links, give them that exact link), show them the record, and call
`add_domain` again once it is published. A
domain that another account already proved stays theirs.

If moonbase refuses to add the domain because the plan doesn't include
custom domains, it names the cheapest plan that does: upgrade
(`billing.md`), then add the domain again.

## Honest limits

- Wildcard domains (`*.example.com`) aren't supported.
- Traffic is measured per project, not per domain.
- Custom domains are on paid plans only (see `billing.md`).

moonbase may send notifications such as "DNS verification pending", "Domain
connected", "TLS certificate renewed" and "Domain certificate expiring";
certificates renew automatically.

Guides: https://moonbase.cloud/docs/custom-domains and
https://moonbase.cloud/docs/custom-domains-101
