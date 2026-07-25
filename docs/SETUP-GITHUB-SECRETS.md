# 🔐 Setting up GitHub Secrets & First Build

This guide walks you through configuring your `salom600/link` repository to run the automated ISO build pipeline.

---

## ⚠️ IMPORTANT: Rotate Your Token First

You shared a GitHub Personal Access Token (PAT) in plain text in our chat. **This token must be considered compromised.** Take these steps immediately:

1. Go to https://github.com/settings/tokens
2. Find the token starting with `ghp_...`
3. Click **Delete** to revoke it
4. Generate a new token (classic) with scope `repo` only
5. Store the new token **only** in GitHub Secrets (never in chat / commit messages / code)

---

## 🗂 Step 1 — Configure Repository Settings

In your browser, go to: **https://github.com/salom600/link/settings**

### 1.1 Actions Permissions
1. Click **Actions** → **General** (left sidebar)
2. Under **Actions permissions**, select **Allow all actions and reusable workflows**
3. Under **Workflow permissions**, choose:
   - ✅ **Read and write permissions** (required for `gh release create`)
   - ✅ **Allow GitHub Actions to create and approve pull requests**
4. Click **Save**

### 1.2 Default Branch
1. Click **Branches** (left sidebar)
2. Ensure `main` is the default branch
3. Add a branch protection rule for `main`:
   - Branch name pattern: `main`
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - Status checks: `Build ISO (archiso)`
   - Click **Create**

---

## 🔑 Step 2 — Configure GitHub Secrets

The workflow uses only the built-in `GITHUB_TOKEN` (auto-provided, no manual secret needed). You do **not** need to add any custom secrets for the basic build.

However, if you want to push the ISO to an **external release** (e.g., a fork, or another storage provider), add these optional secrets:

### 2.1 (Optional) Custom AUR helper token
If you want to enable private AUR packages:
1. Go to **Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Name: `AUR_TOKEN`
4. Value: a GitHub PAT with `repo` scope
5. Click **Add secret**

### 2.2 (Optional) External upload target
For uploading to S3 / R2 / etc.:
- Add `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `S3_BUCKET`, etc.

**For the default workflow, you don't need any of these.** The `GITHUB_TOKEN` is auto-injected by GitHub Actions and has `contents: write` permission (configured in the workflow).

---

## 🚀 Step 3 — Trigger the First Build

Once the repository is pushed (covered in the main README), three triggers fire the workflow:

### Option A — Push to `main` (Rolling Nightly)
```bash
git clone https://github.com/salom600/link.git
cd link
echo "# LinkOS" > README.md
git add .
git commit -m "feat: initial LinkOS repository"
git push origin main
```
A build starts automatically. On success, a **rolling nightly release** is published at:
**https://github.com/salom600/link/releases/tag/nightly**

### Option B — Tagged Release (Stable)
```bash
git tag -a v1.0.0 -m "LinkOS v1.0.0 — first stable release"
git push origin v1.0.0
```
A build starts. On success, a **stable release** is published at:
**https://github.com/salom600/link/releases/tag/v1.0.0**

### Option C — Manual Trigger (UI)
1. Go to **https://github.com/salom600/link/actions/workflows/build.yml**
2. Click **Run workflow** (top-right)
3. Choose branch: `main`
4. Click **Run workflow**

---

## 📊 Step 4 — Monitor the Build

1. Go to **https://github.com/salom600/link/actions**
2. Click the topmost run
3. Watch the live log under **Build ISO (archiso) → Build ISO with mkarchiso**

### Expected timings (first build, cold cache)
| Stage | Time |
|---|---|
| Bootstrap | 1–2 min |
| Checkout | 5–10 sec |
| Cache restore | 5–10 sec |
| Install deps | 2–3 min |
| Add chaotic-aur | 1–2 min |
| **mkarchiso build** | **1.5–3 hours** |
| Checksum | 1 min |
| Upload artifact | 5–10 min (2–3 GB ISO) |
| **Total** | **~2–4 hours** |

### Expected timings (subsequent builds, warm cache)
| Stage | Time |
|---|---|
| Bootstrap | 1–2 min |
| Checkout | 5–10 sec |
| **Cache restore** | **2–3 min** (vs cold) |
| Install deps | 30 sec |
| Add chaotic-aur | 30 sec |
| **mkarchiso build** | **30–60 min** |
| Checksum | 1 min |
| Upload artifact | 5–10 min |
| **Total** | **~45–90 min** |

---

## 📥 Step 5 — Download the ISO

### From a tag/release
1. Go to **https://github.com/salom600/link/releases**
2. Click the desired release
3. Download `linkos-YYYY.MM.DD-x86_64.iso` (and optionally the `.sha256` file)
4. Verify:
   ```bash
   sha256sum -c linkos-*.iso.sha256
   ```

### From an Actions run (PR or non-release push)
1. Go to the specific run: **https://github.com/salom600/link/actions**
2. Scroll to **Artifacts** at the bottom
3. Click `linkos-iso-<run-id>` to download a ZIP containing the ISO
4. Unzip and verify the checksum

---

## 🐛 Troubleshooting

### "Build timeout" (6h limit exceeded)
- Check the log to find the slow step
- Likely cause: chaotic-aur mirror is slow/down → remove `[chaotic-aur]` from `pacman.conf` (but you'll lose pre-built Brave/Proton-GE)
- Alternative: lower `compression-level=15` to `compression-level=10` (faster, larger ISO)

### "Package not found: brave-bin"
- Make sure chaotic-aur is in `pacman.conf`
- Verify the keyring step succeeded in CI logs

### "permission denied" on `gh release create`
- Workflow permissions must include `contents: write` (set in Step 1.1)
- The workflow already declares `permissions: contents: write` at the top

### ISO boots but Calamares fails
- Check `/var/log/calamares/` on the live system
- Common: `partition.conf` schema mismatch with installed Calamares version
- Fix: pin Calamares version in `packages.x86_64` (e.g., `calamares=3.3.0-1`)

### ISO too large (>4 GB)
- Reduce package list (remove `libreoffice-fresh`, `gimp`, `kdenlive`)
- Use `xz` compression instead of `zstd` (smaller but slower — risky for 6h limit)

---

## 🔄 Updating the Workflow

To change build behavior, edit `.github/workflows/build.yml`:

| Want | Change |
|---|---|
| Faster build (larger ISO) | `compression-level=10` → `compression-level=3` |
| Smaller ISO (slower build) | Replace `-c zstd` with `-c xz` |
| Different release tag | Edit `steps.tag.outputs.tag` |
| Trigger on PRs only | Remove `push:` trigger |
| Build on schedule | Add `schedule: - cron: '0 0 * * 0'` (weekly) |

---

## ❓ Need Help?

- Open an issue: https://github.com/salom600/link/issues
- Check existing CI runs for known issues: https://github.com/salom600/link/actions
- Archiso docs: https://wiki.archlinux.org/title/Archiso
