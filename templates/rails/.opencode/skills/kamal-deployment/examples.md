# Kamal Deployment Examples

## Single Server: Rails + PostgreSQL + Redis + Sidekiq + Backups

Everything on one VPS with automatic SSL via Let's Encrypt.

### deploy.yml

```yaml
# config/deploy.yml
service: myapp
image: myuser/myapp

volumes:
  - "/storage:/rails/storage"

ssh:
  user: deploy

servers:
  web:
    hosts:
      - 170.64.149.226
  job:
    hosts:
      - 170.64.149.226
    cmd: bundle exec sidekiq -q default -q mailers

registry:
  username: myuser
  password:
    - KAMAL_REGISTRY_PASSWORD

proxy:
  ssl: true
  host: app.example.com

builder:
  arch: amd64
  cache:
    type: registry
    image: myuser/myapp-build-cache
    options: mode=max

env:
  clear:
    HOST: app.example.com
    RAILS_SERVE_STATIC_FILES: true
    RAILS_LOG_TO_STDOUT: true
    DB_HOST: myapp-postgres
    REDIS_URL: "redis://myapp-redis:6379/0"
  secret:
    - RAILS_MASTER_KEY
    - POSTGRES_PASSWORD

asset_path: /rails/public/assets

accessories:
  postgres:
    image: postgres:16
    roles:
      - web
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

  redis:
    image: redis:7
    roles:
      - web
    cmd: redis-server
    directories:
      - data:/data

  s3_backup:
    image: eeshugerman/postgres-backup-s3:16
    roles:
      - web
    env:
      clear:
        SCHEDULE: "@daily"
        BACKUP_KEEP_DAYS: 30
        S3_ENDPOINT: https://s3.amazonaws.com
        S3_BUCKET: myapp-backups
        S3_PREFIX: production
        POSTGRES_HOST: myapp-postgres
        POSTGRES_DATABASE: myapp_production
        POSTGRES_USER: myapp
      secret:
        - POSTGRES_PASSWORD
        - S3_ACCESS_KEY_ID
        - S3_SECRET_ACCESS_KEY
```

### .kamal/secrets

```bash
KAMAL_REGISTRY_PASSWORD="dckr_pat_xxx"
RAILS_MASTER_KEY=$(cat config/master.key)
POSTGRES_PASSWORD="secure-password-here"
S3_ACCESS_KEY_ID="xxx"
S3_SECRET_ACCESS_KEY="xxx"
```

### database.yml

```yaml
production:
  adapter: postgresql
  host: <%= ENV["DB_HOST"] %>
  database: myapp_production
  username: myapp
  password: <%= ENV["POSTGRES_PASSWORD"] %>
```

### production.rb

```ruby
Rails.application.configure do
  config.assume_ssl = true
  config.force_ssl = true
  config.logger = ActiveSupport::Logger.new(STDOUT)
  config.cache_store = :redis_cache_store, { url: ENV.fetch('REDIS_URL') }
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
```

### Deployment Commands

```bash
# First time
kamal setup

# Boot accessories separately if needed
kamal accessory boot all

# Subsequent deploys
kamal deploy

# Console access
kamal app exec -i 'bin/rails console'

# Database backup
kamal accessory exec s3_backup "sh backup.sh"
kamal accessory exec s3_backup "sh restore.sh"
```

---

## Multi-Server: Behind Load Balancer on Private Network

Separate servers for web, jobs, database, and Redis behind a managed load balancer.

### deploy.yml

```yaml
# config/deploy.yml
service: myapp
image: myuser/myapp

volumes:
  - "/storage:/rails/storage"

ssh:
  user: deploy

servers:
  web:
    hosts:
      - 192.168.0.1      # Private IP, app server 1
      - 192.168.0.2      # Private IP, app server 2
  job:
    hosts:
      - 192.168.0.2
    cmd: bundle exec sidekiq -q default -q mailers

registry:
  username: myuser
  password:
    - KAMAL_REGISTRY_PASSWORD

builder:
  arch: amd64
  cache:
    type: registry
    image: myuser/myapp-build-cache
    options: mode=max

env:
  clear:
    HOST: app.example.com
    RAILS_SERVE_STATIC_FILES: true
    RAILS_LOG_TO_STDOUT: true
  secret:
    - RAILS_MASTER_KEY
    - POSTGRES_URL
    - REDIS_URL

asset_path: /rails/public/assets

accessories:
  postgres:
    image: postgres:16
    hosts:
      - 192.168.0.3
    port: 5432
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

  redis:
    image: redis:7
    hosts:
      - 192.168.0.4
    port: 6379
    cmd: "redis-server --requirepass <%= File.read('.kamal/secrets')[/REDIS_PASSWORD=\"(.*?)\"/, 1] %>"
    directories:
      - data:/data
```

### .kamal/secrets

```bash
KAMAL_REGISTRY_PASSWORD="dckr_pat_xxx"
RAILS_MASTER_KEY=$(cat config/master.key)
POSTGRES_PASSWORD="secure-password"
REDIS_PASSWORD="secure-password"
POSTGRES_URL="postgres://myapp:secure-password@192.168.0.3:5432/myapp_production"
REDIS_URL="redis://:secure-password@192.168.0.4:6379/1"
```

### Load Balancer Setup

1. Choose the same VPC as your servers
2. Set IP addresses to your web server IPs
3. Direct HTTPS (443) to Kamal Proxy (80)
4. Health check: HTTP on port 80, path `/up`
5. Point DNS A record to load balancer IP

With a load balancer handling SSL, set `ssl: false` in proxy config:

```yaml
proxy:
  ssl: false
  host: app.example.com
  forward_headers: true  # Preserve real client IPs
```

---

## Multiple Apps on One Server

Each app gets its own `config/deploy.yml` pointing to the same server IP with a different service name and domain:

```yaml
# App 1: config/deploy.yml
service: blog
image: myuser/blog

servers:
  web:
    - 170.64.149.226

proxy:
  ssl: true
  host: blog.example.com
```

```yaml
# App 2: config/deploy.yml
service: store
image: myuser/store

servers:
  web:
    - 170.64.149.226

proxy:
  ssl: true
  host: store.example.com
```

Kamal Proxy routes traffic based on the `host` setting. Each app is managed independently.

---

## Staging + Production with Destinations

```yaml
# config/deploy.yml (shared base)
service: myapp
image: myuser/myapp
# ... common config ...

# config/deploy.staging.yml
servers:
  web:
    hosts:
      - 165.232.112.195
proxy:
  host: staging.example.com

# config/deploy.production.yml
servers:
  web:
    hosts:
      - 165.232.112.197
proxy:
  host: app.example.com
```

```bash
kamal setup -d staging
kamal deploy -d production
```

---

## Server Provisioning Script

A Ruby script to provision Ubuntu servers for Kamal:

```ruby
#!/usr/bin/env ruby
# ./provision
require "net/ssh"
require "kamal"

config_file = Pathname.new(File.expand_path("config/deploy.yml"))
config = Kamal::Configuration.create_from(config_file: config_file)
hosts = config.roles.map(&:hosts).flatten + config.accessories.map(&:hosts).flatten
hosts.uniq!
user_name = config.ssh.user

install_essentials = <<~EOF
  apt update && apt install -y build-essential curl
EOF

prepare_storage = <<~EOF
  mkdir -p /storage;
  chmod 700 /storage;
  chown 1000:1000 /storage
EOF

add_swap = <<~EOF
  fallocate -l 2GB /swapfile;
  chmod 600 /swapfile;
  mkswap /swapfile;
  swapon /swapfile;
  echo "\\n/swapfile swap swap defaults 0 0\\n" >> /etc/fstab;
  sysctl vm.swappiness=20;
  echo "\\nvm.swappiness=20\\n" >> /etc/sysctl.conf
EOF

add_user = <<~EOF
  useradd --create-home #{user_name};
  usermod -s /bin/bash #{user_name};
  su - #{user_name} -c 'mkdir -p ~/.ssh';
  su - #{user_name} -c 'touch ~/.ssh/authorized_keys';
  cat /root/.ssh/authorized_keys >> /home/#{user_name}/.ssh/authorized_keys;
  chmod 700 /home/#{user_name}/.ssh;
  chmod 600 /home/#{user_name}/.ssh/authorized_keys;
  echo '#{user_name} ALL=(ALL:ALL) NOPASSWD: ALL' | tee /etc/sudoers.d/#{user_name};
  chmod 0440 /etc/sudoers.d/#{user_name};
  visudo -c -f /etc/sudoers.d/#{user_name}
EOF

install_fail2ban = <<~EOF
  apt install -y fail2ban;
  systemctl start fail2ban;
  systemctl enable fail2ban
EOF

configure_firewall = <<~EOF
  ufw logging on;
  ufw default deny incoming;
  ufw default allow outgoing;
  ufw allow 22;
  ufw allow 80;
  ufw allow 443;
  ufw --force enable;
  systemctl restart ufw
EOF

disable_root = <<~EOF
  sed -i 's@PasswordAuthentication yes@PasswordAuthentication no@g' /etc/ssh/sshd_config;
  sed -i 's@PermitRootLogin yes@PermitRootLogin no@g' /etc/ssh/sshd_config;
  chage -E 0 root;
  systemctl restart ssh
EOF

hosts.each do |host|
  Net::SSH.start(host, "root") do |ssh|
    ssh.exec!(install_essentials)
    ssh.exec!(add_swap)
    ssh.exec!(prepare_storage)
    ssh.exec!(add_user)
    ssh.exec!(install_fail2ban)
    ssh.exec!(configure_firewall)
    ssh.exec!(disable_root)
  end
end
```
