# Server Hardening for Kamal

Kamal installs Docker on your servers but does NOT secure them. You must harden servers before deploying to production.

## Quick Checklist

- [ ] Create non-root user with sudo access
- [ ] Disable root SSH login
- [ ] Disable password authentication
- [ ] Install and configure UFW firewall
- [ ] Install fail2ban
- [ ] Add swap space (2GB recommended for small VPS)
- [ ] Prepare storage directory
- [ ] Set up SSH keys

## Non-Root User Setup

```bash
# On Ubuntu
useradd --create-home deploy
usermod -s /bin/bash deploy
su - deploy -c 'mkdir -p ~/.ssh'
su - deploy -c 'touch ~/.ssh/authorized_keys'
cat /root/.ssh/authorized_keys >> /home/deploy/.ssh/authorized_keys
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys
echo 'deploy ALL=(ALL:ALL) NOPASSWD: ALL' | tee /etc/sudoers.d/deploy
chmod 0440 /etc/sudoers.d/deploy
visudo -c -f /etc/sudoers.d/deploy
```

Then in `deploy.yml`:
```yaml
ssh:
  user: deploy
```

## Disable Root Login

```bash
sed -i 's@PasswordAuthentication yes@PasswordAuthentication no@g' /etc/ssh/sshd_config
sed -i 's@PermitRootLogin yes@PermitRootLogin no@g' /etc/ssh/sshd_config
chage -E 0 root
systemctl restart ssh
```

## Firewall (UFW)

```bash
ufw logging on
ufw default deny incoming
ufw default allow outgoing
ufw allow 22     # SSH
ufw allow 80     # HTTP
ufw allow 443    # HTTPS
ufw --force enable
systemctl restart ufw
```

**Warning**: Closing ports in UFW is NOT sufficient for Docker containers. Docker manipulates iptables directly, and its rules take precedence over UFW. Use cloud provider firewalls for additional protection.

## Fail2ban

```bash
apt install -y fail2ban
systemctl start fail2ban
systemctl enable fail2ban
```

## Swap Space

Recommended for VPS with limited RAM to prevent OOM during deploys:

```bash
fallocate -l 2GB /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
sysctl vm.swappiness=20
echo "vm.swappiness=20" >> /etc/sysctl.conf
```

## Storage Directory

If using local file storage instead of S3:

```bash
mkdir -p /storage
chmod 700 /storage
chown 1000:1000 /storage   # UID 1000 = first non-root user in container
```

## SSH Key Generation

```bash
ssh-keygen -t ed25519 -C "admin@example.com"
```

Use the public key when creating VPS instances. Never use password-based SSH auth.

## Cloud Provider Firewalls

For additional security, use cloud provider firewalls (AWS Security Groups, DigitalOcean Cloud Firewalls, etc.):

- Allow SSH (22) only from your IP / VPN
- Allow HTTP (80) and HTTPS (443) from anywhere (or from load balancer only)
- Deny everything else

## VPN for Private Networks

For multi-server setups on private networks:

1. Set up an OpenVPN access server as a bridge
2. Configure routing to your private IP ranges
3. Reference servers by private IPs in `deploy.yml`
4. Restrict firewall to SSH-only from public internet

A VPN gives you access to the private network but doesn't prevent public access to those servers - always combine with firewalls.
