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

git clone "$AUR_REMOTE" "$WORK_DIR/$AUR_PACKAGE" 2>/dev/null || git init "$WORK_DIR/$AUR_PACKAGE"

cd "$WORK_DIR/$AUR_PACKAGE"
if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin "$AUR_REMOTE"
fi

cp "$REPO_ROOT/packaging/aur/PKGBUILD" ./PKGBUILD
cp "$REPO_ROOT/packaging/aur/.SRCINFO" ./.SRCINFO

git add PKGBUILD .SRCINFO

if git diff --cached --quiet; then
  echo "AUR package ${AUR_PACKAGE} is already up to date."
  exit 0
fi

git commit -m "Update ${AUR_PACKAGE}"
git push origin master
