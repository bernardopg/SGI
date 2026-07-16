# Dependency Management

SGI is a release orchestrator. The application and SteamUtility CLI are Git
submodules, so their npm, Cargo, and NuGet manifests are not visible to
Dependabot in this repository.

- GitHub Actions dependencies are updated in this repository.
- Frontend and Rust dependencies are updated in `steam-game-idler`.
- NuGet dependencies are updated in `steam-utility-multiplataform`.
- A parent PR updates the two submodule pointers only after the submodule CI
  and the parent AUR build pass.

The Tauri Rust host, JavaScript API, and JavaScript CLI must share a major and
minor version. `pnpm check:tauri-versions` enforces this contract in CI.

For a local AUR package build with the Docker helper, mount the package
directory, not the repository root:

```bash
docker run --rm -v "$PWD/packaging/aur":/pkgbuild archlinux:latest \
  bash /pkgbuild/.docker-aur-build.sh
```
