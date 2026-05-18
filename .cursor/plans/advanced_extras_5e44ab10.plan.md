---
name: Advanced extras (learning track)
overview: "Inventory of every production-grade extra discussed across the previous deployment plans and chat sessions — CI/CD, tests, security hardening, observability, performance layers, backup/DR, and infrastructure alternatives. The companion `simple_aws_deploy_*.plan.md` covers the minimum to ship the uni project; this plan is a reading list of what real teams add on top. Pick whichever topic you want to learn first; the items are not in execution order."
todos:
  - id: x01-backend-gha
    content: "CI/CD: backend GitHub Actions pipeline (lint + test + docker buildx push to GHCR + optional SSM rollout)"
    status: pending
  - id: x02-frontend-deploy-automation
    content: "CI/CD: automate frontend deploy (either Cloudflare Pages auto-build OR a GHA workflow with `aws s3 sync` + CloudFront invalidation)"
    status: pending
  - id: x03-pr-checks
    content: "CI/CD: PR-check workflows in both repos (lint + tests, required status check before merge)"
    status: pending
  - id: x04-codeql
    content: "Security tooling: github/codeql-action workflow in both repos"
    status: pending
  - id: x05-trivy
    content: "Security tooling: Trivy image scan in the backend pipeline, fail on HIGH+ unfixed CVEs"
    status: pending
  - id: x06-dependency-review
    content: "Security tooling: actions/dependency-review-action on PRs in both repos"
    status: pending
  - id: x07-renovate
    content: "Dependency hygiene: renovate.json replacing Dependabot, grouped patch auto-merge"
    status: pending
  - id: x08-husky-lint-staged-commitlint
    content: "Local hygiene: Husky + lint-staged + commitlint in both repos"
    status: pending
  - id: x09-check-env
    content: "Reliability: scripts/check-env.ts that fails fast on missing required env vars at start"
    status: pending
  - id: x10-pin-node-engines
    content: "Reliability: pin engines.node in both package.json files and align CI matrix + Dockerfile base"
    status: pending
  - id: x11-backend-integration-tests
    content: "Tests: integration tests for /verify-email, /resend-verification, login 403 EMAIL_NOT_VERIFIED + audit write"
    status: pending
  - id: x12-frontend-f16-tests
    content: "Tests: VerifyEmailPage + LoginPage 403/resend CTA tests"
    status: pending
  - id: x13-k6-baseline
    content: "Tests: k6 baseline scenarios (login, doctors list, appointment create) under loadtest/"
    status: pending
  - id: x14-lighthouse-ci
    content: "Tests: Lighthouse CI against PR preview URLs (perf 80, a11y 90, SEO 90 budgets)"
    status: pending
  - id: x15-jwt-revocation
    content: "Security: JWT revocation via Users.token_version (migration, sign-with-tv, strategy check, bump on password reset)"
    status: pending
  - id: x16-audit-retention
    content: "Security/ops: daily retention job deleting AuditEvents older than 365 days"
    status: pending
  - id: x17-csp-tighten
    content: "Security: tighten CSP in wrapper/nginx.conf (real img-src + constrained connect-src)"
    status: pending
  - id: x18-ssh-lockdown
    content: "Security: move SSH off the public internet (Cloudflare Tunnel OR AWS SSM Session Manager)"
    status: pending
  - id: x19-fail2ban
    content: "Security: install fail2ban (SSH jail after 3 failed attempts)"
    status: pending
  - id: x20-budgets-tiered
    content: "Cost control: tiered AWS Budgets alarms at 50/80/100/120% of expected spend"
    status: pending
  - id: x21-sentry-projects
    content: "Observability: Sentry dev + prod projects, paste SENTRY_DSN into EC2 .env and VITE_SENTRY_DSN into frontend build env"
    status: pending
  - id: x22-sentry-sourcemaps
    content: "Observability: source-map upload via @sentry/vite-plugin (SENTRY_AUTH_TOKEN in the build env)"
    status: pending
  - id: x23-sentry-traces
    content: "Observability: bump SENTRY_TRACES_SAMPLE_RATE to 0.1 in prod after error volume validated"
    status: pending
  - id: x24-cloudwatch-agent
    content: "Observability: install CloudWatch agent on EC2, ship docker json-file logs to /healthy-paws/prod log group (30d retention)"
    status: pending
  - id: x25-lru-specializations
    content: "Performance: lru-cache wrapper around doctorsService.getAllSpecializations() (5-min TTL)"
    status: pending
  - id: x26-cf-edge-cache
    content: "Performance: Cloudflare Cache Rule on api.yourdomain.com honoring `Cache-Control: public, s-maxage` on whitelisted endpoints"
    status: pending
  - id: x27-apollo-response-cache
    content: "Performance: @apollo/server-plugin-response-cache with @cacheControl directives on public fields"
    status: pending
  - id: x28-redis-when-triggered
    content: "Performance: adopt Redis (Upstash free OR co-located container) when a documented trigger fires"
    status: pending
  - id: x29-backups-cron
    content: "Backup/DR: nightly Postgres pg_dump to a backups S3 bucket via scripts/backup.sh + crontab"
    status: pending
  - id: x30-backups-lifecycle
    content: "Backup/DR: S3 lifecycle (transition to Glacier Deep Archive at 30d, delete at 365d)"
    status: pending
  - id: x31-restore-drill
    content: "Backup/DR: one restore drill — pull latest backup into a scratch DB, confirm row counts"
    status: pending
  - id: x32-cloudflare-pages
    content: "Infra alternative: Cloudflare Pages for the SPA instead of nginx-on-EC2 (auto-deploys, preview deploys, edge cache)"
    status: pending
  - id: x33-cloudfront-avatars
    content: "Infra alternative: CloudFront + OAC in front of the avatars bucket (cdn.yourdomain.com, ACM cert in us-east-1)"
    status: pending
  - id: x34-ses
    content: "Infra alternative: swap Resend for SES via @aws-sdk/client-sesv2 (62k/mo free from EC2, requires DKIM/SPF + sandbox-exit ticket)"
    status: pending
  - id: x35-rds
    content: "Infra alternative: managed Postgres on RDS instead of in-compose (automated backups + PITR, ~$13/mo after free tier)"
    status: pending
  - id: x36-fargate-or-apprunner
    content: "Infra alternative: ECS Fargate or App Runner instead of EC2+compose (auto-scaling, no SSH, no free tier)"
    status: pending
  - id: x37-oracle-cloud-arm
    content: "Infra alternative: Oracle Cloud Free Tier Ampere ARM VM (24 GB RAM, always free, no 12-month cliff)"
    status: pending
  - id: x38-route53-vs-cloudflare
    content: "Infra alternative: Route 53 hosted zone instead of Cloudflare DNS ($0.50/mo vs free)"
    status: pending
  - id: x39-lets-encrypt
    content: "Infra alternative: Let's Encrypt via certbot instead of Cloudflare Origin Certificate"
    status: pending
  - id: x40-submodule-keep-or-subtree
    content: "Repo layout alternative: keep submodules with documented bump step, OR convert to git subtrees"
    status: pending
  - id: x41-trust-proxy
    content: "Polish: set TRUST_PROXY=2 (already in the simple plan's .env); revisit if you change the proxy chain"
    status: pending
  - id: x42-prod-env-vars
    content: "Polish: NODE_ENV=production + ALLOWED_ORIGINS=https://yourdomain.com (already in the simple plan's .env)"
    status: pending
isProject: false
---

# Advanced extras (learning track)

The companion plan [simple_aws_deploy_b6a51c00.plan.md](healthy-paws-wrapper/.cursor/plans/simple_aws_deploy_b6a51c00.plan.md) gets the uni project online in a day with a single EC2 + S3 + a domain. This plan inventories every "real team would add this" extra raised across the previous deployment plans and our chat sessions — grouped by intent, with one short paragraph per item answering:

1. **What** — the concrete change
2. **Why** — what failure mode or pain a real team avoids
3. **Where** — concrete files / services in this repo to touch

Items are deliberately not in execution order. Pick what interests you and learn each in isolation.

---

## A. CI/CD (continuous integration & deploy)

The simple plan has you running `git pull && docker build && compose up -d` by hand on the box. Real teams automate this so a `git push` to `main` becomes a deploy.

### A1. Backend GitHub Actions pipeline — `x01`

**What:** New file [.github/workflows/backend.yml](healthy-paws-service/.github/workflows/backend.yml). On push to `main`: lint + `npm test` + `docker buildx build --target production --push` to GHCR tagged `:sha-<short>` and `:latest`. Optionally `aws ssm send-command` to the EC2 box: `docker compose pull && up -d`.

**Why:** Removes the "I forgot to push the image" failure mode. Tagging by commit SHA gives second-level rollback (`docker pull ghcr.io/.../healthy-paws-service:sha-abc1234 && docker compose up -d backend`).

**Where:** Use OIDC auth to AWS via `aws-actions/configure-aws-credentials` so you never store an AWS key in GitHub.

### A2. Frontend deploy automation — `x02`

Two options:

- **Cloudflare Pages.** Dashboard -> Pages -> Connect to Git -> pick the frontend repo -> build command `npm run build`, output `dist`, set `VITE_API_BASE_URL` as a build env var, attach your custom domain. Auto-deploys every push to `main` with preview deploys per PR. Free, unlimited bandwidth.
- **GHA workflow.** `.github/workflows/frontend-deploy.yml`: tests + `npm run build` + `aws s3 sync s3://bucket --delete` (long TTL on hashed assets, short on `index.html`) + `aws cloudfront create-invalidation /index.html`. Requires an S3 SPA bucket + CloudFront distribution (see G2).

**Why:** Removes the "build locally + scp dist" step. Cloudflare Pages is the lower-effort path; the S3+CloudFront path stays inside AWS for learning purposes.

### A3. PR checks — `x03`

**What:** `.github/workflows/pr-check.yml` in both repos: on `pull_request`, run lint + `npm test`. Repo Settings -> Branches -> require the check before merge.

**Why:** Catches broken code before it reaches `main`.

### A4. CodeQL static analysis — `x04`

**What:** Drop in `github/codeql-action` via [.github/workflows/codeql.yml](healthy-paws-service/.github/workflows/codeql.yml). Free static analysis for OSS vulnerabilities in JS/TS.

**Why:** Catches SQL injection / XSS / prototype-pollution patterns at PR time.

### A5. Trivy image scan — `x05`

**What:** In the backend image build pipeline: `trivy image --severity HIGH,CRITICAL --exit-code 1 ghcr.io/.../healthy-paws-service:sha-X`. Fail the build on unfixed HIGH/CRITICAL CVEs.

**Why:** Prevents shipping a container based on a Node base image with a known RCE.

### A6. dependency-review-action — `x06`

**What:** `actions/dependency-review-action` on the PR workflow. Blocks PRs that pull in a dependency with a known vulnerability.

**Why:** First line of defense against supply-chain attacks.

### A7. Renovate — `x07`

**What:** `renovate.json` in both repos replacing Dependabot. Groups patch updates into one PR per week, auto-merges if CI passes, runs `npm install` after dep bumps.

**Why:** Dependabot opens 30 PRs a week and you ignore all of them. Renovate's grouped patch PRs actually get reviewed.

### A8. Husky + lint-staged + commitlint — `x08`

**What:** Pre-commit: `eslint --fix` + `prettier --write` on staged files. Commit-msg: enforce Conventional Commits (`feat:`, `fix:`, `chore:`).

**Why:** Stops malformed commits and style-bikeshedding PR comments.

### A9. check-env script — `x09`

**What:** `healthy-paws-service/scripts/check-env.ts` run at `npm start`, exits non-zero if any required env var is missing.

**Why:** Without it, the backend starts, accepts requests, and silently fails on the first DB query because `DB_PASSWORD` was misspelled in `.env`. Loud-fail at startup is much better.

### A10. Pin Node engines — `x10`

**What:** Add `"engines": { "node": ">=20.11 <23" }` to [healthy-paws-service/package.json](healthy-paws-service/package.json) and [healty-paws-frontend/package.json](healty-paws-frontend/package.json). Align the CI matrix and the Dockerfile base image.

**Why:** Prevents the "works on my Node 22 but fails on prod Node 20" class of bugs.

---

## B. Testing

### B1. Backend integration tests for the F-16 auth flow — `x11`

**What:** Test files mirroring [src/test/integration/reset-enumeration.test.ts](healthy-paws-service/src/test/integration/reset-enumeration.test.ts) for the three new auth endpoints:

- `POST /api/auth/verify-email` — happy path, replay (same token used twice -> 410), expired token -> 410, rate-limit 429.
- `POST /api/auth/resend-verification` — enumeration parity (unknown email + already-verified email return identical JSON).
- `POST /api/auth/login` — 403 `EMAIL_NOT_VERIFIED` for valid creds against an unverified account, with audit row written.

**Why:** F-16 has many subtle states. Without tests, the next refactor silently regresses one of them.

### B2. Frontend tests for F-16 UI — `x12`

**What:** `VerifyEmailPage.test.tsx` (verifying spinner, success state, resend fallback on error) + extend `LoginPage.test.tsx` for the 403 branch + "resend verification" CTA click.

**Why:** Same as B1 but at the UI layer.

### B3. k6 baseline load tests — `x13`

**What:** `healthy-paws-service/loadtest/` with `k6` scripts for login, doctors list, appointment create. Run on releases against a staging environment.

**Why:** Catches "the new query I added is O(N²) on the doctors table" before it hits prod.

### B4. Lighthouse CI — `x14`

**What:** GHA workflow that runs Lighthouse against each PR's preview deploy URL. Gate on perf 80, accessibility 90, SEO 90.

**Why:** Prevents perf regressions like a forgotten uncompressed image.

---

## C. Security

### C1. JWT revocation via `Users.token_version` — `x15`

**What:** Add `token_version INT NOT NULL DEFAULT 0` to `Users`. Include `tv` in the JWT payload at sign time in [src/features/authentication/authentication.service.ts](healthy-paws-service/src/features/authentication/authentication.service.ts). The JWT strategy in [src/core/middleware/passport-config.ts](healthy-paws-service/src/core/middleware/passport-config.ts) loads the user and rejects when `payload.tv !== user.token_version`. Bump `token_version` on: password reset completion, explicit "log out everywhere" mutation, email verification (optional). Audit each bump.

**Why:** Logout currently clears the cookie on the current browser only — a stolen JWT remains valid until natural expiry. Token version invalidates all outstanding JWTs for a user in a single bump.

**Cost:** One extra `SELECT token_version` per authenticated request. Cache with a 30-second in-process LRU keyed by user id if it gets hot.

### C2. Audit log retention — `x16`

**What:** Daily job deleting `audit_events` older than 365 days. Either a SQL function + `node-pg-migrate`-managed `pg_cron` rule, or a tiny cron-style runner that hits Postgres nightly.

**Why:** Without retention, [audit_events](healthy-paws-service/migrations/0002_audit_events.cjs) grows forever and eventually the t3.micro's 8 GiB disk fills.

### C3. Tighten CSP — `x17`

**What:** In [healthy-paws-wrapper/nginx/nginx.conf](healthy-paws-wrapper/nginx/nginx.conf): `img-src` adds the real avatar host (`https://*.s3.amazonaws.com` or `https://cdn.yourdomain.com`), `connect-src` constrained to `https://yourdomain.com` only, `script-src 'self'` (drop unsafe-inline).

**Why:** Without a CSP, an injected `<script>` from any user-controllable input can call any URL or load any image. CSP turns that into a CSP violation report instead of a working XSS.

### C4. SSH lockdown — `x18`

**What:** Move SSH off the public internet. Two options:

- **Cloudflare Tunnel:** install `cloudflared` on the box, no public port 22 at all, SSH through the tunnel.
- **AWS SSM Session Manager:** delete the SSH inbound rule, shell into the box via `aws ssm start-session --target i-...`. IAM controls who can connect; no SSH key to lose.

**Why:** SSH bruteforce attempts on a public port 22 are the #1 source of EC2 compromise.

### C5. fail2ban — `x19`

**What:** Install fail2ban on the box, jail SSH after 3 failed attempts.

**Why:** Insurance if SSH stays public.

### C6. Tiered Budgets alarms — `x20`

**What:** AWS Budgets at 50% / 80% / 100% / 120% of expected monthly spend (the simple plan has only $5 at 100%).

**Why:** Catches a runaway container loop putting 100 GB/day into CloudWatch logs before the credit card bill arrives.

---

## D. Observability

### D1. Sentry projects + DSNs — `x21`

**What:** Two Sentry projects (backend Node + frontend React). Paste `SENTRY_DSN` into the EC2 `.env`, `VITE_SENTRY_DSN` into the frontend build env.

**Why:** Production errors are otherwise invisible until a user complains.

### D2. Sentry source-map upload — `x22`

**What:** `@sentry/vite-plugin` in [vite.config.ts](healty-paws-frontend/vite.config.ts), with `SENTRY_AUTH_TOKEN` + `SENTRY_ORG` + `SENTRY_PROJECT` as build-time env vars (in your build environment — laptop, Cloudflare Pages, or GHA).

**Why:** Without source maps, Sentry traces show `(t.j.a) main.js:1` instead of `OwnerProfile.tsx:42`.

### D3. Sentry performance sampling — `x23`

**What:** Bump `SENTRY_TRACES_SAMPLE_RATE` from `0` to `0.1` (10% of requests) after error volume is sane.

**Why:** Free Sentry performance traces find slow endpoints before users notice.

### D4. CloudWatch agent — `x24`

**What:** Install `amazon-cloudwatch-agent` on the EC2 box, ship `docker logs` (the `json-file` driver writes under `/var/lib/docker/containers/*/*.log`) to a CloudWatch log group `/healthy-paws/prod`, retention 30 days.

**Why:** When the container restarts, the logs are gone. CloudWatch keeps them searchable.

**Cost:** First 5 GB of ingestion / month is free; a quiet uni project stays well under.

---

## E. Performance

Apply only in this order — measure before adding the next.

### E1. In-process LRU for hot reads — `x25`

**What:** Wrap `doctorsService.getAllSpecializations()` in [src/features/doctors/doctors.service.ts](healthy-paws-service/src/features/doctors/doctors.service.ts) with `lru-cache`, 5-min TTL.

**Why:** Specializations rarely change. The cache kills ~95% of those reads. Zero infra.

### E2. Cloudflare edge cache rule — `x26`

**What:** Cloudflare -> Cache -> Cache Rules -> match `api.yourdomain.com/*`, honor origin Cache-Control. Set `Cache-Control: public, s-maxage=300` from the backend on `GET /api/openapi.json` and any other genuinely public endpoints.

**Why:** Cloudflare's edge serves the cached response in <5 ms from the user's nearest POP. Free.

### E3. Apollo response-cache plugin — `x27`

**What:** `@apollo/server-plugin-response-cache` with an in-process LRU backend. Annotate cacheable fields with `@cacheControl(maxAge: N)`.

**Why:** GraphQL query-level caching. Only worth adding after measuring that the same queries repeat often.

### E4. Redis — `x28`

**What:** Redis (Upstash free tier OR a co-located container).

**Why:** Only when a documented trigger fires:

- Scale to multiple backend instances (shared session storage)
- JWT denylist instead of token_version
- Postgres CPU > 60% sustained (Postgres becomes the bottleneck)
- Real-time features (notifications, presence)

Don't add Redis pre-emptively.

---

## F. Backup & disaster recovery

### F1. Nightly Postgres backups — `x29`

**What:** A second S3 bucket `healthy-paws-backups` (full Block Public Access). Crontab on the box: `0 3 * * * /opt/healthy-paws/scripts/backup.sh >> /var/log/healthy-paws-backup.log 2>&1`, using the existing [scripts/backup.sh](healthy-paws-wrapper/scripts/backup.sh) — `pg_dump` then `aws s3 cp` into the bucket.

**Why:** Without it, you lose all data if the EC2 is terminated. With it, RPO is 24 hours.

### F2. Lifecycle to Glacier Deep Archive — `x30`

**What:** Backups bucket -> Lifecycle: transition to Glacier Deep Archive at 30 days, delete at 365 days.

**Why:** Cheap long-term retention ($0.00099/GB-month in Glacier DA).

### F3. Restore drill — `x31`

**What:** Once after setting up backups, manually pull yesterday's backup and restore it into a scratch Postgres container. Confirm row counts match the prod DB.

**Why:** Untested backups aren't backups. You only know they work after you've restored at least once.

---

## G. Infrastructure alternatives (for learning what else exists)

### G1. Cloudflare Pages for the SPA — `x32`

**What:** Point Cloudflare Pages at the frontend repo. Pages runs `npm run build` and deploys to its global edge automatically on every push to `main`. Free, unlimited bandwidth, preview deploys per PR.

**Why a real team picks this over nginx-on-EC2:** Removes the build-then-scp step. Removes static-file serving load from the single VM. Edge-cached globally. Preview URLs per PR for stakeholder review.

**Why a uni learner might pick nginx-on-EC2 anyway:** Learning what nginx does + how SPAs are deployed traditionally is more valuable than learning Cloudflare's UI.

### G2. CloudFront in front of the avatars bucket — `x33`

**What:** CloudFront distribution with OAC (Origin Access Control) pointed at the S3 bucket. Custom domain `cdn.yourdomain.com` with an ACM cert in `us-east-1`.

**Why a real team adds this:** Lower latency for image fetches (cached at AWS edge), allows fully-private S3 (CloudFront is the only thing with read access), supports signed URLs for time-limited access, custom cache headers.

**Why the simple plan skips it:** Three extra resources to manage. For single-digit users, direct S3 is fine.

### G3. SES for transactional email — `x34`

**What:** Swap nodemailer to `@aws-sdk/client-sesv2`. Verify your domain in SES (DKIM + SPF + MAIL FROM records published in Cloudflare DNS). Apply for SES production access (24-48h support ticket).

**Why a real team picks this over Resend:** 62k emails/month free from EC2 vs Resend's 3k. Slightly cheaper at scale. Stays in AWS.

**Why the simple plan picks Resend:** Resend works on day-1 with zero DNS work. SES requires DKIM records + a sandbox-exit ticket. For a uni project the volume difference doesn't matter.

### G4. RDS for the database — `x35`

**What:** Replace Postgres-in-compose with AWS RDS Postgres.

**Why a real team picks RDS:** Automated backups + point-in-time recovery, automated minor-version patches, easy upgrades, read replicas, no DB-on-the-app-server contention.

**Why the simple plan skips it:** RDS free tier is 12 months only; after that the smallest db.t4g.micro is ~$13/mo. Postgres-in-compose costs $0.

### G5. ECS Fargate or App Runner for the backend — `x36`

**What:** Replace EC2+docker-compose with serverless container hosting.

**Why a real team picks Fargate/App Runner:** No SSH. Auto-scaling. Zero-downtime deploys built in. No OS patching.

**Why the simple plan skips it:** Costs money from day 1 (no free tier). The "learn what an EC2 actually is" value is high for a beginner.

### G6. Oracle Cloud Free Tier ARM VM — `x37`

**What:** Sign up for Oracle Cloud Free Tier. Provision an `Ampere A1` ARM VM with up to 24 GB RAM. Always free, no 12-month cliff.

**Why a learner might pick this over the AWS free tier:** Year-2 cost drops from ~$8/mo to $0. The VM is dramatically more powerful (24 GB vs 1 GB RAM). Trade-off: one new account; ARM-only images (use `node:20-alpine` which is multi-arch — works as-is).

### G7. Route 53 instead of Cloudflare DNS — `x38`

**What:** AWS Route 53 hosted zone + records.

**Why a real team might pick R53:** Stay fully in AWS. Tight integration with ALB / CloudFront / ACM. Programmable via the AWS SDK and CloudFormation.

**Why the simple plan picks Cloudflare:** R53 is $0.50/month per zone. Cloudflare DNS is $0 and includes WAF + CDN + Universal SSL free.

### G8. Let's Encrypt via certbot instead of Cloudflare Origin Certificate — `x39`

**What:** Install certbot on the EC2 box, request a Let's Encrypt cert for `yourdomain.com`, automate renewal via cron.

**Why a real team might pick LE:** Works without Cloudflare. Cert is publicly trusted (works even with Cloudflare turned off).

**Why the simple plan picks Cloudflare Origin Cert:** 15-year validity = zero renewal automation. Pairs naturally with the Cloudflare proxy. One less moving part.

---

## H. Repo layout — the longer version of A1 in the simple plan

The wrapper currently carries the backend and frontend as git submodules, but real edits land in the standalone repos at the workspace root. Three options:

### H1. Drop submodules — `(done in simple plan s01)`

Wrapper carries only `docker-compose*.yml`, `nginx/`, `scripts/`, `.env.example`. Backend built on the box from a separately-cloned `healthy-paws-service` checkout. Frontend `dist/` scp'd.

**Pros:** simplest. **Cons:** no single-clone "everything together" story.

### H2. Keep submodules with a bump step — `x40`

Every PR that bumps the backend code also bumps the submodule pointer in the wrapper.

**Pros:** single-clone story; deploys are deterministic from one commit. **Cons:** one extra step per PR, easy to forget. Mitigation: pre-push hook + CI check.

### H3. Convert to git subtrees — `x40`

Wrapper actually contains the source via `git subtree`.

**Pros:** single repo, no pointer bumps. **Cons:** harder cross-repo workflow; rare in 2026.

For a uni project: H1 (already in the simple plan). For a real team that wants reproducible "deploy from this exact commit": H2 with strict enforcement.

---

## I. Items already in the simple plan's .env (informational)

These were originally planned as separate todos, but the simple plan's `.env` template already sets them. Listed here so you know what they do:

### I1. `TRUST_PROXY=2` — `x41`

Tells Express to trust the `X-Forwarded-For` chain Cloudflare -> nginx -> backend. Without this, rate-limiting + audit logging see every request as coming from `nginx`'s container IP. Revisit if you change the proxy chain (e.g. add CloudFront in front).

### I2. `NODE_ENV=production` + `ALLOWED_ORIGINS` — `x42`

`NODE_ENV=production` turns on Express's production optimizations + disables stack traces in error responses. `ALLOWED_ORIGINS` lists the origins permitted to call the API; the backend sets the CORS header from this list.

---

## J. Suggested "value for learning effort" ranking

If you have time to pick only a few extras after shipping the simple plan, in rough order of "most magic per hour of work":

1. **C1 JWT revocation (`x15`)** — most directly teaches authn internals.
2. **A1 Backend GHA pipeline (`x01`)** — first time you see "git push deploys to prod" is magic.
3. **D1 + D2 Sentry + source maps (`x21`, `x22`)** — first time you see a production crash in a UI is also magic.
4. **B1 + B2 Tests for F-16 (`x11`, `x12`)** — required if you ever touch the auth code again.
5. **F1 + F3 Backups + restore drill (`x29`, `x31`)** — important even for a uni project; data loss feels real.
6. **E1 LRU cache (`x25`)** — easy win, teaches caching mentally.
7. **G6 Oracle Cloud ARM (`x37`)** — if you want $0/yr forever after the domain, this is the way.

Everything else is real-world-team-only or "wait until something hurts."

---

## K. Cross-reference to historical plans

These older plans contain more verbose write-ups of some items above. Kept for reference; superseded by this plan + the simple plan:

- [aws_free-tier_deployment_plan_51444d33.plan.md](healthy-paws-wrapper/.cursor/plans/aws_free-tier_deployment_plan_51444d33.plan.md) — original full AWS stack design (SES, CloudFront, S3 SPA bucket, RDS-deferral analysis, caching layers).
- [first-time_deployment_walkthrough_caf72360.plan.md](healthy-paws-wrapper/.cursor/plans/first-time_deployment_walkthrough_caf72360.plan.md) — stage-by-stage walkthrough with raw commands. The simple plan's section D borrows command snippets from Stages 6-7.
- [remaining_work_todo_list_a103ef8c.plan.md](healthy-paws-wrapper/.cursor/plans/remaining_work_todo_list_a103ef8c.plan.md) — intermediate consolidation. Superseded by this plan + the simple plan.
