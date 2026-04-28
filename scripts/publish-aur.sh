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

git clone "$AUR_REMOTE" "$WORK_DIR/$AUR_PACKAGE" 2>/dev/null || git init -b master "$WORK_DIR/$AUR_PACKAGE"

cd "$WORK_DIR/$AUR_PACKAGE"
if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin "$AUR_REMOTE"
fi

git config user.name >/dev/null 2>&1 || git config user.name "${GIT_AUTHOR_NAME:-github-actions[bot]}"
git config user.email >/dev/null 2>&1 || git config user.email "${GIT_AUTHOR_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}"

cp "$REPO_ROOT/packaging/aur/PKGBUILD" ./PKGBUILD
cp "$REPO_ROOT/packaging/aur/.SRCINFO" ./.SRCINFO

git add PKGBUILD .SRCINFO

if git diff --cached --quiet; then
  echo "AUR package ${AUR_PACKAGE} is already up to date."
  exit 0
fi

git commit -m "Update ${AUR_PACKAGE}"
git push origin HEAD:master
