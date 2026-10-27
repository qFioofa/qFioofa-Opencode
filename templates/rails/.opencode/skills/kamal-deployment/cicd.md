# CI/CD with Kamal

## GitHub Actions: Test and Deploy

```yaml
# .github/workflows/test_and_deploy.yml
name: Test and Deploy

on:
  push:
    branches:
      - '*'
  pull_request:
    branches:
      - main

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: myapp_test
        ports: ["54320:5432"]
      redis:
        image: redis:7
        ports: ["63790:6379"]
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Install system packages
        run: sudo apt-get update -qq && sudo apt-get install -y libvips-dev
      - name: Setup Ruby and install gems
        uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20
      - name: Setup test database
        env:
          RAILS_ENV: test
        run: bin/rails db:setup
      - name: Run tests
        run: bin/rails test:all

  deploy:
    needs: test
    name: Deploy
    if: ${{ github.event_name == 'push' && github.ref == 'refs/heads/main' }}
    runs-on: ubuntu-latest
    timeout-minutes: 20
    env:
      DOCKER_BUILDKIT: 1
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        id: buildx
        uses: docker/setup-buildx-action@v3

      - name: Setup SSH with a passphrase
        env:
          SSH_AUTH_SOCK: /tmp/ssh_agent.sock
          SSH_PASSPHRASE: ${{ secrets.SSH_PASSPHRASE }}
          SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
        run: |
          ssh-agent -a $SSH_AUTH_SOCK > /dev/null
          echo 'echo $SSH_PASSPHRASE' > ~/.ssh_askpass && chmod +x ~/.ssh_askpass
          echo "$SSH_PRIVATE_KEY" | tr -d '\r' | DISPLAY=None SSH_ASKPASS=~/.ssh_askpass ssh-add - >/dev/null

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      - name: Deploy
        env:
          SSH_AUTH_SOCK: /tmp/ssh_agent.sock
          VERSION: ${{ github.sha }}
          KAMAL_REGISTRY_PASSWORD: ${{ secrets.KAMAL_REGISTRY_PASSWORD }}
          POSTGRES_PASSWORD: ${{ secrets.POSTGRES_PASSWORD }}
          POSTGRES_URL: ${{ secrets.POSTGRES_URL }}
          REDIS_URL: ${{ secrets.REDIS_URL }}
          RAILS_MASTER_KEY: ${{ secrets.RAILS_MASTER_KEY }}
        run: bundle exec kamal deploy --version=$VERSION
```

## Required GitHub Secrets

Set these in your repository under **Settings > Secrets and variables > Actions**:

| Secret | Description |
|--------|-------------|
| `SSH_PRIVATE_KEY` | Private SSH key for server access |
| `SSH_PASSPHRASE` | SSH key passphrase (if set) |
| `KAMAL_REGISTRY_PASSWORD` | Docker registry access token |
| `RAILS_MASTER_KEY` | Rails master key |
| `POSTGRES_PASSWORD` | Database password |
| `POSTGRES_URL` | Full PostgreSQL connection URL |
| `REDIS_URL` | Full Redis connection URL |

## .kamal/secrets for CI

Use variable substitution so secrets come from the CI environment:

```bash
# .kamal/secrets
KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD
RAILS_MASTER_KEY=$RAILS_MASTER_KEY
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_URL=$POSTGRES_URL
REDIS_URL=$REDIS_URL
```

## Builder Cache for CI

Ensure your `deploy.yml` includes cache configuration:

```yaml
builder:
  cache:
    type: registry
    image: myuser/myapp-build-cache
    options: mode=max
```

Or use GitHub Actions cache:

```yaml
builder:
  cache:
    type: gha
```

## Deploy to Specific Destination

```yaml
      - name: Deploy to staging
        run: bundle exec kamal deploy -d staging --version=$VERSION
```

With separate secrets file `.kamal/secrets.staging`.

## Kamal-less Build (Alternative)

Build and push the image in CI, then deploy with `--skip-push`:

```yaml
steps:
  - name: Set up Docker Buildx
    uses: docker/setup-buildx-action@v3
  - name: Login to Docker Hub
    uses: docker/login-action@v3
    with:
      username: myuser
      password: ${{ secrets.KAMAL_REGISTRY_PASSWORD }}
  - name: Build image
    uses: docker/build-push-action@v5
    with:
      context: .
      push: true
      labels: "service=myapp"
      tags: |
        myuser/myapp:latest
        myuser/myapp:${{ github.sha }}
      cache-from: type=gha
      cache-to: type=gha,mode=max
  - name: Deploy
    run: bundle exec kamal deploy --version=${{ github.sha }} --skip-push
```

## Review Apps with Kamal

Use ERB in a separate review app config with dynamic service names from CI variables:

```yaml
# config/deploy.review-app.yml
service: <%= ENV['SERVICE_NAME'] %>

servers:
  web:
    - 192.168.0.1

proxy:
  ssl: true
  host: <%= ENV['APP_HOST'] %>
```

In GitLab CI, use `$CI_COMMIT_REF_SLUG` for dynamic naming. In GitHub Actions, use the branch name.
