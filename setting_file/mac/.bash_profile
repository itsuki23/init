export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# ~/.bashrc
#PS1="\u:\t \W $" # ユーザー名:時間 ディレクトリ名 $
# 31が赤で、32が緑です
#$ PS1="\[\033[31m\]\u:\t\[\033[0m\]\[\033[32m\] \W\[\033[0m\] $"

source ~/.git-prompt.sh

# 出力の後に改行を入れます
function add_line {
  if [[ -z "${PS1_NEWLINE_LOGIN}" ]]; then
    PS1_NEWLINE_LOGIN=true
  else
    printf '\n'
  fi
}
PROMPT_COMMAND='add_line'

export PS1='\[\e[37;100m\] \# \[\e[90;47m\]\[\e[30;47m\] \W \[\e[37m\]$(__git_ps1 "\[\e[37;102m\] \[\e[30m\] %s \[\e[0;92m\]")\[\e[49m\]\[\e[m\] \$ '

source ~/.bashrc
