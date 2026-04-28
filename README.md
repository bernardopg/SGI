# SGI Workspace

Integration workspace for evolving Steam Game Idler with Linux support without breaking the Windows workflow.

## Structure

```text
SGI/
├── steam-game-idler/
└── steam-utility-multiplataform/
```

Both child projects are maintained as Git submodules:

- `steam-game-idler` → `https://github.com/bernardopg/steam-game-idler.git`
- `steam-utility-multiplataform` → `https://github.com/bernardopg/steam-utility-multiplataform.git`

## Cloning

```bash
git clone --recurse-submodules <repo-sgi>
cd SGI
```

If the clone already exists:

```bash
git submodule update --init --recursive
```

## Running on Linux

The local workflow uses the `steam-utility-multiplataform` binary via `SGI_STEAM_UTILITY_PATH`.

```bash
cd /home/bitter/git-clones/SGI
./steam-game-idler/scripts/dev-linux.sh
```

The script:

- validates the `SteamUtility.Cli` binary;
- kills orphan `SteamUtility.Cli idle` helpers;
- clears the temporary idler cache;
- clears `.next/dev`;
- starts `tauri dev`.

## Status

### Done

- Tauri backend compiles on Linux.
- `SteamUtility.Cli` is resolved per platform/env var.
- Card farming on Linux uses isolated temporary directories per AppID, avoiding changes to `src-tauri/steam_appid.txt`.
- Card farming on Linux limits concurrent Steam API sessions to reduce Steam IPC pressure.
- `next dev` runs with Webpack inside the Tauri app to avoid WebKitGTK instability with Turbopack/HMR.
- Custom context menu and native notifications are disabled on problematic dev/Linux paths.
- `/health` endpoint exists for readiness checks.

### Recent validations

```bash
cd steam-game-idler
pnpm typecheck
pnpm build
cd src-tauri
cargo check
```

Manual validation confirmed that card farming runs for an extended period on Linux without the initial crash.

## Repositories

- `steam-game-idler`: main Tauri/Next.js app.
- `steam-utility-multiplataform`: .NET utility responsible for cross-platform Steamworks integration.

## AUR

The AUR package is published as `steam-game-idler-git`.

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

## Principles

1. Preserve Windows.
2. Enable Linux incrementally.
3. Keep the integration between the app and the utility explicit and testable.
4. Avoid dependency on state generated inside directories watched by `tauri dev`.
