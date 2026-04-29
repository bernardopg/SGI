# SGI Workspace

[![CI][ci-badge]][ci-url]
[![AUR Publish][aur-badge]][aur-url]
[![SGI][sgi-badge]][sgi-releases]
[![steam-game-idler][app-badge]][app-url]
[![steam-utility][utility-badge]][utility-url]
[![Linux][linux-badge]][sgi-releases]
[![Windows][windows-badge]][app-url]

Integration workspace for evolving Steam Game Idler with Linux support without breaking the Windows workflow.

[ci-badge]: https://github.com/bernardopg/SGI/actions/workflows/ci.yml/badge.svg?branch=master
[ci-url]: https://github.com/bernardopg/SGI/actions/workflows/ci.yml
[aur-badge]: https://github.com/bernardopg/SGI/actions/workflows/publish-aur.yml/badge.svg
[aur-url]: https://github.com/bernardopg/SGI/actions/workflows/publish-aur.yml
[sgi-badge]: https://img.shields.io/github/v/release/bernardopg/SGI?display_name=tag&sort=semver&style=flat-square&color=%232d6acc&label=SGI
[sgi-releases]: https://github.com/bernardopg/SGI/releases
[app-badge]: https://img.shields.io/github/v/release/zevnda/steam-game-idler?display_name=tag&sort=semver&style=flat-square&color=%23a82869&label=steam-game-idler
[app-url]: https://github.com/bernardopg/steam-game-idler
[utility-badge]: https://img.shields.io/github/v/release/bernardopg/steam-utility-multiplataform?display_name=tag&sort=semver&style=flat-square&color=%23512BD4&label=steam-utility
[utility-url]: https://github.com/bernardopg/steam-utility-multiplataform/releases
[linux-badge]: https://img.shields.io/badge/Linux-supported-FCC624?style=flat-square&logo=linux&logoColor=black
[windows-badge]: https://img.shields.io/badge/Windows-supported-0078D6?style=flat-square&logo=windows11&logoColor=white

## Structure

```text
SGI/
├── steam-game-idler/              # Main Tauri/Next.js app (fork of zevnda/steam-game-idler)
└── steam-utility-multiplataform/  # Cross-platform .NET 10 Steamworks CLI
```

Both child projects are maintained as Git submodules:

- `steam-game-idler` → `https://github.com/bernardopg/steam-game-idler.git`
- `steam-utility-multiplataform` → `https://github.com/bernardopg/steam-utility-multiplataform.git`

## Cloning

```bash
git clone --recurse-submodules https://github.com/bernardopg/SGI.git
cd SGI
```

If the clone already exists:

```bash
git submodule update --init --recursive
```

## Running on Linux

Build the Steam CLI backend first:

```bash
cd steam-utility-multiplataform
dotnet build steam-utility-multiplataform.sln -c Release
cd ..
```

Then start the app:

```bash
./steam-game-idler/scripts/dev-linux.sh
```

The script:

- validates the `SteamUtility.Cli` binary;
- kills orphan `SteamUtility.Cli idle` helpers;
- clears the temporary idler cache and `.next/dev`;
- sources `.env.dev`;
- starts `pnpm tauri dev` with Webpack.

## Status

- Tauri backend compiles on Linux.
- `SteamUtility.Cli` is resolved per platform/env var (`SGI_STEAM_UTILITY_PATH` → `src-tauri/libs/` fallback).
- Card farming on Linux uses isolated temporary directories per AppID, avoiding changes to `src-tauri/steam_appid.txt`.
- Card farming on Linux limits concurrent Steam API sessions to 8 (vs. 32 on Windows) to reduce Steam IPC pressure.
- `next dev` runs with Webpack inside the Tauri app to avoid WebKitGTK instability with Turbopack/HMR.
- Custom context menu and native notifications are disabled on problematic dev/Linux paths.
- `/health` endpoint exists for readiness checks.

## Repositories

| Repo | Role |
|---|---|
| [bernardopg/steam-game-idler](https://github.com/bernardopg/steam-game-idler) | Main Tauri/Next.js app — fork of [zevnda/steam-game-idler](https://github.com/zevnda/steam-game-idler) with Linux support |
| [bernardopg/steam-utility-multiplataform](https://github.com/bernardopg/steam-utility-multiplataform) | Cross-platform .NET 10 CLI for Steamworks operations |

## AUR

The AUR package is published as [`steam-game-idler-git`](https://aur.archlinux.org/packages/steam-game-idler-git).

Distribution files:

- `packaging/aur/PKGBUILD`
- `packaging/aur/.SRCINFO`
- `.github/workflows/publish-aur.yml`

The PKGBUILD uses the `SGI` repo on the `master` branch, initializes submodules, compiles `SteamUtility.Cli`, generates the `.deb` bundle via Tauri, and installs the extracted contents into the Arch package.

Local publish:

```bash
AUR_PACKAGE=steam-game-idler-git ./scripts/publish-aur.sh
```

Publishing via GitHub Actions requires the `AUR_SSH_PRIVATE_KEY` secret.

## Release

The parent `SGI` release workflow is the authoritative packaged release path. Push a `vX.Y.Z` tag from the parent repository after both submodules have been committed and the parent has recorded their new SHAs.

The release workflow builds and attaches:

- Linux `.deb`, `.rpm`, and `.AppImage` bundles
- Windows NSIS installer and portable zip
- AUR `PKGBUILD`, `.SRCINFO`, and built `.pkg.tar.zst`
- vendored `sgi-<version>-source.tar.gz`
- `SHA256SUMS`

It also publishes the pinned AUR metadata when `AUR_SSH_PRIVATE_KEY` is configured.

## Principles

1. Preserve Windows.
2. Enable Linux incrementally.
3. Keep the integration between the app and the utility explicit and testable.
4. Avoid dependency on state generated inside directories watched by `tauri dev`.
