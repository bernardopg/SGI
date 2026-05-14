# Upstream Comparison

Compared on: 2026-05-14

Fork:

- remote: `origin`
- branch: `main`
- commit: `358838ff`

Upstream:

- remote: `upstream`
- branch: `main`
- commit: `e0f3b351`

Ahead/behind:

- upstream-only commits: 11
- fork-only commits: 16

## Main Fork Differences

The fork carries Linux and SGI-workspace work that is not present upstream:

- Linux dev workflow: `scripts/dev-linux.sh` and `scripts/smoke-test-linux.sh`.
- Cross-platform `SteamUtility` path resolution and bundled binary handling.
- Linux idler isolation with per-app temp directories and cleanup.
- Linux card-farming concurrency cap.
- WebKitGTK-oriented zoom/opening behavior.
- Persistence/cache hardening for installed builds.
- Parent-workspace CI/release/AUR orchestration.
- SGI-to-`SteamUtility.Cli` command contract docs.

## Upstream Changes To Review Before Rebasing

Recent upstream commits include:

- `e0f3b351` version bump to `5.0.6`
- `593e024a` changelog update
- `d3bd45fb` sidebar ad slot fix
- `bb5a3e80` achievement unlocker delay validation fix
- `0ba2a6f0` Pro UI refactor
- `35fa8918` feature folder naming convention refactor
- `82aebfce` Crowdin translation update

## Rebase Risk

Do not blindly rebase the fork onto upstream. The feature-folder refactor and
workflow changes can conflict with SGI's Linux integration, custom CI, and docs.

Recommended approach:

1. Review upstream UI and i18n changes separately from backend/Linux changes.
2. Cherry-pick small bug fixes when they are isolated.
3. Keep SGI release and AUR workflows in the parent repo.
4. Re-run `pnpm typecheck`, `pnpm build`, `cargo check`, `cargo test`, docs
   build, and Linux smoke tests after any upstream sync.
