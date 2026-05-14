# Turbopack Recheck Policy

SGI keeps Turbopack disabled for Linux Tauri development until it is validated
inside the actual WebKitGTK WebView.

## Current Decision

Use:

```bash
next dev --webpack -p 3001
```

Do not switch `steam-game-idler/package.json` back to Turbopack based only on a
browser test. The failure mode is specific to the Tauri dev WebView and
card-farming workflows.

## Recheck Triggers

Re-test Turbopack after any of these change:

- Next.js major/minor version.
- Tauri major/minor version.
- WebKitGTK major package version.
- Linux distro image used by release builds.

## Recheck Procedure

1. Temporarily run `next dev -p 3001` without `--webpack`.
2. Start Tauri dev with the normal Linux script after editing the local command.
3. Validate sign-in, settings load/save, game list refresh, achievement data
   fetch, card-farming start/stop, and idler cleanup.
4. Watch for blank WebView, HMR disconnects, crashed WebKit process, stale
   idlers, and malformed `tauri::invoke` responses.
5. Keep `--webpack` unless the Tauri WebView path survives this validation.

## Status

Last policy update: 2026-05-14. No successful WebKitGTK/Tauri Turbopack
validation has been recorded for SGI yet.
