#!/usr/bin/env bash

# Modificado de 'https://github.com/wfxr/tmux-fzf-url/blob/master/fzf-url.sh' 
# Codigo original desarrollado por Wenxuan (wenxuangm@gmail.com)

[ -z "$TMUX" ] && exit 255
if [ -z "$TMUX_SOCKET" ]; then
  TMUX_SOCKET=$(printf '%s' "$TMUX" | cut -d, -f1)
fi
if [ -z "$TMUX_PROGRAM" ]; then
    TMUX_PROGRAM='tmux'
fi


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

init_url() {

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

