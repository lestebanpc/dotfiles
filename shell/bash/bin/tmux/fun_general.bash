#!/usr/bin/env bash

[ -z "$TMUX" ] && exit 255
if [ -z "$TMUX_SOCKET" ]; then
  TMUX_SOCKET=$(printf '%s' "$TMUX" | cut -d, -f1)
fi
if [ -z "$TMUX_PROGRAM" ]; then
    TMUX_PROGRAM='tmux'
fi



#Determinar el tipo de SO compatible con interprete shell POSIX.
#Devuelve:
#  00 > Si es Linux no-WSL
#  01 > Si es Linux WSL2 (Kernel de Linux nativo sobre Windows)
#  02 > Si es Unix
#  03 > Si es MacOS
#  04 > Emulador Bash CYGWIN para Windows
#  05 > Emulador Bash MINGW  para Windows
#  06 > Emulador Bash Termux para Linux Android
#  09 > No identificado
function _get_os_type() {
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


# Obtener el comando externo usado como backend del clipboard
function _get_backend_clipboard() {

    #1. Identificar el SO
    _get_os_type
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
#   1> Key adicional (a 'Enter' y 'MouseDragfEnd1Pane') que se usara
#   2> Comando externo usado como backend de clipboard solo cuando se establece 'set-clipboard external'
#      Si se establece usar OSC52 ('set-clipboard on') o no se establece uso del clipboard, este valor sera vacio
function _set_keybinding_copymode() {

    local p_key="$1"
    local p_command="$2"

    #1. Para tmux < 2.40
    if [ $TMUX_VERSION -lt 240 ]; then

        # Si se requiere usar un comando externo para escribir el clipboard
        if [ ! -z "$p_command" ]; then

            $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -tvi-copy Enter             copy-pipe  "$p_command"
            $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -tvi-copy MouseDragEnd1Pane copy-pipe  "$p_command"
            $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -tvi-copy "$p_key"          copy-pipe "$p_command"

            return 0
        fi

        # Si se usa OSC52 o no se habilita la integracion con el clipboard
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -tvi-copy Enter             copy-selection
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -tvi-copy MouseDragEnd1Pane copy-selection
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -tvi-copy "$p_key"          copy-selection

        return 0

    fi

    #2. Para tmux >= 2.40

    # Si se requiere usar un comando externo para escribir el clipboard
    if [ ! -z "$p_command" ]; then

        # Para tmux > 2.40 y < 3.20
        if [ $TMUX_VERSION -ge 240 ] && [ $TMUX_VERSION -lt 320 ]; then

            $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -T copy-mode-vi Enter             send -X copy-pipe-and-cancel  "$p_command"
            $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel  "$p_command"
            $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -T copy-mode-vi "$p_key"          send -X copy-pipe  "$p_command"

            return 0

        fi

        # Para tmux >= 3.20 (se usara el comando por defecto previamente definido)
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -T copy-mode-vi Enter             send -X copy-pipe-and-cancel
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -T copy-mode-vi "$p_key"          send -X copy-pipe

        return 0

    fi

    # Si se usa OSC52 o no se habilita la integracion con el clipboard
    $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -T copy-mode-vi Enter             send -X copy-selection-and-cancel
    $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-selection-and-cancel
    $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -T copy-mode-vi "$p_key"          send -X copy-selection

    return 0

}


# Esto solo se puede ejecutar cuando el servidor se inicializa.
# Parametro de entrada> Variables de entorno
#  > Version de TMUX comparable 'TMUX_VERSION'
#  > La variable de entorno 'TERM_PROGRAM' indica el nombre del terminal (despues de su inicialización siempre es 'tmux')
# Parametro de entrada>
#  1 > Si se usa comandos externos, sera la Key que se relizara el keybinding del copiado del buffer en modo 'copy-mode-vi'.
#      Se asociara a la accion 'copy-pipe-and-cancel'
#  2 > Parametro donde se indica que tipo de metodo de copiado del clipboard usar
# Parametro de salidad> Variables de entorno
#  > La variable de entorno 'TMUX_SET_CLIPBOARD' y cuyos valores son:
#        > No se ha podido establecer un mecanismo del clipboard (usar comnados externos pero no se estan instalados).
#      0 > Usa 'set-clipboard off' (desactivar el escribir al clipboard).
#      1 > Usa 'set-clipboard on' y usar el OSC52 para escribir en el clipboard.
#      2 > Usa 'set-clipboard external' y usar comandos externos para escribir en el clipboard.
setting_clipboard() {

    local p_key="$1"

    #1. Obtener el modo de escritura al clipboard que se usara para TMUX
    local p_clipboard_mode=0
    if [ "$2" = "0" ]; then
        p_clipboard_mode=0
    elif [ "$2" = "1" ]; then
        p_clipboard_mode=1
    elif [ "$2" = "2" ]; then
        p_clipboard_mode=2
    else
        #Determinar si la terminal soporta OSC 52
        case "$TERM_PROGRAM" in
            #Los siguientes emuladores, que soportan OSC52, definen por defecto esta variable de entorno 'TERM_PROGRAM':
            WezTerm)
                p_clipboard_mode=1
                ;;
            contour)
                p_clipboard_mode=1
                ;;
            iTerm.app)
                p_clipboard_mode=1
                ;;
            #Los siguientes emuladores, que soportan OSC52, deberan definir la variable 'TERM_PROGRAM' en su archivo de configuracion:
            kitty)
                p_clipboard_mode=1
                ;;
            alacritty)
                p_clipboard_mode=1
                ;;
            foot)
                p_clipboard_mode=1
                ;;
            #Opcionalmente, aunque no se recomienta usar un TERM personalizado (no estan en todos los equipos que accede
            #por SSH), algunas terminales definen un TERM personalizado (aunque por campatibilidad, puede modificarlo).
            *)
                case "$TERM" in
                    xterm-kitty)
                        #Emulador de terminal Kitty
                        p_clipboard_mode=1
                        ;;
                    alacritty)
                        #Emulador de terminal Alacritty
                        p_clipboard_mode=1
                        ;;
                    foot)
                        #Emulador de terminal Food
                        p_clipboard_mode=1
                        ;;
                    *)
                        p_clipboard_mode=2
                        ;;
                esac
                ;;
        esac

    fi


    #2. Obtener el comando externo usado como backend del clipboard
    local l_command=$(_get_backend_clipboard)

    # Establecerr el comando externo por defecto usado en 'copy-mode'
    if [ ! -z "$l_command" ] && [ $TMUX_VERSION -ge 320 ]; then
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} set-option -s copy-command "$l_command"
    fi


    #3. Si se se usa desactivar en TMUX escritura al clipboard
    if [ $p_clipboard_mode -eq 0 ]; then

        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} set-option -s set-clipboard off
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} set-environment -g TMUX_SET_CLIPBOARD $p_clipboard_mode

        # Definir el keybinding a usar el modo copia
        _set_keybinding_copymode "$p_key" ""
        return 0

    fi

    #4. Si se se usa activa en TMUX la escritura al clipboard (usando OSC52)
    if [ $p_clipboard_mode -eq 1 ]; then

        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} set-option -s set-clipboard on
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} set-environment -g TMUX_SET_CLIPBOARD $p_clipboard_mode

        # Desde la version de tmux >= 3.3, por defecto. no se permite el reenvio de gran parte de la secuencias de escapa avanzadas
        # entre ellas no se permite el reenvio de la secuencias de escapa de OSC 52 (si permite permite la secuancias del escapes
        # basicas como el movimiento de prompt, sonido, ...).
        # Para habilitar ello debe usar la opcion 'on' o 'all'
        if [ $TMUX_VERSION -ge 330 ]; then
            $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} set-option -w -g allow-passthrough on
            #$TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} set-option -g allow-passthrough on
        fi

        # Definir el keybinding a usar el modo copia
        _set_keybinding_copymode "$p_key" ""
        return 0

    fi

    #5. Si se se usa activa en TMUX la escritura al clipboard usando comandos externos

    # Si no existe el comando externo
    if [ -z "$l_command" ]; then

        # Desactivar la integracion con el clipboard
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} set-option -s set-clipboard off
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} set-environment -g TMUX_SET_CLIPBOARD 1

        # Definir el keybinding a usar el modo copia
        _set_keybinding_copymode "$p_key" ""

        # Mostrar la advertencia que no existe comando externo
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} display-message "Not found external command for paste tmux buffer to os clipboard."

        return 0

    fi


    # Si existe el comnando externo
    $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} set-option -s set-clipboard external
    $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} set-environment -g TMUX_SET_CLIPBOARD $p_clipboard_mode

    # Definir el keybinding a usar el modo copia
    _set_keybinding_copymode "$p_key" "$l_command"

    return 0

}




maximize_pane() {

  current_session=${1:-$(tmux display -p '#{session_name}')}
  current_pane=${2:-$(tmux display -p '#{pane_id}')}

  dead_panes=$(tmux list-panes -s -t "$current_session" -F '#{pane_dead} #{pane_id} #{pane_start_command}' | grep -E -o '^1 %.+maximized.+$' || true)
  restore=$(printf "%s" "$dead_panes" | sed -n -E -e "s/^1 $current_pane .+maximized.+'(%[0-9]+)'\"?$/tmux swap-pane -s \1 -t $current_pane \; kill-pane -t $current_pane/p"\
                                           -e "s/^1 (%[0-9]+) .+maximized.+'$current_pane'\"?$/tmux swap-pane -s \1 -t $current_pane \; kill-pane -t \1/p")

  if [ -z "$restore" ]; then
    [ "$(tmux list-panes -t "$current_session:" | wc -l | sed 's/^ *//g')" -eq 1 ] && tmux display "Can't maximize with only one pane" && return
    info=$(tmux new-window -t "$current_session:" -F "#{session_name}:#{window_index}.#{pane_id}" -P "maximized... 2>/dev/null & \"$TMUX_PROGRAM\" ${TMUX_SOCKET:+-S \"$TMUX_SOCKET\"} setw -t \"$current_session:\" remain-on-exit on; printf \"\\033[\$(tput lines);0fPane has been maximized, press <prefix>+ to restore\n\" '$current_pane'")
    session_window=${info%.*}
    new_pane=${info#*.}

    retry=20
    while [ "$("$TMUX_PROGRAM" ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} list-panes -t "$session_window" -F '#{session_name}:#{window_index}.#{pane_id} #{pane_dead}' 2>/dev/null)" != "$info 1" ] && [ "$retry" -ne 0 ]; do
      sleep 0.1
      retry=$((retry - 1))
    done
    if [ "$retry" -eq 0 ]; then
      tmux display 'Unable to maximize pane'
    fi

    tmux setw -t "$session_window" remain-on-exit off \; swap-pane -s "$current_pane" -t "$new_pane"
  else
    $restore || tmux kill-pane
  fi
}


toggle_mouse() {
  old=$(tmux show -gv mouse)
  new=""

  if [ "$old" = "on" ]; then
    new="off"
  else
    new="on"
  fi

  tmux set -g mouse $new
}



urlview() {
  pane_id="$1"; shift
  tmux capture-pane -J -S - -E - -b "urlview-$pane_id" -t "$pane_id"
  #tmux split-window "'$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} show-buffer -b 'urlview-$pane_id' | urlview || true; '$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} delete-buffer -b 'urlview-$pane_id'"
  tmux display-popup -w99% -E "'$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} show-buffer -b 'urlview-$pane_id' | urlview || true; '$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} delete-buffer -b 'urlview-$pane_id'"
}


urlscan() {
  pane_id="$1"; shift
  tmux capture-pane -J -S - -E - -b "urlscan-$pane_id" -t "$pane_id"
  #tmux split-window "'$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} show-buffer -b 'urlscan-$pane_id' | urlscan $* || true; '$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} delete-buffer -b 'urlscan-$pane_id'"
  tmux display-popup -w99% -E "'$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} show-buffer -b 'urlscan-$pane_id' | urlscan $* || true; '$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} delete-buffer -b 'urlscan-$pane_id'"
}


fpp() {
  tmux capture-pane -J -S - -E - -b "fpp-$1" -t "$1"
  #tmux split-window -c "$2" "'$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} show-buffer -b 'fpp-$1' | fpp || true; '$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} delete-buffer -b 'fpp-$1'"
  tmux display-popup -w99% -h80% -E "'$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} show-buffer -b 'fpp-$1' | fpp || true; '$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} delete-buffer -b 'fpp-$1'"
}


_open_url() {

    local p_open_cmd="$1"
    local p_url="$2"

    if [[ -n "$p_open_cmd" ]]; then a
        $p_open_cmd "$p_url"
    elif hash xdg-open &>/dev/null; then
        nohup xdg-open "$p_url"
    elif hash open &>/dev/null; then
        nohup open "$p_url"
    elif [[ -n $BROWSER ]]; then
        nohup "$BROWSER" "$p_url"
    fi
}

show_urls() {

    local p_open_cmd="$1"
    local p_history_limit="$2"
    local p_extra_filter="$3"

    #Obtener el contenido del panel actual
    local content=''
    if [ -z "$p_history_limit" ]; then
        content="$(tmux capture-pane -J -p -e)"
    else
        content="$(tmux capture-pane -J -p -e -S -${p_history_limit})"
    fi

    #Procesar el contenido
    local urls=$(echo "$content" |grep -oE '(https?|ftp|file):/?//[-A-Za-z0-9+&@#/%?=~_|!:,.;]*[-A-Za-z0-9+&@#/%=~_|]')
    local wwws=$(echo "$content" |grep -oE '(http?s://)?www\.[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}(/\S+)*' | grep -vE '^https?://' |sed 's/^\(.*\)$/http:\/\/\1/')
    local ips=$(echo "$content" |grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(:[0-9]{1,5})?(/\S+)*' |sed 's/^\(.*\)$/http:\/\/\1/')
    local gits=$(echo "$content" |grep -oE '(ssh://)?git@\S*' | sed 's/:/\//g' | sed 's/^\(ssh\/\/\/\)\{0,1\}git@\(.*\)$/https:\/\/\2/')
    local gh=$(echo "$content" |grep -oE "['\"]([_A-Za-z0-9-]*/[_.A-Za-z0-9-]*)['\"]" | sed "s/['\"]//g" | sed 's#.#https://github.com/&#')

    local extras=''
    if [ ! -z "$p_extra_filter" ]; then
        extras=$(echo "$content" | eval "$p_extra_filter")
    fi

    local items=$(printf '%s\n' "${urls[@]}" "${wwws[@]}" "${gh[@]}" "${ips[@]}" "${gits[@]}" "${extras[@]}" |
        grep -v '^$' |
        sort -u |
        nl -w3 -s '  '
    )

    #Mostrar el resultado procesado en FZF
    [ -z "$items" ] && tmux display 'tmux-fzf-url: no URLs found' && return 0

    local fzf_options="$(tmux show -gqv '@url_fzf_options')"
    if [ -z "$fzf_options" ]; then
        fzf_options='--height=50% --tmux=center,100%,50% --multi -0 --no-preview'
    fi

    fzf $fzf_options <<< "$items" | awk '{print $2}' | \
        while read -r url_chosen; do
            _open_url "$p_open_cmd" "$url_chosen" &> "/tmp/tmux-$(id -u)-fzf-url.log"
        done

}


#function _get-opt-value() {
#  tmux show -vg "@thumbs-${1}" 2> /dev/null
#}
#
#function _get-opt-arg() {
#
#  local opt type value
#  opt="${1}"; type="${2}"
#  value="$(_get-opt-value "${opt}")" || true
#
#  if [ "${type}" = string ]; then
#    [ -n "${value}" ] && echo "--${opt}=${value}"
#  elif [ "${type}" = boolean ]; then
#    [ "${value}" = 1 ] && echo "--${opt}"
#  else
#    return 1
#  fi
#
#}
#
#
#PARAMS=()
#
#function _add-param() {
#
#  local type opt arg
#  opt="${1}"; type="${2}"
#
#  if arg="$(_get-opt-arg "${opt}" "${type}")"; then
#    PARAMS+=("${arg}")
#  fi
#}
#
#
#
#start_tmux_thumbs() {
#
#
#    _add-param command        string
#    _add-param upcase-command string
#    _add-param multi-command  string
#    _add-param osc52          boolean
#
#    #echo "${PARAMS[@]}"
#
#    tmux-thumbs "${PARAMS[@]}" || true
#
#
#}


"$@"
