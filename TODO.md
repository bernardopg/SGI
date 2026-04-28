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

## Immediate next steps

- [ ] Push submodule commits before committing/pushing the parent repo.
- [ ] Test full flow after a clean clone with `git clone --recurse-submodules`.
- [ ] Configure the `AUR_SSH_PRIVATE_KEY` secret in the `SGI` GitHub repo for automated AUR publishing.
- [ ] Validate the real AUR package build on a clean Arch environment with `makepkg -si`.
- [ ] Run card farming for a longer window (2–4 hours), monitoring:
  - WebKit crashes;
  - Steam IPC;
  - orphan `SteamUtility.Cli` processes;
  - `/tmp/steam-game-idler` cleanup.
- [ ] Decide whether the Linux 8-idler limit will be a user setting or a per-platform constant.
- [ ] Investigate whether WebKit becomes stable with Turbopack in future Next/Tauri/WebKitGTK versions.

## P1 - Linux release stabilization

- [ ] Document Linux dependencies per distro.
- [x] Confirm `.deb` and AppImage build with `SteamUtility.Cli` bundled. (`build_release_linux` job added to `release.yml`)
- [ ] Validate an actual `build_release_linux` run on a test release.
- [ ] Verify Tauri permissions on an installed build, not just `tauri dev`.
- [ ] Test installation on a clean environment.
- [ ] Review tray, close-to-tray, and native notification behavior outside dev mode.
- [ ] Ensure generated `steam_appid.txt` never lands in versioned/watched directories.

## Bugs to fix in `release.yml`

- [ ] `pnpm/action-setup@v3` → `@v4` in `build_release_bundle` and `build_release_linux` (CI already uses `@v4`).
- [ ] `version: latest` → `10` in pnpm setup for both jobs (`latest` can break builds on a pnpm major release).
- [ ] `build_dotnet_linux` checks out HEAD of the `steam-utility-multiplataform` default branch without respecting the SHA pinned in the SGI submodule — the published binary can diverge from the tested version. Added `utility_ref` input (defaults to `main`) as a first step; long-term, wire up the pinned submodule SHA.

## P2 - SteamUtility integration

- [ ] Create an explicit contract between SGI and `SteamUtility.Cli` for commands and JSON.
- [ ] Separate stdout JSON from native/Steam IPC logs to avoid broken parsing.
- [ ] Add integration tests for:
  - `idle`;
  - `check_ownership`;
  - `get_achievement_data`;
  - achievement/stats mutations.
- [ ] Decide versioning strategy between the app and the utility.

## P3 - upstream and maintenance

- [ ] Compare branch/fork with upstream `zevnda/steam-game-idler`.
- [ ] Split small PRs where it makes sense upstream.
- [ ] Keep a changelog of Linux decisions.
- [ ] Automate CI in the parent workspace with submodule updates.

## Risks

- Windows regression from changes in process management.
- WebKitGTK instability with specific Tauri APIs.
- Steam IPC saturation with many simultaneous games.
- Version divergence between `steam-game-idler` and `steam-utility-multiplataform`.
