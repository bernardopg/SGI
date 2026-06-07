# Linux/AUR Distribution Improvements

## High Priority

- [ ] **MIME types + app cache file handler**
  - Register `application/x-steam-app-cache-file`
  - Update PKGBUILD `.desktop` `MimeType=` entry
  - Keep runtime handling out of scope unless a real deep-link path is added

- [ ] **AppStream metainfo.xml**
  - Create `steam-game-idler.metainfo.xml` in `packaging/aur/`
  - Include: name, summary, description, screenshots, categories, releases, provides
  - Install to `/usr/share/metainfo/` in PKGBUILD

- [ ] **tauri.conf.json Linux defaults**
  - Set `createUpdaterArtifacts: false` for Linux
  - Add `linux.appimage` config with `bundleMediaFramework: true`
  - Add `linux.mimeTypes` array
  - Add `linux.desktopTemplate` with `Categories=Game;Utility;`

- [ ] **PKGBUILD improvements**
  - Add `optdepends`: `webkit2gtk-4.2`, `xdg-desktop-portal`, `libappindicator-gtk3`, `gstreamer`
  - Pin source to tag for stable: `source=("git+https://github.com/bernardopg/SGI.git#tag=v${pkgver}")`
  - Build AppImage: `pnpm tauri build --bundles deb,appimage`
  - Install metainfo.xml and AppImage
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

- [ ] **Systemd user service**
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

- [ ] **Shell completions**
  - Generate zsh/fish/bash completions for `SteamUtility.Cli`
  - Install to `/usr/share/zsh/site-functions/`, `/usr/share/fish/vendor_completions.d/`, `/usr/share/bash-completion/completions/`

- [ ] **Man pages**
  - Create `steam-game-idler.1` and `SteamUtility.Cli.1`
  - Install to `/usr/share/man/man1/`

- [ ] **Flatpak manifest**
  - Create `org.zevnda.SteamGameIdler.yml` in `packaging/flatpak/`
  - Submit to Flathub

- [ ] **Snapcraft.yaml**
  - Create `snapcraft.yaml` in `packaging/snap/`
  - Use `gnome-3-38` or `core22` base

- [ ] **Symbolic/dark icons**
  - Add `icons/symbolic/` variants
  - Add `@2` dark mode icons
  - Install to `hicolor/scalable/apps/`

- [ ] **DBus activation**
  - Register `com.zevnda.steam-game-idler` service
  - Single-instance enforcement
  - CLI activation via `dbus-send`

- [ ] **Hardware video decode**
  - Add `gstreamer` + `gst-plugins-bad` to optdepends
  - Test VA-API/VDPAU with WebKitGTK

- [ ] **Homebrew formula**
  - Create `Formula/steam-game-idler.rb` for Linuxbrew
