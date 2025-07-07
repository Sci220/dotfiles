source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
atuin init fish | source
zoxide init fish | source
# Oh My Posh theme
oh-my-posh init fish --config ~/.config/oh-my-posh/ed.sci220.json | source
alias dfb='cd ~/dotfiles && ./backup.sh'
# Git
alias g 'git'
alias ga 'git add .'
alias gc 'git commit -m'
alias gs 'git status'
alias gp 'git push'
alias gl 'git pull'

# General
alias .. 'cd ..'
alias ... 'cd ../..'
