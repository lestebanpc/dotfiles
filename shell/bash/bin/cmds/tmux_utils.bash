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

g_cmd_name='tmuxu'

declare -a ga_exported_functions=(
        "list_work_folder"
        "list_git_folder"
        "show_sesh_preview"
    )

# Diccionario de sbucomandos. La key es 'id del subcomando' y value es 'la descripcion del subcomando'.
# > Segun el ID de subcomando, se debe tener 2 funciones bash cuyo nombre tiene dicho ID
#   > Funcion de ayuda del comando tiene el nombre 'm_usage_CMD-ID'.
#   > Funcion de controlador del comando tiene el nombre 'controller_CMD-ID'.
declare -A gA_subcmd_ids=(
        ['new_session']='Permite crear una nueva sesion tmux activa o conectarse a una existente'
        ['set_clipboard']='Permite establecer el modo de escritura al clipboard usado por el servidor tmux'
    )


# Diccionario de sbucomandos. La key es 'alias' y value es 'ID del subcomando'.
declare -A gA_subcmd_alias=(
    )


# -------------------------------------------------------------------------------------
# Utility
# -------------------------------------------------------------------------------------

# Determinar el tipo de SO compatible con interprete shell POSIX.
# > Devuelve:
#   00 > Si es Linux no-WSL
#   01 > Si es Linux WSL2 (Kernel de Linux nativo sobre Windows)
#   02 > Si es Unix
#   03 > Si es MacOS
#   04 > Emulador Bash CYGWIN para Windows
#   05 > Emulador Bash MINGW  para Windows
#   06 > Emulador Bash Termux para Linux Android
#   09 > No identificado
function m_get_os_type() {
    local l_system=$(uname -s)

    local l_os_type=0
    local l_tmp=""
    case "$l_system" in
        Linux*)
            l_tmp=$(uname -r)
            if [[ "$l_tmp" == *WSL* ]] && [ -f "/etc/wsl.conf" ]; then
                l_os_type=1
            else
                l_os_type=0
            fi
            ;;
        Darwin*)  l_os_type=3;;
        CYGWIN*)  l_os_type=4;;
        MINGW*)   l_os_type=5;;
        *)
            #Si se ejecuta en Termux
            if echo $PREFIX | grep -o "com.termux" 2> /dev/null; then
                l_os_type=6
            else
                l_os_type=9
            fi
            ;;
    esac

    return $l_os_type

}


# -------------------------------------------------------------------------------------
# Controller 'set_clipboard'> Utility
# -------------------------------------------------------------------------------------



# Obtener el comando externo usado como backend del clipboard
function m_get_backend_clipboard() {

    #1. Identificar el SO
    m_get_os_type
    local l_os_type=$?

    #2. Obtener el comando externo a usar
    local l_command=''

    # Si es Linux no-WSL
    if [ $l_os_type -eq 0 ]; then

        #Si esta habilitado Wayland
        if [ ! -z "$WAYLAND_DISPLAY" ] && command -v wl-copy > /dev/null 2>&1; then

            l_command='wl-copy'

        #Si esta habilitado X11
        elif [ ! -z "$DISPLAY" ]; then

            #Si no se encuentra usar XClip
            if command -v xclip > /dev/null 2>&1; then
                l_command='xclip -i -selection clipboard >/dev/null 2>&1'
            #Dar preferencia a XSel
            elif command -v xsel > /dev/null 2>&1; then
                l_command='xsel -i -b'
            fi

        fi

    # Si es Linux WSL2 (Kernel de Linux nativo sobre Windows)
    elif [ $l_os_type -eq 1 ]; then

        if [ -f "/mnt/c/windows/system32/clip.exe" ]; then
            l_command='/mnt/c/windows/system32/clip.exe'
        fi

    # Si es MacOS
    elif [ $l_os_type -eq 3 ]; then

        if command -v pbcopy > /dev/null 2>&1; then
            l_command='pbcopy'
        fi

    fi

    #3. Retornar el comando

    if [ -z "$l_command" ]; then
        return 1
    fi

    echo "$l_command"
    return 0

}


# Establecer el keybinding en 'copy-mode'
# > Parametros de entrada
#   1> Key adicional (a 'Enter' y 'MouseDragEnd1Pane') que se usara
#   2> Comando externo usado como backend de clipboard solo cuando se establece 'set-clipboard external'
#      Si se establece usar OSC52 ('set-clipboard on') o no se establece uso del clipboard, este valor sera vacio
function m_set_keybinding_copymode() {

    local p_tmux_socket="$1"
    local p_key="$2"
    local p_command="$3"

    local p_flag_verbose=1
    if [ "$4" = "0" ]; then
        p_flag_verbose=0
    fi

    #1. Para tmux < 2.40
    if [ $TMUX_VERSION -lt 240 ]; then

        # Si se requiere usar un comando externo para escribir el clipboard
        if [ ! -z "$p_command" ]; then

            tmux ${p_tmux_socket:+-S "$p_tmux_socket"} bind-key -tvi-copy Enter             copy-pipe  "$p_command"
            tmux ${p_tmux_socket:+-S "$p_tmux_socket"} bind-key -tvi-copy MouseDragEnd1Pane copy-pipe  "$p_command"
            tmux ${p_tmux_socket:+-S "$p_tmux_socket"} bind-key -tvi-copy "$p_key"          copy-pipe "$p_command"

            if [ "$p_flag_verbose" -eq 0 ]; then
                printf 'Establecer el keybinding del %bcopy-mode%b (%btmux < %s%b) para escribir en el clipboard:\n' "$g_color_gray1" \
                       "$g_color_reset" "$g_color_gray1" "2.40" "$g_color_reset"
                printf '  %btmux %s bind-key -tvi-copy %s %s "%s"%b\n' "$g_color_gray1" \
                       "${p_tmux_socket:+-S "$p_tmux_socket"}" "Enter" "copy-pipe" "$p_command" "$g_color_reset"
                printf '  %btmux %s bind-key -tvi-copy %s %s "%s"%b\n' "$g_color_gray1" \
                       "${p_tmux_socket:+-S "$p_tmux_socket"}" "MouseDragEnd1Pane" "copy-pipe" "$p_command" "$g_color_reset"
                printf '  %btmux %s bind-key -tvi-copy %s %s "%s"%b\n' "$g_color_gray1" \
                       "${p_tmux_socket:+-S "$p_tmux_socket"}" "$p_key" "copy-pipe" "$p_command" "$g_color_reset"
            fi

            return 0
        fi

        # Si se usa OSC52 o no se habilita la integracion con el clipboard
        tmux ${p_tmux_socket:+-S "$p_tmux_socket"} bind-key -tvi-copy Enter             copy-selection
        tmux ${p_tmux_socket:+-S "$p_tmux_socket"} bind-key -tvi-copy MouseDragEnd1Pane copy-selection
        tmux ${p_tmux_socket:+-S "$p_tmux_socket"} bind-key -tvi-copy "$p_key"          copy-selection

        if [ "$p_flag_verbose" -eq 0 ]; then
            printf 'Establecer el keybinding del %bcopy-mode%b (%btmux < %s%b) para escribir en el clipboard:\n' "$g_color_gray1" \
                   "$g_color_reset" "$g_color_gray1" "2.40" "$g_color_reset"
            printf '  %btmux %s bind-key -tvi-copy %s %s%b\n' "$g_color_gray1" \
                   "${p_tmux_socket:+-S "$p_tmux_socket"}" "Enter" "copy-selection" "$g_color_reset"
            printf '  %btmux %s bind-key -tvi-copy %s %s%b\n' "$g_color_gray1" \
                   "${p_tmux_socket:+-S "$p_tmux_socket"}" "MouseDragEnd1Pane" "copy-selection" "$g_color_reset"
            printf '  %btmux %s bind-key -tvi-copy %s %s%b\n' "$g_color_gray1" \
                   "${p_tmux_socket:+-S "$p_tmux_socket"}" "$p_key" "copy-selection" "$g_color_reset"
        fi

        return 0

    fi

    #2. Para tmux >= 2.40

    # Si se requiere usar un comando externo para escribir el clipboard
    if [ ! -z "$p_command" ]; then

        # Para tmux > 2.40 y < 3.20
        if [ $TMUX_VERSION -ge 240 ] && [ $TMUX_VERSION -lt 320 ]; then

            tmux ${p_tmux_socket:+-S "$p_tmux_socket"} bind-key -T copy-mode-vi Enter             send -X copy-pipe-and-cancel  "$p_command"
            tmux ${p_tmux_socket:+-S "$p_tmux_socket"} bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel  "$p_command"
            tmux ${p_tmux_socket:+-S "$p_tmux_socket"} bind-key -T copy-mode-vi "$p_key"          send -X copy-pipe  "$p_command"

            if [ "$p_flag_verbose" -eq 0 ]; then
                printf 'Establecer el keybinding del %bcopy-mode%b (%btmux esta <%s, %s>%b) para escribir en el clipboard:\n' "$g_color_gray1" \
                       "$g_color_reset" "$g_color_gray1" "2.40" "3.20" "$g_color_reset"
                printf '  %btmux %s bind-key -T copy-mode-vi %s send -X %s "%s"%b\n' "$g_color_gray1" \
                       "${p_tmux_socket:+-S "$p_tmux_socket"}" "Enter" "copy-pipe-and-cancel" "$p_command" "$g_color_reset"
                printf '  %btmux %s bind-key -T copy-mode-vi %s send -X %s "%s"%b\n' "$g_color_gray1" \
                       "${p_tmux_socket:+-S "$p_tmux_socket"}" "MouseDragEnd1Pane" "copy-pipe-and-cancel" "$p_command" "$g_color_reset"
                printf '  %btmux %s bind-key -T copy-mode-vi %s send -X %s "%s"%b\n' "$g_color_gray1" \
                       "${p_tmux_socket:+-S "$p_tmux_socket"}" "$p_key" "copy-pipe" "$p_command" "$g_color_reset"
            fi

            return 0

        fi

        # Para tmux >= 3.20 (se usara el comando por defecto previamente definido)
        tmux ${p_tmux_socket:+-S "$p_tmux_socket"} bind-key -T copy-mode-vi Enter             send -X copy-pipe-and-cancel
        tmux ${p_tmux_socket:+-S "$p_tmux_socket"} bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel
        tmux ${p_tmux_socket:+-S "$p_tmux_socket"} bind-key -T copy-mode-vi "$p_key"          send -X copy-pipe

        if [ "$p_flag_verbose" -eq 0 ]; then
            printf 'Establecer el keybinding del %bcopy-mode%b (%btmux >= %s%b) para escribir en el clipboard:\n' "$g_color_gray1" \
                   "$g_color_reset" "$g_color_gray1" "3.20" "$g_color_reset"
            printf '  %btmux %s bind-key -T copy-mode-vi %s send -X %s%b\n' "$g_color_gray1" \
                   "${p_tmux_socket:+-S "$p_tmux_socket"}" "Enter" "copy-pipe-and-cancel" "$g_color_reset"
            printf '  %btmux %s bind-key -T copy-mode-vi %s send -X %s%b\n' "$g_color_gray1" \
                   "${p_tmux_socket:+-S "$p_tmux_socket"}" "MouseDragEnd1Pane" "copy-pipe-and-cancel" "$g_color_reset"
            printf '  %btmux %s bind-key -T copy-mode-vi %s send -X %s%b\n' "$g_color_gray1" \
                   "${p_tmux_socket:+-S "$p_tmux_socket"}" "$p_key" "copy-pipe" "$g_color_reset"
        fi

        return 0

    fi

    # Si se usa OSC52 o no se habilita la integracion con el clipboard
    tmux ${p_tmux_socket:+-S "$p_tmux_socket"} bind-key -T copy-mode-vi Enter             send -X copy-selection-and-cancel
    tmux ${p_tmux_socket:+-S "$p_tmux_socket"} bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-selection-and-cancel
    tmux ${p_tmux_socket:+-S "$p_tmux_socket"} bind-key -T copy-mode-vi "$p_key"          send -X copy-selection

    if [ "$p_flag_verbose" -eq 0 ]; then
        printf 'Establecer el keybinding del %bcopy-mode%b (%btmux >= %s%b) para escribir en el clipboard usando OSC52:\n' "$g_color_gray1" \
               "$g_color_reset" "$g_color_gray1" "2.40" "$g_color_reset"
        printf '  %btmux %s bind-key -T copy-mode-vi %s send -X %s%b\n' "$g_color_gray1" \
               "${p_tmux_socket:+-S "$p_tmux_socket"}" "Enter" "copy-pipe-and-cancel" "$g_color_reset"
        printf '  %btmux %s bind-key -T copy-mode-vi %s send -X %s%b\n' "$g_color_gray1" \
               "${p_tmux_socket:+-S "$p_tmux_socket"}" "MouseDragEnd1Pane" "copy-pipe-and-cancel" "$g_color_reset"
        printf '  %btmux %s bind-key -T copy-mode-vi %s send -X %s%b\n' "$g_color_gray1" \
               "${p_tmux_socket:+-S "$p_tmux_socket"}" "$p_key" "copy-pipe" "$g_color_reset"
    fi

    return 0

}


#------------------------------------------------------------------------------------
# Controller 'set_clipboard'> Main Functions
#------------------------------------------------------------------------------------

# Esto solo se puede ejecutar cuando el servidor se inicializa.
# Parametro de entrada> Variables de entorno
#  > Version de TMUX comparable 'TMUX_VERSION'
#  > La variable de entorno 'TERM_PROGRAM' indica el nombre del terminal (despues de su inicialización siempre es 'tmux')
# Parametro de entrada>
#  1 > Si se usa comandos externos, sera la Key que se relizara el keybinding del copiado del buffer en modo 'copy-mode-vi'.
#      Se asociara a la accion 'copy-pipe-and-cancel'
#  2 > Parametro donde se indica que tipo de metodo de copiado del clipboard usar
# Parametro de salidad> Variables de entorno
#  > La variable de entorno 'TMUX_CLIPBOARD_MODE' y cuyos valores son:
#        > No se ha podido establecer un mecanismo del clipboard (usar comnados externos pero no se estan instalados).
#      0 > Usa 'set-clipboard off' (desactivar el escribir al clipboard).
#      1 > Usa 'set-clipboard on' y usar el OSC52 para escribir en el clipboard.
#      2 > Usa 'set-clipboard external' y usar comandos externos para escribir en el clipboard.
m_set_clipboard() {

    local p_tmux_socket="$1"
    local p_key="$2"

    local -i p_flag_verbose=1
    if [ "$4" = "0" ]; then
        p_flag_verbose=0
    fi

    #1. Obtener el modo de escritura al clipboard que se usara para TMUX
    local l_clipboard_mode=''

    if [ -z "$CLIPBOARD_MODE" ]; then

        if [ "$3" = "0" ]; then
            l_clipboard_mode=0
        elif [ "$3" = "1" ]; then
            l_clipboard_mode=1
        elif [ "$3" = "2" ]; then
            l_clipboard_mode=2
        fi

        if [ "$p_flag_verbose" -eq 0 ]; then
            printf 'Clipboard Mode Input (arguments[3]  ): "%b%s%b"\n' "$g_color_gray1" "$3" "$g_color_reset"
        fi

    else

        if [ "$CLIPBOARD_MODE" = "0" ]; then
            l_clipboard_mode=0
        elif [ "$CLIPBOARD_MODE" = "1" ]; then
            l_clipboard_mode=1
        elif [ "$CLIPBOARD_MODE" = "2" ]; then
            l_clipboard_mode=2
        fi

        if [ "$p_flag_verbose" -eq 0 ]; then
            printf 'Clipboard Mode Input (CLIPBOARD_MODE): "%b%s%b"\n' "$g_color_gray1" "$CLIPBOARD_MODE" "$g_color_reset"
        fi

    fi


    #2. Si no se especifica el modo de escritura al clipboard, autocalcularlo
    #   No esta funcionado, debido a que tmux sobreescribe las variables de entorno 'TERM' y 'TERM_PROGRAM' cuando se crea el server tmux
    if [ -z "$l_clipboard_mode" ]; then

        # Determinar si la terminal soporta OSC 52
        case "$TERM_PROGRAM" in
            # Los siguientes emuladores, que soportan OSC52, definen por defecto esta variable de entorno 'TERM_PROGRAM':
            WezTerm)
                l_clipboard_mode=1
                ;;
            contour)
                l_clipboard_mode=1
                ;;
            iTerm.app)
                l_clipboard_mode=1
                ;;
            # Los siguientes emuladores, que soportan OSC52, deberan definir la variable 'TERM_PROGRAM' en su archivo de configuracion:
            kitty)
                l_clipboard_mode=1
                ;;
            alacritty)
                l_clipboard_mode=1
                ;;
            foot)
                l_clipboard_mode=1
                ;;
            # Opcionalmente, aunque no se recomienta usar un TERM personalizado (no estan en todos los equipos que accede
            # por SSH), algunas terminales definen un TERM personalizado (aunque por campatibilidad, puede modificarlo).
            *)
                case "$TERM" in
                    xterm-kitty)
                        # Emulador de terminal Kitty
                        l_clipboard_mode=1
                        ;;
                    alacritty)
                        # Emulador de terminal Alacritty
                        l_clipboard_mode=1
                        ;;
                    foot)
                        # Emulador de terminal Food
                        l_clipboard_mode=1
                        ;;
                    *)
                        l_clipboard_mode=2
                        ;;
                esac
                ;;
        esac

    fi

    if [ "$p_flag_verbose" -eq 0 ]; then
        printf 'Clipboard Mode Final                 : "%b%s%b"\n' "$g_color_gray1" "$l_clipboard_mode" "$g_color_reset"
    fi

    #2. Obtener el comando externo usado como backend del clipboard
    local l_command=$(m_get_backend_clipboard)

    if [ "$p_flag_verbose" -eq 0 ]; then
        printf 'Backend Clipboard                    : "%b%s%b"\n' "$g_color_gray1" "$l_command" "$g_color_reset"
    fi


    # Establecerr el comando externo por defecto usado en 'copy-mode'
    if [ ! -z "$l_command" ] && [ $TMUX_VERSION -ge 320 ]; then

        tmux ${p_tmux_socket:+-S "$p_tmux_socket"} set-option -s copy-command "$l_command"

        if [ "$p_flag_verbose" -eq 0 ]; then
            printf 'Establecer el comando externo: %btmux %s set-option -s copy-command "%s"%b\n' "$g_color_gray1" \
                   "${p_tmux_socket:+-S "$p_tmux_socket"}" "$l_command" "$g_color_reset"
        fi

    fi

    #3. Si el modo de escritura al clipboard esta desactivado
    if [ $l_clipboard_mode -eq 0 ]; then

        tmux ${p_tmux_socket:+-S "$p_tmux_socket"} set-option -s set-clipboard off
        tmux ${p_tmux_socket:+-S "$p_tmux_socket"} set-option -s "@clipboard_writer_mode" "$l_clipboard_mode"
        tmux ${p_tmux_socket:+-S "$p_tmux_socket"} set-environment -g TMUX_CLIPBOARD_MODE $l_clipboard_mode

        if [ "$p_flag_verbose" -eq 0 ]; then
            printf 'Establecer el modo de escritura al clipboard esta desactivado:\n'
            printf '  %btmux %s set-option -s set-clipboard off%b\n' "$g_color_gray1" \
                   "${p_tmux_socket:+-S "$p_tmux_socket"}" "$g_color_reset"
            printf '  %btmux %s set-option -s "@clipboard_writer_mode" "%s"%b\n' "$g_color_gray1" \
                   "${p_tmux_socket:+-S "$p_tmux_socket"}" "$l_clipboard_mode" "$g_color_reset"
            printf '  %btmux %s set-environment -g TMUX_CLIPBOARD_MODE %s%b\n' "$g_color_gray1" \
                   "${p_tmux_socket:+-S "$p_tmux_socket"}" "$l_clipboard_mode" "$g_color_reset"
        fi

        # Definir el keybinding a usar el modo copia
        m_set_keybinding_copymode "$p_tmux_socket" "$p_key" "" "$p_flag_verbose"

        return 0

    fi

    #4. Si el modo de escritura al clipboard usa OSC52
    if [ $l_clipboard_mode -eq 1 ]; then

        tmux ${p_tmux_socket:+-S "$p_tmux_socket"} set-option -s set-clipboard on
        tmux ${p_tmux_socket:+-S "$p_tmux_socket"} set-option -s "@clipboard_writer_mode" "$l_clipboard_mode"
        tmux ${p_tmux_socket:+-S "$p_tmux_socket"} set-environment -g TMUX_CLIPBOARD_MODE $l_clipboard_mode

        # Desde la version de tmux >= 3.3, por defecto. no se permite el reenvio de gran parte de la secuencias de escapa avanzadas
        # entre ellas no se permite el reenvio de la secuencias de escapa de OSC 52 (si permite permite la secuancias del escapes
        # basicas como el movimiento de prompt, sonido, ...).
        # Para habilitar ello debe usar la opcion 'on' o 'all'.
        # Esta capacidad se realizara en '~/.config/tmux/tmux.conf'.
        #if [ $TMUX_VERSION -ge 330 ]; then
        #    tmux ${p_tmux_socket:+-S "$p_tmux_socket"} set-option -w -g allow-passthrough on
        #    #tmux ${p_tmux_socket:+-S "$p_tmux_socket"} set-option -g allow-passthrough on
        #fi

        if [ "$p_flag_verbose" -eq 0 ]; then
            printf 'Establecer el modo de escritura al clipboard usando OSC52:\n'
            printf '  %btmux %s set-option -s set-clipboard on%b\n' "$g_color_gray1" \
                   "${p_tmux_socket:+-S "$p_tmux_socket"}" "$g_color_reset"
            printf '  %btmux %s set-option -s "@clipboard_writer_mode" "%s"%b\n' "$g_color_gray1" \
                   "${p_tmux_socket:+-S "$p_tmux_socket"}" "$l_clipboard_mode" "$g_color_reset"
            printf '  %btmux %s set-environment -g TMUX_CLIPBOARD_MODE %s%b\n' "$g_color_gray1" \
                   "${p_tmux_socket:+-S "$p_tmux_socket"}" "$l_clipboard_mode" "$g_color_reset"
        fi

        # Definir el keybinding a usar el modo copia
        m_set_keybinding_copymode "$p_tmux_socket" "$p_key" "" "$p_flag_verbose"

        return 0

    fi

    #5. Si el modo de escritura al clipboard es usando comandos externos

    # Si no existe el comando externo
    if [ -z "$l_command" ]; then

        # Desactivar la integracion con el clipboard
        tmux ${p_tmux_socket:+-S "$p_tmux_socket"} set-option -s set-clipboard off
        tmux ${p_tmux_socket:+-S "$p_tmux_socket"} set-option -s "@clipboard_writer_mode" "1"
        tmux ${p_tmux_socket:+-S "$p_tmux_socket"} set-environment -g TMUX_CLIPBOARD_MODE 1

        if [ "$p_flag_verbose" -eq 0 ]; then
            printf 'Establecer el modo de escritura al clipboard esta usando comando externo, pero no se encuentra dicho comando:\n'
            printf '  %btmux %s set-option -s set-clipboard off%b\n' "$g_color_gray1" \
                   "${p_tmux_socket:+-S "$p_tmux_socket"}" "$g_color_reset"
            printf '  %btmux %s set-option -s "@clipboard_writer_mode" "%s"%b\n' "$g_color_gray1" \
                   "${p_tmux_socket:+-S "$p_tmux_socket"}" "1" "$g_color_reset"
            printf '  %btmux %s set-environment -g TMUX_CLIPBOARD_MODE %s%b\n' "$g_color_gray1" \
                   "${p_tmux_socket:+-S "$p_tmux_socket"}" "1" "$g_color_reset"
        fi

        # Definir el keybinding a usar el modo copia
        m_set_keybinding_copymode "$p_tmux_socket" "$p_key" "" "$p_flag_verbose"

        # Mostrar la advertencia que no existe comando externo
        tmux ${p_tmux_socket:+-S "$p_tmux_socket"} display-message "Not found external command for paste tmux buffer to os clipboard."

        return 0

    fi


    # Si existe el comnando externo
    tmux ${p_tmux_socket:+-S "$p_tmux_socket"} set-option -s set-clipboard external
    tmux ${p_tmux_socket:+-S "$p_tmux_socket"} set-option -s "@clipboard_writer_mode" "$l_clipboard_mode"
    tmux ${p_tmux_socket:+-S "$p_tmux_socket"} set-environment -g TMUX_CLIPBOARD_MODE $l_clipboard_mode

    if [ "$p_flag_verbose" -eq 0 ]; then
        printf 'Establecer el modo de escritura al clipboard esta usando comando externo:\n'
        printf '  %btmux %s set-option -s set-clipboard external%b\n' "$g_color_gray1" \
               "${p_tmux_socket:+-S "$p_tmux_socket"}" "$g_color_reset"
        printf '  %btmux %s set-option -s "@clipboard_writer_mode" "%s"%b\n' "$g_color_gray1" \
               "${p_tmux_socket:+-S "$p_tmux_socket"}" "$l_clipboard_mode" "$g_color_reset"
        printf '  %btmux %s set-environment -g TMUX_CLIPBOARD_MODE %s%b\n' "$g_color_gray1" \
               "${p_tmux_socket:+-S "$p_tmux_socket"}" "$l_clipboard_mode" "$g_color_reset"
    fi

    # Definir el keybinding a usar el modo copia
    m_set_keybinding_copymode "$p_tmux_socket" "$p_key" "$l_command" "$p_flag_verbose"

    return 0

}


m_usage_set_clipboard() {

    local l_scmd_id='set_clipboard'
    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '    %b%s %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s %s%b [CLIPBOARD_MODE]%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"

    printf '\nLas opciones usados son:\n'
    printf '  > %b-h|--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %b-v%b permite mostrar mas log de los realizado (verbose).%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '\nLos argumentos usados son:\n'
    printf '  > %bCLIPBOARD_MODE%b es el modo de escritura al clipboard que se desea establecer.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bSi no se especifica, se considera que es "9" (se calcula automaticamente)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '%b    > %b%s%b %s.%b\n' "$g_color_gray1" "$g_color_green1" "0" "$g_color_gray1" \
           "No habilita la escritura en el clipboard" "$g_color_reset"
    printf '%b    > %b%s%b %s.%b\n' "$g_color_gray1" "$g_color_green1" "1" "$g_color_gray1" \
           "Implementar un mecanismo usando OSC-52 (la terminal debe soportarlo)" "$g_color_reset"
    printf '%b    > %b%s%b %s.%b\n' "$g_color_gray1" "$g_color_green1" "2" "$g_color_gray1" \
           "Implementar un mecanismo usando comandos externos de gestion de clipboard" "$g_color_reset"
    printf '%b    > %b%s%b %s.%b\n' "$g_color_gray1" "$g_color_green1" "9" "$g_color_gray1" \
           "Determinar automaticamente el mecanismo a usar" "$g_color_reset"

}



# Controlador del subcomando 'new-session'
# > Valores de retorno:
#   (0) OK
#   (1) No se tienen los comandos requeridos para ejecutar el script.
#   (3) Opciones ingresados son invalidos.
#   (4) No se han ingresado argumentos.
#
controller_set_clipboard() {

    #1. Validaciones previas

    # Validaciones previas de tmux
    if [ -z "$TMUX" ]; then
        printf '[%bERROR%b] Debe ejecutar el script dentro de una sesion tmux. Variable de entorno "%b%s%b" no esta definida.\n' \
               "$g_color_red1" "$g_color_reset" "$g_color_gray1" "TMUX" "$g_color_reset"
       return 1
    fi

    if [ -z "$TMUX_VERSION" ]; then
        printf '[%bERROR%b] La variable de entorno "%b%s%b" no esta definida.\n' \
               "$g_color_red1" "$g_color_reset" "$g_color_gray1" "TMUX_VERSION" "$g_color_reset"
       return 1
    fi

    # Obtener el socket tmux
    local l_tmux_socket="$TMUX_SOCKET"
    if [ -z "$l_tmux_socket" ]; then
        l_tmux_socket=$(printf '%s' "$TMUX" | cut -d, -f1)
    fi

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
    local l_flag_verbose=1
    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_set_clipboard
                return 0
                ;;

            -v)
                l_flag_verbose=0
                shift
                ;;



            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_set_clipboard
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #3. Leer los argumentos restantes
    local l_clipboard_mode=""

    #echo "l_clipboard_mode = $1" > /tmp/removeit.txt

    if [ "$1" = "0" ]; then
        l_clipboard_mode=0
    elif [ "$1" = "1" ]; then
        l_clipboard_mode=1
    elif [ "$1" = "2" ]; then
        l_clipboard_mode=2
    elif [ "$1" = "9" ] || [ -z "$1" ]; then
        l_clipboard_mode=9
    fi

    if [ -z "$l_clipboard_mode" ]; then
        printf '[%bERROR%b] El modo de escritura del clipboard especifico "%b%s%b" es invalido.\n\n' "$g_color_red1" \
               "$g_color_reset" "$g_color_gray1" "$1" "$g_color_reset"

        m_usage_set_clipboard
        return 1
    fi

    #4. Ejecutando la funcion principal
    m_set_clipboard "$l_tmux_socket" "y" "$l_clipboard_mode" "$l_flag_verbose"
    #m_set_clipboard "$l_tmux_socket" "y" "$l_clipboard_mode" "0" >> /tmp/removeit.txt

    return 0

}


# -------------------------------------------------------------------------------------
# Controller 'new-session'> Utility (Exported functions)
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
# Controller 'new-session'> Main functions
# -------------------------------------------------------------------------------------

m_usage_new_session() {

    local l_scmd_id='new_session'
    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    local l_alias='s'

    printf 'Usage (using alias):\n'
    printf '    %b%s%b -h|--help%b\n' "$g_color_yellow1" "$l_alias" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s%b [SESSION_PATH]%b\n' "$g_color_yellow1" "$l_alias" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s%b [-g GIT_FOLDER] [-w WORK_FOLDER]%b\n' "$g_color_yellow1" "$l_alias" "$g_color_gray1" "$g_color_reset"

    printf '\nUsage:\n'
    printf '    %b%s %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s %s%b [SESSION_PATH]%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s %s%b [-g GIT_FOLDER] [-w WORK_FOLDER]%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"

    printf '\nLas opciones usados son:\n'
    printf '  > %b-h|--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '  > %b-w WORK_FOLDER%b Especifica la ruta de folderes de trabajo. Se usara para buscar el subfolder donde crear la sesion tmux.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bSi no se especifica, se usara el folder "~/works".%b\n' "$g_color_gray1" "$g_color_reset"
    printf '  > %b-g GIT_FOLDER%b Especifica la ruta donde esta los proyectos GIT. Se usara para buscar el subfolder donde crear la session tmux.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bSi no se especifica, se usara el folder "~/code".%b\n' "$g_color_gray1" "$g_color_reset"

    printf '\nLos argumentos usados son:\n'
    printf '  > %bSESSION_PATH%b es la ruta del folder que se usara para crear la sesion tmux (no muestra el popup de busqueda).%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}

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


# Controlador del subcomando 'new-session'
# > Valores de retorno:
#   (0) OK
#   (1) No se tienen los comandos requeridos para ejecutar el script.
#   (3) Opciones ingresados son invalidos.
#   (4) No se han ingresado argumentos.
#
controller_new_session() {

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
                m_usage_new_session
                return 0
                ;;

            -w)
                if [ ! -d "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" no es un ruta valido: %b%s%b\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-w" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    m_usage_new_session
                    return 3
                fi

                l_work_dir="$2"
                shift 2
                ;;


            -g)
                if [ ! -d "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" no es un ruta valido: %b%s%b\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-g" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    m_usage_new_session
                    return 3
                fi

                l_git_dir="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_new_session
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #3. Leer los argumentos restantes

    # Si se ingresa al folder a quien crear la sesion
    if [ ! -z "$1" ]; then

        if [ ! -d "$1" ]; then
            printf '[%bERROR%b] El folder "%b%s%b" ingresado para crear la sesion es invalido.\n' "$g_color_red1" "$g_color_reset" \
                   "$g_color_gray1" "$1" "$g_color_reset"
            m_usage_new_session
            return 3
        fi


        printf 'Crear una session tmux ...\n'
        printf '%bsesh connect %b"%s"%b\n' "$g_color_green1" "$g_color_gray1" "$1" "$g_color_reset"
        sesh connect "$1"
        return 0

    fi


    #4. Ejecutando la funcion principal
    m_new_or_choose_tmux_session "$l_work_dir" "$l_git_dir"
    return 0

}



# -------------------------------------------------------------------------------------
# Main code > Utilities
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


m_get_subcmd_infos() {

    local l_scmd_id
    local l_scmd_description
    local l_alias
    local l_alias_list
    local l_id

    for l_scmd_id in "${!gA_subcmd_ids[@]}"; do

        printf "%b  > %b%s%b\n" "$g_color_gray1" "$g_color_yellow1" "$l_scmd_id" "$g_color_reset"

        # Obtener los alias del comando
        l_alias_list=''

        for l_alias in "${!gA_subcmd_alias[@]}"; do

            l_id="${gA_subcmd_alias[${l_alias}]}"

            if [ "$l_id" = "$l_scmd_id" ]; then
                if [ -z "$l_alias_list" ]; then
                    printf -v l_alias_list "'%b%s%b'" "$g_color_yellow1" "$l_alias" "$g_color_reset"
                else
                    printf -v l_alias_list "%b, '%b%s%b'" "$l_alias_list" "$g_color_yellow1" "$l_alias" "$g_color_reset"
                fi
            fi

        done

        # Mostrar el alias
        if [ ! -z "$l_alias_list" ]; then
            printf '    Alias: %b\n' "$l_alias_list"
        fi

        # Mostrar la descripcion
        l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
        printf "    %b%s%b\n" "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    done


}


m_usage_global() {

    local l_infos=""
    l_infos=$(m_get_exported_functions)

    printf 'Usage:\n'
    printf '  %b%s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s%b SUBCOMMAND%b [options] [args]%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    if [ ! -z "$l_infos" ]; then
        printf '  %b%s%b -i FUNC_NAME [args]%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_gray1" "$g_color_reset"
    fi

    printf '\nLas opciones globales usados son:\n'
    printf '%b  > %b-h%b o %b--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    if [ ! -z "$l_infos" ]; then
        printf '%b  > %b-i FUNC_NAME%b Especifica el nombre de la funcion interna del script a ejecutar (uso interno y/o debugging).%b\n' \
               "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
        printf '    %bFUNC_NAME puede ser:%b %b\n' "$g_color_gray1" "$g_color_reset" "$l_infos"
    fi

    printf '\nEl argumento principal es el nombre del subcomando %bSUBCOMMAND%b. Los cuales puede ser:\n' "$g_color_green1" "$g_color_reset"
    m_get_subcmd_infos
    printf '\n'

}



# -------------------------------------------------------------------------------------
# Main code > Main Function
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
    #if ! command -v fzf >/dev/null 2>&1; then
    #    printf '[%bERROR%b] Se debe tener el comando "%b%s%b" instalado.\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" "jq" "$g_color_reset"
    #    return 1
    #fi

    #2. Procesar las opciones globales
    local l_func_name=""

    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help|help)
                m_usage_global
                return 0
                ;;

            -i)
                m_is_function_exported "$2"
                local l_found=$?
                if [ "$l_found" -ne 0 ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" no es function exportada valida: %b%s%b\n\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-i" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    m_usage_global
                    return 3
                fi

                l_func_name="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_global
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


    #4. Procesar el 1er argumentos (nombre del subcomando o alias)
    if [ -z "$1" ]; then
        printf '[%bERROR%b] Se debe especificarse un subcomando.\n\n' "$g_color_red1" "$g_color_reset"
        m_usage_global
        return 3
    fi

    # Identificar si es un alias
    local l_scmd_id="${gA_subcmd_alias[${1}]:-}"

    # Validar si es un ID de subcomando valido
    if [ -z "$l_scmd_id" ]; then
        l_scmd_id="$1"
    fi

    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]:-}"

    if [ -z "$l_scmd_description" ]; then
        printf '[%bERROR%b] El subcomando ingresado "%b%s%b" no es valida\n\n' "$g_color_red1" "$g_color_reset" \
               "$g_color_gray1" "$l_scmd_id" "$g_color_reset"
        m_usage_global
        return 3
    fi

    shift

    #5. Validado si ...


    #6. Ejecutando el controlador principal del subcomando
    "controller_${l_scmd_id}" "$@"
    return 0

}



# Ejecutar la funcion principal
main "$@"
_g_result=$?
exit $_g_result
