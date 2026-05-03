# Config Index

Quick map of where things live on this machine.

## Shell

| Tool | Path | Notes |
|---|---|---|
| zsh | `~/.zshrc` | aliases, functions, all plugin sources, prompt, fzf/zoxide/atuin/navi setup |
| zsh | `~/.zprofile` | runs at login (before `.zshrc`) |
| zsh | `~/.zshenv` | runs for every shell, env vars only |
| zsh plugins | `~/.zsh/` | `zsh-syntax-highlighting`, `zsh-autosuggestions`, `zsh-vi-mode`, `fzf-tab` |
| atuin | `~/.config/atuin/config.toml` | shell history backend |
| navi cheatsheets | `~/.local/share/navi/cheats/personal.cheat` | leader (`<Space>` in vi-normal mode) opens picker |
| tmux | `~/.tmux.conf` | terminal multiplexer |

## Git

| Tool | Path | Notes |
|---|---|---|
| git | `~/.gitconfig` | user, aliases, delta config |
| delta | `~/.config/delta/catppuccin.gitconfig` | included from `.gitconfig`, theme palette |

## Editor (Neovim)

| Tool | Path | Notes |
|---|---|---|
| primary nvim | `~/.config/nvim/init.vim` | vim-plug + CoC. Default when running `nvim` |
| primary nvim plugins | `~/.local/share/nvim/plugged/` | vim-plug install dir |
| CoC extensions | `~/.config/coc/extensions/` | LSP/lang services for CoC |
| CoC settings | `~/.config/nvim/coc-settings.json` | CoC config |
| lazyvim | `~/.config/lazyvim/` | secondary config, run via `lvim` alias |

## Terminal

| Tool | Path | Notes |
|---|---|---|
| kitty | `~/.config/kitty/kitty.conf` | terminal emulator |
| kitty theme | `~/.config/kitty/themes/catppuccin-mocha.conf` | included from `kitty.conf` |

## CLI utilities

| Tool | Path | Notes |
|---|---|---|
| bat | `~/.config/bat/config` | cat replacement (theme, style) |
| gh | `~/.config/gh/` | GitHub CLI |
| github-copilot | `~/.config/github-copilot/` | Copilot auth |

## macOS

| Tool | Path | Notes |
|---|---|---|
| Karabiner | `~/.config/karabiner/` | keyboard remapping |

## Claude Code

| Tool | Path | Notes |
|---|---|---|
| cc1 (default) | `~/.claude/` | Pro account session |
| cc2 (max) | `~/.claude-2/` | Max account, launched via `cc2` function |
| user CLAUDE.md | `~/.claude/CLAUDE.md` | global instructions |

## Misc

Other configs found in `~/.config/` (currently unmanaged but present): `agents`, `configstore`, `crush`, `firebase`, `fish`, `flutter`, `gcloud`, `ghc`, `GitHub`, `goose`, `iterm2`, `litellm`, `mc`, `mole`, `opencode`, `pgcli`, `rstudio`, `stripe`, `superpowers`, `texstudio`, `thefuck`, `wireshark`, `yarn`, `yazi`, `zed`.

---

## How to manage all this

Right now these files live in their default locations and are tracked nowhere. If you reformat your Mac tomorrow, you lose everything.

The standard fix is a **dotfiles repo** — one git repo (typically named `dotfiles`) containing the files you care about, and a tool to symlink them into place on a fresh machine.

### The four common approaches, ranked by complexity

**1. GNU stow** (simplest, most popular)

Each app gets a directory mirroring its target structure. `stow zsh` creates symlinks from your repo into `$HOME`. Your repo looks like:

```
~/dotfiles/
├── zsh/.zshrc
├── git/.gitconfig
├── nvim/.config/nvim/init.vim
└── kitty/.config/kitty/kitty.conf
```

On a new machine: `git clone … && cd dotfiles && stow zsh git nvim kitty`. That's it — symlinks created, originals preserved.

Pros: zero magic, just `ln -s` under the hood. Easy to read someone else's stow repo.
Cons: no templating (no per-machine differences without ugly hacks).

**2. chezmoi** (most powerful)

Tracks files via `chezmoi add ~/.zshrc`. Stores them in `~/.local/share/chezmoi/` with metadata. `chezmoi apply` materializes to `$HOME`.

Pros: cross-machine templating (different `.gitconfig` for work vs personal), encrypted secrets via age/gpg, password-manager integration, conditional logic.
Cons: real learning curve. Files aren't plain symlinks — they're rendered, which can confuse.

**3. yadm** (git, but for dotfiles)

Wraps git with `yadm add ~/.zshrc`, `yadm commit`, etc. The repo is a "bare" git repo at `~/.local/share/yadm/`. Files live in their real locations — no symlinks, no copies.

Pros: feels exactly like git. Files are real files.
Cons: less ecosystem than chezmoi, slightly less popular than stow.

**4. Bare git repo in `$HOME`** (the hacker move)

No tools. `git init --bare ~/.dotfiles && alias config='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'`. Then `config add .zshrc; config commit; config push`.

Pros: no dependencies. Maximum hacker cred.
Cons: easy to accidentally `git status` your entire `$HOME` if you forget the alias. Frequent footguns.

### What people actually do

- **Casual setup, one machine**: stow. ~80% of public dotfiles repos use this. Simplest mental model. Reading the [r/unixporn](https://reddit.com/r/unixporn) wikis, this is the default.
- **Multi-machine, syncs work + personal + remote dev box**: chezmoi. Worth the curve once you have 2+ machines.
- **Single power user, no machines to share with**: yadm or stow. Personal taste.

### Suggested first move

Make a `~/Projects/dotfiles` repo, push to GitHub (public is fine — no secrets in any of the files listed above), use **stow** to manage it. Start by stowing just `zsh`, `git`, and `nvim`. Add more over time.

Concrete steps when you're ready:

```bash
mkdir -p ~/Projects/dotfiles && cd ~/Projects/dotfiles
git init
brew install stow

# Move + symlink one file
mkdir -p zsh
mv ~/.zshrc zsh/.zshrc
stow -t ~ zsh   # creates ~/.zshrc → ~/Projects/dotfiles/zsh/.zshrc

# Repeat for git, nvim, kitty…
git add .
git commit -m "initial dotfiles"
gh repo create dotfiles --public --source=. --push
```

After that, every config edit is just an edit + `cd ~/Projects/dotfiles && git commit -am "tweak prompt"`.

### What to keep OUT of the repo

- Anything with API keys / tokens (e.g. `.config/gh/hosts.yml`, `.config/github-copilot/`, atuin keys)
- Per-machine state (`.local/share/atuin/history.db`, browser caches, anything in `~/Library`)
- Big binary blobs (LSP caches, plugin install dirs — `.local/share/nvim/plugged/` should be installable from the config, not stored)

Add a `.gitignore` covering `**/auth*.json`, `**/credentials*`, `**/*token*` to be safe.
