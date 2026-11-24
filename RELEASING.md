# Releasing Tally

Releases are built and signed by GitHub Actions ([`.github/workflows/release.yml`](.github/workflows/release.yml))
when a version tag is pushed. The workflow runs the tests, builds the per-ABI and universal APKs with the release
key, checks they aren't debug-signed, and attaches them to a **draft** release whose notes come from
`CHANGELOG.md`. Nothing reaches users until you press **Publish** on the draft. The in-app update notice only sees
published releases.

## One-time setup: signing secrets

The workflow needs the release keystore and its passwords as repository secrets. Run these from PowerShell in the
repository folder. `gh secret set` asks for each password, so it never ends up in your shell history.

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\slayer-iptv-release.jks")) | gh secret set ANDROID_KEYSTORE_BASE64
```

```powershell
gh secret set ANDROID_KEYSTORE_PASSWORD
```

```powershell
gh secret set ANDROID_KEY_PASSWORD
```

```powershell
gh secret set ANDROID_KEY_ALIAS --body slayer
```

`ANDROID_KEY_PASSWORD` can be left out when it's the same as the keystore password.

Keep the original `.jks` file and passwords backed up somewhere safe. Android only installs updates signed with the
same key; a lost key means people have to uninstall and reinstall.

## Each release

1. Bump `version` in `pubspec.yaml` (for example `0.1.2+3`) and `appVersion` in `lib/app_info.dart`. A test fails
   if they differ.
2. In `CHANGELOG.md`, rename `## Unreleased` to `## 0.1.2 (YYYY-MM-DD)`.
3. Commit, then tag and push:

   ```powershell
   git tag v0.1.2
   ```

   ```powershell
   git push origin main v0.1.2
   ```

4. Wait for the **Release** workflow to finish, open the draft on the Releases page, read it over and press
   **Publish**.

If the workflow fails because the tag and `pubspec.yaml` disagree or the changelog section is missing, fix it, then
move the tag: `git tag -f v0.1.2` and `git push -f origin v0.1.2`.
