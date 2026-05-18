# Deployment notes

Quick reference for the bits that live outside the code: external accounts,
secrets, DNS, and post-deploy chores. The full deployment walkthrough lives
in `.cursor/plans/simple_aws_deploy_b6a51c00.plan.md`.

---

## 1. Email — Resend

The backend ships emails (verification + password reset) through Resend.
We picked Resend over Amazon SES because it has no sandbox approval ticket,
no SNS-bounce wiring to do, and the SMTP credentials are a single API key.

### Account setup

1. Sign up at https://resend.com — free tier is 3 000 emails/month, more
   than enough for development and a small beta.
2. **API Keys → Create API Key** → name it `healthy-paws-prod`,
   permission `Sending access`, save it as `RESEND_API_KEY` in
   `healthy-paws-service/.env` on the EC2 box.
3. Day 1 you can send from `onboarding@resend.dev` (Resend's sandbox sender).
   No DNS work required.

### Sending from your own domain (production)

When you're ready to send from `noreply@yourdomain.com`:

1. **Domains → Add Domain** in the Resend dashboard.
2. Resend will display 4 records to publish in Cloudflare DNS:
   - 1× MX  (envelope return path)
   - 1× TXT (SPF)
   - 2× TXT (DKIM)
3. Publish all 4 in Cloudflare with proxy **OFF** (orange cloud → grey
   cloud). DKIM CNAMEs/TXT must not be proxied.
4. Click **Verify** in the Resend dashboard; usually completes within
   a few minutes.
5. Update `MAIL_FROM=noreply@yourdomain.com` in `.env` and restart the
   backend: `docker compose -f docker-compose.prod.yml up -d backend`.

### DMARC (recommended once SPF+DKIM are live)

| Name      | Type | Value | TTL |
|-----------|------|-------|-----|
| `_dmarc`  | TXT  | `v=DMARC1; p=quarantine; rua=mailto:dmarc@yourdomain.com; pct=100` | Auto |

Start with `p=quarantine`; promote to `p=reject` after 2 weeks of clean
aggregate reports. Use `p=none` only during initial monitoring.

### Local dev without a Resend account

Leave `RESEND_API_KEY` empty in your local `.env`. The mailer falls back to
a stdout transport and prints the full rendered email to the backend logs.
Copy the verification or reset URL from `docker compose logs -f backend`
and paste it into the browser.

---

## 2. Sentry

Both repos read their DSN from env:

- **Backend:** `SENTRY_DSN` in `healthy-paws-service/.env`
- **Frontend:** `VITE_SENTRY_DSN` baked into the build (it's public)

When the DSN is unset, Sentry init is a no-op — local dev and CI never
ship events. Create separate projects per environment (dev / staging /
prod) so error volumes don't cross-contaminate.

The free Developer plan gives 5k errors and 10k performance events per
month, which is comfortably above what a beta-traffic deployment will
generate.

---

## 3. Database backups (cron entry)

`scripts/backup.sh` runs on the **EC2 host** (not in a container) and
shells into the `db` service. Cron entry:

```bash
sudo crontab -e
# Daily at 03:00 UTC. Keep it off-peak; the dump locks tables briefly.
0 3 * * * AWS_REGION=eu-central-1 S3_BUCKET=healthy-paws-backups COMPOSE_DIR=/home/ec2-user/healthy-paws-wrapper DB_USER=healthy_paws DB_DATABASE=healthy_paws /home/ec2-user/healthy-paws-wrapper/scripts/backup.sh >> /var/log/healthy-paws-backup.log 2>&1
```

The bucket needs an S3 lifecycle policy: **transition to Glacier IR after
30 days, expire after 365 days**. The EC2 instance role needs `s3:PutObject`
on the bucket+prefix — no static AWS keys on the box.

Test the restore path at least once before you rely on the backups:

```bash
gunzip -c healthy-paws_2026-05-17T03-00-00Z.sql.gz \
  | docker compose exec -T db psql -U healthy_paws -d healthy_paws_restore_test
```

---

## 4. Database migrations

`docker compose up` automatically runs the one-shot `migrate` service before
`backend` boots. To run migrations manually:

```bash
# Apply pending migrations (idempotent — skips already-applied ones)
docker compose run --rm migrate

# Revert the most recent migration
docker compose run --rm migrate npm run migrate:down

# Create a new migration (run on the host, not in compose)
cd healthy-paws-service && npm run migrate:create -- describe-the-change
```
