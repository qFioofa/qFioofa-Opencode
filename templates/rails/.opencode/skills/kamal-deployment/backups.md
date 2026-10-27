# Database Backups with Kamal

## Automated PostgreSQL Backups to S3

Use the `eeshugerman/postgres-backup-s3` image as a Kamal accessory:

```yaml
# config/deploy.yml
accessories:
  s3_backup:
    image: eeshugerman/postgres-backup-s3:16  # Match your PG major version
    roles:
      - web
    env:
      clear:
        SCHEDULE: "@daily"           # Cron schedule
        BACKUP_KEEP_DAYS: 30         # Retention period
        S3_ENDPOINT: https://s3.amazonaws.com
        S3_BUCKET: myapp-backups
        S3_PREFIX: production
        POSTGRES_HOST: myapp-postgres  # Container name on kamal network
        POSTGRES_DATABASE: myapp_production
        POSTGRES_USER: myapp
        PGDUMP_EXTRA_OPTS: "--exclude-table-data=solid_cache_entries"
      secret:
        - POSTGRES_PASSWORD
        - S3_ACCESS_KEY_ID
        - S3_SECRET_ACCESS_KEY
```

### Manual Operations

```bash
# Trigger immediate backup
kamal accessory exec s3_backup "sh backup.sh"

# Restore latest backup
kamal accessory exec s3_backup "sh restore.sh"
```

### S3-Compatible Storage Options

- **AWS S3**: `https://s3.amazonaws.com`
- **Backblaze B2**: `https://s3.us-west-000.backblazeb2.com`
- **Cloudflare R2**: `https://[ACCOUNT_ID].r2.cloudflarestorage.com`
- **DigitalOcean Spaces**: `https://[REGION].digitaloceanspaces.com`
- **Scaleway Object Storage**: `https://s3.[REGION].scw.cloud`

## PostgreSQL Major Version Upgrades

Major version upgrades require a dump/restore cycle because data directories are incompatible:

1. **Enable maintenance mode** - stop the application
   ```bash
   kamal app stop  # Or scale down
   ```

2. **Create final backup**
   ```bash
   kamal accessory exec s3_backup "sh backup.sh"
   ```

3. **Update configuration** - change image tag and create new data volume
   ```yaml
   accessories:
     postgres:
       image: postgres:17  # New version
       directories:
         - data_17:/var/lib/postgresql/data  # New volume name!
   ```

4. **Remove old accessory and boot new one**
   ```bash
   kamal accessory remove postgres
   kamal accessory boot postgres
   ```

5. **Restore backup into new instance**
   ```bash
   kamal accessory exec s3_backup "sh restore.sh"
   ```

6. **Restart the application**
   ```bash
   kamal deploy
   ```

**Never** just change the image tag and reboot - the old data directory won't be compatible with the new major version.

## Migrating Database from PaaS to Kamal

1. Deploy your app on the new VPS (database will be empty)
2. Set up S3-compatible storage for the dump
3. Enable maintenance mode on your PaaS (scale containers to 0)
4. Generate a database dump from PaaS tools
5. Upload dump to S3
6. Restore on your Kamal accessory:
   ```bash
   kamal accessory exec s3_backup "sh restore.sh"
   ```
7. Verify data integrity
8. Update DNS to point to new server

## Alternative: kartoza/pg-backup for S3

```yaml
accessories:
  pg_backup:
    image: kartoza/pg-backup:16
    roles:
      - web
    env:
      clear:
        POSTGRES_HOST: myapp-postgres
        POSTGRES_PORT: 5432
        DUMPPREFIX: myapp
        CRON_SCHEDULE: "0 2 * * *"  # 2 AM daily
        REMOVE_BEFORE: 30           # Days to keep
        STORAGE_BACKEND: S3
        ACCESS_KEY_ID: xxx
        SECRET_ACCESS_KEY: xxx
        DEFAULT_TARGET_BUCKET: s3://myapp-backups/
      secret:
        - POSTGRES_PASS
```

## Docker Volume Backups

For backing up Docker volumes directly:

```bash
# Backup
docker run -d --rm \
  --volumes-from myapp-web \
  -v $(pwd)/backup:/backup \
  ubuntu \
  tar -czvf /backup/backup.tar -C /path/to/data .

# Restore
docker run -d --rm \
  --volumes-from myapp-web \
  -v $(pwd)/backup:/backup \
  ubuntu \
  bash -c "cd /path/to/data && tar -xzvf /backup/backup.tar --strip 1"
```

## Simple Tar Backup (No S3)

```bash
DATE=$(date +'%d-%m-%Y')
tar --same-permissions -czvf backup-$DATE.tar.gz /path/to/directory
scp backup-$DATE.tar.gz user@backup-host:/backups
```
