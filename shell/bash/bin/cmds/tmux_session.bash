#!/bin/bash

# Constantes
g_fzf_height='60%'
g_fzf_popup_height='80%'
g_fzf_popup_width='99%'

#Colores principales usados
g_color_reset="\x1b[0m"
g_color_green1="\x1b[32m"
g_color_gray1="\x1b[90m"
g_color_cian1="\x1b[36m"
g_color_yellow1="\x1b[33m"
g_color_red1="\x1b[31m"
g_color_blue1="\x1b[34m"

# Obtener la del script
g_script_path="${BASH_SOURCE[0]}"
#echo "$g_script_path"

g_cmd_name='s'
#g_cmd_name='tmux_session'

declare -a ga_exported_functions=(
        "list_work_folder"
        "list_git_folder"
        "show_sesh_preview"
    )

# -------------------------------------------------------------------------------------
# General functions
# -------------------------------------------------------------------------------------

m_get_exported_functions() {

    # Recorrer la lista de parametros identificados ....
    local l_infos=""
    local l_id

    for l_id in "${ga_exported_functions[@]}"; do

        if [ -z "$l_infos" ]; then
            printf -v l_infos "'%b%s%b'" "$g_color_yellow1" "$l_id" "$g_color_reset"
        else
            printf -v l_infos "%b, '%b%s%b'" "$l_infos" "$g_color_yellow1" "$l_id" "$g_color_reset"
        fi

    done

    echo "$l_infos"

}

m_is_function_exported() {

    local p_func_name="$1"

    if [ -z "$p_func_name" ]; then
        return 1
    fi

    local l_found=1
    local l_item

    for l_item in "${ga_exported_functions[@]}"; do

        if [[ "$l_item" == "$p_func_name" ]]; then
            l_found=0
            break
        fi

    done

    return $l_found

}


m_usage() {

    printf 'Usage:\n'
    printf '    %b%s%b -h%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s%b [SESSION_PATH]%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s%b [-g GIT_FOLDER] [-w WORK_FOLDER]%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s%b -i FUNC_NAME [args]%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_gray1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h%b permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %b-w WORK_FOLDER%b Especifica la ruta de folderes de trabajo. Se usara para buscar el subfolder donde crear la sesion tmux.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bSi no se especifica, se usara el folder "~/works".%b\n' "$g_color_gray1" "$g_color_reset"
    printf '  > %b-g GIT_FOLDER%b Especifica la ruta donde esta los proyectos GIT. Se usara para buscar el subfolder donde crear la session tmux.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bSi no se especifica, se usara el folder "~/code".%b\n' "$g_color_gray1" "$g_color_reset"
    printf '  > %b-i FUNC_NAME%b Especifica el nombre de la funcion interna del script a ejecutar (uso interno o debugging).%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    local l_infos=$(m_get_exported_functions)
    printf '    %bFUNC_NAME para este script puede ser:%b %b\n\n' "$g_color_gray1" "$g_color_reset" "$l_infos"

    printf 'Los argumentos usados son:\n'
    printf '  > %bSESSION_PATH%b es la ruta del folder que se usara para crear la sesion tmux (no muestra el popup de busqueda).%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}



# -------------------------------------------------------------------------------------
# Exported functions
# -------------------------------------------------------------------------------------


# Lista los folderes de trabajo que podrian crearse como sesiones tmux
# > Usado para crear sesiones en tmux con sesh
list_work_folder() {

    # Argumentos
    local p_path="$1"
    local -i p_mindepth=$2
    local -i p_maxdepth=$3

    # Validaciones previas
    if [ -z "$p_path" ] || [ -z "$p_mindepth" ] || [ -z "$p_maxdepth" ]; then
        return 1
    fi

    # Procesamiento
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

    # Argumentos
    local p_path="$1"
    local -i p_mindepth=$2
    local -i p_maxdepth=$3

    # Validaciones previas
    if [ -z "$p_path" ] || [ -z "$p_mindepth" ] || [ -z "$p_maxdepth" ]; then
        return 1
    fi

    # Procesamiento
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

    if [ -z "$p_sesh_item" ]; then
        return 1
    fi

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




# -------------------------------------------------------------------------------------
# Main functions
# -------------------------------------------------------------------------------------

#
# > El valor de algunas opciones de 'fzf', como '--bind', el script a ejecutar se calcula cada vez que se ejecuta el keymap.
#   Por tal motivo, las variables usados dentro del valor de esta opcion debe ser una variable global, no puede ser local.
#
_g_fzf_work_path=''
_g_fzf_dir_path=''

# Permite gestionar las 'tmux session':
#  > Listar e ir a sesiones activas
#  > Listar folderes para abrir/seleionar una sesion tmux usando esta ruta
# Parametro de entrada:
#  > Folder donde buscar para crear sesiones
m_new_or_choose_tmux_session() {

    #Obtener el folder donde estan los archivos de trabajo.
    local l_work_path=''

    if [ ! -z "$1" ]; then
        l_work_path="$1"
    else
        if [ -d "$HOME/works" ]; then
            l_work_path="$HOME/works"
        elif [ -d "$HOME/work" ]; then
            l_work_path="$HOME/work"
        else
            l_work_path="$HOME"
        fi
    fi

    # Obtener el folder donde estan los proyectos git
    local l_git_path=''

    if [ ! -z "$2" ]; then
        l_git_path="$2"
    else
        if [ -d "$HOME/code" ]; then
            l_git_path="$HOME/code"
        else
            l_git_path="$HOME"
        fi
    fi

    # Escoger el nombre de la sesion o la ruta de inicio de la sesion
    local l_title=''
    printf -v l_title "%bSession%b: (%bctrl+t%b) show active, (%bctrl+i%b) show configured, (%bctrl+d%b) kill.\n%bSession + Zoxide%b folders: (%bctrl+a%b). %bZoxide%b folders: (%bctrl+x%b).\n%bSubfolders%b of %b%s%b: (%bctrl+g%b) git, %bSubfolders%b of %b%s%b: (%bctrl+f%b) work" \
           "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_green1" "$g_color_reset" "$g_color_cian1" "${l_git_path/#$HOME/\~}" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_green1" "$g_color_reset" "$g_color_cian1" "${l_work_path/#$HOME/\~}" "$g_color_reset" "$g_color_cian1" "$g_color_reset"


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

    _g_fzf_git_path="$l_git_path"
    _g_fzf_work_path="$l_work_path"

    local l_session_or_path=$(sesh list --icons | $l_fzf_cmd $l_fzf_size_args \
		--no-sort --ansi --prompt '⚡Session + Zoxide> ' \
        --header "$l_title" \
        --preview-window 'right:40%' --preview "bash '$g_script_path' -i show_sesh_preview {}" \
		--bind 'tab:down,btab:up' \
		--bind 'ctrl-a:change-prompt(⚡Session + Zoxide> )+reload(sesh list --icons)' \
		--bind 'ctrl-t:change-prompt(🪟 Active sessions> )+reload(sesh list -t --icons)' \
		--bind 'ctrl-i:change-prompt(⚙️ Configured sessions> )+reload(sesh list -c --icons)' \
		--bind 'ctrl-x:change-prompt(📁 Zoxide folder> )+reload(sesh list -z --icons)' \
		--bind "ctrl-f:change-prompt(🔎 Work folder> )" --bind "ctrl-f:+reload:bash '$g_script_path' -i list_work_folder '${_g_fzf_work_path}' 1 7" \
		--bind "ctrl-g:change-prompt(🔎 Git folder> )" --bind "ctrl-g:+reload:bash '$g_script_path' -i list_git_folder '${_g_fzf_git_path}' 1 7" \
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
    #printf 'Crear o ir a una session tmux ...\n'
    #printf '%bsesh connect %b"%s"%b\n' "$g_color_green1" "$g_color_gray1" "$l_session_or_path" "$g_color_reset"
    sesh connect "$l_session_or_path"
    return 0
}



# -------------------------------------------------------------------------------------
# Main code
# -------------------------------------------------------------------------------------


# Funcion principal de entrada
# > Valores de retorno:
#   (0) OK
#   (1) No se tienen los comandos requeridos para ejecutar el script.
#   (3) Opciones ingresados son invalidos.
#   (4) No se han ingresado argumentos.
#
main() {

    #1. Validaciones previas

    # Validar comando requeridos
    if ! command -v fzf >/dev/null 2>&1; then
        printf '[%bERROR%b] Se debe tener el comando "%b%s%b" instalado.\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" "jq" "$g_color_reset"
        return 1
    fi

    if ! sesh --version 2> /dev/null 1>&2; then
       printf 'El comando "%b%s%b" no esta instalado.\n' "$g_color_gray1" "sesh" "$g_color_reset"
       return 2
    fi


    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    local l_work_dir=""
    local l_git_dir=""
    local l_func_name=""


    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage
                return 0
                ;;

            -w)
                if [ ! -d "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" no es un ruta valido: %b%s%b\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-w" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    m_usage
                    return 3
                fi

                l_work_dir="$2"
                shift 2
                ;;


            -g)
                if [ ! -d "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" no es un ruta valido: %b%s%b\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-g" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    m_usage
                    return 3
                fi

                l_git_dir="$2"
                shift 2
                ;;

            -i)
                m_is_function_exported "$2"
                local l_found=$?
                if [ "$l_found" -ne 0 ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" no es function exportada valida: %b%s%b\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-i" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    m_usage
                    return 3
                fi

                l_func_name="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #3. Si es una funcion exportada, invocarlo
    if [ ! -z "$l_func_name" ]; then
        "$l_func_name" "$@"
        return 0
    fi


    #4. Leer los argumentos restantes

    # Si se ingresa al folder a quien crear la sesion
    if [ ! -z "$1" ]; then

        if [ ! -d "$1" ]; then
            printf '[%bERROR%b] El folder "%b%s%b" ingresado para crear la sesion es invalido.\n' "$g_color_red1" "$g_color_reset" \
                   "$g_color_gray1" "$1" "$g_color_reset"
            m_usage
            return 3
        fi


        printf 'Crear una session tmux ...\n'
        printf '%bsesh connect %b"%s"%b\n' "$g_color_green1" "$g_color_gray1" "$1" "$g_color_reset"
        sesh connect "$1"
        return 0

    fi


    #5. Ejecutando la funcion principal
    m_new_or_choose_tmux_session "$l_work_dir" "$l_git_dir"
    return 0

}



# Ejecutar la funcion principal
main "$@"
_g_result=$?
exit $_g_result
