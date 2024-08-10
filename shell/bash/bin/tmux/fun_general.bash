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
#        > No se ha podido establecer un mecanismo del clipboard (se indica que usa comando externo, pero no se ubica.
#      0 > Usar comandos externo de clipboard y la opcion 'set-clipboard' en 'off'
#      1 > Usar OSC 52 con la opcion 'set-clipboard' en 'on'
#      2 > Usar OSC 52 con la opcion 'set-clipboard' en 'external'
setting_clipboard() {

    local p_key="$1"

    #Obtener si se se usara el metodo 'OSC 52' o 'external command' para poder escribir automaticamente
    #el contenido del buffer a la terminal.
    local p_use_osc54=1
    if [ "$2" = "0" ]; then
        p_use_osc54=0
    elif [ "$2" = "1" ]; then
        p_use_osc54=1
    elif [ "$2" = "2" ]; then
        p_use_osc54=1
    else
        #Determinar si la terminal soporta OSC 52
        case "$TERM_PROGRAM" in
            #Los siguientes emuladores definen por defecto esta variable de entorno:
            WezTerm)
                p_use_osc54=2
                ;;
            contour)
                p_use_osc54=2
                ;;
            iTerm.app)
                p_use_osc54=2
                ;;
            #Los siguientes emuladores debera definir la variable con este valor en su archivo de configuracion:
            kitty)
                p_use_osc54=2
                ;;
            alacritty)
                p_use_osc54=2
                ;;
            foot)
                p_use_osc54=2
                ;;
            #Opcionalmente, aunque no se recomienta usar un TERM personalizado (no estan en todos los equipos que accede
            #por SSH), algunas terminales definen un TERM personalizado (aunque por campatibilidad, puede modificarlo).
            *)                
                case "$TERM" in
                    xterm-kitty)
                        #Emulador de terminal Kitty
                        p_use_osc54=2
                        ;;
                    alacritty)
                        #Emulador de terminal Alacritty
                        p_use_osc54=2
                        ;;
                    foot)
                        #Emulador de terminal Food
                        p_use_osc54=2
                        ;;
                    *)
                        p_use_osc54=0
                        ;;
                esac
                ;;
        esac

    fi
    
    #Activar el metodo de clipboard identicado
    if [ $p_use_osc54 -eq 2 ]; then
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} set-option -s set-clipboard external
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} set-environment -g TMUX_SET_CLIPBOARD 2 
        return 0
    fi 

    if [ $p_use_osc54 -eq 1 ]; then
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} set-option -s set-clipboard on
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} set-environment -g TMUX_SET_CLIPBOARD 1
        return 0
    fi

    #Usandpo comandos externos
    _get_os_type
    local l_os_type=$?
    local l_command=''

    #  00 > Si es Linux no-WSL
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

        if [ -z "$l_command" ]; then
            $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} display-message "Not found command 'xclip' or 'xsel' for paste buffer to clipboard"
            return 0
        fi


    #  01 > Si es Linux WSL2 (Kernel de Linux nativo sobre Windows)
    elif [ $l_os_type -eq 1 ]; then

        if [ ! -f "/mnt/c/windows/system32/clip.exe" ]; then
            $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} display-message "Not found command 'clip.exe' for paste buffer to clipboard"
            return 0
        fi

        l_command='/mnt/c/windows/system32/clip.exe'

    #  03 > Si es MacOS
    elif [ $l_os_type -eq 3 ]; then

        if ! command -v pbcopy > /dev/null 2>&1; then
            $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} display-message "Not found command 'pbcopy' for paste buffer to clipboard"
            return 0
        fi
        l_command='pbcopy'

    else
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} display-message "Not definited command to manage clipboard for this OS"
        return 0
    fi

    if [ $TMUX_VERSION -lt 240 ]; then

        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -tvi-copy "$p_key"          copy-pipe "$l_command"
        #$TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -tvi-copy Enter             copy-pipe  "$l_command"
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -tvi-copy MouseDragEnd1Pane copy-pipe  "$l_command"

    elif [ $TMUX_VERSION -ge 240 ] && [ $TMUX_VERSION -lt 320 ]; then

        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -Tcopy-mode-vi "$p_key"          send -X copy-pipe-and-cancel  "$l_command"
        #$TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -Tcopy-mode-vi Enter             send -X copy-pipe-and-cancel  "$l_command"
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -Tcopy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel  "$l_command"

    else

        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} set-option -s copy-command "$l_command"
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -Tcopy-mode-vi "$p_key"          send -X copy-pipe-and-cancel
        #$TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -Tcopy-mode-vi Enter             send -X copy-pipe-and-cancel
        $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} bind-key -Tcopy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel

    fi

    $TMUX_PROGRAM ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} set-environment -g TMUX_SET_CLIPBOARD 0
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

"$@"

