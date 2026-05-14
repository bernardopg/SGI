# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commits

Never add `Co-Authored-By: Claude` or any Claude/Anthropic co-author trailer to commit messages in this repository.

## Workspace structure

SGI is a parent repository with two Git submodules:

```
SGI/
├── steam-game-idler/              # Main Tauri/Next.js app
└── steam-utility-multiplataform/  # Cross-platform .NET 10 CLI for Steam operations
```

Clone with submodules:
```bash
git clone --recurse-submodules <repo-sgi>
# or, on an existing clone:
git submodule update --init --recursive
```

**Commit order matters.** Submodule commits must be made and pushed before committing or pushing the parent repo, otherwise the parent will point to an unpublished commit.

## Commands

### Linux dev (from workspace root)
```bash
./steam-game-idler/scripts/dev-linux.sh
```
Validates `SteamUtility.Cli`, kills orphan idle helpers, clears `/tmp/steam-game-idler` and `.next/dev`, sources `.env.dev`, then runs `pnpm tauri dev`.

Build the binary first if needed:
```bash
cd steam-utility-multiplataform
dotnet build steam-utility-multiplataform.sln -c Release
```

### Frontend (`steam-game-idler/`)
```bash
pnpm install --frozen-lockfile
pnpm typecheck
pnpm lint
pnpm build
pnpm prettier
```

### Rust backend (`steam-game-idler/src-tauri/`)
```bash
cargo check
cargo test
```

### .NET (`steam-utility-multiplataform/`)
```bash
dotnet build steam-utility-multiplataform.sln -c Release
dotnet run --project tests/SteamUtility.Tests -c Release   # custom runner, not dotnet test
```

### AUR
```bash
AUR_PACKAGE=steam-game-idler-git ./scripts/publish-aur.sh
```
Automated publishing to AUR is part of `release.yml` (job `publish_aur`) and runs only on tag pushes (`v*.*.*`) or manual `workflow_dispatch` without `dry_run`. Requires the `AUR_SSH_PRIVATE_KEY` secret on the SGI repo.

## Architecture

### Data flow
The Tauri Rust backend spawns `SteamUtility.Cli` as a subprocess for all Steam operations. The Next.js frontend communicates with Rust via `tauri::invoke`. Rust does not call the Steam API directly — everything goes through the CLI.

### Binary resolution (`steam_utility.rs`)
At runtime the binary path is resolved in order:
1. `SGI_STEAM_UTILITY_PATH` env var — used in local Linux dev
2. Fallback: `src-tauri/libs/SteamUtility.Cli` — used in production and AUR builds

### Idle process isolation (`idling.rs`)
Each idle session spawns in an isolated temp directory: `/tmp/steam-game-idler/idlers/<pid>-<appid>-<nanos>/` with its own `steam_appid.txt`. This prevents card farming from touching versioned files in `src-tauri/`. Concurrent session cap: 8 on Linux, 32 on Windows.

### Tauri backend modules
| Module | Responsibility |
|---|---|
| `steam_utility` | Binary path resolution |
| `idling` | Idle process spawn/kill, card farming |
| `command_runner` | `CREATE_NO_WINDOW` flag on Windows |
| `achievement_manager` | Unlock/lock/toggle achievements and stats |
| `trading_cards` | Card data and market prices |
| `process_handler` | Child process monitoring and cleanup |
| `crypto` | AES obfuscation of the Steam API key for production builds |
| `settings`, `user_data`, `game_data`, `custom_lists`, `logging`, `automation`, `utils` | Domain logic |

### Frontend
Next.js, organized under `src/features/` by domain: `achievement-manager`, `achievement-unlocker`, `card-farming`, `customlists`, `gameslist`, `inventory-manager`, `settings`. Each feature barrel-exports via `index.ts`.

### Environment variables
- `.env.dev` — dev only; requires at least `KEY=""` or a real Steam Web API key
- `.env.prod` — release only; key is AES-obfuscated and embedded at build time
- Production build panics at startup if no obfuscated key is available

### Known Linux constraints
- `next dev --webpack` is mandatory — Turbopack/HMR is unstable with WebKitGTK inside the Tauri WebView
- Custom context menu (`Menu.popup()`) and native notifications are disabled in dev/Linux paths
- `localhost:3000` in a regular browser will fail (`invoke` is only available inside the Tauri WebView)

### `steam-utility-multiplataform` CLI commands
**Discovery (no live Steam required):** `detect`, `libraries`, `apps`, `compatdata`, `compat-tools`, `compat-mapping`, `compat-report`, `state-report`

**Steam-native (live Steam session required):** `check_ownership`, `idle`, `get_achievement_data`, and all achievement/stats mutation commands

### AUR (`packaging/aur/`)
The PKGBUILD publishes `SteamUtility.Cli` as a self-contained single-file binary into `src-tauri/libs/`, then runs `pnpm tauri build --bundles deb` and extracts the resulting `.deb`. `.SRCINFO` must stay in sync with `PKGBUILD` — the CI validates this with `makepkg --printsrcinfo`.

## CI / Release workflows (`.github/workflows/`)

| Workflow | Trigger | Purpose |
|---|---|---|
| `ci.yml` | push to `master`, all PRs | `pnpm typecheck` + `cargo check` against current submodule state, and `.SRCINFO` ≡ `makepkg --printsrcinfo` |
| `aur-build.yml` | PR touching `packaging/aur/**`, manual dispatch | Build the PKGBUILD in an Arch container and install it to catch regressions |
| `release.yml` | tag `v*.*.*` push, manual dispatch | Full release pipeline — see below |

`release.yml` jobs (in dependency order):

| Job | Runner | Purpose |
|---|---|---|
| `prepare` | ubuntu-latest | Resolve `version` / `tag` / `should_publish` from tag or dispatch input |
| `ci_gate` | ubuntu-22.04 | Re-run typecheck + cargo check + `.SRCINFO` validation before any artifact work starts |
| `build_steamutility` | ubuntu-22.04 + windows-latest matrix | Publish `SteamUtility.Cli` (linux-x64) and `SteamUtility.exe` (win-x64) from `steam-utility-multiplataform` |
| `build_linux_bundle` | ubuntu-22.04 | Tauri bundle: `.deb`, `.rpm`, `.AppImage` |
| `build_windows_bundle` | windows-latest | Tauri bundle: NSIS installer + portable `.zip` |
| `build_aur` | archlinux container | Build `.pkg.tar.zst` from the PKGBUILD, pinning `pkgver` and the `source=` ref to this commit; upload PKGBUILD/.SRCINFO/.pkg.tar.zst as artifacts |
| `build_source_tarball` | ubuntu-latest | Vendored `sgi-<version>-source.tar.gz` (SGI + both submodules, no `.git`/build dirs) |
| `publish_aur` | ubuntu-latest | **Only runs when `should_publish==true`** (real tag, or dispatch with `dry_run=false`). Pushes PKGBUILD/.SRCINFO to `ssh://aur@aur.archlinux.org/steam-game-idler-git.git` |
| `publish_release` | ubuntu-latest | Same gate as above. Attaches every artifact + `SHA256SUMS` to a single GitHub release for the tag |

**AUR is published only on a versioned release** — never on a regular push to `master`. The legacy stand-alone `publish-aur.yml` was removed in favour of the gated `release.yml -> publish_aur` job to avoid pushing intermediate snapshots.

Pinned action versions: `actions/checkout@v6.0.2`, `actions/setup-node@v6.4.0`, `pnpm/action-setup@v6.0.5`, `actions/setup-dotnet@v5.2.0`, `actions/upload-artifact@v7.0.1`, `actions/download-artifact@v8.0.1`, `actions/github-script@v9`, `softprops/action-gh-release@v3`, `swatinem/rust-cache@v2.9.1`, `dtolnay/rust-toolchain@stable`.

### How to cut a release

```bash
# from SGI/ master, after submodule pointers are at their intended commits
git tag v5.0.6
git push origin v5.0.6
```

Or, from the Actions UI: run "Release" workflow_dispatch with `version=5.0.6` and `dry_run=false`. Setting `dry_run=true` builds everything and uploads artifacts but skips the AUR push and the GitHub release.