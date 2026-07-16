<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:0F172A,40:1D4ED8,100:22C55E&height=220&section=header&text=SGI%20Workspace&fontSize=56&fontColor=FFFFFF&fontAlignY=38&desc=Steam%20Game%20Idler%20%E2%80%94%20Multiplatform%20Release%20Orchestrator&descAlignY=60" alt="SGI banner" />
</p>

<p align="center">
  <a href="https://github.com/bernardopg/SGI/actions/workflows/ci.yml">
    <img src="https://github.com/bernardopg/SGI/actions/workflows/ci.yml/badge.svg?branch=master" alt="CI" />
  </a>
  <a href="https://github.com/bernardopg/SGI/releases">
    <img src="https://img.shields.io/github/v/release/bernardopg/SGI?display_name=tag&sort=semver&style=flat-square&color=1D4ED8&label=SGI" alt="SGI release" />
  </a>
  <a href="https://github.com/bernardopg/steam-game-idler">
    <img src="https://img.shields.io/github/v/release/zevnda/steam-game-idler?display_name=tag&sort=semver&style=flat-square&color=a82869&label=steam-game-idler" alt="steam-game-idler" />
  </a>
  <a href="https://github.com/bernardopg/steam-utility-multiplataform/releases">
    <img src="https://img.shields.io/github/v/release/bernardopg/steam-utility-multiplataform?display_name=tag&sort=semver&style=flat-square&color=512BD4&label=steam-utility" alt="steam-utility" />
  </a>
  <a href="https://aur.archlinux.org/packages/steam-game-idler-git">
    <img src="https://img.shields.io/aur/version/steam-game-idler-git?style=flat-square&color=1793D1&logo=archlinux&logoColor=white&label=AUR" alt="AUR" />
  </a>
  <br/>
  <img src="https://img.shields.io/badge/Linux-supported-22C55E?style=flat-square&logo=linux&logoColor=black" alt="Linux" />
  <img src="https://img.shields.io/badge/Windows-supported-0078D6?style=flat-square&logo=windows11&logoColor=white" alt="Windows" />
  <img src="https://img.shields.io/badge/Tauri-2.x-FFC131?style=flat-square&logo=tauri&logoColor=black" alt="Tauri" />
  <img src="https://img.shields.io/badge/.NET-10-512BD4?style=flat-square&logo=dotnet&logoColor=white" alt=".NET" />
  <img src="https://img.shields.io/badge/Rust-stable-CE422B?style=flat-square&logo=rust&logoColor=white" alt="Rust" />
  <img src="https://img.shields.io/badge/Next.js-15-000000?style=flat-square&logo=nextdotjs&logoColor=white" alt="Next.js" />
  <img src="https://img.shields.io/github/license/bernardopg/SGI?style=flat-square&color=22C55E" alt="License" />
</p>

---

**SGI** is the parent workspace that orchestrates the multiplatform release of [Steam Game Idler](https://github.com/bernardopg/steam-game-idler) — a Tauri desktop app for farming Steam trading cards, managing achievements, and automating playtime — with full Linux support added on top of the upstream Windows-first codebase.

---

## Table of Contents

- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Feature Overview](#feature-overview)
- [Data Flow](#data-flow)
- [Getting Started](#getting-started)
- [CLI Reference](#cli-reference)
- [CI / CD Pipeline](#cicd-pipeline)
- [Release](#release)
- [AUR](#aur)
- [Runtime Dependencies](#runtime-dependencies)
- [Principles](#principles)

---

## Architecture

SGI is a mono-workspace composed of two Git submodules glued together at build and runtime:

```
SGI (parent)
├── steam-game-idler/           Tauri 2 + Next.js 15 desktop app
│   ├── src/                    React frontend (feature-sliced)
│   └── src-tauri/              Rust backend (15 modules)
│       └── libs/
│           ├── SteamUtility.Cli      Linux binary (resolved at runtime)
│           └── SteamUtility.exe      Windows binary (resolved at runtime)
└── steam-utility-multiplataform/    .NET 10 cross-platform Steamworks CLI
    └── src/SteamUtility.Cli/        Single-file self-contained binary
```

### Technology Stack

| Layer           | Technology             | Version |
| --------------- | ---------------------- | ------- |
| Desktop shell   | Tauri                  | 2.8     |
| Frontend        | Next.js + React        | 15      |
| Styling         | HeroUI + Tailwind      | —       |
| Rust backend    | tokio, serde, aes      | stable  |
| Steam CLI       | .NET / C#              | 10.0    |
| Package manager | pnpm                   | 10      |
| Build system    | cargo + dotnet publish | —       |

---

## Repository Structure

```text
SGI/
├── .github/
│   ├── actions/
│   │   └── pin-tauri-version/      Composite action — patches tauri.conf.json,
│   │                               disables updater, drops API-key panic
│   └── workflows/
│       ├── ci.yml                  Typecheck + cargo check + .SRCINFO validation
│       ├── aur-build.yml           PKGBUILD smoke-test (PR + manual)
│       └── release.yml             Full multiplatform release pipeline
├── packaging/
│   └── aur/
│       ├── PKGBUILD
│       └── .SRCINFO
├── scripts/
│   └── publish-aur.sh              Local AUR publish helper
├── steam-game-idler/               Submodule → bernardopg/steam-game-idler
└── steam-utility-multiplataform/   Submodule → bernardopg/steam-utility-multiplataform
```

---

## Feature Overview

| Feature                  | Description                                                                                                                                                                                                |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Card Farming**         | Idles games to accumulate Steam trading card drops. Up to 8 concurrent sessions on Linux, 32 on Windows. Each session runs in an isolated `/tmp/steam-game-idler/idlers/<pid>-<appid>-<nanos>/` directory. |
| **Achievement Manager**  | Unlock, lock, toggle individual achievements and reset/update stats.                                                                                                                                       |
| **Achievement Unlocker** | Automated sequential achievement unlocking with configurable interval.                                                                                                                                     |
| **Inventory Manager**    | Browse and manage Steam inventory items.                                                                                                                                                                   |
| **Game List**            | Full library with ownership check, playtime, and card data.                                                                                                                                                |
| **Custom Lists**         | User-defined game groupings for batch operations.                                                                                                                                                          |
| **Settings**             | Per-user Steam Web API key, theme, automation rules, idle limits.                                                                                                                                          |

---

## Data Flow

```
┌──────────────────────────────────────────────┐
│              Next.js Frontend                │
│    (React, HeroUI, feature-sliced src/)      │
└───────────────────┬──────────────────────────┘
                    │  tauri::invoke()
                    ▼
┌─────────────────────────────────────────────────┐
│           Tauri Rust Backend                    │
│                                                 │
│  steam_utility  ──► binary path resolution      │
│  idling         ──► spawn / kill idle procs     │
│  achievement_manager ──► unlock / lock / toggle │
│  trading_cards  ──► card data + market prices   │
│  crypto         ──► AES key obfuscation         │
│  automation     ──► scheduled actions           │
│  process_handler ──► child process monitoring    │
└───────────────────┬─────────────────────────────┘
                    │  subprocess (stdin/stdout/stderr)
                    ▼
┌──────────────────────────────────────────────┐
│         SteamUtility.Cli  (.NET 10)          │
│                                              │
│  Discovery (no live Steam required):         │
│    detect · libraries · apps · compatdata    │
│    compat-tools · compat-mapping             │
│    compat-report · state-report              │
│                                              │
│  Live Steam session required:                │
│    check_ownership · idle                    │
│    get_achievement_data                      │
│    unlock/lock/toggle_achievement            │
│    unlock/lock_all_achievements              │
│    update_stats · reset_all_stats            │
└──────────────────────────────────────────────┘
                    │
                    ▼
              Steam Client (IPC)
```

### Binary Resolution (Linux-first)

```
1. SGI_STEAM_UTILITY_PATH env var   ← local dev
2. src-tauri/libs/SteamUtility.Cli  ← production / AUR
   src-tauri/libs/SteamUtility.exe  ← Windows
```

---

## Getting Started

### Clone

```bash
git clone --recurse-submodules https://github.com/bernardopg/SGI.git
cd SGI

# Existing clone
git submodule update --init --recursive
```

### Linux — Development

Build the .NET CLI backend first:

```bash
cd steam-utility-multiplataform
dotnet build steam-utility-multiplataform.sln -c Release
cd ..
```

Start the app:

```bash
./steam-game-idler/scripts/dev-linux.sh
```

The dev script:

1. Validates the `SteamUtility.Cli` binary
2. Kills orphan idle helpers from previous sessions
3. Clears `/tmp/steam-game-idler` and `.next/dev`
4. Sources `.env.dev` (requires at minimum `KEY=""`)
5. Starts `pnpm tauri dev --webpack`

> **Note:** Turbopack/HMR is disabled inside the Tauri WebView on Linux (WebKitGTK instability). Webpack is mandatory.

### Windows — Development

```bash
cd steam-game-idler
pnpm install --frozen-lockfile
pnpm tauri dev
```

### Frontend only

```bash
cd steam-game-idler
pnpm install --frozen-lockfile
pnpm typecheck
pnpm lint
pnpm build
```

### Rust backend only

```bash
cd steam-game-idler/src-tauri
cargo check
cargo test
```

### .NET CLI

```bash
cd steam-utility-multiplataform
dotnet build steam-utility-multiplataform.sln -c Release

# Run tests (custom runner, not dotnet test)
dotnet run --project tests/SteamUtility.Tests -c Release
```

---

## CLI Reference

`SteamUtility.Cli` is a self-contained single-file binary. It is spawned as a subprocess by the Tauri backend for every Steam operation.

### Discovery commands _(no live Steam session required)_

| Command          | Description                                 |
| ---------------- | ------------------------------------------- |
| `detect`         | Locate Steam installation directory         |
| `libraries`      | List Steam library folders                  |
| `apps`           | List all installed apps                     |
| `compatdata`     | List Proton compatibility data              |
| `compat-tools`   | List installed Proton / compatibility tools |
| `compat-mapping` | Map apps to their compatibility tool        |
| `compat-report`  | Full compatibility report                   |
| `state-report`   | Overall Steam state summary                 |

### Live commands _(active Steam session required)_

| Command                           | Description                              |
| --------------------------------- | ---------------------------------------- |
| `check_ownership <appid>`         | Verify game ownership                    |
| `idle <appid>`                    | Start idle session for card farming      |
| `get_achievement_data <appid>`    | Fetch achievement definitions + progress |
| `unlock_achievement <appid> <id>` | Unlock a single achievement              |
| `lock_achievement <appid> <id>`   | Lock a single achievement                |
| `toggle_achievement <appid> <id>` | Toggle achievement state                 |
| `unlock_all_achievements <appid>` | Unlock all achievements                  |
| `lock_all_achievements <appid>`   | Lock all achievements                    |
| `update_stats <appid> <json>`     | Write stat values                        |
| `reset_all_stats <appid>`         | Reset all stats to default               |

---

## CI/CD Pipeline

### CI (`ci.yml`) — every push to `master` and all PRs

```
push/PR
  └── workspace
        ├── Install Tauri system deps (cached via cache-apt-pkgs-action)
        ├── pnpm install --frozen-lockfile
        ├── pnpm typecheck
        └── cargo check  (rust-cache shared across runs)
  └── aur-metadata
        ├── Configure pacman mirrors
        └── makepkg --printsrcinfo → diff .SRCINFO
```

### Release (`release.yml`) — tag `v*.*.*` push or manual dispatch

```
prepare (5 min timeout)
  └── Resolve version / tag / should_publish
        │
        ├──────────────────────────────────┐
        ▼                                  ▼
  ci_gate                          build_source_tarball (15 min timeout)
  (typecheck + cargo check +
   .SRCINFO + apt cache)
        │
        ├────────────────────────────────────────┐
        ▼                                        ▼
  build_steamutility (matrix)              build_aur (archlinux container)
  ├── linux-x64  ~26s                      └── makepkg → install → verify
  └── win-x64    ~1m45s                          │
  (dotnet NuGet cache)                           ▼
        │                                  publish_aur (10 min timeout)
        ├─────────────┐                    └── SSH push to AUR git
        ▼             ▼
  build_linux_bundle  build_windows_bundle
  (deb + rpm +        (NSIS + portable zip)
   AppImage)
  ~13-14 min          ~14 min
  (rust-cache +       (rust-cache +
   apt cache)          pnpm cache)
        │
        └──────────────────────┐
                               ▼
                        publish_release
                        └── GitHub release + SHA256SUMS
```

### Job timing (v5.0.9, cache warm)

| Job                          | Time        | Notes                               |
| ---------------------------- | ----------- | ----------------------------------- |
| Resolve version              | 2s          | —                                   |
| Source tarball               | 10s         | —                                   |
| CI gate                      | ~3m         | apt cache hit                       |
| Build SteamUtility linux-x64 | **26s**     | NuGet cache hit                     |
| Build SteamUtility win-x64   | **1m45s**   | NuGet cache hit                     |
| AUR package                  | ~9m         | pacman + makepkg                    |
| Tauri bundle Linux           | ~13m        | rust-cache + apt cache              |
| Tauri bundle Windows         | ~14m        | rust-cache                          |
| Push PKGBUILD to AUR         | 24s         | —                                   |
| Publish GitHub release       | 28s         | —                                   |
| **Total**                    | **~20 min** | **~12-14 min with warm Rust cache** |

### Pinned action versions

| Action                            | Version  |
| --------------------------------- | -------- |
| `actions/checkout`                | `v7.0.0` |
| `actions/setup-node`              | `v6.4.0` |
| `pnpm/action-setup`               | `v6.0.9` |
| `actions/setup-dotnet`            | `v5.4.0` |
| `actions/upload-artifact`         | `v7.0.1` |
| `actions/download-artifact`       | `v8.0.1` |
| `actions/github-script`           | `v9`     |
| `softprops/action-gh-release`     | `v3`     |
| `swatinem/rust-cache`             | `v2.9.1` |
| `dtolnay/rust-toolchain`          | `1.97.0` |

---

## Release

Cut a release from the SGI parent after both submodule pointers are at their intended commits:

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

Or trigger manually from the Actions UI:

```
Workflow: Release
  version: X.Y.Z
  dry_run: false   # true = build everything, skip AUR push + GitHub release
```

Each release produces:

| Artifact                                                   | Platform                    |
| ---------------------------------------------------------- | --------------------------- |
| `steam-game-idler_X.Y.Z_amd64.deb`                         | Debian / Ubuntu             |
| `steam-game-idler-X.Y.Z-1.x86_64.rpm`                      | Fedora / openSUSE           |
| `steam-game-idler_X.Y.Z_amd64.AppImage`                    | Any Linux                   |
| `steam-game-idler_X.Y.Z_x64-setup.exe`                     | Windows (NSIS installer)    |
| `steam-game-idler_X.Y.Z_x64-portable.zip`                  | Windows (portable)          |
| `steam-game-idler-git-X.Y.Z.rN.gHASH-1-x86_64.pkg.tar.zst` | Arch Linux                  |
| `steam-game-idler-git.PKGBUILD`                            | AUR metadata                |
| `steam-game-idler-git.SRCINFO`                             | AUR metadata                |
| `sgi-X.Y.Z-source.tar.gz`                                  | Vendored source (no `.git`) |
| `SHA256SUMS`                                               | Checksums for all above     |

---

## AUR

The package [`steam-game-idler-git`](https://aur.archlinux.org/packages/steam-game-idler-git) is published automatically on every versioned release.

```bash
# Install via yay
yay -S steam-game-idler-git

# Local publish (requires AUR_SSH_PRIVATE_KEY)
AUR_PACKAGE=steam-game-idler-git ./scripts/publish-aur.sh
```

For a full local package verification, see [dependency management](docs/DEPENDENCY_MANAGEMENT.md).

Files:

```
packaging/aur/
├── PKGBUILD
└── .SRCINFO
```

The PKGBUILD:

1. Clones the SGI workspace at the pinned release commit
2. Publishes `SteamUtility.Cli` as a self-contained single-file binary
3. Runs `pnpm tauri build --bundles deb`
4. Extracts and installs the `.deb` contents into the Arch package layout

---

## Runtime Dependencies

### Linux

| Distro family   | Packages                                                                  |
| --------------- | ------------------------------------------------------------------------- |
| Debian / Ubuntu | `libwebkit2gtk-4.1-0` `libgtk-3-0` `libssl3` `libayatana-appindicator3-1` |
| Arch / Manjaro  | `webkit2gtk-4.1` `gtk3` `openssl` `libayatana-appindicator`               |
| Fedora          | `webkit2gtk4.1` `gtk3` `openssl` `libappindicator-gtk3`                   |
| openSUSE        | `webkit2gtk3` `gtk3` `libopenssl3` `libappindicator3-1`                   |

### Windows

No additional runtime dependencies. The NSIS installer and portable zip are self-contained.

---

## Principles

1. **Preserve Windows.** All Linux changes must not regress the Windows build or runtime.
2. **Enable Linux incrementally.** Each subsystem (idle, achievements, cards) is ported and tested independently.
3. **Explicit integration.** The boundary between the Tauri Rust backend and `SteamUtility.Cli` is a subprocess interface — no hidden shared state.
4. **Isolated idle sessions.** Each card-farming process runs in its own temp directory to prevent cross-contamination with `tauri dev` watched paths.
5. **Reproducible releases.** AUR builds pin the exact SGI commit SHA; the source tarball vendors both submodules with no `.git` metadata.

---

## Repositories

| Repo                                                                                                  | Role                                      |
| ----------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| [bernardopg/SGI](https://github.com/bernardopg/SGI)                                                   | This workspace — release orchestrator     |
| [bernardopg/steam-game-idler](https://github.com/bernardopg/steam-game-idler)                         | Tauri/Next.js app fork with Linux support |
| [bernardopg/steam-utility-multiplataform](https://github.com/bernardopg/steam-utility-multiplataform) | Cross-platform .NET 10 Steamworks CLI     |
| [zevnda/steam-game-idler](https://github.com/zevnda/steam-game-idler)                                 | Upstream app (Windows-only)               |

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:22C55E,60:1D4ED8,100:0F172A&height=120&section=footer" alt="footer" />
</p>
