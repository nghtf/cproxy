SHELL := /bin/sh

SITE := $(filter-out stub unstub,$(MAKECMDGOALS))

.DEFAULT_GOAL := help

.PHONY: help run stop restart reload logs ps stub unstub

help:
	@printf '%s\n' 'Available targets:'
	@printf '%s\n' '  make run            Start the shared reverse proxy (creates the "proxy" network)'
	@printf '%s\n' '  make reload         Reload Caddyfile without downtime (after editing Caddyfile/sites)'
	@printf '%s\n' '  make restart        Restart the proxy container'
	@printf '%s\n' '  make stop           Stop the proxy'
	@printf '%s\n' '  make logs           Follow proxy logs'
	@printf '%s\n' '  make ps             Show running containers'
	@printf '%s\n' '  make stub <site>    Show "under construction" stub for <site> instead of proxying'
	@printf '%s\n' '  make unstub <site>  Restore normal proxying for <site>'

run:
	docker compose up -d
	@printf '%s\n' 'Proxy is starting on :80 / :443'

stop:
	docker compose down

restart:
	docker compose restart

reload:
	docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile

logs:
	docker compose logs -f caddy

ps:
	docker compose ps

stub:
	@if [ -z "$(SITE)" ]; then echo "Usage: make stub <site>"; exit 1; fi
	@if [ ! -f "sites-available/$(SITE).stub.caddy" ]; then \
		echo "No stub config for '$(SITE)' (sites-available/$(SITE).stub.caddy not found)"; exit 1; \
	fi
	cp "sites-available/$(SITE).stub.caddy" "sites/$(SITE).caddy"
	$(MAKE) reload
	@printf '%s\n' "$(SITE): stub enabled"

unstub:
	@if [ -z "$(SITE)" ]; then echo "Usage: make unstub <site>"; exit 1; fi
	@if [ ! -f "sites-available/$(SITE).proxy.caddy" ]; then \
		echo "No proxy config for '$(SITE)' (sites-available/$(SITE).proxy.caddy not found)"; exit 1; \
	fi
	cp "sites-available/$(SITE).proxy.caddy" "sites/$(SITE).caddy"
	$(MAKE) reload
	@printf '%s\n' "$(SITE): proxy restored"

# Swallow the site name positional arg (e.g. `make stub kpgn`) so make
# doesn't try to find a rule for it.
%:
	@:
