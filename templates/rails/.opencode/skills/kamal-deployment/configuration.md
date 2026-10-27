# Kamal 2 Configuration Reference

## Minimal deploy.yml

```yaml
# config/deploy.yml
service: my-app
image: my-user/my-app

servers:
  web:
    - 192.168.0.1

proxy:
  ssl: true
  host: app.example.com

registry:
  username: my-user
  password:
    - KAMAL_REGISTRY_PASSWORD

builder:
  arch: amd64
```

## Service

```yaml
service: my-app  # Used to uniquely name containers
```

## Image

```yaml
image: my-user/my-app  # Registry namespace/repository
```

## Labels

```yaml
labels:
  my-label: my-value
```

## Top-Level Options

```yaml
retain_containers: 5          # Number of old containers to keep (default: 5)
minimum_version: 2.3.0        # Required minimum Kamal version
readiness_delay: 7             # Seconds to wait before checking status (default: 7)
deploy_timeout: 30             # Max wait for container to boot (default: 30)
drain_timeout: 30              # Wait for old container to finish requests (default: 30)
primary_role: web              # Default primary role (default: web)
allow_empty_roles: false       # Allow roles with no hosts (default: false)
require_destinations: false    # Require -d flag on all commands (default: false)
hooks_path: .kamal/hooks       # Path to hook scripts (default: .kamal/hooks)
error_pages_path: public/errors # Directory for custom 4xx/5xx HTML error pages
run_directory: .kamal          # Where lock files and audit logs live
```

### Extensions

Prefix sections with `x-` to add ignored keys (useful for YAML anchors):

```yaml
x-common-env: &common-env
  RAILS_LOG_TO_STDOUT: true

env:
  clear:
    <<: *common-env
```

## Servers

```yaml
servers:
  web:
    hosts:
      - 192.168.0.1
    labels:
      my_label: "value"
    options:
      cpus: 2
      memory: 1g
  job:
    hosts:
      - 192.168.0.2
    cmd: bundle exec sidekiq -q default -q mailers
```

The `web` role is special - it receives traffic from Kamal Proxy on port 80. Other roles can be named anything.

### Resource Limits

```yaml
servers:
  web:
    hosts:
      - 192.168.0.1
    options:
      cpus: 1.5
      cpuset-cpus: "0,3"
      memory: 0.5g
      memory-swap: 1g
```

### Server Tags

Tags allow assigning host-specific environment variables:

```yaml
servers:
  web:
    hosts:
      - 172.0.0.1
      - 172.0.0.2: experiments
      - 172.0.0.3: [experiments, three]
```

### Network Options

Kamal 2 automatically creates a `kamal` Docker network for all containers. Reference accessories by their container name `[SERVICE]-[ACCESSORY]`.

**Do NOT add a custom private network** - Kamal 2 provides its own.

## Registry

```yaml
# Docker Hub (default)
registry:
  username: my-user
  password:
    - KAMAL_REGISTRY_PASSWORD

# Other registries (DigitalOcean, GHCR, ECR, etc.)
registry:
  server: registry.digitalocean.com  # or ghcr.io
  username: my-user
  password:
    - KAMAL_REGISTRY_PASSWORD
```

### AWS ECR

```yaml
registry:
  server: [ACCOUNT_ID].dkr.ecr.[REGION].amazonaws.com
  username: AWS
  password:
    - KAMAL_REGISTRY_PASSWORD
```

In `.kamal/secrets`:
```bash
KAMAL_REGISTRY_PASSWORD=$(aws ecr get-login-password --region [REGION])
```

## Proxy

```yaml
proxy:
  # Host and port
  host: app.example.com       # Domain for routing
  app_port: 3000              # Container port (default: 80)

  # SSL/TLS via Let's Encrypt
  ssl: true                    # Automatic TLS certificates
  # Set ssl: false if using Cloudflare or external LB for SSL

  # Health checks
  healthcheck:
    path: /up                  # Default: /up
    interval: 3                # Seconds between checks
    timeout: 3                 # Seconds to wait for response

  # Timeouts
  response_timeout: 30s       # Default: 30s

  # Buffering
  buffering:
    requests: true
    responses: true
    max_request_body: 40_000_000  # Bytes (40MB)
    max_response_body: 0          # 0 = unlimited
    memory: 2_000_000             # 2MB buffer memory limit

  # Forward headers (enable behind Cloudflare/LB)
  forward_headers: true

  # Logging
  logging:
    request_headers:
      - Cache-Control
      - X-Forwarded-Proto
    response_headers:
      - X-Request-ID

  # Multiple hosts for same app
  hosts:
    - foo.example.com
    - bar.example.com

  # Custom SSL certificates (when Let's Encrypt isn't viable)
  ssl:
    certificate_pem: CERTIFICATE_PEM  # Secret name
    private_key_pem: PRIVATE_KEY_PEM  # Secret name

  # SSL redirect (HTTP to HTTPS, enabled by default with ssl: true)
  ssl_redirect: true

  # Path-based routing (route by URL path)
  path_prefix: "/api,/oauth_callback"
  # OR
  path_prefixes:
    - /api
    - /oauth_callback
  strip_path_prefix: true          # Strip prefix before forwarding (default: true)
```

### Proxy Per-Role

```yaml
servers:
  web:
    hosts:
      - 192.168.0.1
    proxy: true                    # Enabled by default for primary role
  job:
    hosts:
      - 192.168.0.2
    cmd: bundle exec sidekiq
    proxy: false                   # Disabled by default for non-primary roles
```

### Proxy Run Options

```yaml
proxy:
  run_options:
    http_port: 80
    https_port: 443
    metrics_port: 9090
    log_max_size: 10m
    debug: false
    memory: 512m
    cpus: 1
```

## Builder

```yaml
builder:
  arch: amd64                  # Target architecture (amd64 or arm64)
  args:
    RUBY_VERSION: 3.2.2
  context: .                   # Build from uncommitted changes
  dockerfile: Dockerfile.production
  target: production
  driver: docker

  # Build cache (recommended for CI)
  cache:
    type: registry             # or gha (GitHub Actions)
    image: my-user/my-app-build-cache
    options: mode=max,oci-mediatypes=true

  # Remote builder
  remote: ssh://docker@docker-builder
  local: false                 # Only use remote

  # SSH for builder
  ssh: default=$SSH_AUTH_SOCK

  # Build secrets (from .kamal/secrets)
  secrets:
    - GITHUB_TOKEN

  # Cloud Native Buildpacks (instead of Dockerfile)
  pack:
    builder: heroku/builder:24
    buildpacks:
      - heroku/ruby
      - heroku/procfile

  # Docker Build Cloud driver
  driver: cloud org-name/builder-name

  # Attestation
  provenance: false                # Provenance attestation (boolean or mode=max)
  sbom: false                      # Software Bill of Materials
```

## Environment Variables

```yaml
env:
  clear:
    RAILS_LOG_TO_STDOUT: true
    RAILS_SERVE_STATIC_FILES: true
    HOST: app.example.com
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
    - DB_PASSWORD:MAIN_DB_PASSWORD  # Aliased secret (ENV_NAME:SECRET_NAME)
```

### Per-role environment with tags

```yaml
servers:
  job:
    hosts:
      - 192.168.0.2: fast
      - 192.168.0.3: [recurring, test]
    cmd: bin/rails jobs
env:
  tags:
    fast:
      QUEUE_NAME: fast
    recurring:
      clear:
        QUEUE_NAME: recurring
      secret:
        - CUSTOM_SECRET
```

## Secrets (.kamal/secrets)

```bash
# Direct values (DO NOT commit to git!)
KAMAL_REGISTRY_PASSWORD="dckr_pat_xxx"
RAILS_MASTER_KEY="abc123..."

# Variable substitution (from shell environment)
KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD

# Command substitution
RAILS_MASTER_KEY=$(cat config/master.key)

# 1Password integration
KAMAL_REGISTRY_PASSWORD=$(op read op://[VAULT]/KAMAL_REGISTRY_PASSWORD/password)

# Kamal secrets helper
SECRETS=$(kamal secrets fetch --adapter 1password --account [ACCOUNT_ID] --from [VAULT] KAMAL_REGISTRY_PASSWORD)
KAMAL_REGISTRY_PASSWORD=$(kamal secrets extract KAMAL_REGISTRY_PASSWORD $SECRETS)
```

## Accessories

```yaml
accessories:
  postgres:
    image: postgres:16
    host: 192.168.0.3          # Specific host
    # OR
    roles:                     # Deploy to all servers in role
      - web
    port: 5432                 # Expose port (optional, security risk!)
    env:
      clear:
        POSTGRES_USER: myapp
        POSTGRES_DB: myapp_production
      secret:
        - POSTGRES_PASSWORD
    files:
      - config/init.sql:/docker-entrypoint-initdb.d/setup.sql
    directories:
      - data:/var/lib/postgresql/data
    volumes:
      - /host/path:/container/path

  redis:
    image: redis:7
    roles:
      - web
    cmd: "redis-server --requirepass <%= File.read('.kamal/secrets')[/REDIS_PASSWORD=\"(.*?)\"/, 1] %>"
    directories:
      - data:/data
    options:
      restart: always
    labels:
      my-label: redis
    network: kamal                 # Default: kamal (custom network override)

  s3_backup:
    image: eeshugerman/postgres-backup-s3:16
    host: 192.168.0.3
    env:
      clear:
        SCHEDULE: "@daily"
        BACKUP_KEEP_DAYS: 30
        S3_ENDPOINT: https://s3.amazonaws.com
        S3_BUCKET: my-backups
        S3_PREFIX: my-app
        POSTGRES_HOST: myapp-postgres
        POSTGRES_DATABASE: myapp_production
        POSTGRES_USER: myapp
      secret:
        - POSTGRES_PASSWORD
        - S3_ACCESS_KEY_ID
        - S3_SECRET_ACCESS_KEY
```

## Volumes

```yaml
# Docker volume
volumes:
  - "app_storage:/app/storage"

# Host bind mount
volumes:
  - "/storage:/rails/storage"
```

## Asset Bridging

```yaml
# Must be explicitly set - not automatic!
asset_path: /rails/public/assets
```

Bridges fingerprinted assets between old and new versions during deploy to prevent 404s.

## Healthchecks

### Proxy roles (web)

Kamal Proxy hits `/up` every second with 5-second timeout during the 20-second deploy timeout.

```yaml
proxy:
  healthcheck:
    path: /health
    interval: 2s
    timeout: 2s

deploy_timeout: 20s            # Max wait for new container to boot
drain_timeout: 20s             # Wait for old container to finish requests
```

### Non-proxy roles (job, cron)

Use Docker HEALTHCHECK in Dockerfile or options:

```yaml
servers:
  job:
    cmd: bin/jobs
    options:
      health-cmd: bin/jobs-healthy
      health-start-period: 0s
      health-retries: 3
      health-timeout: 30s
      health-interval: 30s

readiness_delay: 20s           # Wait before checking running status
```

## Destinations

```yaml
# config/deploy.staging.yml
servers:
  web:
    hosts:
      - 165.232.112.195

proxy:
  host: staging.example.com
```

```bash
kamal setup -d staging
kamal deploy -d staging
```

Secrets file: `.kamal/secrets.staging`

## SSH

```yaml
ssh:
  user: deploy               # Default: root
  port: 22                   # Default: 22
  log_level: fatal           # Default: fatal (use debug for troubleshooting)
  keys_only: true            # Only use specified keys, ignore ssh-agent
  keys: ["~/.ssh/id_pem"]   # Private key file paths
  key_data:                  # PEM keys from secrets
    - SSH_PRIVATE_KEY
  proxy: "deploy@192.168.0.1"  # Bastion/jump host
  proxy_command: aws ssm start-session (...)  # Custom proxy command
  config: ["~/.ssh/myconfig"]  # OpenSSH config file(s)
```

## SSHKit

```yaml
sshkit:
  max_concurrent_starts: 30   # Max concurrent SSH connections (default: 30)
  pool_idle_timeout: 900      # Seconds before idle connection is closed (default: 900)
  dns_retries: 3              # Retry DNS failures during concurrent starts (default: 3)
```

## Logging

```yaml
logging:
  driver: json-file           # or local, journald, awslogs, gcplogs, none
  options:
    max-size: 10m             # 3 files x 10MB = 30MB per container
    max-file: 3
```

## Aliases

```yaml
aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell: app exec --interactive --reuse "bash"
  logs: app logs -f
  dbc: app exec --interactive --reuse "bin/rails dbconsole"
```

```bash
kamal console
kamal shell
kamal dbc
```

## Boot Configuration

```yaml
boot:
  limit: 10                   # Or "25%" - rolling deploy batch size
  wait: 2                     # Seconds between batches
```

## Hooks

Hook scripts live in `.kamal/hooks/` (configurable via `hooks_path`). If a script returns a non-zero exit code, the command is aborted. Use `--skip-hooks` to bypass.

### Available Hooks

| Hook | When it fires |
|------|--------------|
| `docker-setup` | During Docker initialization |
| `pre-connect` | Before establishing SSH connections |
| `pre-build` | Before building the container image |
| `pre-deploy` | Before deployment begins |
| `post-deploy` | After deployment completes |
| `pre-app-boot` | Before the application starts |
| `post-app-boot` | After the application starts |
| `pre-proxy-reboot` | Before proxy restart |
| `post-proxy-reboot` | After proxy restart |

Hook filenames must match the hook name without extensions (e.g., `pre-deploy`, not `pre-deploy.sh`).

### Available Environment Variables in Hooks

`KAMAL_RECORDED_AT`, `KAMAL_PERFORMER`, `KAMAL_SERVICE`, `KAMAL_SERVICE_VERSION`, `KAMAL_VERSION`, `KAMAL_HOSTS`, `KAMAL_COMMAND`, `KAMAL_SUBCOMMAND`, `KAMAL_DESTINATION`, `KAMAL_ROLE`.

## Upgrading from Kamal 1 to Kamal 2

Key breaking changes:
- **Proxy**: Traefik replaced by kamal-proxy
- **Networking**: All containers run in a `kamal` Docker network
- **Secrets**: `.env` replaced by `.kamal/secrets`
- **Default port**: Changed from 3000 to 80

```bash
# Upgrade path
gem install kamal --version 1.9.0  # First upgrade to 1.9.x
gem install kamal                   # Then upgrade to 2.x
kamal config                        # Validate new config
kamal upgrade                       # In-place upgrade (stops Traefik, starts kamal-proxy)
kamal upgrade --rolling             # Zero-downtime upgrade
# kamal downgrade                   # Reverse if needed
```
