# Fish Shell Configuration
# Place this file at: ~/.config/fish/config.fish
set -U fish_greeting
set -Ux ANDROID_HOME /opt/android-sdk
# Initialize Starship prompt
starship init fish | source

# Initialize zoxide (smarter cd command)
zoxide init fish | source

# Enable Vi key bindings
fish_vi_key_bindings

# Enable tab completion (Fish has this by default, but ensuring it's configured)
# Tab completion is built-in and enabled by default in Fish

bind -M insert \t accept-autosuggestion
# Bind 'jk' to escape insert mode and return to normal mode
# This allows you to press 'j' then 'k' quickly to exit insert mode
bind -M insert -m default jk backward-char force-repaint

alias vim="nvim"
alias c="clear"
alias vimd="nvim ."
alias zl="zellij"

if status is-interactive
    eval (zellij setup --generate-auto-start fish | string collect)
end
# Optional: Add some useful aliases
# alias ls='ls --color=auto'
# alias ll='ls -lah'
# alias cd='z'  # Use zoxide instead of cd

# Optional: Set default editor
# set -gx EDITOR vim

# Optional: Add custom colors for vi mode indicator
# function fish_mode_prompt
#     switch $fish_bind_mode
#         case default
#             set_color --bold red
#             echo '[N] '
#         case insert
#             set_color --bold green
#             echo '[I] '
#         case replace_one
#             set_color --bold yellow
#             echo '[R] '
#         case visual
#             set_color --bold magenta
#             echo '[V] '
#         case '*'
#             set_color --bold red
#             echo '[?] '
#     end
#     set_color normal
# end

# opencode
fish_add_path /home/tomi/.opencode/bin

test -f ~/.free-coding-models.env; and source ~/.free-coding-models.env  # free-coding-models-env

# >>> grok installer >>>
fish_add_path $HOME/.grok/bin
# <<< grok installer <<<

# Added by LM Studio CLI tool (lms)
set -gx PATH $PATH /home/tomi/.lmstudio/bin
