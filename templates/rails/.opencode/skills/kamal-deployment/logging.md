# Logging & Monitoring with Kamal

## Application Logging

### Rails Configuration for Structured Logging

```ruby
# config/environments/production.rb
config.logger = ActiveSupport::Logger.new(STDOUT)

# Add lograge for structured JSON logs
config.lograge.enabled = true
config.lograge.formatter = Lograge::Formatters::Json.new
```

Logging to STDOUT ensures Docker captures all output for Kamal to access.

### Viewing Logs

```bash
# All application logs
kamal app logs

# Follow logs in real time
kamal app logs -f

# Logs for specific role
kamal app logs -r web
kamal app logs -r job

# Logs for specific host
kamal app logs -h 192.168.0.1

# Grep logs
kamal app logs -g "error" -s 50m -n 100

# Accessory logs
kamal accessory logs postgres
kamal accessory logs redis

# Proxy logs
kamal proxy logs
```

### Log Options

| Flag | Description |
|------|-------------|
| `-f` | Follow logs (tail) |
| `-r/--roles` | Filter by role (`web`, `job`) |
| `-d/--destination` | Filter by destination (`staging`) |
| `-g/--grep` | Grep log lines for text |
| `-o/--grep-options` | Pass options to grep (e.g., `-A 5`) |
| `-n/--lines` | Limit number of lines |
| `-s/--since` | Time duration (e.g., `50m`, `2h`) |
| `-h` | Specific host or list of hosts |

## Docker Log Configuration

```yaml
# config/deploy.yml
logging:
  driver: json-file
  options:
    max-size: 10m          # Max file size before rotation
    max-file: 3            # Number of rotated files to keep
    labels: service        # Include container labels in logs
```

3 files x 10MB = 30MB max disk space per container.

### Available Log Drivers

| Driver | Use Case |
|--------|----------|
| `json-file` | Default, good for most setups |
| `local` | Minimal overhead, custom format |
| `journald` | System logging integration |
| `awslogs` | Amazon CloudWatch |
| `gcplogs` | Google Cloud Platform |
| `none` | Disable logging |

### Per-Role Logging

```yaml
servers:
  web:
    hosts:
      - 165.232.112.197
    logging:
      driver: local
      options:
        max-size: 100M
  job:
    hosts:
      - 165.232.112.198
    logging:
      driver: local
      options:
        max-size: 10M
```

## Vector Log Aggregation

Use Vector as a Kamal accessory to collect, transform, and ship logs to external services.

### Accessory Configuration

```yaml
# config/deploy.yml
accessories:
  vector:
    image: timberio/vector:latest-alpine
    roles:
      - web
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    files:
      - config/vector/vector.yaml:/etc/vector/vector.yaml
```

### Vector Pipeline Configuration

```yaml
# config/vector/vector.yaml
sources:
  docker:
    type: docker_logs

transforms:
  parse_logs:
    type: remap
    inputs: ["docker"]
    source: |
      payload, err = parse_json(string!(.message))
      if err == null {
        .payload = payload
        del(.message)
      }

sinks:
  # Example: Honeybadger Insights
  honeybadger_events:
    type: http
    inputs: ["parse_logs"]
    uri: "https://api.honeybadger.io/v1/events"
    request:
      headers:
        X-API-Key: "${HONEYBADGER_API_KEY}"
    encoding:
      codec: json
    framing:
      method: newline_delimited

  # Example: stdout for debugging
  console:
    type: console
    inputs: ["parse_logs"]
    encoding:
      codec: json
```

### Deploy Vector

```bash
kamal env push
kamal accessory reboot vector
```

The Docker socket mount allows Vector to monitor all container logs on the host automatically.
