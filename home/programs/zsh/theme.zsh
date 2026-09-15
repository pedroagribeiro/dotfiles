# THEME
export ZSH=~/.oh-my-zsh
export TERM="xterm-256color"

# $ZSH_PROMPT ("starship" or "p10k") is set at the top of zshrc — see the note
# there for how to switch. Fall back to p10k when starship isn't installed, so
# hosts that haven't enabled the module still get a prompt.
if [[ "$ZSH_PROMPT" != p10k ]] && ! command -v starship >/dev/null; then
  ZSH_PROMPT=p10k
fi

if [[ "$ZSH_PROMPT" == p10k ]]; then
  ZSH_THEME="powerlevel10k/powerlevel10k"
else
  # Leave the prompt to starship; oh-my-zsh skips theme loading when unset.
  ZSH_THEME=""
fi

source $ZSH/oh-my-zsh.sh

if [[ "$ZSH_PROMPT" == p10k ]]; then
  # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
  source $DOTFILES/home/programs/zsh/themes/p10k.zsh
else
  # Config lives in home/programs/starship/starship.toml, symlinked to
  # ~/.config/starship.toml — edits apply in the next shell, no rebuild needed.
  eval "$(starship init zsh)"
fi
