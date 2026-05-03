#!/usr/bin/env bash
# Bootstrap a fresh Mac with this dotfiles setup.
#
#   git clone <this-repo> ~/Projects/dotfiles
#   cd ~/Projects/dotfiles
#   ./bootstrap.sh
#
# Idempotent — safe to re-run.

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES"

# ─── Re-exec under arm64 if running under Rosetta on Apple Silicon ────────
if [[ "$(uname -m)" == "arm64" ]] && [[ "$(arch)" != "arm64" ]]; then
  echo "→ relaunching under arm64..."
  exec arch -arm64 "$0" "$@"
fi

step() { printf "\n\033[1;36m→ %s\033[0m\n" "$*"; }
note() { printf "  \033[2m%s\033[0m\n" "$*"; }

# ─── Homebrew ─────────────────────────────────────────────────────────────
step "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for this shell so subsequent commands work
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  note "already installed"
fi

# ─── CLI formulae ─────────────────────────────────────────────────────────
step "Brew formulae"
BREW_FORMULAE=(
  # Shell tooling that this dotfiles setup hard-depends on
  fzf zoxide atuin navi
  # Modern coreutils replacements (aliased in .zshrc)
  bat eza fd ripgrep
  # Git diff prettifier (referenced from .gitconfig)
  delta
  # Dotfiles management
  stow
  # thefuck — referenced in .zshrc
  thefuck
  # Required by .zshrc helper functions (cc1-usage / cc2-usage)
  jq
)
brew install "${BREW_FORMULAE[@]}" 2>&1 | grep -vE '^(Warning: .* is already installed|==> Auto-updat)' || true

# ─── Casks ────────────────────────────────────────────────────────────────
step "Brew casks"
BREW_CASKS=(
  kitty
)
brew install --cask "${BREW_CASKS[@]}" 2>&1 | grep -vE '^Warning: .* is already installed' || true

# ─── fzf shell integration ────────────────────────────────────────────────
step "fzf shell integration"
note "auto-loaded via 'source <(fzf --zsh)' in .zshrc — no setup needed"

# ─── zsh plugins (cloned, not from brew) ──────────────────────────────────
step "zsh plugins"
mkdir -p ~/.zsh
ZSH_PLUGINS=(
  "zsh-users/zsh-syntax-highlighting"
  "zsh-users/zsh-autosuggestions"
  "jeffreytse/zsh-vi-mode"
  "Aloxaf/fzf-tab"
)
for repo in "${ZSH_PLUGINS[@]}"; do
  name="${repo##*/}"
  if [ -d "$HOME/.zsh/$name" ]; then
    note "$name already cloned"
  else
    git clone --depth=1 "https://github.com/$repo" "$HOME/.zsh/$name"
  fi
done

# ─── vim-plug ─────────────────────────────────────────────────────────────
step "vim-plug (Neovim)"
PLUG_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
if [ -f "$PLUG_PATH" ]; then
  note "already installed"
else
  curl -fsSL --create-dirs -o "$PLUG_PATH" \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# ─── Symlink dotfiles into place via stow ─────────────────────────────────
step "Stowing dotfiles"
PACKAGES=(zsh git tmux nvim kitty bat delta navi)
for pkg in "${PACKAGES[@]}"; do
  if [ -d "$DOTFILES/$pkg" ]; then
    stow -t "$HOME" "$pkg"
    note "stowed $pkg"
  fi
done

# ─── Neovim plugins ───────────────────────────────────────────────────────
step "Installing Neovim plugins"
nvim --headless +PlugInstall +qa 2>&1 | tail -5 || true

# ─── Done ─────────────────────────────────────────────────────────────────
cat <<'EOF'

✓ Bootstrap complete.

Manual steps that aren't automated:
  • Open a new shell so the new .zshrc is sourced:   exec zsh
  • Open kitty (cask installs it; first-run sets up theme/font automatically)
  • Inside nvim, run :CocInstall coc-tsserver coc-prettier coc-json (etc.)
    for the language servers you actually use
  • atuin: optionally `atuin register -u <name> -e <email>` to sync history
    across machines
  • Karabiner-Elements: install separately if you want Caps→Esc/Ctrl
    (not in this dotfiles repo — has machine-specific state)

Language runtimes (Python / Node / Ruby / etc.) are NOT bootstrapped here.
This dotfiles repo deliberately stays out of the toolchain business — install
pyenv/nvm/conda/chruby/etc. on demand, OR consider switching to `mise` to
manage all of them with one tool:

    brew install mise
    echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
    mise use --global node@20 python@3.12

EOF
