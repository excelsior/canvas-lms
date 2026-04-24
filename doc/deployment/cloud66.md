# Cloud 66 Rails Deployment

This repo is configured for Cloud 66's native Rails support, not Cloud 66
container services.

Cloud 66 will run Canvas as a Rails app under Passenger, run Rails database
migrations automatically, compile Canvas assets through deploy hooks, provision
PostgreSQL and Redis during application setup, and start background workers from
the root `Procfile`.

## Create the Application

Push this branch to a Git remote Cloud 66 can access, then create a new Rails
application in the Cloud 66 dashboard:

1. Choose **Rails / Rack** rather than containerized deployment.
2. Select this repository and branch.
3. Confirm PostgreSQL and Redis in the analysis step.
4. Add the environment variables below before the first deploy.

The native Rails flow uses:

- `.cloud66/manifest.yml` for Ruby, Node, database, and APC settings. It
  pins PostgreSQL 18.3 and Redis 8.6.2, which are newer than Canvas's minimums
  in this branch.
- `.cloud66/deploy_hooks.yml` for system packages, config file activation, and
  Canvas asset compilation.
- `Procfile` for background workers.

## Required Environment Variables

Upload `.cloud66/env.sample` through the Cloud 66 environment variables UI or
Toolbelt, then set real values where appropriate:

```bash
cx env-vars upload \
  --stack canvas-production \
  --file .cloud66/env.sample \
  --file-type dotenv \
  --apply-strategy deployment
```

Required:

- `ENCRYPTION_KEY`
- `JWT_ENCRYPTION_KEY`
- `CANVAS_DOMAIN`
- `RAILS_ENV=production`
- `RACK_ENV=production`
- `NODE_ENV=production`

Cloud 66 replaces `AUTO_GENERATE_*` values with generated secrets on deploy.
Keep those generated values stable after the first production deployment.

## File Storage

Without S3 variables, Canvas stores uploaded files in `tmp/files` inside the
container. That is not durable across container replacement. For production,
set:

- `AWS_S3_BUCKET`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

## Runtime Config

Canvas config files are committed as `.cloud66` templates because
`/config/*.yml` is intentionally ignored in this repo. During `after_checkout`,
`.cloud66/deploy_hooks.yml` copies them into place:

- `config/database.yml`
- `config/redis.yml`
- `config/cache_store.yml`
- `config/security.yml`
- `config/domain.yml`
- `config/file_store.yml`
- `config/amazon_s3.yml` when S3 is configured
- `config/outgoing_mail.yml` when SMTP is configured

## Asset Compilation

Cloud 66's standard Rails asset pipeline compilation is disabled in the
manifest. Canvas assets are compiled with:

```bash
bin/rails canvas:compile_assets --trace
```

The hook also prepares Yarn 1.19.1 with Corepack to match Canvas's lockfile.
