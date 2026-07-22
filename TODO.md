# Linux/AUR Distribution Improvements

## High Priority

- [x] **MIME types + app cache file handler**
  - Register `application/x-steam-app-cache-file`
  - Update PKGBUILD `.desktop` `MimeType=` entry
  - Keep runtime handling out of scope unless a real deep-link path is added

- [x] **AppStream metainfo.xml**
  - Create `steam-game-idler.metainfo.xml` in `packaging/aur/`
  - Include: name, summary, description, screenshots, categories, releases, provides
  - Install to `/usr/share/metainfo/` in PKGBUILD

- [x] **tauri.conf.json Linux defaults**
  - Set `bundle.linux.appimage.bundleMediaFramework: true` (already present)
  - Added `bundle.fileAssociations` for `application/x-steam-app-cache-file` (generates MimeType= natively in .desktop)
  - Added `bundle.linux.deb.desktopTemplate` and `bundle.linux.rpm.desktopTemplate` pointing to `src-tauri/templates/linux.desktop.hbs`
  - Custom template features:
    - `Categories={{categories}}Utility;` (appends Utility to Tauri category)
    - `Comment={{long_description}}` (avoids duplicating the application name)
    - `StartupWMClass={{name}}` (avoids quoting issues)
    - Preserves `{{#if mime_type}}` block for file associations
  - Note: `createUpdaterArtifacts` remains `"v1Compatible"` in the base config for standalone upstream builds; SGI package builds disable it through the pin action and PKGBUILD because this repository does not publish updater metadata

- [x] **PKGBUILD improvements**
  - Add `optdepends`: `webkit2gtk-4.2`, `xdg-desktop-portal`, `libappindicator-gtk3`, `gstreamer`
  - Pin the published AUR source to the exact SGI release commit
  - Build AppImage separately in the release workflow; keep the AUR package based on the `.deb` bundle
  - Install AppStream metainfo in the AUR package
  - Add `check()` function for basic smoke test

- [ ] **Wayland fractional scaling fix**
  - Test `decorations: false` + `transparent: true` on GNOME 45+ / KDE 6
  - Consider `gtk:allow-gtk` capability for portal fallback
  - Add `WEBKIT_DISABLE_DMABUF_RENDERER=1` env var option

## Medium Priority

- [ ] **Portal API support (xdg-desktop-portal)**
  - Add `gtk:allow-gtk` to capabilities for file picker/screenshot portals
  - Test in Flatpak/sandboxed environment
  - Fallback to native dialogs when portal unavailable

- [x] **Systemd user service**
  - Create `steam-game-idler.service` in `packaging/aur/`
  - Install to `/usr/lib/systemd/user/`
  - Enable `systemctl --user enable steam-game-idler` for true boot start

- [ ] **SELinux/AppArmor profile**
  - Create basic AppArmor profile for `/usr/lib/steam-game-idler/steam-game-idler`
  - Allow: `~/.steam/**`, `~/.local/share/Steam/**`, network, dbus

- [ ] **Reproducible builds**
  - Pin submodule commits in release workflow
  - Use `--locked` for cargo, `--frozen-lockfile` for pnpm
  - Document build environment (rustc version, node version)

## Low Priority / Polish

- [x] **Shell completions**
  - Generate zsh/fish/bash completions for `SteamUtility.Cli`
  - Install to `/usr/share/zsh/site-functions/`, `/usr/share/fish/vendor_completions.d/`, `/usr/share/bash-completion/completions/`

- [x] **Man pages**
  - Create `steam-game-idler.1` and `SteamUtility.Cli.1`
  - Install to `/usr/share/man/man1/`

- [ ] **Flatpak manifest**
  - Manifest `SteamGameIdler.yml` is intentionally a non-building draft pending SDK extensions for Node/pnpm and .NET.
  - Complete the build modules and validate locally before submitting to Flathub.

- [ ] **Snapcraft.yaml**
  - Create `snapcraft.yaml` in `packaging/snap/`
  - Use `gnome-3-38` or `core22` base

- [ ] **Symbolic/dark icons**
  - Add `icons/symbolic/` variants
  - Add `@2` dark mode icons
  - Install to `hicolor/scalable/apps/`

- [ ] **DBus activation**
  - Register `SteamGameIdler` service
  - Single-instance enforcement
  - CLI activation via `dbus-send`

- [ ] **Hardware video decode**
  - Add `gstreamer` + `gst-plugins-bad` to optdepends
  - Test VA-API/VDPAU with WebKitGTK

- [ ] **Homebrew formula**
  - Create `Formula/steam-game-idler.rb` for Linuxbrew
