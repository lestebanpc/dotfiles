#!/bin/bash


#Colores principales usados para presentar en FZF
g_color_reset="\x1b[0m"
g_color_gray1="\x1b[90m"
g_color_green1="\x1b[32m"
g_color_cyan1="\x1b[36m"


#Lista los folderes de trabajo que podrian crearse como sesiones tmux
#Usado para crear sesiones en tmux con sesh
list_work_folder() {

    local p_path="$1"
    local p_mindepth=$2
    local p_maxdepth=$3

    local l_exclude_options=''

    #Si es HOME (se usa ello para permitir la ruta relativa y no usar realpath)
    if [ -f "$l_path/.bashrc" ]; then
        l_exclude_options="-name 'Documents' -o -name 'Downloads' -o -name 'Desktop' -o -name 'Pictures' -o -name 'Music' -o -name 'Videos' -o -name 'Templates' -o -name 'personal' -o -name 'photos'"
    else
        l_exclude_options="-name 'bin' -o -name 'obj' -o -name 'node_modules'"
    fi

    #echo "$l_exclude_options"

    # find ./code -mindepth 2 -maxdepth 10 -type d -name '.git' -exec dirname "{}" \;
    # find ~/code -mindepth 2 -maxdepth 10 -type d -execdir test -d "{}/.git" \; -prune -print
    # find ~/code -mindepth 2 -maxdepth 10 -type d \( -execdir  test -e "{}/.ignore" \; -prune \) -o \( -execdir test -d "{}/.git" \; -prune -print \)
    # find ~ -mindepth 1 -maxdepth 2 -type d \( -name ".*" -o -name "Documents" -o -name "Downloads" -o -name "Desktop" -o -name "Pictures" -o \
    #        -name "Videos" -o -name "personal" -o -name "photos" \) -prune -o \( -type d -writable -print \)
    # find . -mindepth 1 -maxdepth 10 -type d \( -name ".*" -o -name "Documents" -o -name "Downloads" -o -name "Desktop" -o -name "Pictures" -o -name "Videos" -o -name "personal" -o -name "photos" \) -prune -o -type d -print
    # find . -mindepth 1 -maxdepth 10 -type d -name ".git" -print -o -type d \( -name ".*" -o -name "Documents" -o -name "Downloads" -o -name "Desktop" -o -name "Pictures" -o -name "Videos" -o -name "personal" -o -name "photos" \) -prune
    find "$p_path" -mindepth $p_mindepth -maxdepth $p_maxdepth -type d \( -name '.*' -o $l_exclude_options \) -prune -o -type d -print

}

#Lista los folderes de trabajo con repositorio git que podrian crearse como sesiones tmux
#Usado para crear sesiones en tmux con sesh
list_git_folder() {

    local p_path="$1"
    local p_mindepth=$2
    local p_maxdepth=$3

    local l_exclude_options=''

    #Si es HOME (se usa ello para permitir la ruta relativa y no usar realpath)
    if [ -f "$l_path/.bashrc" ]; then
        l_exclude_options='-name "Documents" -o -name "Downloads" -o -name "Desktop" -o -name "Pictures" -o -name "Music" -o -name "Videos" -o -name "Templates" -o -name "personal" -o -name "photos"'
    else
        l_exclude_options='-name "bin" -o -name "obj" -o -name "node_modules"'
    fi

    #echo "$l_exclude_options"

    find "$p_path" -mindepth $p_mindepth -maxdepth $p_maxdepth -type d -name ".git" -exec dirname "{}" \; -o -type d \( -name '.*' -o $l_exclude_options \) -prune

}

#Los parametros debe ser la funcion y los parametros
"$@"

