#!/usr/bin/env bash
# Installs Homebrew (if needed) and the apps from this repo's Brewfiles.
#
#   ./install.sh            ask whether to include developer tools
#   ./install.sh --dev      everyday apps + developer tools, no questions
#   ./install.sh --no-dev   everyday apps only, no questions
#
# Also works when piped from curl; see the repo README.
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/sethadam1/essential-mac-apps/main/install"
dev=ask

for arg in "$@"; do
  case "$arg" in
    --dev)    dev=yes ;;
    --no-dev) dev=no ;;
    -h|--help) sed -n '2,8p' "${BASH_SOURCE[0]:-$0}" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (try --help)" >&2; exit 1 ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS." >&2
  exit 1
fi

# Use the Brewfiles next to this script, or download them when piped from curl.
src_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [[ -f "$src_dir/Brewfile" ]]; then
  dir="$src_dir"
else
  dir="$(mktemp -d)"
  trap 'rm -rf "$dir"' EXIT
  for f in Brewfile Brewfile.dev; do
    curl -fsSL "$REPO_RAW/$f" -o "$dir/$f"
  done
fi

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if ! command -v brew >/dev/null 2>&1; then
  for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x "$p" ]] && eval "$("$p" shellenv)" && break
  done
fi

# Profile (read from the terminal so this also works when piped from curl)
if [[ "$dev" == ask ]]; then
  if [[ -r /dev/tty ]]; then
    read -r -p "Also install developer tools? [y/N] " answer </dev/tty
    [[ "$answer" =~ ^[Yy] ]] && dev=yes || dev=no
  else
    dev=no
  fi
fi

echo
echo "Note: the Mac App Store apps need you to be signed into the App Store first."
echo "Installs that fail are reported at the end; the rest still go through."
echo

status=0
brew bundle install --file="$dir/Brewfile" || status=$?
if [[ "$dev" == yes ]]; then
  brew bundle install --file="$dir/Brewfile.dev" || status=$?
fi

exit "$status"
