# TODO - SGI

## Done

- [x] Organize workspace with the structure:

  ```text
  SGI/
  ├── steam-game-idler/
  └── steam-utility-multiplataform/
  ```

- [x] Register `steam-game-idler` and `steam-utility-multiplataform` as submodules in the parent repo.
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
- [x] Validate:
  - `pnpm typecheck`;
  - `pnpm build`;
  - `cargo check`;
  - extended card farming run on Linux.
- [x] Prepare AUR metadata for `steam-game-idler-git`.
- [x] Add CI workflow for the parent workspace.
- [x] Add AUR publish workflow.
- [x] Create/confirm remote for the parent `SGI` repo. (repo `bernardopg/SGI` active; CI and AUR confirmed)
- [x] Add parent release workflow for SGI and validate it locally.
- [x] Push parent CI/release automation to `origin/master` and confirm GitHub Actions success. (`b29ec87`, CI run `25126274686`)
- [x] Decide that the Linux idler cap stays as a per-platform constant for now. (8 on Linux, 32 on Windows; documented in README/CLAUDE and hard-coded in `idling.rs`)
- [x] Keep Turbopack disabled for Linux/dev until there is a future Next/Tauri/WebKitGTK stability reason to revisit it. (`next dev --webpack` remains mandatory for Tauri dev WebView)

## Immediate next steps

- [x] Push submodule commits before committing/pushing the parent repo.
- [x] Test full flow after a clean clone with `git clone --recurse-submodules`.
- [x] Configure the `AUR_SSH_PRIVATE_KEY` secret in the `SGI` GitHub repo for automated AUR publishing.
- [x] Validate the real AUR package build on a clean Arch environment with `makepkg -si`. (confirmed in `archlinux:base-devel` container on 2026-04-28; package built and installed as `steam-game-idler-git 5.0.4.r1711.g56b6b4d2-1`)
- [x] Close the immediate Linux stabilization decisions: keep the 8-idler cap as a per-platform constant, keep Webpack for Linux/dev, and move the live 2–4h card-farming soak test to P1 because it requires an interactive Steam session.

## P1 - Linux release stabilization

- [ ] Run a live card-farming soak test for 2–4 hours on a real Steam session, monitoring:
  - WebKit crashes;
  - Steam IPC;
  - orphan `SteamUtility.Cli` processes;
  - `/tmp/steam-game-idler` cleanup.
- [x] Document Linux dependencies per distro. (`steam-game-idler/docs/content/docs/get-started/linux-dependencies.mdx` plus parent README runtime summary)
- [x] Confirm `.deb`, `.rpm`, and AppImage build paths with `SteamUtility.Cli` bundled. (`build_release_linux` job added to `release.yml`)
- [ ] Validate an actual `build_release_linux` run on a test release.
- [ ] Verify Tauri permissions on an installed build, not just `tauri dev`.
- [ ] Test installation on a clean environment.
- [ ] Review tray, close-to-tray, and native notification behavior outside dev mode.
- [x] Ensure generated `steam_appid.txt` never lands in versioned/watched directories. (covered by `idling.rs` regression test and `git ls-files '*steam_appid.txt'`)

## Bugs to fix in `release.yml`

- [x] `pnpm/action-setup@v3` → `@v4` in `build_release_bundle` and `build_release_linux`.
- [x] `version: latest` → `10` in pnpm setup for both jobs.
- [x] `build_dotnet_linux` always checks out HEAD of `steam-utility-multiplataform` default branch — resolved by the current parent release workflow, which checks out submodules recursively and builds `SteamUtility.Cli` from the pinned submodule SHA in `build_steamutility`.

## P2 - SteamUtility integration

- [x] Create an explicit contract between SGI and `SteamUtility.Cli` for commands and JSON. (`steam-game-idler/docs/STEAM_UTILITY_CONTRACT.md`)
- [x] Separate stdout JSON from native/Steam IPC logs to avoid broken parsing. (SGI parses utility stdout as JSON; `StdoutJsonContractTests` enforces JSON-only stdout for SGI command paths)
- [x] Add integration tests for:
  - `idle`;
  - `check_ownership`;
  - `get_achievement_data`;
  - achievement/stats mutations.
- [x] Decide versioning strategy between the app and the utility. (`docs/VERSIONING.md`)

## P3 - upstream and maintenance

- [x] Compare branch/fork with upstream `zevnda/steam-game-idler`. (`docs/UPSTREAM_COMPARISON.md`; compared `origin/main` 358838ff with `upstream/main` e0f3b351 on 2026-05-14)
- [x] Split small PRs where it makes sense upstream. (`docs/UPSTREAM_PR_PLAN.md`)
- [x] Keep a changelog of Linux decisions. (`docs/LINUX_DECISIONS.md`)
- [x] Automate CI in the parent workspace with submodule updates. (parent CI/release automation committed in `b29ec87`; CI run `25126274686` passed)
- [x] Periodically re-check whether Turbopack is stable inside the Tauri/WebKitGTK dev WebView after future Next/Tauri/WebKitGTK upgrades. (`docs/TURBOPACK_RECHECK.md` defines triggers and procedure)

## Risks

- Windows regression from changes in process management.
- WebKitGTK instability with specific Tauri APIs.
- Steam IPC saturation with many simultaneous games.
- Version divergence between `steam-game-idler` and `steam-utility-multiplataform`.
