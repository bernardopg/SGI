#!/usr/bin/env bash
set -euo pipefail
set -x

cat > /etc/pacman.d/mirrorlist << 'EOF'
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
EOF

# Disable download timeout for slow connections and enable parallel downloads
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
grep -q 'DisableDownloadTimeout' /etc/pacman.conf \
|| echo 'DisableDownloadTimeout' >> /etc/pacman.conf

echo "[1/6] System update + base-devel"
pacman -Syu --noconfirm --needed
pacman -S --noconfirm --needed base-devel git sudo

echo "[2/6] Install makedepends"
pacman -S --noconfirm --needed rust nodejs pnpm dotnet-sdk xdg-utils

echo "[3/6] Install Tauri system deps (webkit2gtk-4.1 is ~35 MB, patience...)"
pacman -S --noconfirm --needed \
webkit2gtk-4.1 gtk3 openssl libayatana-appindicator librsvg

echo "[4/6] Create builder user"
useradd -m builder 2>/dev/null || true
echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

echo "[5/6] Setup build dir"
mkdir -p /build
cp /pkgbuild/PKGBUILD /pkgbuild/.SRCINFO /build/
chown -R builder /build

echo "[6/6] makepkg full build"
sudo -u builder bash -c "
  cd /build
  makepkg -d --noconfirm --noprogressbar 2>&1
"

echo ""
echo "=== BUILD RESULT ==="
pkg=$(find /build -maxdepth 1 -name 'steam-game-idler-git-*.pkg.tar.zst' -print -quit)
if [[ -n "$pkg" ]]; then
    ls -lh "$pkg"
    echo "SUCCESS: package built"
else
    echo "FAIL: no .pkg.tar.zst found"
    exit 1
fi
