# GitHub Actions CI/CD Pipeline Documentation

Complete documentation for the Gemstone Management App CI/CD pipeline.

---

## Overview

The CI/CD pipeline automates the build, test, and release process for the Flutter Android app using GitHub Actions.

### Pipeline Features

- **Automatic Builds**: Build on every push to main/develop
- **Pull Request Checks**: Validate code before merging
- **Release Automation**: Create releases with signed APKs
- **Artifact Storage**: Store APKs for 7-30 days
- **Release Notes**: Auto-generate release documentation

---

## Workflow Files

### 1. build-apk.yml

**Purpose**: Automatic build on push and pull requests

**Triggers**:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual trigger (workflow_dispatch)

**Steps**:
1. Checkout code
2. Setup Java 11
3. Setup Flutter 3.19.0
4. Get dependencies
5. Run analysis
6. Run tests
7. Build debug APK
8. Build release APK
9. Upload artifacts
10. Create release (on tags)

**Artifacts**:
- `gemstone-app-debug` (7 days)
- `gemstone-app-release` (30 days)

### 2. build-signed-apk.yml

**Purpose**: Manual signed release build

**Triggers**:
- Manual trigger with version input (workflow_dispatch)

**Steps**:
1. Checkout code
2. Setup Java 11
3. Setup Flutter 3.19.0
4. Get dependencies
5. Create keystore from secrets
6. Build release APK (signed)
7. Build App Bundle (AAB)
8. Upload artifacts
9. Create release notes
10. Create GitHub Release

**Artifacts**:
- Signed APK
- App Bundle (AAB)
- Release notes

**Secrets Required**:
- `KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`
- `KEY_PASSWORD`

---

## Setup Instructions

### Step 1: Create GitHub Repository

```bash
# Create repository on GitHub
# Clone to local machine
git clone https://github.com/yourusername/gemstone-management.git
cd gemstone-management
```

### Step 2: Add Workflow Files

Workflow files are already in `.github/workflows/`:
- `.github/workflows/build-apk.yml`
- `.github/workflows/build-signed-apk.yml`

### Step 3: Configure Secrets

1. Go to repository **Settings**
2. Click **Secrets and variables** → **Actions**
3. Add secrets:

```
KEYSTORE_BASE64 = <base64 encoded keystore>
KEYSTORE_PASSWORD = <your password>
KEY_ALIAS = gemstone-app-key
KEY_PASSWORD = <your password>
```

### Step 4: Push Code

```bash
git add .
git commit -m "Initial commit with CI/CD pipeline"
git push origin main
```

### Step 5: Verify Workflow

1. Go to **Actions** tab
2. Monitor build progress
3. Check logs for errors

---

## Usage

### Automatic Build (On Push)

```bash
# Make changes
git add .
git commit -m "Update feature"
git push origin main

# Workflow automatically triggers
# Check Actions tab for progress
```

### Manual Build

1. Go to **Actions** tab
2. Select **Build Android APK**
3. Click **Run workflow**
4. Wait for completion
5. Download artifacts

### Create Release

```bash
# Create tag
git tag -a v1.0.0 -m "Release v1.0.0"

# Push tag
git push origin v1.0.0

# Workflow automatically:
# - Builds signed APK
# - Creates release
# - Uploads files
```

---

## Workflow Configuration

### Flutter Version

Update in workflow file:

```yaml
- uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.19.0'  # Change version here
    channel: 'stable'
```

### Build Targets

Modify build command:

```yaml
flutter build apk --release \
  --target-platform android-arm64 \
  --split-per-abi
```

### Artifact Retention

Change retention days:

```yaml
retention-days: 30  # Change days here
```

### Notifications

Add Slack/Discord notifications:

```yaml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
```

---

## Monitoring

### View Build Status

1. Go to **Actions** tab
2. See all workflow runs
3. Click run for details
4. Check logs

### Download Artifacts

1. Select workflow run
2. Scroll to **Artifacts**
3. Download desired artifact

### View Releases

1. Go to **Releases** tab
2. See all releases
3. Download APK/AAB

---

## Troubleshooting

### Build Fails: "Flutter not found"

**Check**: Workflow uses correct Flutter version

```yaml
flutter-version: '3.19.0'
```

**Solution**: Update to latest stable version

### Build Fails: "Dependency not found"

**Check**: pubspec.yaml has all dependencies

```bash
flutter pub get
```

**Solution**: Update dependencies

### Build Fails: "Signing error"

**Check**: Secrets are configured correctly

```bash
gh secret list
```

**Solution**: Verify keystore and passwords

### APK not in artifacts

**Check**: Build output path

```yaml
path: frontend/build/app/outputs/flutter-apk/
```

**Solution**: Verify path matches build output

### Workflow not triggering

**Check**: Branch name and trigger conditions

```yaml
on:
  push:
    branches:
      - main
      - develop
```

**Solution**: Push to correct branch

---

## Best Practices

### 1. Branch Strategy

```
main (production)
  ↑
develop (staging)
  ↑
feature/* (development)
```

### 2. Commit Messages

```
feat: Add new feature
fix: Fix bug
docs: Update documentation
chore: Update dependencies
```

### 3. Version Numbering

```
v1.0.0 (major.minor.patch)
v1.0.0-beta (pre-release)
v1.0.0-rc.1 (release candidate)
```

### 4. Release Process

1. Create release branch
2. Update version in pubspec.yaml
3. Create pull request
4. Merge to main
5. Create git tag
6. Workflow creates release

### 5. Security

- Keep secrets secure
- Rotate keystore periodically
- Use branch protection rules
- Require code review
- Enable status checks

---

## Performance Optimization

### Build Time Reduction

1. **Cache dependencies**:
   ```yaml
   - uses: actions/cache@v3
     with:
       path: ~/.pub-cache
       key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
   ```

2. **Parallel builds**:
   ```yaml
   strategy:
     matrix:
       include:
         - arch: arm64-v8a
         - arch: armeabi-v7a
   ```

3. **Skip tests on PR**:
   ```yaml
   if: github.event_name != 'pull_request'
   ```

### Storage Optimization

1. **Limit artifact retention**:
   ```yaml
   retention-days: 7
   ```

2. **Delete old artifacts**:
   ```bash
   gh run list --status completed --limit 100 | \
     awk '{print $1}' | xargs -I {} gh run delete {}
   ```

---

## Integration with Other Services

### Slack Notifications

```yaml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "Build ${{ job.status }}",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Build Status*: ${{ job.status }}"
            }
          }
        ]
      }
```

### Email Notifications

```yaml
- name: Send Email
  uses: dawidd6/action-send-mail@v3
  with:
    server_address: smtp.gmail.com
    server_port: 465
    username: ${{ secrets.EMAIL_USERNAME }}
    password: ${{ secrets.EMAIL_PASSWORD }}
    subject: Build ${{ job.status }}
    body: Check GitHub Actions for details
    to: team@example.com
```

### Google Play Store Upload

```yaml
- name: Upload to Play Store
  uses: r0adkll/upload-google-play@v1
  with:
    serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_KEY }}
    packageName: com.gemstone.app
    releaseFiles: build/app/outputs/bundle/release/app-release.aab
    track: internal
```

---

## Maintenance

### Update Flutter Version

1. Check latest Flutter version
2. Update workflow file
3. Test build locally
4. Commit and push
5. Verify workflow passes

### Update Dependencies

```bash
flutter pub upgrade
git add pubspec.lock
git commit -m "Update dependencies"
git push origin main
```

### Rotate Keystore

Every 2-3 years:
1. Generate new keystore
2. Update GitHub secrets
3. Release new version
4. Notify users

### Monitor Costs

GitHub Actions free tier includes:
- 2,000 minutes/month
- 500MB storage
- Sufficient for most projects

---

## Advanced Configuration

### Matrix Builds

Build for multiple architectures:

```yaml
strategy:
  matrix:
    arch: [arm64-v8a, armeabi-v7a, x86_64]
steps:
  - run: flutter build apk --target-platform android-${{ matrix.arch }}
```

### Conditional Steps

```yaml
- name: Build Release
  if: startsWith(github.ref, 'refs/tags/')
  run: flutter build apk --release
```

### Environment Variables

```yaml
env:
  FLUTTER_VERSION: 3.19.0
  JAVA_VERSION: 11
  API_BASE_URL: https://api.gemstone-app.com
```

---

## Troubleshooting Checklist

- [ ] Secrets configured correctly
- [ ] Workflow file syntax valid
- [ ] Branch name matches trigger
- [ ] Flutter version available
- [ ] Dependencies installed
- [ ] Build command correct
- [ ] Artifact path correct
- [ ] Permissions set correctly
- [ ] Keystore valid
- [ ] Passwords correct

---

## Support

For issues:
1. Check GitHub Actions logs
2. Review workflow file
3. Verify secrets
4. Test locally
5. Contact support

---

**Last Updated**: May 31, 2026
**Version**: 1.0.0
