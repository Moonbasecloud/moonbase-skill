# Custom domains

Every mission already has its own address, `<mission>.moonbase.host`, with
HTTPS. A custom domain (like `example.com` or `app.example.com`) is optional
and needs a **paid plan**.

Explain DNS simply: "DNS is the internet's address book. You'll add one line
to your domain's address book that says 'send visitors to moonbase'."

The user needs: a domain they already own, and access to where they bought
it (the "registrar": GoDaddy, Namecheap, Cloudflare, etc.). moonbase
never changes anything at the registrar; the user adds the record.

## Step by step

1. In moonbase, open **Domains** (in the sidebar, or from the mission's Mission Control).
2. Click **Add domain**.
3. Type the domain (`example.com` or `app.example.com`) and pick which
   mission it should show.
   *moonbase shows the exact DNS record to add. Keep this page open.*
4. In a new tab, sign in to your registrar and open the DNS settings for that
   domain.
5. Add the record exactly as moonbase shows it:
   - **Main domain** (`example.com`, called "apex"): an **A** record.
     - Type: `A`
     - Name: `@` (or leave it blank)
     - Value: the IP address shown on moonbase's Domains page
     - TTL: `300` (or the lowest the registrar allows)
     A main domain can't use a CNAME (that's a DNS rule).
   - **Subdomain** (`www.example.com`, `app.example.com`): a **CNAME** record.
     - Type: `CNAME`
     - Name: `www` (or `app`, etc.)
     - Value: your mission's own address shown on the Domains page, like
       `your-mission.moonbase.host` (never a `*.` wildcard: registrars reject
       it)
     - TTL: `300`
6. Save the record at the registrar.
7. Back in moonbase, click **Verify**.
   *First the domain waits for DNS until moonbase sees your record. Then
   moonbase gets the HTTPS certificate (from Let's Encrypt), usually within a
   few minutes, and the domain shows as active.*

**Cloudflare users:** set the record to **DNS only (grey cloud)**, not
proxied (orange). The orange proxy blocks moonbase's certificate.

**How long?** Usually under an hour, sometimes up to 48 hours. moonbase checks
from its own server, which may see the change before your computer does. A
tool like dnschecker.org shows progress around the world.

Use the IP address and target that moonbase's Domains page shows. Don't type
one from memory.

## If it won't verify

1. Open the domain on **Domains** and compare the record letter by letter.
2. A record for a main domain, CNAME for a subdomain.
3. Make sure no other old record (another host's A or CNAME) is still there
   for the same name.
4. Cloudflare: grey cloud.
5. Wait a bit, then click **Verify** again.

If moonbase refuses to add the domain because the plan doesn't include
custom domains, it names the cheapest plan that does: upgrade
(`billing.md`), then add the domain again.

## Honest limits

- Wildcard domains (`*.example.com`) aren't supported.
- Traffic is measured per mission, not per domain.
- Custom domains are on paid plans only (see `billing.md`).

moonbase may send notifications such as "DNS verification pending", "Domain
connected", "TLS certificate renewed" and "Domain certificate expiring";
certificates renew automatically.

Guides: https://moonbase.cloud/docs/custom-domains and
https://moonbase.cloud/docs/custom-domains-101
