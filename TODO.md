# TODO - SGI

## Current status

- SGI is the parent workspace for two submodules:
  - `steam-game-idler/` — Tauri/Next.js desktop app.
  - `steam-utility-multiplataform/` — cross-platform .NET Steam utility used by the app.
- Latest verified release: `v5.0.6` on 2026-05-14.
  - GitHub Actions release run `25874439239`: success.
  - GitHub Release: https://github.com/bernardopg/SGI/releases/tag/v5.0.6
  - AUR commit: `8153de0 Update steam-game-idler-git to 5.0.6.r1721.g6524fa73`.
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
