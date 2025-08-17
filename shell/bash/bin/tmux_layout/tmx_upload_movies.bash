#!/bin/bash

_make_tmux_layout() {

    #1. Argumentos
    local p_height=$1


    #2. Ventana de pelicual a  subir

    # Renombrar el panel actual
    tmux rename-window 'upload'

    # Crear un nuevo panel sin convertirlo en activo (opcion '-d')
    local l_pane_id=''
    l_pane_id=$(tmux split-window -vdp $(( 100 - p_height )) -PF "#{pane_id}")

    tmux send-keys -t "$l_pane_id" 'clear' Enter
    tmux send-keys -t "$l_pane_id" "lftp -e 'set ftp:ssl-allow no' -u lucianoepc ftp://nas50.quyllur.home"
    #tmux send-keys -t "$l_pane_position" 'clear' Enter
    #tmux send-keys -lt "$l_pane_position" "$g_tmux_command"
    #tmux send-keys -t "$l_pane_position" Enter


    #3. Ventana de archivos descargados

    # Crear la nueva ventana
    local l_window_id=''
    local l_working_dir='/tempo/download'

    l_window_id=$(tmux new-window -c "$l_working_dir" -dn 'download' -PF "#{window_id}")

    tmux send-keys -t "${l_window_id}" 'clear' Enter
    tmux send-keys -t "${l_window_id}" 'pwd' Enter

    # Crear un nuevo panel sin convertirlo en activo (opcion '-d')
    l_working_dir='/tempo/download/movies'
    if [ ! -d "$l_working_dir" ]; then
        mkdir $l_working_dir
    fi

    l_pane_id=$(tmux split-window -t "${l_window_id}" -c "$l_working_dir" -vdp $(( 100 - p_height )) -PF "#{pane_id}")

    tmux send-keys -t "${l_window_id}.${l_pane_id}" 'clear' Enter
    tmux send-keys -t "${l_window_id}.${l_pane_id}" 'pwd' Enter


    #4. Finalizacion

    # Limpiar la ventana actual y listar su contenido
    tmux send-keys 'clear' Enter
    tmux send-keys 'ls' Enter

}

# Codigo ejecutado justo despues de que sesion fue creado por sesh.
# La sesion creada es el por defecto: 1 sesion con 1 ventana con 1 panel con un shell interactivo por defecto.

_make_tmux_layout 20
