export PATH="$JAVA_HOME/bin:$PATH"
export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home"
export HOME="/Users/jcjustin"
export ANDROID_HOME="/Users/jcjustin/Library/Android/sdk"
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
export PGDATA="/opt/homebrew/var/postgresql@15"

export PYENV_ROOT="$HOME/.pyenv"
#export PATH="$PYENV_ROOT/bin:$PATH"
#export PATH="/usr/local/bin:$PATH"
#eval "$(pyenv init -)"


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/jcjustin/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/jcjustin/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/jcjustin/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/jcjustin/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Completion system (required before fzf-tab)
autoload -Uz compinit && compinit

# fzf-tab must load BEFORE syntax-highlighting and autosuggestions
source /Users/jcjustin/.zsh/fzf-tab/fzf-tab.plugin.zsh

source /Users/jcjustin/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /Users/jcjustin/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source /Users/jcjustin/.zsh/zsh-vi-mode/zsh-vi-mode.zsh

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
alias java11="/Library/Java/JavaVirtualMachines/zulu-11.jdk/Contents/Home/bin/java"
alias javac11="/Library/Java/JavaVirtualMachines/zulu-11.jdk/Contents/Home/bin/javac"
alias vim="nvim"

# bat = better cat. Auto-passthrough when piped, so safe to alias.
# Use \cat or `command cat` to get the original.
alias cat='bat --paging=never'

# eza = better ls (colors, git status, icons, tree).
# Use \ls or `command ls` to get the original.
alias ls='eza --group-directories-first --icons=auto'
alias ll='eza -lah --group-directories-first --icons=auto --git'
alias lt='eza --tree --level=2 --group-directories-first --icons=auto'

# Show images inline in kitty. `icat foo.png` instead of `kitty +kitten icat foo.png`.
alias icat='kitten icat'

# Project shortcuts — `~tt` works as a path anywhere (cd ~tt, ls ~tt, cat ~tt/foo)
hash -d tt=~/Projects/tippytop
alias tt='cd ~tt'

source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
source /opt/homebrew/opt/chruby/share/chruby/auto.sh
chruby ruby-3.2.2

export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
alias lvim='NVIM_APPNAME=lazyvim nvim'

eval $(thefuck --alias)

[ -f "/Users/jcjustin/.ghcup/env" ] && . "/Users/jcjustin/.ghcup/env" # ghcup-envexport PATH="$HOME/bin:$PATH"

# Created by `pipx` on 2026-01-07 11:34:01
export PATH="$PATH:/Users/jcjustin/.local/bin"

function aic() {
  local cmd
  cmd="$(ai-commit-cmd)" || return 1
  print -z -- "$cmd"     # insert into cursor
}

zle -N aic



# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
[[ ! -r '/Users/jcjustin/.opam/opam-init/init.zsh' ]] || source '/Users/jcjustin/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null
# END opam configuration

eval $(opam env)

cc1() {
  claude "$@"
}

cc2() {
  CLAUDE_CONFIG_DIR="$HOME/.claude-2" claude "$@"
}

# Fetch Claude Code usage limits via OAuth API (no need to launch the CLI).
# Mirrors the pattern in the statusline script: pull token from Keychain,
# call https://api.anthropic.com/api/oauth/usage with the oauth beta header.
_claude_usage() {
  local keychain_entry=$1 label=$2
  local blob token
  blob=$(security find-generic-password -s "$keychain_entry" -w 2>/dev/null)
  if [ -z "$blob" ]; then
    print -u2 "usage: no keychain entry '$keychain_entry' (is $label logged in?)"
    return 1
  fi
  token=$(printf '%s' "$blob" | jq -r '.claudeAiOauth.accessToken // empty')
  if [ -z "$token" ]; then
    print -u2 "usage: could not read access token for $label"
    return 1
  fi
  local resp
  resp=$(curl -s --max-time 5 \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $token" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage")
  if ! printf '%s' "$resp" | jq -e '.five_hour' >/dev/null 2>&1; then
    print -u2 "usage: unexpected response for $label: $resp"
    return 1
  fi
  printf '%s' "$resp" | jq -r --arg label "$label" '
    "\($label):  5h \(.five_hour.utilization // 0 | floor)%   7d \(.seven_day.utilization // 0 | floor)%   (7d resets \(.seven_day.resets_at // "n/a"))"
  '
}

cc1-usage() { _claude_usage "Claude Code-credentials"          "cc1 (pro)"; }
cc2-usage() { _claude_usage "Claude Code-credentials-950212fc" "cc2 (max)"; }

export CLOUDSDK_PYTHON=/Library/Frameworks/Python.framework/Versions/3.11/bin/python3
export PATH="$HOME/go/bin:$PATH"

# opencode
export PATH=/Users/jcjustin/.opencode/bin:$PATH

# ── Minimal prompt: cwd + git branch + ❯ ──────────────────────────────────
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' %F{yellow}(%b)%f'
setopt PROMPT_SUBST
PROMPT='%F{cyan}%~%f${vcs_info_msg_0_} ❯ '

# ── fzf (Ctrl-T file picker, Ctrl-R history, Alt-C cd) ────────────────────
source <(fzf --zsh)

# Catppuccin Mocha palette for fzf
export FZF_DEFAULT_OPTS="--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--color=border:#313244,label:#cdd6f4"

# ── fzf-tab tweaks ────────────────────────────────────────────────────────
# preview directories on cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null || ls -1 $realpath'
# show group headers, switch groups with < and >
zstyle ':fzf-tab:*' switch-group '<' '>'

# ── zoxide (use `z <dir>` to jump, `zi` for interactive) ──────────────────
eval "$(zoxide init zsh)"

# ── atuin (better Ctrl-R history) ─────────────────────────────────────────
eval "$(atuin init zsh --disable-up-arrow)"

# ── navi (cheatsheet launcher = "leader key" for the shell) ───────────────
# In vi normal mode, <Space> opens an fzf picker over ~/.local/share/navi/cheats/
# (mirrors the neovim <leader>=<Space> convention; insert-mode space is untouched).
eval "$(navi widget zsh)"

# Bind keys AFTER zsh-vi-mode finishes init, otherwise vi-mode clobbers them.
function zvm_after_init() {
  bindkey '^r' atuin-search           # Ctrl-R → atuin (insert mode)
  bindkey -M vicmd ' ' _navi_widget   # Space  → navi (normal mode only)
}

