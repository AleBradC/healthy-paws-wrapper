# Healthy Paws — wrapper

Deployment-only repository. Carries the docker compose files, nginx config,
backup script, and `.env.example`. The actual application code lives in two
sibling repositories cloned next to this one:

```
Project/
├─ healthy-paws-wrapper/      ← this repo (compose + nginx + scripts)
├─ healthy-paws-service/      ← backend (Node + Apollo + Postgres) — separate git repo
└─ healty-paws-frontend/      ← frontend (React + Vite) — separate git repo
```

The wrapper does **not** carry the source as submodules. Both source repos
are independent; the wrapper's `docker-compose.yml` references them via
relative paths (`../healthy-paws-service`, `../healty-paws-frontend`).

---

## Local development

```bash
# one-time clone
git clone https://github.com/AleBradC/healthy-paws-wrapper.git
git clone https://github.com/AleBradC/healthy-paws-service.git
git clone https://github.com/AleBradC/healty-paws-frontend.git
# all three live side-by-side in the same parent directory

# create env files (gitignored)
cp healthy-paws-wrapper/.env.example healthy-paws-wrapper/.env
cp healthy-paws-service/.env.example healthy-paws-service/.env
# edit both .env files and fill in real values

# bring the dev stack up
cd healthy-paws-wrapper
docker compose up --build
```

The stack exposes:

| Service  | Port (host) | Purpose                                          |
|----------|-------------|--------------------------------------------------|
| gateway  | `80`        | nginx — entry point; proxies `/api/*` + `/graphql` to backend, everything else to frontend |
| frontend | (internal)  | Vite dev server with HMR                         |
| backend  | (internal)  | Express + Apollo, reachable as `backend:8080`    |
| db       | (internal)  | Postgres 15, reachable as `db:5432`              |

Open `http://localhost` in a browser.

---

## Production

See [`.cursor/plans/simple_aws_deploy_b6a51c00.plan.md`](.cursor/plans/simple_aws_deploy_b6a51c00.plan.md)
for the step-by-step AWS deploy. In short: same architecture but `docker-compose.prod.yml`
swaps the dev `build:` directives for `image: healthy-paws-service:latest`
(built on the EC2 box from the cloned service repo) and drops the `frontend`
service in favor of nginx serving the pre-built `dist/` directly.

---

## Repository layout

- `docker-compose.yml` — dev stack (builds backend + frontend from source, runs nginx + Postgres + migrate)
- `docker-compose.prod.yml` — production stack (added in step `s03` of the simple deploy plan)
- `nginx/nginx.conf` — dev gateway config (proxies frontend on `5173` + backend on `8080`)
- `nginx/nginx.prod.conf` — production gateway (serves `dist/` SPA + 443 SSL with Cloudflare Origin Cert)
- `scripts/backup.sh` — nightly Postgres → S3 backup script
- `.env.example` — required vars for the wrapper itself (DB_USER / DB_PASSWORD / DB_DATABASE — these are used for docker-compose variable substitution and must match `healthy-paws-service/.env`)
- `.cursor/plans/` — deployment plans and operational notes

---

## Updating the deployed app

Backend code change:

```bash
ssh -i healthy-paws-prod.pem ec2-user@<EIP>
cd /opt/healthy-paws-service && git pull
docker build --target production -t healthy-paws-service:latest .
cd /opt/healthy-paws && docker compose -f docker-compose.prod.yml up -d backend
```

Frontend code change:

```bash
# on your laptop
cd healty-paws-frontend
VITE_API_BASE_URL=https://yourdomain.com npm run build
scp -i ../healthy-paws-prod.pem -r dist/* ec2-user@<EIP>:/opt/healthy-paws/nginx/spa/
```

Nginx serves the new files immediately — no reload needed.
