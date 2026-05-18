---
name: Simple AWS deploy
overview: "Beginner-friendly walkthrough to ship the Healthy Paws uni project to AWS using EC2 + S3 + a purchased domain. nginx on a single EC2 t3.micro serves the React SPA and reverse-proxies the Node/GraphQL backend running in docker compose alongside Postgres. S3 stores avatar uploads. Cloudflare provides free DNS + TLS + WAF. Resend handles email via its zero-DNS sandbox sender. Total ongoing cost: just the domain (~$10/year)."
todos:
  - id: s01-drop-submodules
    content: "Code prep: drop the wrapper submodules so deploys are unambiguous"
    status: pending
  - id: s02-dockerfile-prod-stage
    content: "Code prep: rename the final Dockerfile stage to `AS production` in healthy-paws-service/Dockerfile"
    status: pending
  - id: s03-compose-prod
    content: "Code prep: create healthy-paws-wrapper/docker-compose.prod.yml (no frontend service, nginx publishes 443 + mounts origin cert)"
    status: pending
  - id: s04-resend-transport
    content: "Code prep: swap nodemailer to Resend SMTP in authentication + email-verification services (RESEND_API_KEY env, onboarding@resend.dev sandbox sender)"
    status: pending
  - id: s05-s3-avatars-code
    content: "Code prep: implement S3 avatar uploads (storage.service, presigned PUT mutations, owners.profile_image_key migration, frontend uploader, delete localStorage base64 path)"
    status: pending
  - id: s06-aws-account
    content: "Sign up for AWS, enable MFA, create IAM `deploy` user, set $5 Budget alarm"
    status: pending
  - id: s07-cloudflare-account
    content: "Sign up for Cloudflare (free, no card)"
    status: pending
  - id: s08-resend-account
    content: "Sign up for Resend, create a Send-only API key"
    status: pending
  - id: s09-buy-domain
    content: "Buy a domain at Cloudflare Registrar (~$10/yr) and point its nameservers at Cloudflare; in Cloudflare set SSL mode to Full (strict)"
    status: pending
  - id: s10-s3-bucket
    content: "Create the avatars S3 bucket with bucket policy granting public-read on the `avatars/*` prefix only, plus CORS for PUT from your domain"
    status: pending
  - id: s11-iam-role
    content: "Create IAM policy + role `healthy-paws-ec2` granting s3:PutObject + s3:HeadObject on bucket/avatars/*"
    status: pending
  - id: s12-ec2-launch
    content: "Launch EC2 t3.micro (Amazon Linux 2023), 8 GiB gp3, attach keypair + IAM role + Elastic IP, security group 22/My IP + 80/0.0.0.0 + 443/0.0.0.0"
    status: pending
  - id: s13-ec2-setup
    content: "First-time setup on the box: install Docker + compose plugin + git, add ec2-user to docker group, create 2 GiB swap, mkdir /opt/healthy-paws"
    status: pending
  - id: s14-origin-cert
    content: "Generate Cloudflare Origin Certificate (15-year, *.yourdomain.com), install at /opt/healthy-paws/nginx/certs/origin.{pem,key} with chmod 600"
    status: pending
  - id: s15-dns-records
    content: "Add proxied A records in Cloudflare DNS: @ -> EIP, www -> EIP. Verify nslookup returns a Cloudflare IP."
    status: pending
  - id: s16-clone-and-build
    content: "On EC2: clone both healthy-paws-service and healthy-paws-wrapper into /opt; `docker build --target production -t healthy-paws-service:latest` from the service checkout"
    status: pending
  - id: s17-build-spa
    content: "On your laptop: `VITE_API_BASE_URL=https://yourdomain.com npm run build` in the frontend, then scp `dist/` to /opt/healthy-paws/nginx/spa/ on the box"
    status: pending
  - id: s18-prod-nginx-conf
    content: "Add nginx/nginx.prod.conf with two server blocks: 80 -> redirect to https, 443 ssl + origin cert serves /usr/share/nginx/spa and proxies /api/* + /graphql to backend:8080"
    status: pending
  - id: s19-env-and-up
    content: "Create /opt/healthy-paws/.env (NODE_ENV, JWT_SECRET, DB_*, RESEND_API_KEY, MAIL_FROM, AVATARS_BUCKET, AVATARS_REGION, ALLOWED_ORIGINS, TRUST_PROXY=2) with chmod 600, then `docker compose -f docker-compose.prod.yml up -d`"
    status: pending
  - id: s20-smoke-test
    content: "Smoke test: curl healthz, register + verify via Resend dashboard link, log in, upload an avatar, confirm the object lands in S3"
    status: pending
  - id: s21-update-flow-doc
    content: "Document the update flow in DEPLOYMENT-NOTES.md (backend = git pull + docker build + compose up -d backend; frontend = npm run build + scp)"
    status: pending
isProject: false
---

# Simple AWS deploy (beginner-friendly)

Single-VM deployment of the Healthy Paws uni project. One EC2 t3.micro runs nginx + the backend + Postgres in docker compose. S3 holds avatar uploads. Cloudflare is the free DNS + TLS + WAF layer. Resend handles email via its sandbox sender (no DNS work). Total ongoing cost: **just the domain (~$10/year)**.

This plan is intentionally beginner-paced — every command is here. The longer-form alternatives (Cloudflare Pages, CloudFront, SES, GHA pipelines, RDS, etc.) live in the companion plan `advanced_extras_*.plan.md`.

---

## 0. Architecture

```
[ Browser ]
    |
    v   HTTPS (Cloudflare Universal SSL, free)
[ Cloudflare DNS + WAF ]    <-- proxied A records point at the EIP
    |
    v   HTTPS (Cloudflare Origin Cert -> nginx, free)
[ EC2 t3.micro / Amazon Linux 2023 ]
    |
    +- nginx       /             -->  /usr/share/nginx/spa/* (built React SPA)
    |              /api/* + /graphql  -->  backend:8080
    |
    +- backend container (Node + Apollo)
    |              |
    |              +-->  Postgres (same compose network)
    |              +-->  S3 PutObject   -->  healthy-paws-avatars-<unique>   (IAM role on the EC2)
    |              +-->  HTTPS          -->  resend.com (sandbox sender)
    |
    +- Postgres container (data in named volume `pg_data`)
```

Resources you will create:

- 1 EC2 t3.micro (free tier: 750 hrs/mo for 12 months)
- 1 Elastic IP (free while attached to a running instance)
- 1 IAM role + 1 IAM policy (free)
- 1 S3 bucket (free tier: 5 GB + 20k GET + 2k PUT / month for 12 months)
- 1 Cloudflare zone (free forever)
- 1 Resend account (free forever, 3k mails/mo)
- 1 domain (~$10/year)

Nothing else. No ALB, no RDS, no CloudFront, no SES, no second S3 bucket for the SPA, no Route 53.

### Where each piece physically lives

In plain English: **one VM hosts all three tiers** (frontend static files, backend API, Postgres DB). The only AWS resource beyond the VM is the S3 bucket for avatar uploads and the IAM role that lets the VM write to it. Domain + TLS + WAF go through Cloudflare.

| Tier | Where it runs | How it gets there |
|---|---|---|
| **Frontend (React SPA)** | Static files inside the nginx container on EC2, served from `/usr/share/nginx/spa` | Run `npm run build` on your laptop (step **s17**), then `scp` the `dist/` folder to `/opt/healthy-paws/nginx/spa/` on EC2 (plan section F2) |
| **Backend (Node/Apollo)** | Docker container on EC2, image `healthy-paws-service:latest` | Built on the EC2 box from a `git clone` of the service repo (step **s16**), then `docker compose -f docker-compose.prod.yml up -d` |
| **Database (Postgres)** | Docker container on the **same** EC2, alongside the backend | Started by the same `docker compose up -d` (step **s19**); data persisted in the `pg_data` named volume |
| **S3 avatars bucket** | AWS S3 (separate resource, not on the VM) | Created in step **s10** (deferred while s05 is parked) |
| **DNS + TLS + WAF** | Cloudflare (free) | Domain + zone in step **s09**, Origin Cert in step **s14**, DNS records in step **s15** |
| **Email** | Resend SaaS (free) | API key in step **s08**; `RESEND_API_KEY` baked into the EC2 `.env` in step **s19** |

The single-VM design is intentional for a uni project — it's the cheapest, simplest layout and fits comfortably in AWS Free Tier for the first 12 months. If you later want to split the frontend off onto its own free hosting (Cloudflare Pages, Vercel, Netlify) so EC2 only carries the backend + DB, that swap is documented in [advanced_extras_5e44ab10.plan.md](healthy-paws-wrapper/.cursor/plans/advanced_extras_5e44ab10.plan.md) section G1.

---

## A. Local code prep (do these BEFORE touching AWS)

Five focused commits get the codebase shippable. Each is a separate todo above.

### A1. Drop the wrapper submodules — `s01`

The wrapper carries [healthy-paws-service](healthy-paws-wrapper/healthy-paws-service) and [healty-paws-frontend](healthy-paws-wrapper/healty-paws-frontend) as git submodules, but every real edit lands in the *standalone* repos at the workspace root. For a uni project the simplest fix is to delete the submodules; the wrapper then carries only `docker-compose*.yml`, `nginx/`, `scripts/`, `.env.example`.

```bash
cd healthy-paws-wrapper
git submodule deinit -f healthy-paws-service
git submodule deinit -f healty-paws-frontend
git rm healthy-paws-service healty-paws-frontend
rm -rf .git/modules/healthy-paws-service .git/modules/healty-paws-frontend
git commit -m "drop submodules; wrapper carries only deploy artefacts"
```

### A2. Tag the Dockerfile final stage `AS production` — `s02`

[healthy-paws-service/Dockerfile](healthy-paws-service/Dockerfile) currently has an unnamed final stage on line 20:

```dockerfile
FROM node:20-alpine
```

Change to:

```dockerfile
FROM node:20-alpine AS production
```

That lets `docker-compose.prod.yml` target it with `target: production`.

### A3. Add `docker-compose.prod.yml` to the wrapper — `s03`

New file [healthy-paws-wrapper/docker-compose.prod.yml](healthy-paws-wrapper/docker-compose.prod.yml). Shape:

```yaml
services:
  backend:
    image: healthy-paws-service:latest      # built locally on the box from the cloned repo
    restart: unless-stopped
    env_file: .env
    depends_on: [postgres]
    deploy: { resources: { limits: { memory: 400m } } }
    logging: { driver: json-file, options: { max-size: "10m", max-file: "5" } }

  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: [pg_data:/var/lib/postgresql/data]
    deploy: { resources: { limits: { memory: 300m } } }
    logging: { driver: json-file, options: { max-size: "10m", max-file: "3" } }

  nginx:
    image: nginx:1.27-alpine
    restart: unless-stopped
    ports: ["80:80", "443:443"]
    volumes:
      - ./nginx/nginx.prod.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/certs:/etc/nginx/certs:ro
      - ./nginx/spa:/usr/share/nginx/spa:ro
    depends_on: [backend]
    deploy: { resources: { limits: { memory: 100m } } }

volumes:
  pg_data:
```

No `frontend` service — nginx serves the pre-built SPA directly.

### A4. Swap nodemailer to Resend — `s04`

Touch [src/features/authentication/authentication.service.ts](healthy-paws-service/src/features/authentication/authentication.service.ts), [src/features/email-verification/email-verification.service.ts](healthy-paws-service/src/features/email-verification/email-verification.service.ts), and [src/core/config/email.ts](healthy-paws-service/src/core/config/email.ts):

```ts
import nodemailer from "nodemailer";

export const mailer = nodemailer.createTransport({
  host: "smtp.resend.com",
  port: 465,
  secure: true,
  auth: { user: "resend", pass: process.env.RESEND_API_KEY! },
});

export const mailFrom = process.env.MAIL_FROM ?? "onboarding@resend.dev";
```

Remove `MAIL_HOST` / `MAIL_PORT` / `MAIL_USER` / `MAIL_PASSWORD` from `.env.example`, replace with `RESEND_API_KEY` and `MAIL_FROM`. Update the env table in [DEPLOYMENT-NOTES.md](healthy-paws-wrapper/DEPLOYMENT-NOTES.md).

`onboarding@resend.dev` works on day one with no DNS work. (Later, if you want to send from `you@yourdomain.com`, verify your domain in the Resend dashboard, paste the four DNS records into Cloudflare, then update `MAIL_FROM`.)

### A5. Implement S3 avatar uploads — `s05`

The most substantial code change in this plan. Backend pieces:

- **Migration:** new file under [migrations/](healthy-paws-service/migrations) — `ALTER TABLE owners ADD COLUMN profile_image_key TEXT;`
- **New module** `src/features/storage/storage.service.ts` wrapping `@aws-sdk/client-s3` and `@aws-sdk/s3-request-presigner`. Credentials come from the EC2 instance role — no static keys.
- **GraphQL additions** in [src/schema/typeDefs.graphql](healthy-paws-service/src/schema/typeDefs.graphql):

  ```graphql
  type PresignedUpload { uploadUrl: String!, key: String!, expiresAt: String! }

  extend type Mutation {
    requestProfileImageUpload(contentType: String!, sizeBytes: Int!): PresignedUpload!
    confirmProfileImage(key: String!): Owner!
  }

  extend type Owner { profileImageUrl: String }
  ```

- **Resolver** validates `contentType ∈ {image/jpeg, image/png, image/webp}`, `sizeBytes ≤ 2_097_152`, key pattern `avatars/{ownerId}/{uuid}.{ext}`, 15-min URL TTL. `confirmProfileImage` does a `HeadObject` + authz check `ctx.user.id === ownerId`. `Owner.profileImageUrl` returns `https://${AVATARS_BUCKET}.s3.${AVATARS_REGION}.amazonaws.com/${key}`.

Frontend pieces (in [healty-paws-frontend](healty-paws-frontend)):

- Delete the base64-in-localStorage path in [AvatarImage.tsx](healty-paws-frontend/src/components/ui/AvatarImage/AvatarImage.tsx) and its callers.
- New upload flow: file picker -> `requestProfileImageUpload` -> `fetch(uploadUrl, { method: "PUT", body: file, headers: { "content-type": file.type } })` -> `confirmProfileImage` -> re-render with `owner.profileImageUrl`.

Don't worry about a CDN — direct S3 reads are fine for a uni project.

---

## B. External accounts — sign up in this order

### B1. AWS account — `s06`

- Sign up at `aws.amazon.com` (credit card required; you pay $0 if you stay in free tier).
- Enable MFA on the root account.
- IAM -> Users -> create `deploy` -> attach `AmazonEC2FullAccess` + `AmazonS3FullAccess` + `IAMReadOnlyAccess` for console use. **Never use root for daily work.**
- Billing -> Budgets -> create a $5 monthly cost budget that emails you at 80% / 100%.

### B2. Cloudflare account — `s07`

Sign up at `cloudflare.com`. No card required.

### B3. Resend account — `s08`

Sign up at `resend.com`. Dashboard -> API Keys -> Create -> name `healthy-paws-prod`, scope `Send only`. **Save the key now** — it is shown only once. You will paste it as `RESEND_API_KEY` in `.env` later.

---

## C. Buy a domain (~$10/year, the only real cost) — `s09`

Cheapest: **Cloudflare Registrar** (at-cost pricing, no markup; `.com` ~$9.77/yr). Requires the Cloudflare zone to exist first.

Alternative: Namecheap (~$10 year 1, ~$13 renewal) — easier UI if you've never registered a domain.

After purchase:

1. In the registrar's panel, change nameservers to the two Cloudflare nameservers shown in your Cloudflare dashboard (e.g. `lara.ns.cloudflare.com`, `tim.ns.cloudflare.com`).
2. Wait 5 minutes to 24 hours for propagation.
3. In Cloudflare -> SSL/TLS -> set encryption mode to **Full (strict)**.
4. Cloudflare -> SSL/TLS -> Edge Certificates -> enable **Always Use HTTPS**.

DNS records for the EC2 come in section E.

---

## D. AWS infrastructure

### D1. S3 bucket for avatars — `s10`

Console -> S3 -> Create bucket:

- Name: `healthy-paws-avatars-<your-initials-and-digits>` (must be globally unique)
- Region: `us-east-1`
- Object Ownership: **Bucket owner enforced** (no ACLs)
- Block Public Access: keep "block via ACLs" checked, **uncheck** "block via bucket policies"

After creation:

- **Bucket policy** tab:

  ```json
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Sid": "PublicReadAvatars",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::healthy-paws-avatars-<your-suffix>/avatars/*"
    }]
  }
  ```

- **CORS** tab:

  ```json
  [{
    "AllowedOrigins": ["https://yourdomain.com", "https://www.yourdomain.com"],
    "AllowedMethods": ["PUT", "GET", "HEAD"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3000
  }]
  ```

- **Lifecycle rule** Management -> Lifecycle -> Create: `avatars/orphans/` -> expire after 7 days.

### D2. IAM instance profile — `s11`

So the backend can `PutObject` without baked-in credentials.

IAM -> Policies -> Create -> JSON:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:PutObject", "s3:HeadObject"],
    "Resource": "arn:aws:s3:::healthy-paws-avatars-<your-suffix>/avatars/*"
  }]
}
```

Name it `healthy-paws-s3-avatars`.

Then IAM -> Roles -> Create role -> AWS service -> EC2 -> attach the policy above. Name the role `healthy-paws-ec2`. An instance profile with the same name is auto-created.

### D3. Launch the EC2 — `s12`

Console -> EC2 -> Launch instance:

- Name: `healthy-paws-prod`
- AMI: **Amazon Linux 2023**
- Instance type: **t3.micro** (free tier)
- Key pair: create new -> download `healthy-paws-prod.pem` -> `chmod 400 healthy-paws-prod.pem`
- Network: default VPC. Create security group `healthy-paws-sg`:
  - Inbound: SSH (22) **My IP**, HTTP (80) Anywhere, HTTPS (443) Anywhere
- Storage: 8 GiB gp3 (in free tier)
- Advanced -> IAM instance profile: select `healthy-paws-ec2` (from D2)
- Launch.

After launch: EC2 -> Elastic IPs -> Allocate -> Associate to your instance. The EIP is free while attached to a running instance.

### D4. First-time setup on the box — `s13`

```bash
ssh -i healthy-paws-prod.pem ec2-user@<your-EIP>

sudo dnf update -y
sudo dnf install -y docker git
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user
exit                                                  # log out so the docker group takes effect
ssh -i healthy-paws-prod.pem ec2-user@<your-EIP>

# docker compose plugin (Amazon Linux doesn't ship it)
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
docker compose version                                # confirm it works

# 2 GiB swap (t3.micro has only 1 GiB RAM)
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# project dir
sudo mkdir -p /opt/healthy-paws
sudo chown ec2-user:ec2-user /opt/healthy-paws

# smoke tests
docker run --rm hello-world                           # docker works
aws sts get-caller-identity                           # IAM role works (Amazon Linux ships awscli2)
```

The `get-caller-identity` should return an ARN like `arn:aws:sts::123456789012:assumed-role/healthy-paws-ec2/i-0abc...`. If it does, the instance profile is attached correctly.

---

## E. TLS + DNS wiring

### E1. Cloudflare Origin Certificate — `s14`

Cloudflare dashboard -> SSL/TLS -> Origin Server -> **Create Certificate**:

- Hostnames: `yourdomain.com`, `*.yourdomain.com`
- Validity: 15 years
- Format: PEM (Origin Certificate + Private key — both shown only once, save them now).

On the EC2 box:

```bash
mkdir -p /opt/healthy-paws/nginx/certs
nano /opt/healthy-paws/nginx/certs/origin.pem        # paste cert
nano /opt/healthy-paws/nginx/certs/origin.key        # paste key
chmod 600 /opt/healthy-paws/nginx/certs/*
```

### E2. DNS records — `s15`

Cloudflare -> DNS -> Records -> Add:

- Type **A**, name `@`, IPv4 `<your-EIP>`, Proxy status **Proxied** (orange cloud), TTL Auto.
- Type **A**, name `www`, IPv4 `<your-EIP>`, Proxy status **Proxied**.

Verify from your laptop:

```bash
nslookup yourdomain.com 1.1.1.1
```

Should return a Cloudflare IP (`104.x.x.x` or `172.x.x.x`), **not** your EIP. That means Cloudflare is proxying. Good.

---

## F. Deploy the app

### F1. Clone repos and build the backend image on the box — `s16`

```bash
ssh -i healthy-paws-prod.pem ec2-user@<EIP>
cd /opt
git clone https://github.com/<your-github-username>/healthy-paws-service.git
git clone https://github.com/<your-github-username>/healthy-paws-wrapper.git healthy-paws

cd /opt/healthy-paws-service
docker build --target production -t healthy-paws-service:latest .
```

The build takes 3-5 minutes on a t3.micro (swap helps). Drop a coffee.

### F2. Build the SPA locally and ship it — `s17`

On your **laptop**:

```bash
cd healty-paws-frontend
VITE_API_BASE_URL=https://yourdomain.com npm run build
scp -i ../healthy-paws-prod.pem -r dist/* ec2-user@<EIP>:/opt/healthy-paws/nginx/spa/
```

(npm install on t3.micro is too RAM-hungry for the frontend's dep tree — build locally on your laptop instead.)

### F3. Add the prod nginx config — `s18`

On the EC2 box, create [healthy-paws-wrapper/nginx/nginx.prod.conf](healthy-paws-wrapper/nginx/nginx.prod.conf):

```nginx
events { worker_connections 1024; }

http {
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  server_tokens off;
  client_max_body_size 1m;

  limit_req_zone $binary_remote_addr zone=auth_limit:10m rate=10r/m;

  upstream backend { server backend:8080; }

  map $sent_http_content_type $hp_csp {
    default "default-src 'self'; img-src 'self' data: blob: https://*.s3.amazonaws.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com data:; script-src 'self' 'unsafe-inline'; connect-src 'self' https://*.s3.amazonaws.com; frame-ancestors 'none'; base-uri 'self'; form-action 'self'; object-src 'none';";
  }

  server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$host$request_uri;
  }

  server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    ssl_certificate     /etc/nginx/certs/origin.pem;
    ssl_certificate_key /etc/nginx/certs/origin.key;

    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    add_header Content-Security-Policy $hp_csp always;

    root /usr/share/nginx/spa;
    index index.html;

    location /api/ {
      limit_req zone=auth_limit burst=5 nodelay;
      limit_req_status 429;
      proxy_pass http://backend;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto https;
    }

    location /graphql {
      proxy_pass http://backend/graphql;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto https;
    }

    location / { try_files $uri $uri/ /index.html; }
  }
}
```

Make sure `docker-compose.prod.yml` (from A3) mounts this file: `./nginx/nginx.prod.conf:/etc/nginx/nginx.conf:ro`.

### F4. `.env` + first boot — `s19`

Still on the box, in `/opt/healthy-paws`:

```bash
cat > .env <<'EOF'
NODE_ENV=production
PORT=8080

JWT_SECRET=                                # paste output of: openssl rand -hex 32
DB_HOST=postgres
DB_PORT=5432
DB_NAME=healthypaws
DB_USER=hp_admin
DB_PASSWORD=                               # strong random password

RESEND_API_KEY=                            # from B3
MAIL_FROM=onboarding@resend.dev

AVATARS_BUCKET=healthy-paws-avatars-<your-suffix>
AVATARS_REGION=us-east-1

ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
TRUST_PROXY=2
EOF
chmod 600 .env
nano .env                                  # fill in the blanks

docker compose -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml logs -f backend
```

Wait for migrations to run and "Server listening on port 8080". Ctrl-C to exit the follow.

---

## G. Smoke test — `s20`

From your laptop:

```bash
curl -I https://yourdomain.com                                # HTTP/2 200, cf-* headers
curl https://yourdomain.com/healthz                           # {"status":"ok"} or similar
curl -X POST https://yourdomain.com/graphql \
  -H 'content-type: application/json' \
  -d '{"query":"{ __typename }"}'                             # {"data":{"__typename":"Query"}}
```

From a browser:

1. Open `https://yourdomain.com` -> SPA loads.
2. Register a new account.
3. Open the Resend dashboard -> Emails -> click the verification link in your most recent send.
4. Log in successfully.
5. Edit profile -> upload an avatar. Confirm it renders. Check S3 console: `s3://healthy-paws-avatars-<suffix>/avatars/<your-user-id>/<uuid>.jpg` should exist.

All five passing means you are deployed.

---

## H. Updating the deployed app — `s21`

**Backend code change:**

```bash
ssh -i healthy-paws-prod.pem ec2-user@<EIP>
cd /opt/healthy-paws-service
git pull
docker build --target production -t healthy-paws-service:latest .
cd /opt/healthy-paws
docker compose -f docker-compose.prod.yml up -d backend
```

**Frontend code change:**

```bash
# laptop
cd healty-paws-frontend
VITE_API_BASE_URL=https://yourdomain.com npm run build
scp -i ../healthy-paws-prod.pem -r dist/* ec2-user@<EIP>:/opt/healthy-paws/nginx/spa/
```

Nginx serves the new files immediately — no reload needed.

**Database migration:** runs automatically when the backend container starts. To roll back: `docker compose -f docker-compose.prod.yml exec backend npm run migrate down`.

Add a short "Update flow" section to [DEPLOYMENT-NOTES.md](healthy-paws-wrapper/DEPLOYMENT-NOTES.md) capturing the above so future-you doesn't have to re-derive it.

---

## I. Cost

| Item | Year 1 | Year 2+ |
|---|---|---|
| Domain | $10 | ~$10/yr |
| EC2 t3.micro | $0 (free tier 750 hrs/mo) | ~$8/mo on-demand, ~$5/mo with 1-yr Savings Plan, ~$3/mo if you switch to t4g.nano (ARM) |
| Elastic IP | $0 (attached) | $0 (attached) |
| S3 storage | $0 (5 GB free tier) | ~$0.30/mo for a few GB |
| Cloudflare DNS+TLS+WAF | $0 | $0 |
| Resend | $0 | $0 |
| **Total** | **$10** | **$10/yr + ~$3-8/mo** |

To minimise year-2 cost: stop the EC2 when you're not actively demoing it. You pay only for hours it's running.

---

## J. Troubleshooting

| Symptom | First thing to check |
|---|---|
| `https://yourdomain.com` won't load | `nslookup yourdomain.com 1.1.1.1` — DNS propagated? Cloudflare A records added + proxied (orange cloud)? |
| TLS error / `ERR_SSL_VERSION_OR_CIPHER_MISMATCH` | Cloudflare SSL/TLS mode = **Full (strict)**, not "Flexible" or "Off". Origin cert paths in the nginx config match the mounted volume. |
| 502 Bad Gateway | Backend container down. `docker compose ps`, `docker compose logs backend`. |
| 404 on `/api/...` | Typo in the `location /api/` block in `nginx.prod.conf`. |
| Avatar upload returns 403 | IAM role not attached, OR bucket name in `.env` wrong. Run `aws s3 ls s3://healthy-paws-avatars-<suffix>/` from the box. |
| Avatar uploaded but renders as broken image | Bucket policy missing public read on `avatars/*` (see D1). |
| Verification email never arrives | Resend dashboard -> Emails -> did send succeed? Check spam folder. |
| App slow or OOM after a few minutes | `free -h` on the box. If swap usage > 500 MiB the t3.micro is RAM-starved — tune Postgres `shared_buffers` down to 64 MB, or stop and resize to t3.small (paid). |
| Container keeps restarting | `docker compose logs <service>` — usually a missing env var. |

---

## K. What this plan deliberately skips

Everything in `advanced_extras_*.plan.md`. Highlights:

- No CI/CD pipeline. You deploy by hand (3 commands).
- No HTTPS certificate automation. Cloudflare Origin Cert is 15-year, set-and-forget.
- No CloudFront, no second domain for the API — same nginx serves SPA + API.
- No SES; Resend sandbox sender is fine for a uni project.
- No managed Postgres (no RDS); Postgres runs in compose.
- No source-map upload, no perf monitoring, no log shipping.
- No automated backups. **If you want backups even for a uni project**, run [scripts/backup.sh](healthy-paws-wrapper/scripts/backup.sh) by hand once a week.
- No JWT revocation (token_version) — logout clears the cookie on this browser only.

If any of those start to matter (or you just want to learn one), pull it out of the advanced plan.
