# Versioning Strategy

## Decision

SGI releases are versioned at the parent workspace level. The parent release tag
is the source of truth for distributed artifacts:

- `steam-game-idler` app bundles (`.deb`, `.rpm`, AppImage, NSIS, portable zip)
- bundled `SteamUtility.Cli` binaries
- AUR package metadata
- vendored source archive

The two submodules keep their own internal versions, but a parent SGI release
pins both by Git submodule SHA. That pin is the compatibility contract for a
published build.

## Rules

- Parent tags use `vX.Y.Z`.
- `steam-game-idler/src-tauri/tauri.conf.json` may lag during development; the
  release workflow pins generated package metadata to the parent release
  version.
- `SteamUtility.Cli` does not need a matching semantic version for every app
  release. Compatibility is defined by the submodule SHA bundled into the parent
  release.
- Breaking command/output changes between SGI and `SteamUtility.Cli` must update
  `steam-game-idler/docs/STEAM_UTILITY_CONTRACT.md` and should be released
  through a parent SGI tag.
- AUR `pkgver` is generated from the parent repository and points at the exact
  parent commit being released.

## Practical Workflow

1. Land changes in `steam-utility-multiplataform` first when the CLI contract
   changes.
2. Land SGI app changes that consume the new contract.
3. Update the parent repo submodule pointers.
4. Cut one parent `vX.Y.Z` tag after CI passes.

This avoids pretending that the app and utility are independently releasable
when the desktop bundle ships them together.
