#!/bin/bash

################################################################################################
# Editing Code> General Functions
################################################################################################

# Listar archivos/folderes de una carpeta.
# - Argumentos :
#   01 - Ruta del folder donde se busca los archivos.
#   02 - Usar '0' para incluir todos los archivos, incluido los temporales de desarrollo.
_g_fzf_fd=""
f-ls() {

    #1. Argumentos
    local l_include=1
    if [[ "$2" == "0" ]]; then
        l_include=0
    fi

    #2. Generar el comando
    if [ $l_include -eq 0 ]; then
        _t_fzf_cmd_1="fd -H -I"
    else
        _t_fzf_cmd_1="fd -H -E '.git' -E 'node_modules' -E '*.swp' -E '*.un~'"
    fi
    [ ! -z "$1" ] && _t_fzf_cmd_1="${_t_fzf_cmd_1} . '$1'"

    #echo "$_t_fzf_cmd_1"

    #3. Usar FZF
    FZF_DEFAULT_COMMAND="$_t_fzf_cmd_1" \
    fzf --prompt 'All> ' \
        --bind "ctrl-d:change-prompt(Directories> )+reload(${_t_fzf_cmd_1} -t d)" \
        --bind "ctrl-f:change-prompt(Files> )+reload(${_t_fzf_cmd_1} -t f)" \
        --header $'CTRL-D (Search directories), CTRL-F (Search files)\n'
}

# Buscar archivos con vista previa.
# - Argumentos :
#   01 - Ruta del folder donde se busca los archivos.
f-files() {
    local l_cmd_ls="fd -H -t f -E '.git' -E 'node_modules' -E '*.swp' -E '*.un~'"
    [ ! -z "$1" ] && l_cmd_ls="${l_cmd_ls} . '$1'"

    FZF_DEFAULT_COMMAND="$l_cmd_ls" \
    fzf --preview 'bat --style=numbers --color=always {}' -m --prompt 'File> ' \
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" \
        --bind "ctrl-z:execute:bat --style=numbers,header-filename,grid --color=always {}" \
        --header $'CTRL-z (Show in full-screen), SHIFT-↑/↓ (Navigate preview\'s pages)\n'
}

# Listar los procesos del SO
f-ps() {
    (echo "Date: $(date '+%F %T') (Use CTRL-r to reload screen)"; ps -ef) |
    fzf --bind=$'ctrl-r:reload(echo "Date: $(date \'+%F %T\') (Use CTRL-r to reload screen)"; ps -ef)' \
        --prompt 'Process> ' --header-lines=2 \
        --preview='echo {}' --preview-window=down,3,wrap \
        --layout=reverse --height=80% | awk '{print $2}'
}        

_g_fzf_rg="rg --column --line-number --no-heading --color=always --smart-case "
_g_fzf_rg_initial_query="${*:-}"

f-rg() {
    FZF_DEFAULT_COMMAND="$_g_fzf_rg $(printf %q "$_g_fzf_rg_initial_query")" \
    fzf --ansi \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --disabled --query "$_g_fzf_rg_initial_query" \
        --bind "change:reload:sleep 0.1; $_g_fzf_rg {q} || true" \
        --bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(2. fzf> )+enable-search+rebind(ctrl-r)+transform-query(echo {q} > /tmp/rg-fzf-r; cat /tmp/rg-fzf-f)" \
        --bind "ctrl-r:unbind(ctrl-r)+change-prompt(1. ripgrep> )+disable-search+reload($_g_fzf_rg {q} || true)+rebind(change,ctrl-f)+transform-query(echo {q} > /tmp/rg-fzf-f; cat /tmp/rg-fzf-r)" \
        --bind "start:unbind(ctrl-r)" \
        --prompt '1. ripgrep> ' \
        --delimiter : \
        --header 'CTRL-r (ripgrep mode), CTRL-f (fzf mode)' \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --bind 'enter:become(vim {1} +{2})'
}

f-rg1() {
    FZF_DEFAULT_COMMAND="$_g_fzf_rg $(printf %q "$_g_fzf_rg_initial_query")" \
    fzf --ansi \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --disabled --query "$_g_fzf_rg_initial_query" \
        --bind "change:reload:sleep 0.1; $_g_fzf_rg {q} || true" \
        --bind "alt-enter:unbind(change,alt-enter)+change-prompt(2. fzf> )+enable-search+clear-query" \
        --prompt '1. ripgrep> ' \
        --delimiter : \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --bind 'enter:become(vim {1} +{2})'
}

################################################################################################
# Editing Code> GIT Functions
################################################################################################

#01. Search for commit with FZF preview and copy hash
#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
#    > [CTRL + y]    - Ver el detalle de commit y navegar en sus paginas
#    > [ENTER]       - Copiar el hash del commit en portapapeles de windows
#    > [SHIFT + ↓/↑] - Cambio de pagina en la vista de preview
#
alias glog='git log --color=always --format="%C(cyan)%h%Creset %C(blue)%ar%Creset%C(auto)%d%Creset %C(yellow)%s%+b %C(white)%ae%Creset" "$@"'
#¿que pase si en la linea ({}) existe una comilla? ... ¿como se ejecuta el comando?
_g_fzf_glog_hash="echo {} | grep -o '[a-f0-9]\{7\}' | head -1"
_g_fzf_glog_view="$_g_fzf_glog_hash | xargs git show --color=always | delta"

f-glog() {
    #Obtener el directorio .git pero no imprimir su valor ni los errores. Si no es un repositorio valido salir
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo 'Invalid git repository'
        return 0
    fi

    #Mostrar los commit y su preview
    glog | fzf -i -e --no-sort --reverse --tiebreak index -m --ansi \
        --preview "$_g_fzf_glog_view" \
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" --bind "ctrl-z:execute:$_g_fzf_glog_view" \
        --header $'CTRL-z (Show in full-screen), SHIFT-↑/↓ (Navigate preview\'s pages)\n' \
        | grep -o '[a-f0-9]\{7\}' 
        #--print-query 
}

#Usando las funciones de ...

# Redefine this function to change the options
_fzf_git_fzf() {
  fzf-tmux -p80%,60% -- \
    --layout=reverse --multi --height=50% --min-height=20 --border \
    --color='header:italic:underline' \
    --preview-window='right,50%,border-left' \
    --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' "$@"
}

_fzf_git_check() {
  git rev-parse HEAD > /dev/null 2>&1 && return

  [[ -n $TMUX ]] && tmux display-message "Not in a git repository"
  return 1
}

__fzf_git=~/.files/terminal/linux/functions/fzf-git.sh

if [[ -z $_fzf_git_cat ]]; then
  # Sometimes bat is installed as batcat
  export _fzf_git_cat="cat"
  _fzf_git_bat_options="--style='${BAT_STYLE:-full}' --color=always --pager=never"
  if command -v batcat > /dev/null; then
    _fzf_git_cat="batcat $_fzf_git_bat_options"
  elif command -v bat > /dev/null; then
    _fzf_git_cat="bat $_fzf_git_bat_options"
  fi
fi

#for Files
f-gfiles() {
  _fzf_git_check || return
  (git -c color.status=always status --short
   git ls-files | grep -vxFf <(git status -s | grep '^[^?]' | cut -c4-; echo :) | sed 's/^/   /') |
  _fzf_git_fzf -m --ansi --nth 2..,.. \
    --prompt '📁 Files> ' \
    --header $'CTRL-O (open in browser) ╱ ALT-E (open in editor)\n\n' \
    --bind "ctrl-o:execute-silent:bash $__fzf_git file {-1}" \
    --bind "alt-e:execute:${EDITOR:-vim} {-1} > /dev/tty" \
    --preview "git diff --no-ext-diff --color=always -- {-1} | sed 1,4d; $_fzf_git_cat {-1}" "$@" |
  cut -c4- | sed 's/.* -> //'
}

#for Branches
f-gbranches() {
  _fzf_git_check || return
  bash "$__fzf_git" branches |
  _fzf_git_fzf --ansi \
    --prompt '🌲 Branches> ' \
    --header-lines 2 \
    --tiebreak begin \
    --preview-window down,border-top,40% \
    --color hl:underline,hl+:underline \
    --no-hscroll \
    --bind 'ctrl-/:change-preview-window(down,70%|hidden|)' \
    --bind "ctrl-o:execute-silent:bash $__fzf_git branch {}" \
    --bind "alt-a:change-prompt(🌳 All branches> )+reload:bash \"$__fzf_git\" all-branches" \
    --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1)' "$@" |
  sed 's/^..//' | cut -d' ' -f1
}

#for Tags
f-gtags() {
  _fzf_git_check || return
  git tag --sort -version:refname |
  _fzf_git_fzf --preview-window right,70% \
    --prompt '📛 Tags> ' \
    --header $'CTRL-O (open in browser)\n\n' \
    --bind "ctrl-o:execute-silent:bash $__fzf_git tag {}" \
    --preview 'git show --color=always {}' "$@"
}

#for commit Hashes
f-ghashes() {
  _fzf_git_check || return
  git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
  _fzf_git_fzf --ansi --no-sort --bind 'ctrl-s:toggle-sort' \
    --prompt '🍡 Hashes> ' \
    --header $'CTRL-O (open in browser) ╱ CTRL-D (diff) ╱ CTRL-S (toggle sort)\n\n' \
    --bind "ctrl-o:execute-silent:bash $__fzf_git commit {}" \
    --bind 'ctrl-d:execute:grep -o "[a-f0-9]\{7,\}" <<< {} | head -n 1 | xargs git diff > /dev/tty' \
    --color hl:underline,hl+:underline \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | head -n 1 | xargs git show --color=always' "$@" |
  awk 'match($0, /[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]*/) { print substr($0, RSTART, RLENGTH) }'
}

#for Remotes
f-gremotes() {
  _fzf_git_check || return
  git remote -v | awk '{print $1 "\t" $2}' | uniq |
  _fzf_git_fzf --tac \
    --prompt '📡 Remotes> ' \
    --header $'CTRL-O (open in browser)\n\n' \
    --bind "ctrl-o:execute-silent:bash $__fzf_git remote {1}" \
    --preview-window right,70% \
    --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" {1}/"$(git rev-parse --abbrev-ref HEAD)"' "$@" |
  cut -d$'\t' -f1
}

#for Stashes
f-gstashes() {
  _fzf_git_check || return
  git stash list | _fzf_git_fzf \
    --prompt '🥡 Stashes> ' \
    --header $'CTRL-X (drop stash)\n\n' \
    --bind 'ctrl-x:execute-silent(git stash drop {1})+reload(git stash list)' \
    -d: --preview 'git show --color=always {1}' "$@" |
  cut -d: -f1
}

#for Each ref (git for-each-ref)
f-gfor-each-ref() {
  _fzf_git_check || return
  bash "$__fzf_git" refs | _fzf_git_fzf --ansi \
    --nth 2,2.. \
    --tiebreak begin \
    --prompt '☘️  Each ref> ' \
    --header-lines 2 \
    --preview-window down,border-top,40% \
    --color hl:underline,hl+:underline \
    --no-hscroll \
    --bind 'ctrl-/:change-preview-window(down,70%|hidden|)' \
    --bind "ctrl-o:execute-silent:bash $__fzf_git {1} {2}" \
    --bind "alt-e:execute:${EDITOR:-vim} <(git show {2}) > /dev/tty" \
    --bind "alt-a:change-prompt(🍀 Every ref> )+reload:bash \"$__fzf_git\" all-refs" \
    --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" {2}' "$@" |
  awk '{print $2}'
}


################################################################################################
# K8S Functions
################################################################################################

f-kpods() {
    local l_cmd="kubectl get pods"
    #local l_cmd="kubectl get pods --all-namespaces"
    [ ! -z "$1" ] && l_cmd_ls="${l_cmd} -n '$1'"
    FZF_DEFAULT_COMMAND="$l_cmd" \
    fzf --info=inline --layout=reverse --header-lines=1 \
        --prompt "$(kubectl config current-context | sed 's/-context$//')> " \
        --header $'Enter (kubectl exec), CTRL-o (open log in editor), CTRL-r (reload)\n' \
        --bind 'ctrl-/:change-preview-window(80%,border-bottom|hidden|)' \
        --bind 'enter:execute:kubectl exec -it --namespace {1} {2} -- bash > /dev/tty' \
        --bind 'ctrl-o:execute:${EDITOR:-vim} <(kubectl logs --all-containers --namespace {1} {2}) > /dev/tty' \
        --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' \
        --preview-window up:follow \
        --preview 'kubectl logs --follow --all-containers --tail=10000 {1} ' "$@"
        #--preview 'kubectl logs --follow --all-containers --tail=10000 --namespace {1} {2}' "$@"
}

f-opods() {
    local l_cmd="oc get pods"
    [ ! -z "$1" ] && l_cmd_ls="${l_cmd} -n '$1'"
    FZF_DEFAULT_COMMAND="$l_cmd" \
    fzf --info=inline --layout=reverse --header-lines=1 \
        --prompt "$(kubectl config current-context | sed 's/-context$//')> " \
        --header $'Enter (oc exec), CTRL-o (open log in editor), CTRL-r (reload)\n' \
        --bind 'ctrl-/:change-preview-window(80%,border-bottom|hidden|)' \
        --bind 'enter:execute:oc exec -it --namespace {1} {2} -- bash > /dev/tty' \
        --bind 'ctrl-o:execute:${EDITOR:-vim} <(oc logs --all-containers --namespace {1} {2}) > /dev/tty' \
        --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' \
        --preview-window up:follow \
        --preview 'oc logs --follow --all-containers --tail=10000 {1} ' "$@"
        #--preview 'oc logs --follow --all-containers --tail=10000 --namespace {1} {2}' "$@"
}


