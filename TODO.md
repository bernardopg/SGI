# TODO - SGI

## Current status

- SGI is the parent workspace for two submodules:
  - `steam-game-idler/` — Tauri/Next.js desktop app.
  - `steam-utility-multiplataform/` — cross-platform .NET Steam utility used by the app.
- Latest verified release: `v5.0.8` on 2026-05-19 (cut via `git tag v5.0.8 && git push origin v5.0.8`; GitHub Actions run `26074511298`; Windows bundle required re-run after infra flake on rust-cache restore).
  - Previous verified release: `v5.0.7` on 2026-05-19.
  - `v5.0.6` on 2026-05-14 (GitHub Actions run `25874439239`; AUR commit `8153de0`).
- AUR publishing is now release-gated only:
  - tag push matching `v*.*.*`; or
  - manual `release.yml` dispatch with `dry_run=false`.
  - Regular pushes to `master` no longer publish to AUR.
- Remaining high-value work is mostly live runtime validation on real systems, not build-pipeline plumbing.

## Done

### Workspace and Linux stabilization

- [x] Organize workspace with the structure:

  ```text
  SGI/
  ├── steam-game-idler/
  └── steam-utility-multiplataform/
  ```

- [x] Register `steam-game-idler` and `steam-utility-multiplataform` as submodules in the parent repo.
- [x] Create/confirm remote for the parent `SGI` repo. (`bernardopg/SGI`)
- [x] Create Linux local workflow at `steam-game-idler/scripts/dev-linux.sh`.
- [x] Resolve `SteamUtility.Cli` per platform/env var.
- [x] Make the Tauri backend compile on Linux.
- [x] Fix crash caused by changes to `src-tauri/steam_appid.txt` during card farming.
- [x] Isolate each idle process in its own temporary directory.
- [x] Clean up helpers/temporary directories between runs.
- [x] Limit card farming on Linux to 8 concurrent Steam API sessions.
- [x] Disable unstable paths on Linux/dev:
  - native notifications in `tauri dev`;
  - custom context menu via `Menu.popup()`;
  - Turbopack in `next dev`.
- [x] Add `/health` for readiness checks.
- [x] Keep Turbopack disabled for Linux/dev until there is a future Next/Tauri/WebKitGTK stability reason to revisit it. (`next dev --webpack` remains mandatory for the Tauri dev WebView)
- [x] Decide that the Linux idler cap stays as a per-platform constant for now. (8 on Linux, 32 on Windows; documented in README/CLAUDE and hard-coded in `idling.rs`)
- [x] Ensure generated `steam_appid.txt` never lands in versioned/watched directories. (covered by `idling.rs` regression test and `git ls-files '*steam_appid.txt'`)

### Frontend cross-platform UI fixes

- [x] Remove hardcoded "Windows" from `runAtStartup` setting label and description across all 12 affected locales (de-DE, en-US, fr-FR, id-ID, it-IT, mk-MK, pl-PL, pt-BR, ru-RU, tr-TR, uk-UA, zh-CN). Text now uses `{{os}}` interpolation; `useGeneralSettings` detects `platform()` at runtime and injects `"Linux"` or `"Windows"` accordingly. pt-BR title also fixed: `"Iniciar com o Windows"` → `"Iniciar com o Sistema"`.
- [x] Add Linux platform guard to `UpdateButton.handleUpdate()` and `Menu.handleUpdate()`: check `latest.platforms['linux-x86_64']` before calling `update.downloadAndInstall()`, matching the guard already present in `useCheckForUpdates`. Also fixed `Menu.handleUpdate()` to fetch `latest` before `downloadAndInstall` (previously fetched after install, so `latest.major` check was racing against a completed install).
- [x] Fix toast width and visual polish: override HeroUI default `w-full` with `!w-[300px] !max-w-[300px]` on `base`, set `!w-auto` on the region container, reduce shadow to `shadow-lg`, reduce font weights and sizes for a more compact notification style, and slim the progress bar to `2px`.
- [x] Fix `check_for_updates` Rust guard in `src-tauri/src/lib.rs`: replaced fragile string-match on error with typed pattern match on `tauri_plugin_updater::Error::TargetNotFound` under `#[cfg(target_os = "linux")]`; guards "No updates available" `NotificationExt` call behind `#[cfg(not(target_os = "linux"))]` to avoid DBus dependency on Linux.
- [x] Fix `Menu.handleUpdate()` and `UpdateButton.handleUpdate()` catch blocks: `tauri-plugin-updater` throws a JS exception with `TargetNotFound` message before any platform guard runs, landing in `catch` and calling `showDangerToast` + `logEvent`. Fix: detect `linux-x86_64`/`platforms` in the error string and show `showPrimaryToast(checkUpdate.none)` instead — no error log.
- [x] Fix duplicate React key collisions in `IdlingGamesList` during card farming: `start_farm_idle` Rust command was pushing `ProcessInfo` for same `app_id` on repeated cycle calls. Fix: added dedup guard at top of per-game loop in `start_farm_idle` (`SPAWNED_PROCESSES.lock()?.iter().any(|p| p.app_id == game.app_id)`).
- [x] Audit `useTitlebar.windowClose`: confirmed `is_dev` path correctly uses `minimize()` (lines 28-31); confirmed `window.hide()` is correct in production Linux because `should_setup_tray_icon()` always enables tray in non-dev builds. No change needed.

### Linux compatibility audit (2026-05-19)

Full audit of all Linux-relevant paths across frontend TypeScript and Rust backend. Findings:

**Confirmed correct — no action needed:**
- `useContextMenu`: `platform()` called synchronously (no `await`) at effect setup; returns `'linux'` string causing `skipCustomMenu = true` before `Menu.popup()` is reached. Guard is correct and `Menu.popup()` never fires on Linux.
- `useCardFarming`: `getMaxFarmIdlers()` uses `platform()` with `await` correctly; returns `LINUX_MAX_FARM_IDLERS = 8` on Linux. Cap is enforced in both `processGamesWithDrops` and `processIndividualGames`.
- `useCheckForUpdates`: pre-check `fetchLatest()` → `platforms['linux-x86_64']` before `check()` on Linux is correct. No redundant install path.
- `updateTrayIcon` in `tasks.ts`: uses `TrayIcon.getById('1')` which returns `null` when tray not registered; guarded by `if (trayIcon)`. Errors caught and logged. Silent in dev/no-tray contexts.
- `update_tray_menu` Rust command: uses `app.tray_by_id("1")` with `if let Some(tray)` guard — no panic when tray absent. `useInit` calling it in dev with no tray just logs a harmless error.
- `check_start_minimized_setting` Rust: reads JSON settings file directly, no OS-specific behavior. Safe on all platforms.
- `ExportSettings.tsx / collectSystemInfo()`: correctly handles `linux` / `macos` / Windows with build number detection. No changes needed.
- `main.rs`: `#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]` applies only on Windows (cfg is compile-time on target). No Linux impact.
- `command_runner.rs`: `CREATE_NO_WINDOW` flag guarded by `#[cfg(windows)]` throughout. Linux path uses Unix process group logic.

**Gaps identified and tracked as remaining work:**
- `sendNativeNotification` in `tasks.ts`: has `!isTauri()` and `is_dev` guards but no `platform()` guard. On Linux, DBus/libnotify must be available; function silently skips if permission not granted (catch block calls `showDangerToast` which is excessive for a notification failure). See P2 item below.
- `tray.*` i18n keys (`tray.show`, `tray.update`, `tray.quit`): only present in `en-US`, `fr-FR`, `it-IT`, `ru-RU` out of 24 locales. Other 20 locales including `pt-BR`, `de-DE`, `zh-CN`, `es-ES` fall back to `en-US` values via i18next fallback. Tray menu shows English text in most locales. See P2 item below.
- `pt-BR` locale: missing `startMinimized.description` and `closeToTray.description` entries (both present in `en-US`). Falls back silently to English. See P2 item below.

### Validation completed so far

- [x] Validate:
  - `pnpm typecheck`;
  - `pnpm build`;
  - `cargo check`;
  - extended card farming run on Linux.
- [x] Test full flow after a clean clone with `git clone --recurse-submodules`.
- [x] Validate the real AUR package build on a clean Arch environment with `makepkg -si`. (confirmed in `archlinux:base-devel` container on 2026-04-28; package built and installed as `steam-game-idler-git 5.0.4.r1711.g56b6b4d2-1`)
- [x] Validate the release AUR package build/install in the `v5.0.6` release pipeline. (`AUR package` job succeeded and verified `/usr/bin/steam-game-idler`, `.desktop`, icon, and bundled `SteamUtility.Cli`)
- [x] Validate an actual Linux release bundle run. (`v5.0.6` produced `.deb`, `.rpm`, and AppImage successfully)
- [x] Validate Windows release bundle run. (`v5.0.6` produced NSIS installer and portable zip successfully)

### CI, release, and AUR automation

- [x] Add CI workflow for the parent workspace.
- [x] Add parent release workflow for SGI and validate it locally.
- [x] Push parent CI/release automation to `origin/master` and confirm GitHub Actions success.
- [x] Configure the `AUR_SSH_PRIVATE_KEY` secret in the `SGI` GitHub repo for automated AUR publishing.
- [x] Prepare AUR metadata for `steam-game-idler-git`.
- [x] Replace the legacy standalone `publish-aur.yml` with the gated `release.yml -> publish_aur` job.
- [x] Restrict `aur-build.yml` to PRs touching AUR packaging or manual dispatch.
- [x] Add release workflow guardrails:
  - `prepare` resolves `version`, `tag`, and `should_publish` once;
  - `publish_aur` and `publish_release` run only when `should_publish == true`;
  - dry-run dispatch builds artifacts without publishing AUR/GitHub release;
  - AUR `source=` is pinned to the exact parent commit SHA, not mutable `master`;
  - AUR `pkgver` is pinned to the release version plus submodule revision.
- [x] Fix pnpm setup drift in release jobs. (current workflows use `pnpm/action-setup@v6.0.5` and `PNPM_VERSION=10`)
- [x] Defensively inject `allowBuilds` for pnpm strict build dependencies in AUR/release builds when older submodule pointers lack it. (fixes `ERR_PNPM_IGNORED_BUILDS` for `@heroui/shared-utils`, `esbuild`, and `sharp`)
- [x] Publish `v5.0.6` through the full release pipeline and confirm:
  - CI gate success;
  - Linux and Windows bundles success;
  - AUR package build/install success;
  - AUR push success;
  - GitHub Release asset upload success.

### SteamUtility integration

- [x] Create an explicit contract between SGI and `SteamUtility.Cli` for commands and JSON. (`steam-game-idler/docs/STEAM_UTILITY_CONTRACT.md`)
- [x] Separate stdout JSON from native/Steam IPC logs to avoid broken parsing. (SGI parses utility stdout as JSON; `StdoutJsonContractTests` enforces JSON-only stdout for SGI command paths)
- [x] Add integration tests for:
  - `idle`;
  - `check_ownership`;
  - `get_achievement_data`;
  - achievement/stats mutations.
- [x] Decide versioning strategy between the app and the utility. (`docs/VERSIONING.md`)

### Upstream and maintenance

- [x] Compare branch/fork with upstream `zevnda/steam-game-idler`. (`docs/UPSTREAM_COMPARISON.md`; compared `origin/main` 358838ff with `upstream/main` e0f3b351 on 2026-05-14)
- [x] Split small PRs where it makes sense upstream. (`docs/UPSTREAM_PR_PLAN.md`)
- [x] Keep a changelog of Linux decisions. (`docs/LINUX_DECISIONS.md`)
- [x] Automate CI in the parent workspace with submodule updates.
- [x] Periodically re-check whether Turbopack is stable inside the Tauri/WebKitGTK dev WebView after future Next/Tauri/WebKitGTK upgrades. (`docs/TURBOPACK_RECHECK.md` defines triggers and procedure)

## Remaining work

### P1 - Live Linux release validation

- [ ] Run a live card-farming soak test for 2–4 hours on a real Steam session, monitoring:
  - WebKit crashes;
  - Steam IPC;
  - orphan `SteamUtility.Cli` processes;
  - `/tmp/steam-game-idler` cleanup.
- [ ] Verify Tauri permissions on an installed build, not just `tauri dev`.
- [ ] Manually install and launch the published Linux artifacts on clean desktop environments:
  - `.deb` on Debian/Ubuntu-like system;
  - `.rpm` on Fedora/openSUSE-like system;
  - AppImage on a clean Linux desktop with FUSE/runtime dependencies.
- [ ] Review tray, close-to-tray, and native notification behavior outside dev mode.
- [ ] Confirm the installed Linux app can find and execute the bundled `SteamUtility.Cli` without `SGI_STEAM_UTILITY_PATH`.

### P1 - Live Windows release validation

- [ ] Install and launch `steam-game-idler_5.0.6_x64-setup.exe` on a real Windows machine.
- [ ] Launch and exercise `steam-game-idler_5.0.6_x64-portable.zip` on a real Windows machine.
- [ ] Confirm the installed/portable Windows app finds bundled `SteamUtility.exe` and can run discovery commands.
- [ ] Run at least one real Steam-native command path through the Windows app with Steam running.

### P2 - i18n completeness

- [x] Add `tray.show`, `tray.update`, `tray.quit` keys to all 24 locales. Translation.json files use flat dotted keys; all locales were missing these — added native-language translations to every locale.
- [x] Add `settings.general.startMinimized.description` and `settings.general.closeToTray.description` to 14 locales that were missing them (ar-SA, cs-CZ, es-ES, et-EE, fi-FI, hi-IN, ja-JP, ko-KR, nl-NL, pt-BR, pt-PT, ro-RO, zh-CN, zh-TW). All 24 locales now have full coverage.
- [x] Audit remaining locales for `startMinimized.description` / `closeToTray.description` coverage — 14 locales missing (not just pt-BR); all fixed above.

### P2 - Notification hardening (Linux)

- [x] Refactor `sendNativeNotification` in `src/shared/utils/tasks.ts`: replaced `showDangerToast` in catch block with `logEvent`-only — a failed OS notification is not a user-facing error.
- [ ] Verify `sendNativeNotification` call in `handleCheckForFreeGames.ts` works correctly on Linux in an installed build (DBus present). Confirm the "Free Games Available!" notification fires and does not produce spurious toast errors.

### P2 - Packaging hardening

- [ ] Add an explicit installed-app smoke test for `.deb` and `.rpm` packages if a suitable container/VM path is practical.
- [ ] Add an AppImage smoke test that catches missing runtime dependencies without launching a full desktop session, if practical.
- [ ] Consider signing/updater artifact support once release key management is defined.

### P3 - Maintenance

- [ ] Re-check AUR install via `paru -S steam-game-idler-git` after the public AUR metadata cache refreshes.
- [ ] Revisit Linux idler concurrency only after new live soak data suggests changing the cap.

## Risks

- Windows regression from changes in process management.
- WebKitGTK instability with specific Tauri APIs.
- Steam IPC saturation with many simultaneous games.
- Version divergence between `steam-game-idler` and `steam-utility-multiplataform`.
- Release artifacts can build successfully in CI while still needing manual installed-app validation on real desktops.
