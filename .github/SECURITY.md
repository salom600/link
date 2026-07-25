# LinkOS Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in LinkOS:

1. **DO NOT** open a public issue
2. Email: security@example.com (replace with your email)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Affected versions
   - Suggested fix (if any)

We will acknowledge receipt within 48 hours and provide a fix timeline within 7 days.

## Default Credentials

The LinkOS live ISO uses these default credentials:

| User | Password |
|---|---|
| `linkos` | `linkos` |
| `root` | `linkos` |

**⚠️ These are for the LIVE ISO only.** The Calamares installer requires you to set a new password during installation. Never leave the default password on an installed system.

## Hardening Recommendations

After installation:

```bash
# 1. Set a strong root password
sudo passwd root

# 2. Disable root SSH login
sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# 3. Enable the firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable

# 4. Install fail2ban (optional)
sudo pacman -S fail2ban
sudo systemctl enable --now fail2ban

# 5. Enable AppArmor
sudo systemctl enable --now apparmor
```

## Token Rotation

If a GitHub Personal Access Token (PAT) used in CI is leaked:

1. Immediately revoke at https://github.com/settings/tokens
2. Generate a new token
3. Update all GitHub Secrets that referenced it
4. Audit Actions runs for unauthorized activity
5. Force-push to retrigger all workflow runs
