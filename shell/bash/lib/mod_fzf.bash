#!/bin/bash

[ -z "$MY_REPO_PATH" ] && MY_REPO_PATH=~/.files

#Carpetas de archivos temporales ¿porque usar la memoria y no usar "/var/tmp/"?
_g_tmp_data_path="/tmp/.files"
if [ ! -d "$_g_tmp_data_path" ]; then
    mkdir -p $_g_tmp_data_path
fi

#Identificador de una session interactiva (usuario y id por sesion)
if [ -z "$_g_uid" ]; then
    #ID del proceso del interprete shell actual (pueder ser bash o no)
    _g_uid="$$"
fi


################################################################################################
# FZF> General Functions
################################################################################################
#
# > El valor de algunas opciones de 'fzf', como '--bind', el script a ejecutar se calcula cada vez que se ejecuta el keymap.
#   Por tal motivo, las variables usados dentro del valor de esta opcion debe ser una variable global, no puede ser local.
#

# Constantes
g_fzf_height='60%'
g_fzf_popup_height='80%'
g_fzf_popup_width='99%'

# Permite gestionar las 'tmux session':
#  > Listar e ir a sesiones activas
#  > Listar folderes para abrir/seleionar una sesion tmux usando esta ruta
# Parametro de entrada:
#  > Folder donde buscar para crear sesiones
s () {

    local l_path="$g_code_folder_path"
    if [ ! -z "$1" ]; then
        l_path="$1"
    fi

    #if [ ! -d "$l_path" ]; then
    #    printf 'La ruta ingresada "%b%s%b" no existe o no se tiene permisos.\n' "$g_color_gray1" "$l_path" "$g_color_reset"
    #    return 2
    #fi

    ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_tmux_sesh.bash "new_or_choose_tmux_session" "$l_path"
    return $?

}


# Listar archivos/folderes de una carpeta.
# - Argumentos :
#   01 - Ruta del folder donde se busca los archivos.
#   02 - Usar '0' para incluir todos los archivos, incluido los temporales de desarrollo.
_g_fzf_fd=""
ge_ls() {

    #1. Argumentos
    local l_include=1
    if [ "$2" = "0" ]; then
        l_include=0
    fi

    #2. Generar el comando
    if [ $l_include -eq 0 ]; then
        _g_fzf_fd="fd -H -I"
    else
        _g_fzf_fd="fd -H -E '.git' -E 'node_modules' -E '*.swp' -E '*.un~'"
    fi
    [ ! -z "$1" ] && _g_fzf_fd="${_g_fzf_fd} . '$1'"

    #echo "$_g_fzf_fd"


    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    #3. Usar FZF
    FZF_DEFAULT_COMMAND="$_g_fzf_fd" \
    $l_fzf_cmd $l_fzf_size_args --prompt 'All> ' \
        --bind "ctrl-d:change-prompt(📁 Directories> )+reload(${_g_fzf_fd} -t d)" \
        --bind "ctrl-f:change-prompt(📄 Files> )+reload(${_g_fzf_fd} -t f)" \
        --header $'CTRL-d (Search directories), CTRL-f (Search files)\n'

}

# Buscar archivos con vista previa.
# > Argumentos :
#   > 01 - Ruta del folder donde se busca los archivos.
ge_files() {

    local l_cmd_ls="fd -H -t f -E '.git' -E 'node_modules' -E '*.swp' -E '*.un~'"
    [ ! -z "$1" ] && l_cmd_ls="${l_cmd_ls} . '$1'"

    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    FZF_DEFAULT_COMMAND="$l_cmd_ls" \
    $l_fzf_cmd $l_fzf_size_args --preview "bat --color=always --style=numbers,header-filename {}" \
        --prompt '📄 File> ' -m \
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" \
        --bind "ctrl-a:execute:bat --color=always --paging always --style=numbers,header-filename {}" \
        --preview-window "right,60%" \
        --header $'CTRL-a (Show in full-screen), SHIFT-↑/↓ (Navigate preview\'s pages)\n'

}

# Listar los procesos del SO
ge_ps() {

    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    (echo "Date: $(date '+%F %T') (Use CTRL-r to reload screen)"; ps -ef) |
    $l_fzf_cmd $l_fzf_size_args --bind=$'ctrl-r:reload(echo "Date: $(date \'+%F %T\') (Use CTRL-r to reload screen)"; ps -ef)' \
        --prompt '🔧 Process> ' --header-lines=2 \
        --preview='echo {}' --preview-window=down,3,wrap \
        --layout=reverse --height=80% | awk '{print $2}'

}

_g_fzf_rg_cmd=''
_g_fzf_rg_initial_query=""


_ge_rg_open_vim() {

    local p_result="$1"

    local -A processed_files
    local -a files_to_open=()
    local -a line_numbers=()

    # Procesar cada línea
    while IFS= read -r line; do

        if [[ "$line" =~ ^([^:]+):([0-9]+):([0-9]+): ]]; then
            file="${BASH_REMATCH[1]}"
            line_num="${BASH_REMATCH[2]}"

            if [[ -z "${processed_files[$file]}" ]]; then
                processed_files["$file"]=1
                files_to_open+=("$file")
                line_numbers+=("$line_num")
            fi
        fi

    done <<< "$p_result"

    # Verificar si hay resultados
    if [[ ${#files_to_open[@]} -eq 0 ]]; then
        echo "No se encontraron archivos para abrir"
        exit 0
    fi

    # Usar argumentos de array para manejar mejor los espacios
    local -a vim_args=()

    # Primer archivo con su línea
    vim_args+=("+${line_numbers[0]}")
    vim_args+=("${files_to_open[0]}")

    # Archivos restantes
    for ((i=1; i<${#files_to_open[@]}; i++)); do
        vim_args+=("-c")
        vim_args+=("edit ${files_to_open[$i]}")
        vim_args+=("-c")
        vim_args+=("${line_numbers[$i]}")
    done

    # Ejecutar vim
    #printf '"%s"\n' "${vim_args[@]}"
    vim "${vim_args[@]}"

}


#Uselo para buscar contenido de archivos en carpetas (recursivamente).
#Restricciones:
# - No es pensado para busqueda en un archivo use directamente el comando 'ripgrep' o simplemente 'grep'.
# - Solo permite la busqueda de un query de busqueda. No esta diseñado usar muilples query con '-e' o '-f'.
# - RipGrep solo esta pensado para criterios de busqueda usando expresiones regulares extendidas.
ge_rg1() {

    local l_initial_query="$1"
    local l_path="$2"

    if [ -z "$l_initial_query" ]; then
        printf 'You must specify the first parameter.\nUsage:\n'
        printf '    ge_rg QUERY\n'
        printf '    ge_rg QUERY PATH\n'
        return 1
    fi

    #Anteponer el caracter de escape "\" a los caracteres especial de una cadena
    _g_fzf_rg_initial_query=$(printf %q "$l_initial_query")

    if [ ! -z "$l_path" ]; then
        _g_fzf_rg_cmd="rg --column --line-number --no-heading --color=always --smart-case ${l_path} -e"
    else
        _g_fzf_rg_cmd='rg --column --line-number --no-heading --color=always --smart-case -e'
    fi

    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    local l_status=0
    local l_result=$(FZF_DEFAULT_COMMAND="${_g_fzf_rg_cmd} ${_g_fzf_rg_initial_query}" \
    $l_fzf_cmd $l_fzf_size_args --ansi -m \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --header 'CTRL-r (ripgrep mode), CTRL-f (fzf mode), ENTER (Open in VIM)' \
        --disabled --query "$_g_fzf_rg_initial_query" \
        --bind "change:reload:sleep 0.1; $_g_fzf_rg_cmd {q} || true" \
        --bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(🔦 fzf> )+enable-search+rebind(ctrl-r)+transform-query(echo {q} > /tmp/rg-fzf-ra; cat /tmp/rg-fzf-fa)" \
        --bind "ctrl-r:unbind(ctrl-r)+change-prompt(🔍 ripgrep> )+disable-search+reload($_g_fzf_rg_cmd {q} || true)+rebind(change,ctrl-f)+transform-query(echo {q} > /tmp/rg-fzf-fa; cat /tmp/rg-fzf-ra)" \
        --bind "start:unbind(ctrl-r)" \
        --prompt '🔍 ripgrep> ' \
        --delimiter : \
        --preview "bat --color=always --style=numbers,header-filename {1} --highlight-line {2}" \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
    )
    l_status=$?

    if [ $l_status -ne 0 ]; then
        return $l_status
    fi

    # Si el usuario no seleciono nada
    if [ -z "$l_result" ]; then
        return 0
    fi

    # Parsear el resultado
    _ge_rg_open_vim "$l_result"

}


#Uselo para buscar contenido de archivos en carpetas (recursivamente).
#Restricciones:
# - No es pensado para busqueda en un archivo use directamente el comando 'ripgrep' o simplemente 'grep'.
# - Solo permite la busqueda de un query de busqueda. No esta diseñado usar muilples query con '-e' o '-f'.
# - RipGrep solo esta pensado para criterios de busqueda usando expresiones regulares extendidas.
ge_rg2() {

    local l_initial_query="$1"
    local l_path="$2"

    if [ -z "$l_initial_query" ]; then
        printf 'You must specify the first parameter.\nUsage:\n'
        printf '    ge_rg QUERY\n'
        printf '    ge_rg QUERY PATH\n'
        return 1
    fi

    #Anteponer el caracter de escape "\" a los caracteres especial de una cadena
    _g_fzf_rg_initial_query=$(printf %q "$l_initial_query")

    if [ ! -z "$l_path" ]; then
        _g_fzf_rg_cmd="rg --column --line-number --no-heading --color=always --smart-case ${l_path} -e"
    else
        _g_fzf_rg_cmd='rg --column --line-number --no-heading --color=always --smart-case -e'
    fi


    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    FZF_DEFAULT_COMMAND="${_g_fzf_rg_cmd} ${_g_fzf_rg_initial_query}" \
    $l_fzf_cmd $l_fzf_size_args --ansi \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --header 'CTRL-r (ripgrep mode), CTRL-f (fzf mode), ENTER (Exit & view file)' \
        --disabled --query "$_g_fzf_rg_initial_query" \
        --bind "change:reload:sleep 0.1; $_g_fzf_rg_cmd {q} || true" \
        --bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(🔦 fzf> )+enable-search+rebind(ctrl-r)+transform-query(echo {q} > /tmp/rg-fzf-rb; cat /tmp/rg-fzf-fb)" \
        --bind "ctrl-r:unbind(ctrl-r)+change-prompt(🔍 ripgrep> )+disable-search+reload($_g_fzf_rg_cmd {q} || true)+rebind(change,ctrl-f)+transform-query(echo {q} > /tmp/rg-fzf-fb; cat /tmp/rg-fzf-rb)" \
        --bind "start:unbind(ctrl-r)" \
        --prompt '🔍 ripgrep> ' \
        --delimiter : \
        --preview "bat --color=always --style=numbers,header-filename {1} --highlight-line {2}" \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --bind 'enter:become(vim {1} +{2})'
}


################################################################################################
# FZF> GIt Functions
################################################################################################

# Obtenido y modificado de https://github.com/junegunn/fzf-git.sh

#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
# Utilidades generales
#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .


# Redefine this function to change the options
_fzf_git_fzf() {


    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    $l_fzf_cmd $l_fzf_size_args \
        --layout=reverse --multi --min-height=20 --border \
        --color='header:italic:underline' \
        --preview-window='right,50%,border-left' \
        --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' "$@"

}

_fzf_git_check() {
    git rev-parse HEAD > /dev/null 2>&1 && return
    [[ -n $TMUX ]] && tmux display-message "Not in a git repository"
    return 1
}

_g_fzf_data1=''

#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
# Funciones
#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

# > Argumentos:
#   > Tipo de objeto GIT:
#      1 - Un commit: hash
#      2 - Branch (Local y Remoto): name
#      3 - Remote (Alias del repositorio remoto): name
#      4 - File: name
#      5 - Tag: name


#for Files
gi_files() {

    _fzf_git_check || return

    (git -c color.status=always status --short
    git ls-files | grep -vxFf <(git status -s | grep '^[^?]' | cut -c4-; echo :) | sed 's/^/   /') |
    _fzf_git_fzf -m --ansi --nth 2..,.. \
        --prompt '📄 Files> ' \
        --header $'CTRL-o (open in browser) ╱ ALT-e (open in editor)\n\n' \
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" \
        --bind "ctrl-o:execute-silent:bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_git.bash git_open_url 4 {-1}" \
        --bind "alt-e:execute:${EDITOR:-vim} {-1} > /dev/tty" \
        --preview-window "right,60%" \
        --preview "git diff --color=always -- {-1} | delta; bat --color=always --style=numbers,header-filename {-1}" "$@" |
    cut -c4- | sed 's/.* -> //'
}

#for Branches (Local y Remoto)
gi_branches() {

    _fzf_git_check || return

    bash "${MY_REPO_PATH}/shell/bash/fun/fzf/fun_git.bash" list_objects branches |
    _fzf_git_fzf --ansi \
        --prompt '🌲 Branches> ' \
        --header-lines 2 \
        --tiebreak begin \
        --preview-window down,border-top,40% \
        --color hl:underline,hl+:underline \
        --no-hscroll \
        --bind 'ctrl-/:change-preview-window(down,70%|hidden|)' \
        --bind "ctrl-o:execute-silent:bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_git.bash git_open_url 2 {}" \
        --bind "alt-a:change-prompt(🌳 All branches> )+reload:bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_git.bash\" list_objects all-branches" \
        --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1)' "$@" |
    sed 's/^..//' | cut -d' ' -f1
}

#for Tags
gi_tags() {

    _fzf_git_check || return

    git tag --sort -version:refname |
    _fzf_git_fzf --preview-window right,70% \
        --prompt '📛 Tags> ' \
        --header $'CTRL-o (Open in browser)\n\n' \
        --bind "ctrl-o:execute-silent:bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_git.bash git_open_url 5 {}" \
        --preview-window "right,60%" \
        --preview 'git show --color=always {} | delta' "$@"
}

#for commit Hashes
gi_hashes() {
    _fzf_git_check || return

    local p_file="$1"

    local l_status=1
    local l_result=''
    local l_prompt='🍡 Hashes> '
    _g_fzf_data1=''
    if [ -z "$p_file" ]; then
        l_result=$(git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always)
        l_status=$?
    else
        printf -v l_prompt '🍡 Hashes of %s> ' "$p_file"
        printf -v _g_fzf_data1 " -- '%s'" "$p_file"
        l_result=$(git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always -- "$p_file")
        l_status=$?
    fi


    #echo "data1: ${_g_fzf_data1}"


    if [ $l_status -ne 0 ]; then
        printf 'Ocurrio un error en obtener los commits: %b\n' "$l_result"
        return 1
    fi


    echo "$l_result" | _fzf_git_fzf --ansi --no-sort --bind 'ctrl-s:toggle-sort' \
        --prompt "$l_prompt" \
        --header $'CTRL-o (Open in browser), CTRL-d (View Diff), CTRL-s (Toggle sort)\n\n' \
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" \
        --bind "ctrl-o:execute-silent:bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_git.bash git_open_url 1 {}" \
        --bind "ctrl-d:execute:grep -o '[a-f0-9]\{7,\}' <<< {} | head -n 1 | xargs -I%% git diff --color=always %% ${_g_fzf_data1} | delta > /dev/tty" \
        --color hl:underline,hl+:underline \
        --preview-window "right,60%" \
        --preview "grep -o '[a-f0-9]\{7,\}' <<< {} | head -n 1 | xargs -I%% git show --color=always %% ${_g_fzf_data1} | delta" |
    awk 'match($0, /[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]*/) { print substr($0, RSTART, RLENGTH) }'

    return 0
}

#alias glog='git log --color=always --format="%C(cyan)%h%Creset %C(blue)%ar%Creset%C(auto)%d%Creset %C(yellow)%s%+b %C(white)%ae%Creset" "$@"'
##¿que pase si en la linea ({}) existe una comilla? ... ¿como se ejecuta el comando?
#_g_fzf_glog_hash="echo {} | grep -o '[a-f0-9]\{7\}' | head -1"
#_g_fzf_glog_view="$_g_fzf_glog_hash | xargs git show --color=always | delta"
#
#gi_log() {
#
#    #Obtener el directorio .git pero no imprimir su valor ni los errores. Si no es un repositorio valido salir
#    if ! git rev-parse --git-dir > /dev/null 2>&1; then
#        echo 'Invalid git repository'
#        return 0
#    fi
#
#    #Mostrar los commit y su preview
#    glog | fzf -i -e --no-sort --reverse --tiebreak index -m --ansi \
#        --preview "$_g_fzf_glog_view" \
#        --bind "shift-up:preview-page-up,shift-down:preview-page-down" --bind "ctrl-z:execute:$_g_fzf_glog_view" \
#        --header $'CTRL-z (Show in full-screen), SHIFT-↑/↓ (Navigate preview\'s pages)\n' \
#        | grep -o '[a-f0-9]\{7\}'
#        #--print-query
#}


#for Remotes (Alias de los repositorios remotos)
gi_remotes() {
    _fzf_git_check || return

    git remote -v | awk '{print $1 "\t" $2}' | uniq |
    _fzf_git_fzf --tac \
        --prompt '📡 Remotes> ' \
        --header $'CTRL-o (Open in browser)\n\n' \
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" \
        --bind "ctrl-o:execute-silent:bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_git.bash git_open_url 3 {1}" \
        --preview-window right,70% \
        --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" {1}/"$(git rev-parse --abbrev-ref HEAD)"' "$@" |
    cut -d$'\t' -f1
}

#for Stashes
gi_stashes() {
    _fzf_git_check || return

    git stash list | _fzf_git_fzf \
        --prompt '🥡 Stashes> ' \
        --header $'CTRL-x (Drop stash)\n\n' \
        --bind 'ctrl-x:execute-silent(git stash drop {1})+reload(git stash list)' \
        -d: --preview 'git show --color=always {1} | delta' "$@" |
    cut -d: -f1
}

#for Each ref (git for-each-ref)
gi_eachref() {
    _fzf_git_check || return

    bash "$${MY_REPO_PATH}/shell/bash/fun/fzf/fun_git.bash" list_objects refs | _fzf_git_fzf --ansi \
        --nth 2,2.. \
        --tiebreak begin \
        --prompt '☘️  Each ref> ' \
        --header-lines 2 \
        --preview-window down,border-top,40% \
        --color hl:underline,hl+:underline \
        --no-hscroll \
        --bind 'ctrl-/:change-preview-window(down,70%|hidden|)' \
        --bind "ctrl-o:execute-silent:bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_git.bash git_open_url 2 {2}" \
        --bind "ctrl-s:execute:git show {2} | delta > /dev/tty" \
        --bind "ctrl-d:execute:git diff {2} | delta > /dev/tty" \
        --bind "alt-a:change-prompt(🍀 Every ref> )+reload:bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_git.bash\" list_objects all-refs" \
        --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" {2}' "$@" |
    awk '{print $2}'
    #--bind "alt-e:execute:${EDITOR:-vim} <(git show {2}) > /dev/tty" \
}


################################################################################################
# FZF> K8S Functions
################################################################################################

#Se usara 'kubectl' por defecto, opcionalmente se usara 'oc' de RHOCP.
#Para 'kubectl', en caso de existir, se usara el "short-names" del recursos:
#    componentstatuses          = cs
#    configmaps                 = cm
#    endpoints                  = ep
#    events                     = ev
#    limitranges                = limits
#    namespaces                 = ns
#    nodes                      = no
#    persistentvolumeclaims     = pvc
#    persistentvolumes          = pv
#    pods                       = po
#    replicationcontrollers     = rc
#    resourcequotas             = quota
#    serviceaccounts            = sa
#    services                   = svc
#    customresourcedefinitions  = crd, crds
#    daemonsets                 = ds
#    deployments                = deploy
#    replicasets                = rs
#    statefulsets               = sts
#    horizontalpodautoscalers   = hpa
#    cronjobs                   = cj
#    certificiaterequests       = cr, crs
#    certificates               = cert, certs
#    certificatesigningrequests = csr
#    ingresses                  = ing
#    networkpolicies            = netpol
#    podsecuritypolicies        = psp
#    replicasets                = rs
#    scheduledscalers           = ss
#    priorityclasses            = pc
#    storageclasses             = sc


#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
# Utilidades generales
#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

#Argumentos:
#  1 > Si es 0, se muestra el default Namespace
_fzf_kc_get_context_info() {

    #TODO mejorar para obtener la URL del servidor, nombre del usuario, ...
    local l_data=$(kubectl config current-context)
    local l_tmp="${l_data//// }"
    local l_items=($l_tmp)
    local l_n=${#l_items[@]}

    local l_color_1="\x1b[91m"
    local l_color_2="\x1b[33m"
    local l_color_3="\x1b[92m"
    #local l_color_opaque="\x1b[90m"
    local l_color_reset="\x1b[0m"

    if [ $l_n -lt 3 ]; then
        printf "Context: '%b%s%b'" "$l_color_1" "${l_data}" "$l_color_reset"
    else
        if [ "$1" = "0" ]; then
            printf "User: '%b%s%b', Server: '%b%s%b', Default Namespace: '%b%s%b'" "$l_color_1" "${l_items[2]}" "$l_color_reset" "$l_color_2" "${l_items[1]}" "$l_color_reset" "$l_color_3" "${l_items[2]}" "$l_color_reset"
        else
            printf "User: '%b%s%b', Server: '%b%s%b'" "$l_color_1" "${l_items[2]}" "$l_color_reset" "$l_color_2" "${l_items[1]}" "$l_color_reset"
        fi
    fi
}

#Plantilla de opciones usando en las acciones FZF, cuyo formato es "resource-type/[resource-name] -n=[namespace]"
#  > "[resource-name]" puede ser el nombre del recurso o "{n}" donde n es el numero de campo donde se obtendra.
#  > "[namespace]" puede ser el nombre del namespace o "{n}" donde n es el numero de campo donde se obtendra.
_g_fzf_kc_options=""

#Nombre del archivo de dato
_g_fzf_kc_data_file=""


#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
# Funciones
#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

kc_resources() {

    #1. Inicializar variables requeridas para fzf y awk
    local l_resource_name="$1"
    local l_awk_template="{print \"${l_resource_name}/\"\$1}"
    _g_fzf_kc_options="${l_resource_name}/{1}"

    #2. Procesar los argumentos y modificar las variables segun ello

    #Ayuda
    if [ -z "$1" ]; then
        echo "Parametros invalidos. Use 'oc_resources --help' para ver mas detalle de su uso."
        return 1
    elif [ "$1" = "--help" ]; then
        echo "Usar: "
        echo "     kc_resources RESOURCE-KIND NAMESPACE FILTER-LABELS FILTER-FIELDS"
        echo "     kc_resources --help"
        echo "> Use '.' si desea no ingresar valor para el argumento."
        echo "> Argumento 'NAMESPACE'    : Coloque solo el nombre del namespace o use '--all' para establecer todos los namespaces. "
        echo "  Si el recurso no posee namespace o no desea colocarlo, use '.'."
        echo "> Argumento 'FILTER-LABELS': Coloque el listado de los labels deseado (igual al valor de '-l' o '--selector' de kubectl)."
        echo "  Ejemplo 'label1=value1,label2=value2'"
        echo "> Argumento 'FILTER-FIELDS': Coloque el listado de los campos deseado (igual al valor de '--field-selector' de kubectl)."
        echo "  Ejemplo 'field1=value1,field2==value1,field2!=value'"
        return 0
    fi

    #Resource KIND o Name
    local l_cmd="kubectl get $1"

    #Namespace
    if [ ! -z "$2" ] && [ "$2" != "." ]; then
        if [ "$2" = "--all" ]; then
            l_cmd="${l_cmd} --all-namespaces"
            l_awk_template="{print \"${l_resource_name}/\"\$2\" -n \"\$1}"
            _g_fzf_kc_options="${l_resource_name}/{2} -n={1}"
        else
            l_cmd="${l_cmd} -n $2"
            l_awk_template="{print \"${l_resource_name}/\"\$1\" -n $2\"}"
            _g_fzf_kc_options="${l_resource_name}/{1} -n=$2"
        fi
    fi

    #Labels
    if [ ! -z "$3" ] &&  [ "$3" != "." ]; then
        l_cmd="${l_cmd} -l $3"
    fi

    #Filed Selectors
    if [ ! -z "$4" ] &&  [ "$4" != "." ]; then
        l_cmd="${l_cmd} --field-selector $4"
    fi

    #echo "$_g_fzf_oc_pod_path"
    #echo "$l_awk_template"


    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    #3. Generar el reporte deseado con la data ingresada
    FZF_DEFAULT_COMMAND="$l_cmd" \
    $l_fzf_cmd $l_fzf_size_args --info=inline --layout=reverse --header-lines=1 -m \
        --prompt "${l_resource_name}> " \
        --header "$(_fzf_kc_get_context_info 1)"$'\nCTRL-r (reload), CTRL-a (View yaml)\n' \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(oc get ${_g_fzf_kc_options} -o yaml) > /dev/tty" \
        --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' |
    awk "$l_awk_template"

}



oc_projects() {

    #1. Inicializar variables requeridas para fzf y awk
    local l_awk_template='{print $1}'
    local l_cmd_options="get project -o json"
    _g_fzf_kc_data_file="${_g_tmp_data_path}/projects_${_g_uid}.json"

    #2. Procesar los argumentos y modificar las variables segun ello

    #Ayuda
    if [ "$1" = "--help" ]; then
        echo "Usar: "
        echo "     oc_projects FILTER-LABELS FILTER-FIELDS"
        echo "     oc_projects --help"
        echo "> Use '.' si desea no ingresar valor para el argumento."
        echo "> Argumento 'FILTER-LABELS': Coloque el listado de los labels deseado (igual al valor de '-l' o '--selector' de kubectl)."
        echo "  Ejemplo 'label1=value1,label2=value2'"
        echo "> Argumento 'FILTER-FIELDS': Coloque el listado de los campos deseado (igual al valor de '--field-selector' de kubectl)."
        echo "  Ejemplo 'field1=value1,field2==value1,field2!=value'"
        return 0
    fi

    #Labels
    if [ ! -z "$1" ] &&  [ "$1" != "." ]; then
        l_cmd_options="${l_cmd_options} -l $1"
    fi

    #Filed Selectors
    if [ ! -z "$2" ] &&  [ "$2" != "." ]; then
        l_cmd_options="${l_cmd_options} --field-selector $2"
    fi

    #echo "$l_cmd_options"

    #3. Obtener la data del cluster y almacenarlo en un archivo temporal
    kubectl $l_cmd_options > $_g_fzf_kc_data_file
    if [ $? -ne 0 ]; then
        echo "Check the connection to k8s cluster"
        return 1
    fi

    #4. Generar el reporte deseado con la data ingresada
    local l_data
    local l_status
    l_data=$(bash "${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash" show_namespace_table "${_g_fzf_kc_data_file}" 0)
    l_status=$?

    if [ $l_status -eq 1 ]; then
        echo "Error en el fitro usado"
        return 2
    elif [ $l_status -ne 0 ]; then
        echo "No data found"
        return 3
    fi



    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    #5. Mostrar el reporte
    echo "$l_data" |
    $l_fzf_cmd $l_fzf_size_args --info=inline --layout=reverse --header-lines=2 -m --nth=..1 \
        --prompt "Project> " \
        --header "$(_fzf_kc_get_context_info 1)"$'\nCTRL-a (View pod yaml), CTRL-b (View Preview), CTRL-d (Set Default), CTRL-e (View Events)\n' \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_object_yaml '${_g_fzf_kc_data_file}' '{1}') > /dev/tty" \
        --bind "ctrl-b:execute:bat --color=always --paging always --style plain <(bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_namespace_info '${_g_fzf_kc_data_file}' '{1}' 0) > /dev/tty" \
        --bind "ctrl-d:execute-silent:oc project {1}" \
        --bind "ctrl-e:execute:bat --color=always --paging always --style plain <(kubectl get event -n={1}) > /dev/tty" \
        --preview-window "right,60%" \
        --preview "bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_namespace_info '${_g_fzf_kc_data_file}' '{1}' 0 | bat --color=always --style plain" |
    awk "$l_awk_template"

    rm -f $_g_fzf_kc_data_file


}




kc_ns() {

    #1. Inicializar variables requeridas para fzf y awk
    local l_awk_template='{print $1}'
    local l_cmd_options="get namespace -o json"
    _g_fzf_kc_data_file="${_g_tmp_data_path}/namespaces_${_g_uid}.json"

    #2. Procesar los argumentos y modificar las variables segun ello

    #Ayuda
    if [ "$1" = "--help" ]; then
        echo "Usar: "
        echo "     kc_namespaces FILTER-LABELS FILTER-FIELDS"
        echo "     kc_namespaces --help"
        echo "> Use '.' si desea no ingresar valor para el argumento."
        echo "> Argumento 'FILTER-LABELS': Coloque el listado de los labels deseado (igual al valor de '-l' o '--selector' de kubectl)."
        echo "  Ejemplo 'label1=value1,label2=value2'"
        echo "> Argumento 'FILTER-FIELDS': Coloque el listado de los campos deseado (igual al valor de '--field-selector' de kubectl)."
        echo "  Ejemplo 'field1=value1,field2==value1,field2!=value'"
        return 0
    fi

    #Labels
    if [ ! -z "$1" ] &&  [ "$1" != "." ]; then
        l_cmd_options="${l_cmd_options} -l $1"
    fi

    #Filed Selectors
    if [ ! -z "$2" ] &&  [ "$2" != "." ]; then
        l_cmd_options="${l_cmd_options} --field-selector $2"
    fi

    #echo "$l_cmd_options"

    #3. Obtener la data del cluster y almacenarlo en un archivo temporal
    kubectl $l_cmd_options > $_g_fzf_kc_data_file
    if [ $? -ne 0 ]; then
        echo "Check the connection to k8s cluster"
        return 1
    fi

    #4. Generar el reporte deseado con la data ingresada
    local l_data
    local l_status
    l_data=$(bash "${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash" show_namespace_table "${_g_fzf_kc_data_file}" 1)
    l_status=$?

    if [ $l_status -eq 1 ]; then
        echo "Error en el fitro usado"
        return 2
    elif [ $l_status -ne 0 ]; then
        echo "No data found"
        return 3
    fi

    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    #5. Mostrar el reporte
    echo "$l_data" |
    $l_fzf_cmd $l_fzf_size_args --info=inline --layout=reverse --header-lines=2 -m --nth=..1 \
        --prompt "Project> " \
        --header "$(_fzf_kc_get_context_info 1)"$'\nCTRL-a (View pod yaml), CTRL-b (View Preview), CTR-d (Set Default), CTRL-e (View Events)\n' \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_object_yaml '${_g_fzf_kc_data_file}' '{1}') > /dev/tty" \
        --bind "ctrl-b:execute:bat --color=always --paging always --style plain <(bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_namespace_info '${_g_fzf_kc_data_file}' '{1}' 1) > /dev/tty" \
        --bind "ctrl-d:execute-silent:kubectl config set-context --current --namespace={1}" \
        --bind "ctrl-e:execute:bat --color=always --paging always --style plain <(kubectl get event -n={1}) > /dev/tty" \
        --preview-window "right,60%" \
        --preview "bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_namespace_info '${_g_fzf_kc_data_file}' '{1}' 1 | bat --color=always --style plain" |
    awk "$l_awk_template"

    rm -f $_g_fzf_kc_data_file


}



kc_po() {

    #1. Inicializar variables requeridas para fzf y awk
    local l_awk_template='{print "pod/"$1" -n "$2}'
    local l_cmd_options="get pod -o json"
    _g_fzf_kc_data_file="${_g_tmp_data_path}/pods_${_g_uid}.json"

    #2. Procesar los argumentos y modificar las variables segun ello

    #Ayuda
    if [ "$1" = "--help" ]; then
        echo "Usar: "
        echo "     kc_pods NAMESPACE FILTER-LABELS FILTER-FIELDS"
        echo "     kc_pods --help"
        echo "> Use '.' si desea no ingresar valor para el argumento."
        echo "> Argumento 'NAMESPACE'    : Coloque solo el nombre del namespace o use '--all' para establecer todos los namespaces. "
        echo "  Si el recurso no posee namespace o no desea colocarlo, use '.'."
        echo "> Argumento 'FILTER-LABELS': Coloque el listado de los labels deseado (igual al valor de '-l' o '--selector' de kubectl)."
        echo "  Ejemplo 'label1=value1,label2=value2'"
        echo "> Argumento 'FILTER-FIELDS': Coloque el listado de los campos deseado (igual al valor de '--field-selector' de kubectl)."
        echo "  Ejemplo 'field1=value1,field2==value1,field2!=value'"
        return 0
    fi

    #Namespace
    if [ ! -z "$1" ] && [ "$1" != "." ]; then
        if [ "$1" = "--all" ]; then
            l_cmd_options="${l_cmd_options} --all-namespaces"
        else
            l_cmd_options="${l_cmd_options} -n $1"
        fi
    fi

    #Labels
    if [ ! -z "$2" ] &&  [ "$2" != "." ]; then
        l_cmd_options="${l_cmd_options} -l $2"
    fi

    #Filed Selectors
    if [ ! -z "$3" ] &&  [ "$3" != "." ]; then
        l_cmd_options="${l_cmd_options} --field-selector $3"
    fi

    #echo "$l_cmd_options"

    #3. Obtener la data del cluster y almacenarlo en un archivo temporal
    kubectl $l_cmd_options > $_g_fzf_kc_data_file
    if [ $? -ne 0 ]; then
        echo "Check the connection to k8s cluster"
        return 1
    fi

    #4. Generar el reporte deseado con la data ingresada
    local l_data
    local l_status
    l_data=$(bash "${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash" show_pods_table "${_g_fzf_kc_data_file}" 0)
    l_status=$?

    if [ $l_status -eq 1 ]; then
        echo "Error en el fitro usado"
        return 2
    elif [ $l_status -ne 0 ]; then
        echo "No data found"
        return 3
    fi


    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    #5. Mostrar el reporte
    echo "$l_data" |
    $l_fzf_cmd $l_fzf_size_args --info=inline --layout=reverse --header-lines=2 -m --nth=..2 \
        --prompt "Not-succeeded Pod> " \
        --header "$(_fzf_kc_get_context_info 1)"$'\nCTRL-a (View pod yaml), CTRL-b (View Preview), CTRL-e (Exit & Terminal), CTRL-t (Bash Terminal), CTRL-l (View log), CTRL-p (Exit & Port-Forward), CTRL-x (Exit & follow logs), ALT-a (View all Pods), ATL-b (View Not-succeeded pods)\n' \
        --bind "alt-a:change-prompt(Pod> )+reload:bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" show_pods_table \"${_g_fzf_kc_data_file}\" 1" \
		--bind "alt-b:change-prompt(Not-succeeded Pod> )+reload:bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" show_pods_table \"${_g_fzf_kc_data_file}\" 0" \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_object_yaml '${_g_fzf_kc_data_file}' '{1}' '{2}') > /dev/tty" \
        --bind "ctrl-b:execute:bat --color=always --paging always --style plain <(bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_pod_info '${_g_fzf_kc_data_file}' '{1}' '{2}') > /dev/tty" \
        --bind "ctrl-e:become:bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" open_terminal1 '{1}' '{2}' 'bash' 0 '${_g_fzf_kc_data_file}' > /dev/tty" \
        --bind "ctrl-t:execute:bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" open_terminal1 '{1}' '{2}' 'bash' 1 '${_g_fzf_kc_data_file}' > /dev/tty" \
        --bind "ctrl-l:execute(bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" show_log_pod '{1}' '{2}' 1 10000 '${_g_fzf_kc_data_file}' > /dev/tty)" \
        --bind "ctrl-p:become(bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" port_forward_pod '{1}' '{2}' '${_g_fzf_kc_data_file}' > /dev/tty)" \
        --bind "ctrl-x:become(bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" show_log_pod '{1}' '{2}' 0 200 '${_g_fzf_kc_data_file}' > /dev/tty)" \
        --preview-window "down,border-top,70%" \
        --preview "bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_pod_info '${_g_fzf_kc_data_file}' '{1}' '{2}' | bat --color=always --style plain" |
    awk "$l_awk_template"

    rm -f $_g_fzf_kc_data_file

}



kc_containers() {

    #1. Inicializar variables requeridas para fzf y awk
    local l_awk_template='{print "pod/"$1" -n "$2" -c "$3}'
    local l_cmd_options="get pod -o json"
    _g_fzf_kc_data_file="${_g_tmp_data_path}/containers_${_g_uid}.json"

    #2. Procesar los argumentos y modificar las variables segun ello

    #Ayuda
    if [ "$1" = "--help" ]; then
        echo "Usar: "
        echo "     kc_containers NAMESPACE FILTER-LABELS FILTER-FIELDS"
        echo "     kc_containers --help"
        echo "> Use '.' si desea no ingresar valor para el argumento."
        echo "> Argumento 'NAMESPACE'    : Coloque solo el nombre del namespace o use '--all' para establecer todos los namespaces. "
        echo "  Si el recurso no posee namespace o no desea colocarlo, use '.'."
        echo "> Argumento 'FILTER-LABELS': Coloque el listado de los labels deseado (igual al valor de '-l' o '--selector' de kubectl)."
        echo "  Ejemplo 'label1=value1,label2=value2'"
        echo "> Argumento 'FILTER-FIELDS': Coloque el listado de los campos deseado (igual al valor de '--field-selector' de kubectl)."
        echo "  Ejemplo 'field1=value1,field2==value1,field2!=value'"
        return 0
    fi

    #Namespace
    if [ ! -z "$1" ] && [ "$1" != "." ]; then
        if [ "$1" = "--all" ]; then
            l_cmd_options="${l_cmd_options} --all-namespaces"
        else
            l_cmd_options="${l_cmd_options} -n $1"
        fi
    fi

    #Labels
    if [ ! -z "$2" ] &&  [ "$2" != "." ]; then
        l_cmd_options="${l_cmd_options} -l $2"
    fi

    #Filed Selectors
    if [ ! -z "$3" ] &&  [ "$3" != "." ]; then
        l_cmd_options="${l_cmd_options} --field-selector $3"
    fi

    #echo "$l_cmd_options"

    #3. Obtener la data del cluster y almacenarlo en un archivo temporal
    kubectl $l_cmd_options > $_g_fzf_kc_data_file
    if [ $? -ne 0 ]; then
        echo "Check the connection to k8s cluster"
        return 1
    fi

    #4. Generar el reporte deseado con la data ingresada
    local l_data
    local l_status
    l_data=$(bash "${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash" show_containers_table "${_g_fzf_kc_data_file}" 0)
    l_status=$?

    if [ $l_status -eq 1 ]; then
        echo "Error en el fitro usado"
        return 2
    elif [ $l_status -ne 0 ]; then
        echo "No data found"
        return 3
    fi

    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    #5. Mostrar el reporte
    echo "$l_data" |
    $l_fzf_cmd $l_fzf_size_args --info=inline --layout=reverse --header-lines=2 -m --nth=..3 \
        --prompt "Not-succeeded Pod's Container> " \
        --header "$(_fzf_kc_get_context_info 1)"$'\nCTRL-a (View pod yaml), CTRL-b (View Preview), CTRL-e (Exit & Terminal), CTRL-t (Bash Terminal), CTRL-l (View log), CTRL-p (Exit & Port-Forward), CTRL-x (Exit & follow logs), ALT-a (View all Pods), ATL-b (View Not-succeeded pods)\n' \
        --bind "alt-a:change-prompt(Pod's Container> )+reload:bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" show_containers_table \"${_g_fzf_kc_data_file}\" 1" \
		--bind "alt-b:change-prompt(Not-succeeded Pod's Container> )+reload:bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" show_containers_table \"${_g_fzf_kc_data_file}\" 0" \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_object_yaml '${_g_fzf_kc_data_file}' '{1}' '{2}') > /dev/tty" \
        --bind "ctrl-b:execute:bat --color=always --paging always --style plain <(bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_container_info '${_g_fzf_kc_data_file}' '{1}' '{2}' '{3}') > /dev/tty" \
        --bind "ctrl-e:become:bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" open_terminal2 '{1}' '{2}' '{3}' 'bash' 0 '${_g_fzf_kc_data_file}' > /dev/tty" \
        --bind "ctrl-t:execute:bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" open_terminal2 '{1}' '{2}' '{3}' 'bash' 1 '${_g_fzf_kc_data_file}' > /dev/tty" \
        --bind "ctrl-l:execute(bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" show_log_container '{1}' '{2}' '{3}' 1 10000 '${_g_fzf_kc_data_file}' > /dev/tty)" \
        --bind "ctrl-p:become(bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" port_forward_container '{1}' '{2}' '{3}' '{7}' '${_g_fzf_kc_data_file}' > /dev/tty)" \
        --bind "ctrl-x:become(bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" show_log_container '{1}' '{2}' '{3}' 0 200 '${_g_fzf_kc_data_file}' > /dev/tty)" \
        --preview-window "down,border-top,70%" \
        --preview "bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_container_info '${_g_fzf_kc_data_file}' '{1}' '{2}' '{3}' | bat --color=always --style plain" |
    awk "$l_awk_template"

    #    --bind "ctrl-l:execute:bat --color=always --paging always --style plain  <(kubectl logs {1} -n={2} -c={3} --tail=10000 --timestamps) > /dev/tty" \
    #    --bind "ctrl-x:become(bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" show_log 0 0 200 '{1}' '-n={2}' '-c={3}' '${_g_fzf_kc_data_file}' > /dev/tty)" \

    rm -f $_g_fzf_kc_data_file

}


kc_deploy() {

    #1. Inicializar variables requeridas para fzf y awk
    #local l_awk_template='{print "deployment/"$1" -n "$2" | pod -n "$2"-l "$7}'
    local l_awk_template='{print "deployment/"$1" -n "$2}'
    local l_cmd_options="get deployment -o json"
    _g_fzf_kc_data_file="${_g_tmp_data_path}/deployments_${_g_uid}.json"

    #2. Procesar los argumentos y modificar las variables segun ello

    #Ayuda
    if [ "$1" = "--help" ]; then
        echo "Usar: "
        echo "     kc_deployments NAMESPACE FILTER-LABELS FILTER-FIELDS"
        echo "     kc_deployments --help"
        echo "> Use '.' si desea no ingresar valor para el argumento."
        echo "> Argumento 'NAMESPACE'    : Coloque solo el nombre del namespace o use '--all' para establecer todos los namespaces. "
        echo "  Si el recurso no posee namespace o no desea colocarlo, use '.'."
        echo "> Argumento 'FILTER-LABELS': Coloque el listado de los labels deseado (igual al valor de '-l' o '--selector' de kubectl)."
        echo "  Ejemplo 'label1=value1,label2=value2'"
        echo "> Argumento 'FILTER-FIELDS': Coloque el listado de los campos deseado (igual al valor de '--field-selector' de kubectl)."
        echo "  Ejemplo 'field1=value1,field2==value1,field2!=value'"
        return 0
    fi

    #Namespace
    if [ ! -z "$1" ] && [ "$1" != "." ]; then
        if [ "$1" = "--all" ]; then
            l_cmd_options="${l_cmd_options} --all-namespaces"
        else
            l_cmd_options="${l_cmd_options} -n $1"
        fi
    fi


    #Labels
    if [ ! -z "$2" ] &&  [ "$2" != "." ]; then
        l_cmd_options="${l_cmd_options} -l $2"
    fi

    #Filed Selectors
    if [ ! -z "$3" ] &&  [ "$3" != "." ]; then
        l_cmd_options="${l_cmd_options} --field-selector $3"
    fi

    #echo "$l_cmd_options"

    #3. Obtener la data del cluster y almacenarlo en un archivo temporal
    kubectl $l_cmd_options > $_g_fzf_kc_data_file
    if [ $? -ne 0 ]; then
        echo "Check the connection to k8s cluster"
        return 1
    fi

    #4. Generar el reporte deseado con la data ingresada (por ahora solo muestra los '.spec.replicas' no sea 0)
    local l_data
    local l_status
    l_data=$(bash "${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash" show_deployment_table "${_g_fzf_kc_data_file}" 0)
    l_status=$?

    if [ $l_status -eq 1 ]; then
        echo "Error en el fitro usado"
        return 2
    elif [ $l_status -ne 0 ]; then
        echo "No data found"
        return 3
    fi


    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi


    #5. Mostrar el reporte
    echo "$l_data" |
    $l_fzf_cmd $l_fzf_size_args --info=inline --layout=reverse --header-lines=2 -m --nth=..2 \
        --prompt "Deployment> " \
        --header "$(_fzf_kc_get_context_info 1)"$'\nCTRL-a (View yaml), CTRL-b (View Preview), CTRL-d (View Revisions), CTRL-w (Watch pods)\n' \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_object_yaml '${_g_fzf_kc_data_file}' '{1}' '{2}') > /dev/tty" \
        --bind "ctrl-b:execute:bat --color=always --paging always --style plain <(bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_deployment_info '${_g_fzf_kc_data_file}' '{1}' '{2}' '{9}') > /dev/tty" \
        --bind "ctrl-d:execute:bat --color=always --paging always --style plain <(bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_dply_revision1 '${_g_fzf_kc_data_file}' '{1}' '{2}') > /dev/tty" \
        --bind "ctrl-w:execute:kubectl get pod -n={2} -l='{9}' -w -o wide > /dev/tty" \
        --preview-window "down,border-top,70%" \
        --preview "bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_deployment_info '${_g_fzf_kc_data_file}' '{1}' '{2}' '{9}' | bat --color=always --style plain" |
    awk "$l_awk_template"

    rm -f ${_g_fzf_kc_data_file}

    #    --header "$(_fzf_kc_get_context_info 1)"$'\nCTRL-a (View yaml), CTRL-b (Preview in full-screen), CTRL-d (View revisions), CTRL-l (View logs), CTRL-x (Exit & follow logs)\n' \
    #    --bind "ctrl-l:execute(bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" show_log_dply '{1}' '{2}' 1 10000 '${_g_fzf_kc_data_file}' > /dev/tty)" \
    #    --bind "ctrl-x:become(bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" show_log_dply '{1}' '{2}' 0 200 '${_g_fzf_kc_data_file}' > /dev/tty)" \

}



kc_rs() {

    #1. Inicializar variables requeridas para fzf y awk
    #local l_awk_template='{print "replicaset/"$1" -n "$2" | pod -n "$2"-l "$7}'
    local l_awk_template='{print "replicaset/"$1" -n "$2}'
    local l_cmd_options="get replicaset -o json"
    _g_fzf_kc_data_file="${_g_tmp_data_path}/replicaset_${_g_uid}.json"

    #2. Procesar los argumentos y modificar las variables segun ello

    #Ayuda
    if [ "$1" = "--help" ]; then
        echo "Usar: "
        echo "     kc_replicasets NAMESPACE FILTER-LABELS FILTER-FIELDS"
        echo "     kc_replicasets --help"
        echo "> Use '.' si desea no ingresar valor para el argumento."
        echo "> Argumento 'NAMESPACE'    : Coloque solo el nombre del namespace o use '--all' para establecer todos los namespaces. "
        echo "  Si el recurso no posee namespace o no desea colocarlo, use '.'."
        echo "> Argumento 'FILTER-LABELS': Coloque el listado de los labels deseado (igual al valor de '-l' o '--selector' de kubectl)."
        echo "  Ejemplo 'label1=value1,label2=value2'"
        echo "> Argumento 'FILTER-FIELDS': Coloque el listado de los campos deseado (igual al valor de '--field-selector' de kubectl)."
        echo "  Ejemplo 'field1=value1,field2==value1,field2!=value'"
        return 0
    fi

    #Namespace
    if [ ! -z "$1" ] && [ "$1" != "." ]; then
        if [ "$1" = "--all" ]; then
            l_cmd_options="${l_cmd_options} --all-namespaces"
        else
            l_cmd_options="${l_cmd_options} -n $1"
        fi
    fi


    #Labels
    if [ ! -z "$2" ] &&  [ "$2" != "." ]; then
        l_cmd_options="${l_cmd_options} -l $2"
    fi

    #Filed Selectors
    if [ ! -z "$3" ] &&  [ "$3" != "." ]; then
        l_cmd_options="${l_cmd_options} --field-selector $3"
    fi

    #echo "$l_cmd_options"

    #3. Obtener la data del cluster y almacenarlo en un archivo temporal
    kubectl $l_cmd_options > $_g_fzf_kc_data_file
    if [ $? -ne 0 ]; then
        echo "Check the connection to k8s cluster"
        return 1
    fi

    #4. Generar el reporte deseado con la data ingresada (por ahora solo muestra los '.spec.replicas' no sea 0)
    local l_data
    local l_status
    l_data=$(bash "${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash" show_replicasets_table "${_g_fzf_kc_data_file}" 0)
    l_status=$?

    if [ $l_status -eq 1 ]; then
        echo "Error en el fitro usado"
        return 2
    elif [ $l_status -ne 0 ]; then
        echo "No data found"
        return 3
    fi


    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi


    #5. Mostrar el reporte
    echo "$l_data" |
    $l_fzf_cmd $l_fzf_size_args --info=inline --layout=reverse --header-lines=2 -m --nth=..3 \
        --prompt "Active ReplicaSet> " \
        --header "$(_fzf_kc_get_context_info 1)"$'\nALT-a (View all rs), ATL-b (View rs with pods), CTRL-a (View yaml), CTRL-b (View Preview), CTRL-d (View Revisions), CTRL-w (Watch pods)\n' \
        --bind "alt-a:change-prompt(All Replicaset> )+reload:bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" show_replicasets_table \"${_g_fzf_kc_data_file}\" 1" \
		--bind "alt-b:change-prompt(Active Replicaset> )+reload:bash \"${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash\" show_replicasets_table \"${_g_fzf_kc_data_file}\" 0" \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_object_yaml '${_g_fzf_kc_data_file}' '{1}' '{2}') > /dev/tty" \
        --bind "ctrl-b:execute:bat --color=always --paging always --style plain <(bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_replicaset_info '${_g_fzf_kc_data_file}' '{1}' '{2}' '{9}') > /dev/tty" \
        --bind "ctrl-d:execute:bat --color=always --paging always --style plain <(bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_dply_revision2 '${_g_fzf_kc_data_file}' '{1}' '{2}') > /dev/tty" \
        --bind "ctrl-w:execute:kubectl get pod -n={2} -l='{9}' -w -o wide > /dev/tty" \
        --preview-window "down,border-top,70%" \
        --preview "bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_k8s.bash show_replicaset_info '${_g_fzf_kc_data_file}' '{1}' '{2}' '{9}' | bat --color=always --style plain" |
    awk "$l_awk_template"

    rm -f ${_g_fzf_kc_data_file}

}
