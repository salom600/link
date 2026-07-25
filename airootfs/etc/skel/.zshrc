# ============================================================================
# LinkOS — ~/.zshrc
# Default zsh config for the linkos user.
# ============================================================================

# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ───────────────────────── History ─────────────────────────
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory
setopt incappendhistory
setopt histignoredups
setopt histignorespace
setopt histreduceblanks
setopt histverify
setopt extendedhistory

# ───────────────────────── Shell options ─────────────────────────
setopt autocd
setopt beep
setopt extendedglob
setopt nomatch
setopt notify
setopt correct
setopt completeinword
setopt promptsubst

# ───────────────────────── Key bindings ─────────────────────────
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[3~' delete-char

# ───────────────────────── Aliases ─────────────────────────
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -lah --color=auto --group-directories-first'
alias la='ls -A --color=auto --group-directories-first'
alias l='ls -CF --color=auto --group-directories-first'
alias grep='grep --color=auto'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias df='df -h'
alias du='du -h'
alias free='free -h'

alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias search='pacman -Ss'
alias aur='paru'
alias flatpak-update='flatpak update -y'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias c='clear'
alias h='history'
alias x='exit'
alias vim='nvim 2>/dev/null || vim'
alias vi='nvim 2>/dev/null || vim'
alias nano='nano -c'

alias reboot='sudo systemctl reboot'
alias shutdown='sudo systemctl poweroff'
alias suspend='systemctl suspend'

# LinkOS specific
alias linkos-help='cat /etc/motd'
alias linkos-install='sudo calamares'

# ───────────────────────── Functions ─────────────────────────
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2|*.tbz2) tar xjf "$1" ;;
            *.tar.gz|*.tgz)   tar xzf "$1" ;;
            *.tar.xz)         tar xJf "$1" ;;
            *.tar)            tar xf "$1" ;;
            *.bz2)            bunzip2 "$1" ;;
            *.gz)             gunzip "$1" ;;
            *.rar)            unrar x "$1" ;;
            *.7z)             7z x "$1" ;;
            *.zip)            unzip "$1" ;;
            *)                echo "Don't know how to extract '$1'..." ;;
        esac
    else
        echo "'$1' is not a valid file!"
    fi
}

mkcd() { mkdir -p "$1" && cd "$1"; }
ff() { find . -type f -iname "*$1*" 2>/dev/null; }

# ───────────────────────── Exports ─────────────────────────
export PATH="$PATH:$HOME/.local/bin:$HOME/.local/share/flatpak/exports/bin"
export EDITOR=nano
export VISUAL=nano
export TERMINAL=xfce4-terminal
export BROWSER=brave
export PAGER=less
export LANG=en_US.UTF-8

# ───────────────────────── Plugins ─────────────────────────
# Auto-suggestions
if [[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Syntax highlighting (must be last)
if [[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Completions
if [[ -f /usr/share/zsh/plugins/zsh-completions/zsh-completions.plugin.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-completions/zsh-completions.plugin.zsh
fi

# fzf
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh
fi
if [[ -f /usr/share/fzf/completion.zsh ]]; then
    source /usr/share/fzf/completion.zsh
fi

# zoxide (smart cd)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# ───────────────────────── Completion ─────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ───────────────────────── Welcome ─────────────────────────
if command -v fastfetch >/dev/null 2>&1; then
    fastfetch 2>/dev/null
elif command -v neofetch >/dev/null 2>&1; then
    neofetch --source /etc/os-release 2>/dev/null
fi
