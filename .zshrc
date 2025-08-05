# ------------------------------------------------------
# You may need to manually set your language environment
export LC_ALL=en_GB.UTF-8
export LANG=en_GB.UTF-8

# ENV if it's exists
[ -f $HOME/.zshenv ] && source $HOME/.zshenv

# Greetings
echo May the force be with you, $LOGNAME!
# ------------------------------------------------------

#options
setopt autocd

SHARE="/opt/homebrew/share"
fpath+=$SHARE/zsh/site-functions

# wd
wd() {
  . $HOME/.zsh/wd/wd.sh
}

fpath=($HOME/.zsh/wd $fpath)

autoload -Uz compinit
compinit

# yarn autompletion
source $HOME/.zsh/zsh-yarn-completions/zsh-yarn-completions.zsh

# autompletion preview
source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# syntax higlighting, order is important here, otherwise confilct when accepting suggestions
source $HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# vi mode
source $HOME/.zsh/zsh-vim-mode/zsh-vim-mode.plugin.zsh

KEYTIMEOUT=1

# VIM_MODE_INITIAL_KEYMAP=vicmd

MODE_CURSOR_VIINS="blinking bar"
MODE_CURSOR_VISUAL="steady block"

MODE_INDICATOR_VIINS='%F{15}%F{8}ins%f'
MODE_INDICATOR_VICMD='%F{10}%F{2}nrm%f'
MODE_INDICATOR_REPLACE='%F{9}%F{1}rpl%f'
MODE_INDICATOR_SEARCH='%F{13}%F{5}src%f'
MODE_INDICATOR_VISUAL='%F{12}%F{4}vis%f'
MODE_INDICATOR_VLINE='%F{12}%F{4}vln%f'

# should come after vi-mode
bindkey '^l' autosuggest-accept

# theme
autoload -U promptinit
promptinit

prompt pure

PURE_PROMPT_SYMBOL=➜
PURE_PROMPT_VICMD_SYMBOL=➜

# colours, please
export CLICOLOR=1

# eslint_d
export ESLINT_D_LOCAL_ESLINT_ONLY=true

# BAT theme
export BAT_THEME="Nord"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

export PATH="$HOME/.local/scripts:$PATH"

# Aliases
alias reload='source $HOME/.zshrc'
alias zshconfig="nvim $HOME/.zshrc"
alias l='ls -lFh'     #size,show type,human readable
alias la='ls -lAFh'   #long list,show almost all,show type,human readable
alias lr='ls -tRFh'   #sorted by date,recursive,show type,human readable
alias lt='ls -ltFh'   #long list,sorted by date,show type,human readable
alias ll='ls -l'      #long list
alias ssh='TERM=xterm-256color ssh'
alias ad=$HOME/scripts/audio.mjs
alias s="spotify"
alias pause="spotify pause"
alias play="spotify play"

# FZF
[ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh

# fnm
NODE_BINARY=$(which node)
export PATH=$HOME/.fnm:$PATH
export NODE_BINARY=$NODE_BINARY
eval "$(fnm env --use-on-cd)"

# issues with xcode finding node when building RN projects
alias ln-node='ln -s $NODE_BINARY /usr/local/bin/node'
alias unln-node='rm /usr/local/bin/node'
