# cproxy

Shared reverse proxy (router) for all site containers.

Caddy listens on `80`/`443`, obtains and renews Let's Encrypt certificates itself (HTTP-01), and proxies requests to the site containers by their Docker service name over the shared `proxy` network.

## Startup

Bring this up **first**, before any site containers — it creates the external `proxy` network that the site stacks connect to.

```bash
make run     # docker compose up -d, brings up the proxy network + caddy on :80/:443
```

Before the first run, make sure the domains' DNS A/AAAA records already point to this VPS's IP — otherwise Let's Encrypt won't be able to issue a certificate (the HTTP-01 challenge must reach this server).

## Adding a new site

1. In the site's `docker-compose.yml`, connect the service to the external `proxy` network — don't publish ports 80/443 to the host, only connect via the network.
2. Add two files under `sites-available/`, based on the templates below:
   - `<site>.proxy.caddy` — the normal working config (`reverse_proxy <container_name>:80`)
   - `<site>.stub.caddy` — a placeholder (see below)
3. Copy the working config to make it active: `cp sites-available/<site>.proxy.caddy sites/<site>.caddy`
4. Reload the config with no downtime: `make reload` (or `make restart`)

`Caddyfile` picks up all files under `sites/*.caddy` automatically (`import sites/*.caddy`) — you normally don't need to touch it.

### Templates

Generic starting points, with `example.com` / `example-site` as placeholders to replace:

- `sites-available/_template.proxy.caddy`
- `sites-available/_template.stub.caddy`

```bash
cp sites-available/_template.proxy.caddy sites-available/<site>.proxy.caddy
cp sites-available/_template.stub.caddy sites-available/<site>.stub.caddy
# then edit both to swap example.com / example-site for the real domain and container name
```

## "Under construction" stub (`make stub` / `make unstub`)

When a domain already points at the server but the site isn't ready yet (or is undergoing maintenance), you can temporarily show a static placeholder page instead of proxying, without tearing down the site stack itself:

```bash
make stub <site>     # shows stub/index.html instead of proxying, for <site>'s domain(s)
make unstub <site>   # restores normal proxying to <site>
```

This just switches `sites/<site>.caddy` between `sites-available/<site>.stub.caddy` and `sites-available/<site>.proxy.caddy` and runs `caddy reload` — no downtime, no container rebuilds. The stub page text is shared across all sites — `stub/index.html`.

## Files

- `docker-compose.yml` — the Caddy service, the `proxy` network, volumes for certificates/state
- `Caddyfile` — `import sites/*.caddy`, contains no domain blocks itself
- `sites/` — active site configs (what's actually connected right now)
- `sites-available/` — available config variants per site: `<site>.proxy.caddy` (production) and `<site>.stub.caddy` (placeholder)
- `stub/index.html` — static "site launching soon" page, shared by all stubs
