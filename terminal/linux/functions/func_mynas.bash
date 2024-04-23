#!/bin/bash

g_color_gray1="\x1b[90m"
g_color_reset="\x1b[0m"

#Carpetas de archivos temporales
#_g_tmp_data_path="/tmp/.files"
#if [ ! -d "$_g_tmp_data_path" ]; then
#    mkdir -p $_g_tmp_data_path
#fi


################################################################################################
# Inicializar/Finalizar la musica de la NAS 
################################################################################################

start_music() {

    #1. Argumentos

    #2. Validar si tiene los puntos de montaje configurados
    local l_aux

    l_aux=$(grep '/nas/music/2.0' /etc/fstab 2> /dev/null)
    local l_status=$?

    if [ $l_status -ne 0 ] || [ -z "$l_aux" ]; then
        printf 'No esta registrado el punto de montaje "%b%s%b" en "%b%s%b".\n' "$g_color_gray1" "/nas/music/2.0" "$g_color_reset" \
               "$g_color_gray1" "/etc/fstab" "$g_color_reset" 
        return 1 
    fi

    l_aux=$(grep '/nas/music/5.1' /etc/fstab 2> /dev/null)
    l_status=$?

    if [ $l_status -ne 0 ] || [ -z "$l_aux" ]; then
        printf 'No esta registrado el punto de montaje "%b%s%b" en "%b%s%b".\n' "$g_color_gray1" "/nas/music/5.1" "$g_color_reset" \
               "$g_color_gray1" "/etc/fstab" "$g_color_reset" 
        return 2 
    fi

    #3. Montar los punto de montaje de musica
    if cat /proc/mounts | grep '/nas/music/2.0' 2>&1 > /dev/null; then
        printf 'El punto de montaje "%b%s%b" ya esta montado.\n' "$g_color_gray1" "/nas/music/2.0" "$g_color_reset"
    else
        printf 'Montando el punto de montaje "%b%s%b"...\n' "$g_color_gray1" "/nas/music/2.0" "$g_color_reset"
        sudo mount /nas/music/2.0
    fi

    if cat /proc/mounts | grep '/nas/music/5.1' 2>&1 > /dev/null; then
        printf 'El punto de montaje "%b%s%b" ya esta montado.\n' "$g_color_gray1" "/nas/music/5.1" "$g_color_reset"
    else
        printf 'Montando el punto de montaje "%b%s%b"...\n' "$g_color_gray1" "/nas/music/5.1" "$g_color_reset"
        sudo mount /nas/music/5.1
    fi

    #4. Iniciando el domonio mdp
    if systemctl is-active mpd.service 2>&1 > /dev/null; then
        printf 'El demonio MDP "%bMusic Player Daemon%b" ya esta iniciado.\n' "$g_color_gray1" "$g_color_reset"
    else
        printf 'Iniciando el demonio MDP "%bMusic Player Daemon%b"...\n' "$g_color_gray1" "$g_color_reset"
        sudo systemctl start mpd.service
    fi

    return 0
        
}


stop_music() {

    #1. Argumentos

    #2. Deteniendo el domonio mdp
    if systemctl is-active mpd.service 2>&1 > /dev/null; then
        printf 'Deteniendo el demonio MDP "%bMusic Player Daemon%b"...\n' "$g_color_gray1" "$g_color_reset"
        sudo systemctl stop mpd.service
        sudo systemctl stop mpd.socket
    else
        printf 'El demonio MDP "%bMusic Player Daemon%b" ya esta detenido.\n' "$g_color_gray1" "$g_color_reset"
    fi

    #3. Desmontando los punto de montaje de musica
    if cat /proc/mounts | grep '/nas/music/2.0' 2>&1 > /dev/null; then
        printf 'Desmontando el punto de montaje "%b%s%b"...\n' "$g_color_gray1" "/nas/music/2.0" "$g_color_reset"
        sudo umount /nas/music/2.0
    else
        printf 'El punto de montaje "%b%s%b" ya esta desmontado.\n' "$g_color_gray1" "/nas/music/2.0" "$g_color_reset"
    fi

    if cat /proc/mounts | grep '/nas/music/5.1' 2>&1 > /dev/null; then
        printf 'Desmontando el punto de montaje "%b%s%b"...\n' "$g_color_gray1" "/nas/music/5.1" "$g_color_reset"
        sudo umount /nas/music/5.1
    else
        printf 'El punto de montaje "%b%s%b" ya esta desmontado.\n' "$g_color_gray1" "/nas/music/5.1" "$g_color_reset"
    fi

    return 0
        
}







