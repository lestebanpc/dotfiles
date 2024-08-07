#!/usr/bin/env bash

[ -z "$TMUX" ] && exit 255
if [ -z "$TMUX_SOCKET" ]; then
  TMUX_SOCKET=$(printf '%s' "$TMUX" | cut -d, -f1)
fi
if [ -z "$TMUX_PROGRAM" ]; then
    TMUX_PROGRAM='tmux'
fi


_maximize_pane() {

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


_toggle_mouse() {
  old=$(tmux show -gv mouse)
  new=""

  if [ "$old" = "on" ]; then
    new="off"
  else
    new="on"
  fi

  tmux set -g mouse $new
}


_urlview() {
  pane_id="$1"; shift
  tmux capture-pane -J -S - -E - -b "urlview-$pane_id" -t "$pane_id"
  #tmux split-window "'$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} show-buffer -b 'urlview-$pane_id' | urlview || true; '$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} delete-buffer -b 'urlview-$pane_id'"
  tmux display-popup -w99% -E "'$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} show-buffer -b 'urlview-$pane_id' | urlview || true; '$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} delete-buffer -b 'urlview-$pane_id'"
}

_urlscan() {
  pane_id="$1"; shift
  tmux capture-pane -J -S - -E - -b "urlscan-$pane_id" -t "$pane_id"
  #tmux split-window "'$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} show-buffer -b 'urlscan-$pane_id' | urlscan $* || true; '$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} delete-buffer -b 'urlscan-$pane_id'"
  tmux display-popup -w99% -E "'$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} show-buffer -b 'urlscan-$pane_id' | urlscan $* || true; '$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} delete-buffer -b 'urlscan-$pane_id'"
}

_fpp() {
  tmux capture-pane -J -S - -E - -b "fpp-$1" -t "$1"
  #tmux split-window -c "$2" "'$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} show-buffer -b 'fpp-$1' | fpp || true; '$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} delete-buffer -b 'fpp-$1'"
  tmux display-popup -w99% -h80% -E "'$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} show-buffer -b 'fpp-$1' | fpp || true; '$TMUX_PROGRAM' ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} delete-buffer -b 'fpp-$1'"
}


open_url() {

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
            open_url "$p_open_cmd" "$url_chosen" &> "/tmp/tmux-$(id -u)-fzf-url.log"
        done

}

"$@"

