#!/usr/bin/env bash
set -euo pipefail

AUR_PACKAGE="${AUR_PACKAGE:-steam-game-idler-git}"
AUR_REMOTE="${AUR_REMOTE:-ssh://aur@aur.archlinux.org/${AUR_PACKAGE}.git}"
WORK_DIR="${WORK_DIR:-$(mktemp -d)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# --- Compute the dynamic pkgver from the local SGI working tree -------------
#
# The PKGBUILD's pkgver() function would compute this at build time inside
# makepkg's $srcdir, but the AUR git repo metadata (and the AUR website's
# "Last Updated" column) is read from the static `pkgver=` line. Compute the
# same value here from the local checkout so the AUR repo is always pushed
# with an up-to-date version, matching what users will actually build.
compute_pkgver() {
  local appver rev hash
  local sgi_root="$REPO_ROOT"

  if [[ ! -f "$sgi_root/steam-game-idler/src-tauri/tauri.conf.json" ]]; then
    echo "publish-aur.sh: cannot find steam-game-idler/src-tauri/tauri.conf.json — submodule not initialized?" >&2
    return 1
  fi

  appver=$(grep -m1 '"version"' "$sgi_root/steam-game-idler/src-tauri/tauri.conf.json" \
    | sed -E 's/.*"version": "([^"]+)".*/\1/')
  rev=$(git -C "$sgi_root/steam-game-idler" rev-list --count HEAD)
  hash=$(git -C "$sgi_root/steam-game-idler" rev-parse --short HEAD)

  printf '%s.r%s.g%s' "$appver" "$rev" "$hash"
}

PKGVER=$(compute_pkgver)
echo "publish-aur.sh: computed pkgver=${PKGVER}"

# --- Stage PKGBUILD/.SRCINFO with that pkgver ------------------------------
# We patch the static `pkgver=` line in both files in place. Anchored to the
# beginning of the line so we don't accidentally substitute references inside
# the pkgver() function body. We avoid `makepkg --printsrcinfo` here because
# this script needs to run on plain ubuntu-latest where pacman/makepkg aren't
# available; .SRCINFO is a deterministic projection of PKGBUILD whose only
# pkgver-derived line is `\tpkgver = ...`, so a parallel sed keeps them in
# sync as long as no other PKGBUILD field changes — which is guaranteed
# because we only ever touch pkgver here.
STAGE_DIR="$WORK_DIR/stage"
mkdir -p "$STAGE_DIR"

cp "$REPO_ROOT/packaging/aur/PKGBUILD" "$STAGE_DIR/PKGBUILD"
cp "$REPO_ROOT/packaging/aur/.SRCINFO" "$STAGE_DIR/.SRCINFO"

sed -i -E "s/^pkgver=.*/pkgver=${PKGVER}/" "$STAGE_DIR/PKGBUILD"
sed -i -E "s/^\tpkgver = .*/\tpkgver = ${PKGVER}/" "$STAGE_DIR/.SRCINFO"

# Sanity check — make sure both files actually got the new version.
if ! grep -q "^pkgver=${PKGVER}$" "$STAGE_DIR/PKGBUILD"; then
  echo "publish-aur.sh: PKGBUILD was not patched correctly" >&2
  exit 1
fi
if ! grep -q "^	pkgver = ${PKGVER}$" "$STAGE_DIR/.SRCINFO"; then
  echo "publish-aur.sh: .SRCINFO was not patched correctly" >&2
  exit 1
fi

# --- Sync to the AUR git repo and commit/push only on a real change --------
git clone "$AUR_REMOTE" "$WORK_DIR/$AUR_PACKAGE" 2>/dev/null \
  || git init -b master "$WORK_DIR/$AUR_PACKAGE"

cd "$WORK_DIR/$AUR_PACKAGE"
if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin "$AUR_REMOTE"
fi

git config user.name >/dev/null 2>&1 \
  || git config user.name "${GIT_AUTHOR_NAME:-github-actions[bot]}"
git config user.email >/dev/null 2>&1 \
  || git config user.email "${GIT_AUTHOR_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}"

cp "$STAGE_DIR/PKGBUILD" ./PKGBUILD
cp "$STAGE_DIR/.SRCINFO" ./.SRCINFO

git add PKGBUILD .SRCINFO

if git diff --cached --quiet; then
  echo "publish-aur.sh: AUR package ${AUR_PACKAGE} is already up to date (pkgver=${PKGVER})."
  exit 0
fi

git commit -m "Update ${AUR_PACKAGE} to ${PKGVER}"
git push origin HEAD:master
