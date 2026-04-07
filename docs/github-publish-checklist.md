# GitHub Publish Checklist

## Purpose

This checklist explains how to connect the local `k6-organization` repository to a GitHub remote and push the existing `main` branch.

Assumptions:

- the local repository already exists at `C:\Users\jnipl\projects\k6-organization`
- the repository already has committed work on `main`
- no Git remotes are currently configured

## Recommended Repository Name

Suggested GitHub repository names:

- `k6-organization`
- `k6-system-organization`

## Before Publishing

Check these items before pushing:

1. Run `git status` and confirm the working tree is clean.
2. Review `README.md` so the public repository description and usage guidance are accurate.
3. Confirm that no sensitive local-only paths, secrets, tokens, credentials, or personal data are being published.

## Connect the Remote

Replace `<GITHUB_REPO_URL>` with the actual GitHub repository URL.

```bash
git remote add origin <GITHUB_REPO_URL>
git remote -v
git branch -M main
git push -u origin main
```

## If the Remote Already Exists

If `origin` already exists but points to the wrong repository, update it instead of adding a new remote:

```bash
git remote set-url origin <GITHUB_REPO_URL>
git remote -v
git branch -M main
git push -u origin main
```

## Verify the Remote

After pushing:

1. Run `git remote -v` and confirm `origin` points to the expected GitHub URL.
2. Open the GitHub repository page and confirm the files are visible.
3. Confirm that the default branch shown on GitHub is `main`.
4. Confirm that the latest commit on GitHub matches the latest local commit.

## Exact Commands

For a new remote:

```bash
git remote add origin <GITHUB_REPO_URL>
git branch -M main
git push -u origin main
git remote -v
```

For an existing `origin` that needs correction:

```bash
git remote set-url origin <GITHUB_REPO_URL>
git branch -M main
git push -u origin main
git remote -v
```
