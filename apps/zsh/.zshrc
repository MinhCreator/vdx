# Exports
source "$ZDOTDIR/exports"
source "$ZDOTDIR/keys"

# Local secrets (not tracked by git)
[[ -f "$HOME/.config/secrets/env" ]] && source "$HOME/.config/secrets/env"

# Oh My Zsh
export ZSH="$HOME/.local/share/oh-my-zsh"
export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"
export ZSH_CUSTOM="$ZSH/custom"
ZSH_THEME=""
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump"
source "$ZSH/oh-my-zsh.sh"

# Functions
if [[ -d "$ZDOTDIR/functions" ]]; then
    fpath=("$ZDOTDIR/functions" $fpath)
    autoload -Uz "$ZDOTDIR/functions/"*(-.N:t)
fi

# Aliases
[[ -f "$ZDOTDIR/aliases" ]] && source "$ZDOTDIR/aliases"

# Prompt
eval "$(starship init zsh)"

# bun completions
[ -s "/home/diominvd/.local/state/bun/_bun" ] && source "/home/diominvd/.local/state/bun/_bun"
