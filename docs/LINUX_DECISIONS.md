# Linux Decisions

This changelog records Linux-specific decisions that affect SGI behavior,
packaging, or support.

## Current Decisions

- Linux development uses `steam-game-idler/scripts/dev-linux.sh` from the parent
  workspace. The script validates `SteamUtility.Cli`, clears stale idlers, loads
  `.env.dev`, and starts Tauri.
- Tauri dev WebView uses `next dev --webpack`. Turbopack remains disabled for
  Linux/Tauri dev because WebKitGTK validation showed instability.
- Card farming concurrency is capped per platform: 8 idlers on Linux and 32 on
  Windows. The Linux cap reduces Steam IPC pressure.
- Each idle process gets its own directory under the system temp directory.
  `steam_appid.txt` is generated there, not under versioned project paths.
- Linux runtime packages are documented per distro in
  `steam-game-idler/docs/content/docs/get-started/linux-dependencies.mdx`.
- AppImage builds on modern Arch require `NO_STRIP=1` because the linuxdeploy
  AppImage `strip` binary can fail on newer `.relr.dyn` sections.
- `SteamUtility.Cli` is bundled as `src-tauri/libs/SteamUtility.Cli` on Linux.
  Development can override this with `SGI_STEAM_UTILITY_PATH`.
- Parent SGI releases pin `steam-game-idler` and `steam-utility-multiplataform`
  by submodule SHA; Linux artifacts are built from those pinned revisions.

## Open Validation Items

- Long live card-farming soak on a real Steam session.
- Installed-build validation for Tauri permissions, tray behavior, close-to-tray,
  and native notifications.
- Clean-environment package install validation.
