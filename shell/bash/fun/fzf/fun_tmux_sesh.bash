#!/bin/bash

[ -z "$MY_REPO_PATH" ] && MY_REPO_PATH=~/.files

# Constantes
g_fzf_height='60%'
g_fzf_popup_height='80%'
g_fzf_popup_width='99%'

# Colores principales usados para presentar en FZF
g_color_reset="\x1b[0m"
g_color_gray1="\x1b[90m"
g_color_green1="\x1b[32m"
g_color_cyan1="\x1b[36m"


# Lista los folderes de trabajo que podrian crearse como sesiones tmux
# > Usado para crear sesiones en tmux con sesh
list_work_folder() {

    local p_path="$1"
    local p_mindepth=$2
    local p_maxdepth=$3

    local -a l_args=("$p_path" '-mindepth' "$p_mindepth" '-maxdepth' "$p_maxdepth" '-type' 'd' '(' '-name' '.*' '-o')

    #Si es HOME (modificar el mecanismo usado, no usar el realpath)
    if [ -f "$l_path/.bashrc" ]; then
        # Argumentos: "-name 'Documents' -o -name 'Downloads' -o -name 'Desktop' -o -name 'Pictures' -o -name 'Music' -o -name 'Videos' -o -name 'Templates' -o -name 'personal' -o -name 'photos'"
        l_args+=('-name' 'Documents' '-o' '-name' 'Downloads' '-o' '-name' 'Desktop' '-o' '-name' 'Pictures' '-o' '-name' 'Music' '-o' '-name' 'Videos' '-o' '-name' 'Templates' '-o' '-name' 'personal' '-o' '-name' 'photos')
    else
        # Argumentos: "-name 'bin' -o -name 'obj' -o -name 'node_modules'"
        l_args+=('-name' 'bin' '-o' '-name' 'obj' '-o' '-name' 'node_modules')
    fi

    l_args+=(')' '-prune' '-o' '-type' 'd' '-print')
    #echo "$l_exclude_options"

    # find ./code -mindepth 2 -maxdepth 10 -type d -name '.git' -exec dirname "{}" \;
    # find ~/code -mindepth 2 -maxdepth 10 -type d -execdir test -d "{}/.git" \; -prune -print
    # find ~/code -mindepth 2 -maxdepth 10 -type d \( -execdir  test -e "{}/.ignore" \; -prune \) -o \( -execdir test -d "{}/.git" \; -prune -print \)
    # find ~ -mindepth 1 -maxdepth 2 -type d \( -name ".*" -o -name "Documents" -o -name "Downloads" -o -name "Desktop" -o -name "Pictures" -o \
    #        -name "Videos" -o -name "personal" -o -name "photos" \) -prune -o \( -type d -writable -print \)
    # find . -mindepth 1 -maxdepth 10 -type d \( -name ".*" -o -name "Documents" -o -name "Downloads" -o -name "Desktop" -o -name "Pictures" -o -name "Videos" -o -name "personal" -o -name "photos" \) -prune -o -type d -print
    # find . -mindepth 1 -maxdepth 10 -type d -name ".git" -print -o -type d \( -name ".*" -o -name "Documents" -o -name "Downloads" -o -name "Desktop" -o -name "Pictures" -o -name "Videos" -o -name "personal" -o -name "photos" \) -prune
    find "${l_args[@]}" | sed "s|^$HOME|~|"

}

# Lista los folderes de trabajo con repositorio git que podrian crearse como sesiones tmux
# > Usado para crear sesiones en tmux con sesh
list_git_folder() {

    local p_path="$1"
    local p_mindepth=$2
    local p_maxdepth=$3

    local -a l_args=("$p_path" '-mindepth' "$p_mindepth" '-maxdepth' "$p_maxdepth" '-type' 'd' '-name' '.git' '-exec' 'dirname' "{}" ';' '-o' '-type' 'd' '(' '-name' '.*' '-o')

    #Si es HOME (modificar el mecanismo usado, no usar el realpath)
    if [ -f "$l_path/.bashrc" ]; then
        # Argumentos: "-name 'Documents' -o -name 'Downloads' -o -name 'Desktop' -o -name 'Pictures' -o -name 'Music' -o -name 'Videos' -o -name 'Templates' -o -name 'personal' -o -name 'photos'"
        l_args+=('-name' 'Documents' '-o' '-name' 'Downloads' '-o' '-name' 'Desktop' '-o' '-name' 'Pictures' '-o' '-name' 'Music' '-o' '-name' 'Videos' '-o' '-name' 'Templates' '-o' '-name' 'personal' '-o' '-name' 'photos')
    else
        # Argumentos: "-name 'bin' -o -name 'obj' -o -name 'node_modules'"
        l_args+=('-name' 'bin' '-o' '-name' 'obj' '-o' '-name' 'node_modules')
    fi

    l_args+=(')' '-prune')
    #echo "$l_exclude_options"

    find "${l_args[@]}" | sed "s|^$HOME|~|"

}


show_sesh_preview() {

    #Incluye el icono y el nombre de la sesion/folder
    local p_sesh_item="$1"

    #Considerando un folder si inicia con:
    # '~': '~/.files', ....
    # '.': './files', '../files', '../../files'
    # '/': '/etc/alsa'
    local l_sesh_prefix="${p_sesh_item:2:1}"

    if [ "$l_sesh_prefix" = '~' ] || [ "$l_sesh_prefix" = '.' ] || [ "$l_sesh_prefix" = '/' ]; then

        local l_sesh_subfix="${p_sesh_item:2}"
        #TODO: Evitar usar eval obligar la expansion
        eza --tree --color=always --icons always -L 1 $(eval echo "$l_sesh_subfix") | head -n 300
        return 0

    fi

    sesh preview "$p_sesh_item"

}

#
# > El valor de algunas opciones de 'fzf', como '--bind', el script a ejecutar se calcula cada vez que se ejecuta el keymap.
#   Por tal motivo, las variables usados dentro del valor de esta opcion debe ser una variable global, no puede ser local.
#
_g_fzf_gnrl_path=''

# Permite gestionar las 'tmux session':
#  > Listar e ir a sesiones activas
#  > Listar folderes para abrir/seleionar una sesion tmux usando esta ruta
# Parametro de entrada:
#  > Folder donde buscar para crear sesiones
new_or_choose_tmux_session() {

    #Validar si existe el comando sesh
    if ! sesh --version 2> /dev/null 1>&2; then
       printf 'El comando "%b%s%b" no esta instalado.\n' "$g_color_gray1" "sesh" "$g_color_reset"
       return 2
    fi

    #Obtener el folder donde se analizara las carpetas
    local l_path=''
    if [ ! -z "$1" ]; then

        if [ ! -d "$1" ]; then
            printf 'La ruta ingresada "%b%s%b" no existe o no se tiene permisos.\n' "$g_color_gray1" "$1" "$g_color_reset"
            return 2
        fi

        l_path="$1"

    fi

    if [ -z "$l_path" ]; then
        if [ -d "$HOME/code" ]; then
            l_path="$HOME/code"
        else
            l_path="$HOME"
        fi
    fi

    # Escoger el nombre de la sesion o la ruta de inicio de la sesion
    local l_title=''
    printf -v l_title "%bSession%b: (%bctrl+t%b) show active, (%bctrl+i%b) show configured, (%bctrl+d%b) kill. %bSession + zoxide%b folders: (%bctrl+a%b)\n%bFolders%b: (%bctrl+x%b) zoxide. %bSubfolders%b of %b%s%b: (%bctrl+g%b) git, (%bctrl+f%b) all" \
           "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_green1" "$g_color_reset" "$g_color_cian1" "${l_path/#$HOME/\~}" "$g_color_reset" "$g_color_cian1" "$g_color_reset"\
           "$g_color_cian1" "$g_color_reset"


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

    _g_fzf_gnrl_path="$l_path"

    local l_session_or_path=$(sesh list --icons | $l_fzf_cmd $l_fzf_size_args \
		--no-sort --ansi --prompt '⚡Session + Zoxide> ' \
        --header "$l_title" \
        --preview-window 'right:40%' --preview "bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_tmux_sesh.bash show_sesh_preview {}" \
		--bind 'tab:down,btab:up' \
		--bind 'ctrl-a:change-prompt(⚡Session + Zoxide> )+reload(sesh list --icons)' \
		--bind 'ctrl-t:change-prompt(🪟 Active sessions> )+reload(sesh list -t --icons)' \
		--bind 'ctrl-i:change-prompt(⚙️ Configured sessions> )+reload(sesh list -c --icons)' \
		--bind 'ctrl-x:change-prompt(📁 Zoxide folder> )+reload(sesh list -z --icons)' \
		--bind "ctrl-f:change-prompt(🔎 Work folder> )" --bind "ctrl-f:+reload:bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_tmux_sesh.bash list_work_folder '${_g_fzf_gnrl_path}' 1 7" \
		--bind "ctrl-g:change-prompt(🔎 Git folder> )" --bind "ctrl-g:+reload:bash ${MY_REPO_PATH}/shell/bash/fun/fzf/fun_tmux_sesh.bash list_git_folder '${_g_fzf_gnrl_path}' 1 7" \
        --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡ Session + Zoxide> )+reload(sesh list --icons)')

    if [ -z "$l_session_or_path" ]; then
        return 0
    fi

    #echo "$l_session_or_path"

    #Ir a la sesion o crear la sesion basandose en la ruta
    # > Si la sesion existe:
    #   - Si el cliente ya esta conectado a uno, lo desvincuala del cliente actual y luego los vuncual a la sesion existente.
    #   - Si el cliente no esta conectado, vincula el cliente a la sesion existente.
    # > Si la sesion no existe, lo crea
    #   - Si el cliente ya esta conectado a uno, lo desvincuala del cliente actual y luego los vuncual a la sesion creada.
    #   - Si el cliente no esta conectado, vincula el cliente a la sesion creada.
    sesh connect "$l_session_or_path"
    return 0
}



#Los parametros debe ser la funcion y los parametros
"$@"
