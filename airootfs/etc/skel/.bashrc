# ============================================================================
# LinkOS — ~/.bashrc
# Default shell config (bash is the default user shell until zsh replaces it).
# ============================================================================

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ───────────────────────── History ─────────────────────────
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend
shopt -s checkwinsize
shopt -s cdspell
shopt -s dirspell
shopt -s globstar

# ───────────────────────── Prompt ─────────────────────────
# Custom LinkOS prompt (red green blue yellow style)
PS1='\[\033[01;36m\]┌─[\[\033[01;34m\]\u@\h\[\033[01;36m\]]─[\[\033[01;33m\]\w\[\033[01;36m\]]\n\[\033[01;36m\]└─\[\033[01;32m\]\$\[\033[00m\] '

# ───────────────────────── Aliases ─────────────────────────
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -lah --color=auto --group-directories-first'
alias la='ls -A --color=auto --group-directories-first'
alias l='ls -CF --color=auto --group-directories-first'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias ln='ln -iv'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias diff='diff --color=auto'

# Apps
alias brave='brave --force-dark-mode 2>/dev/null || brave'
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias search='pacman -Ss'
alias owned='pacman -Qo'
alias files='pacman -Ql'
alias info='pacman -Qi'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null'
alias aur='paru'
alias flatpak-update='flatpak update -y'
alias flatpak-install='flatpak install flathub'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Quick
alias c='clear'
alias h='history'
alias j='jobs -l'
alias x='exit'
alias :q='exit'
alias vim='nvim 2>/dev/null || vim'
alias vi='nvim 2>/dev/null || vim'
alias nano='nano -c'

# System
alias ports='sudo netstat -tulanp'
alias meminfo='free -m -l -t'
alias psmem='ps auxf | sort -nr -k 4 | head -10'
alias pscpu='ps auxf | sort -nr -k 3 | head -10'
alias cpuinfo='lscpu'
alias gpumem='watch -n.5 nvidia-smi --query-gpu=memory.used,memory.free,memory.total --format=csv'

# Power
alias reboot='sudo systemctl reboot'
alias shutdown='sudo systemctl poweroff'
alias suspend='systemctl suspend'
alias hibernate='systemctl hibernate'

# LinkOS
alias linkos-help='cat /etc/motd'
alias linkos-install='sudo calamares'

# ───────────────────────── Functions ─────────────────────────
# Extract any archive
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2|*.tbz2) tar xjf "$1" ;;
            *.tar.gz|*.tgz)   tar xzf "$1" ;;
            *.tar.xz)         tar xJf "$1" ;;
            *.tar.7z)         7z x "$1" ;;
            *.tar)            tar xf "$1" ;;
            *.bz2)            bunzip2 "$1" ;;
            *.gz)             gunzip "$1" ;;
            *.rar)            unrar x "$1" ;;
            *.7z)             7z x "$1" ;;
            *.zip)            unzip "$1" ;;
            *.Z)              uncompress "$1" ;;
            *)                echo "Don't know how to extract '$1'..." ;;
        esac
    else
        echo "'$1' is not a valid file!"
    fi
}

# Make dir & cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Find file by name
ff() {
    find . -type f -iname "*$1*" 2>/dev/null
}

# ───────────────────────── Exports ─────────────────────────
export PATH="$PATH:$HOME/.local/bin:$HOME/.local/share/flatpak/exports/bin"
export EDITOR=nano
export VISUAL=nano
export TERMINAL=xfce4-terminal
export BROWSER=brave
export PAGER=less
export LANG=en_US.UTF-8

# ───────────────────────── Welcome ─────────────────────────
if command -v neofetch >/dev/null 2>&1; then
    neofetch --source /etc/os-release 2>/dev/null
fi

# ───────────────────────── Bash completion ─────────────────────────
if [[ -f /etc/bash_completion ]]; then
    . /etc/bash_completion
fi
if [[ -f /usr/share/bash-completion/completions ]]; then
    . /usr/share/bash-completion/bash_completion
fi

# ───────────────────────── zoxide (smart cd) ─────────────────────────
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

# ───────────────────────── Starship prompt (if installed) ─────────────────────────
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi
