#!/bin/bash


#Constantes: Colores
g_color_reset="\x1b[0m"
g_color_green1="\x1b[32m"
g_color_gray1="\x1b[90m"
g_color_cian1="\x1b[36m"
g_color_yellow1="\x1b[33m"
g_color_red1="\x1b[31m"
g_color_blue1="\x1b[34m"

#Expresiones regulares de sustitucion mas usuadas para las versiones
if [ -z "$g_regexp_sust_version1" ]; then
    #La version 'x.y.z' esta la inicio o despues de caracteres no numericos
    declare -r g_regexp_sust_version1='s/[^0-9]*\([0-9]\+\.[0-9.]\+\).*/\1/'
fi


################################################################################################
# Colores de la terminal
################################################################################################

# La mayoria de los comandos built-in por el interprete shell soportan colores y estos colores lo
# obtinen de la variable de entorno 'LS_COLORS'. Por tal motivo, la mayoria de las distros 
# implementa los siguientes alias en su profile:
#    alias grep='grep --color=auto'
#    alias fgrep='fgrep --color=auto'
#    alias egrep='egrep --color=auto'

declare -A _g_ls_colors_types=(
    [bd]="block device"
    [ca]="file with capability"
    [cd]="character device"
    [di]="directory"
    [do]="door"
    [ex]="executable file"
    [fi]="regular file"
    [ln]="symbolic link"
    [mh]="multi-hardlink"
    [mi]="missing file"
    [no]="normal non-filename text"
    [or]="orphan symlink"
    [ow]="other-writable directory"
    [pi]="named pipe, AKA FIFO"
    [rs]="reset to no color"
    [sg]="set-group-ID"
    [so]="socket"
    [st]="sticky directory"
    [su]="set-user-ID"
    [tw]="sticky and other-writable directory"
)

# Mustra la entradas almacenadas en las variable de entorno "LS_COLORS" (el tipo, el color y la
# descripcion si existe).
# La variable LS_COLORS almacena ...
print_ls_colors() {

    local IFS=:
    local l_ls_color=""
    local l_color=""
    local l_type=""
    local l_desc=""
    local l_color_prev=""

    for l_ls_color in $LS_COLORS; do

        l_color="${l_ls_color#*=}"
        l_type="${l_ls_color%=*}"
    
        # Add description for named types.
        l_desc="${_g_ls_colors_types[$l_type]}"
    
        # Separate each color with a newline.
        if [[ $l_color_prev ]] && [[ $l_color != "$l_color_prev" ]]; then
            printf '\n'
        fi
    
        printf "\e[%sm%s%s\e[m " "$l_color" "$l_type" "${l_desc:+ ($l_desc)}"
    
        # For next loop
        l_color_prev="$l_color"

    done
    
    printf '\n'
}

# Colores de la terminal
# Obtenido y modificado de: https://gist.github.com/HaleTom/89ffe32783f89f403bba96bd7bcd1263

# Return a colour that contrasts with the given colour Bash only does integer division, so keep it integral
function _contrast_colour {
    local r g b luminance
    colour="$1"

    if (( colour < 16 )); then # Initial 16 ANSI colours
        (( colour == 0 )) && printf "15" || printf "0"
        return
    fi

    # Greyscale # rgb_R = rgb_G = rgb_B = (number - 232) * 10 + 8
    if (( colour > 231 )); then # Greyscale ramp
        (( colour < 244 )) && printf "15" || printf "0"
        return
    fi

    # All other colours:
    # 6x6x6 colour cube = 16 + 36*R + 6*G + B  # Where RGB are [0..5]
    # See http://stackoverflow.com/a/27165165/5353461

    # r=$(( (colour-16) / 36 ))
    g=$(( ((colour-16) % 36) / 6 ))
    # b=$(( (colour-16) % 6 ))

    # If luminance is bright, print number in black, white otherwise.
    # Green contributes 587/1000 to human perceived luminance - ITU R-REC-BT.601
    (( g > 2)) && printf "0" || printf "15"
    return

    # Uncomment the below for more precise luminance calculations

    # # Calculate percieved brightness
    # # See https://www.w3.org/TR/AERT#color-contrast
    # # and http://www.itu.int/rec/R-REC-BT.601
    # # Luminance is in range 0..5000 as each value is 0..5
    # luminance=$(( (r * 299) + (g * 587) + (b * 114) ))
    # (( $luminance > 2500 )) && printf "0" || printf "15"
}

# Print a coloured block with the number of that colour
_print_colour() {
    local colour="$1" contrast
    contrast=$(_contrast_colour "$1")
    printf "\e[48;5;%sm" "$colour"                # Start block of colour
    printf "\e[38;5;%sm%3d" "$contrast" "$colour" # In contrast, print number
    printf "\e[0m "                               # Reset colour
}

# Starting at $1, print a run of $2 colours
_print_run () {
    local i
    local printable_colours=256
    for (( i = "$1"; i < "$1" + "$2" && i < printable_colours; i++ )) do
        _print_colour "$i"
    done
    printf "  "
}

# Print blocks of colours
_print_blocks() {
    local start="$1" i
    local end="$2" # inclusive
    local block_cols="$3"
    local block_rows="$4"
    local blocks_per_line="$5"
    local block_length=$((block_cols * block_rows))

    # Print sets of blocks
    for (( i = start; i <= end; i += (blocks_per_line-1) * block_length )) do
        printf "\n" # Space before each set of blocks
        # For each block row
        for (( row = 0; row < block_rows; row++ )) do
            # Print block columns for all blocks on the line
            for (( block = 0; block < blocks_per_line; block++ )) do
                _print_run $(( i + (block * block_length) )) "$block_cols"
            done
            (( i += block_cols )) # Prepare to print the next row
            printf "\n"
        done
    done
}

print_256_colors () {
	# The first 16 colours are spread over the whole spectru
	_print_run 0 16 
	printf "\n"
	# 6x6x6 colour cube between 16 and 231 inclusive
	_print_blocks 16 231 6 6 3
    # Not 50, but 24 Shades of Grey
	_print_blocks 232 255 12 2 1 
}

################################################################################################
# NerdCtl con CRT 'ContainerD'
################################################################################################

start_nerdctl() {

    #1. Argumentos
    local l_tag_mode="rootless"
    local p_root_mode=1
    if [ "$1" = "0" ]; then
        p_root_mode=0
        l_tag_mode="root"
    fi

    local l_user_is_root=1
    if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
        l_user_is_root=0
        p_root_mode=0
        l_tag_mode="root"
    fi

    #Validar si existe los comandos
    local l_version
    l_version=$(nerdctl --version 2> /dev/null)
    local l_status=$?

    if [ $l_status -ne 0 ]; then
       printf 'El programa "%b%s%b" no esta instalado.\n' "$g_color_gray1" "nerdctl" "$g_color_reset"
       return 1
    else
       l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
       printf 'El programa "%b%s%b" con la versión "%b%s%b" esta instalado.\n' "$g_color_gray1" "nerdctl" "$g_color_reset" \
              "$g_color_gray1" "$l_version" "$g_color_reset"
    fi

    l_version=$(containerd --version 2> /dev/null)
    local l_status=$?

    if [ $l_status -ne 0 ]; then
       printf 'El programa "%b%s%b" no esta instalado.\n' "$g_color_gray1" "containerd" "$g_color_reset"
       return 2
    else
       l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
       printf 'El programa "%b%s%b" con la versión "%b%s%b" esta instalado.\n' "$g_color_gray1" "containerd" "$g_color_reset" \
              "$g_color_gray1" "$l_version" "$g_color_reset"
    fi

    local l_flag_buildkit=1
    l_version=$(buildkitd --version 2> /dev/null)
    local l_status=$?

    if [ $l_status -ne 0 ]; then
       printf 'El programa "%b%s%b" no esta instalado.\n' "$g_color_gray1" "buildkitd" "$g_color_reset"
    else
       l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
       printf 'El programa "%b%s%b" con la versión "%b%s%b" esta instalado.\n' "$g_color_gray1" "buildkitd" "$g_color_reset" \
              "$g_color_gray1" "$l_version" "$g_color_reset"
       l_flag_buildkit=0
    fi

    #Validar si esta configurado la unidad systemd
    if [ $p_root_mode -ne 0 ]; then

        if [ ! -f "${HOME}/.config/systemd/user/containerd.service" ]; then
           printf 'El archivos de configuración "%b%s%b" de la unidad "%b%s%b" no existe.\n' "$g_color_gray1" "~/.config/systemd/user/containerd.service" \
                  "$g_color_reset" "$g_color_gray1" "containerd" "$g_color_reset"
           return 3
        fi

        if [ $l_flag_buildkit -eq 0 ] && [ ! -f "${HOME}/.config/systemd/user/buildkit.service" ]; then
           printf 'El archivos de configuración "%b%s%b" de la unidad "%b%s%b" no existe.\n' "$g_color_gray1" "~/.config/systemd/user/buildkit.service" \
                  "$g_color_reset" "$g_color_gray1" "containerd" "$g_color_reset"
           l_flag_buildkit=1
        fi

    else

        if [ ! -f "/usr/lib/systemd/system/containerd.service" ]; then
           printf 'El archivos de configuración "%b%s%b" de la unidad "%b%s%b" no existe.\n' "$g_color_gray1" "/usr/lib/systemd/system/containerd.service" \
                  "$g_color_reset" "$g_color_gray1" "containerd" "$g_color_reset"
           return 3
        fi

        if [ $l_flag_buildkit -eq 0 ] && [ ! -f "/usr/lib/systemd/system/buildkit.service" ]; then
           printf 'El archivos de configuración "%b%s%b" de la unidad "%b%s%b" no existe.\n' "$g_color_gray1" "/usr/lib/systemd/system/buildkit.service" \
                  "$g_color_reset" "$g_color_gray1" "containerd" "$g_color_reset"
           l_flag_buildkit=1
        fi

    fi

    printf 'Ejecutando el Container Runtime "%b%s%b" en modo "%b%s%b"...\n' "$g_color_cian1" "containerd" "$g_color_reset" \
           "$g_color_cian1" "$l_tag_mode" "$g_color_reset"

    #3. Iniciando la unidad systemd
    if [ $p_root_mode -ne 0 ]; then
        if systemctl --user is-active containerd.service 2>&1 > /dev/null; then
            printf 'La unidad systemd %b%s%b ya esta iniciado.\n' "$g_color_gray1" "containerd.service" "$g_color_reset"
        else
            printf 'La unidad systemd %b%s%b se esta iniciando: "%b%s%b".\n' "$g_color_cian1" "containerd.service" "$g_color_reset" \
                   "$g_color_gray1" "systemctl --user start containerd.service" "$g_color_reset"
            systemctl --user start containerd.service
        fi
    else
        if systemctl is-active containerd.service 2>&1 > /dev/null; then
            printf 'La unidad systemd %b%s%b ya esta iniciado.\n' "$g_color_gray1" "containerd.service" "$g_color_reset"
        else
            if [ $l_user_is_root -eq 0 ]; then
                printf 'La unidad systemd %b%s%b se esta iniciando: "%b%s%b".\n' "$g_color_cian1" "containerd.service" "$g_color_reset" \
                       "$g_color_gray1" "systemctl start containerd.service" "$g_color_reset"
                systemctl start containerd.service
            else
                printf 'La unidad systemd %b%s%b se esta iniciando: "%b%s%b".\n' "$g_color_cian1" "containerd.service" "$g_color_reset" \
                       "$g_color_gray1" "sudo systemctl start containerd.service" "$g_color_reset"
                sudo systemctl start containerd.service
            fi
        fi
    fi

    if [ $l_flag_buildkit -eq 0 ]; then

        printf 'Ejecutando el Image Builder "%b%s%b" en modo "%b%s%b"...\n' "$g_color_cian1" "buildkit" "$g_color_reset" \
           "$g_color_cian1" "$l_tag_mode" "$g_color_reset"

        if [ $p_root_mode -ne 0 ]; then
            if systemctl --user is-active buildkit.service 2>&1 > /dev/null; then
                printf 'La unidad systemd %b%s%b ya esta iniciado.\n' "$g_color_gray1" "buildkit.service" "$g_color_reset"
            else
                sleep 1
                printf 'La unidad systemd %b%s%b se esta iniciando: "%b%s%b".\n' "$g_color_cian1" "buildkit.service" "$g_color_reset" \
                       "$g_color_gray1" "systemctl --user start buildkit.service" "$g_color_reset"
                systemctl --user start buildkit.service
            fi
        else
            if systemctl is-active buildkit.service 2>&1 > /dev/null; then
                printf 'La unidad systemd %b%s%b ya esta iniciado.\n' "$g_color_gray1" "buildkit.service" "$g_color_reset"
            else
                sleep 1
                if [ $l_user_is_root -eq 0 ]; then
                    printf 'La unidad systemd %b%s%b se esta iniciando: "%b%s%b".\n' "$g_color_cian1" "buildkit.service" "$g_color_reset" \
                           "$g_color_gray1" "systemctl start buildkit.service" "$g_color_reset"
                    systemctl start buildkit.service
                else
                    printf 'La unidad systemd %b%s%b se esta iniciando: "%b%s%b".\n' "$g_color_cian1" "buildkit.service" "$g_color_reset" \
                           "$g_color_gray1" "sudo systemctl start buildkit.service" "$g_color_reset"
                    sudo systemctl start buildkit.service
                fi
            fi
        fi
    fi

    return 0
        
}


stop_nerdctl() {

    #1. Argumentos
    local l_tag_mode="rootless"
    local p_root_mode=1
    if [ "$1" = "0" ]; then
        p_root_mode=0
        l_tag_mode="root"
    fi

    local l_user_is_root=1
    if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
        l_user_is_root=0
        p_root_mode=0
        l_tag_mode="root"
    fi

    printf 'Deteniendo las unidades vinculadas al Container Runtime "%b%s%b" de modo "%b%s%b"...\n' "$g_color_cian1" "containerd" "$g_color_reset" \
           "$g_color_gray1" "$l_tag_mode" "$g_color_reset"

    #2. Deteniendo las unidades systemd

    if [ $p_root_mode -ne 0 ]; then
        if systemctl --user is-active buildkit.service 2>&1 > /dev/null; then
            printf 'La unidad systemd %b%s%b se esta deteniendo: "%b%s%b".\n' "$g_color_cian1" "buildkit.service" "$g_color_reset" \
                   "$g_color_gray1" "systemctl --user stop buildkit.service" "$g_color_reset"
            systemctl --user stop buildkit.service
        else
            printf 'La unidad systemd %b%s%b ya esta detenido.\n' "$g_color_gray1" "buildkit.service" "$g_color_reset"
        fi
    else

        if systemctl is-active buildkit.service 2>&1 > /dev/null; then
            if [ $l_user_is_root -eq 0 ]; then
                printf 'La unidad systemd %b%s%b se esta deteniendo: "%b%s%b".\n' "$g_color_cian1" "buildkit.service" "$g_color_reset" \
                       "$g_color_gray1" "systemctl stop buildkit.service" "$g_color_reset"
                systemctl stop buildkit.service
            else
                printf 'La unidad systemd %b%s%b se esta deteniendo: "%b%s%b".\n' "$g_color_cian1" "buildkit.service" "$g_color_reset" \
                       "$g_color_gray1" "sudo systemctl stop buildkit.service" "$g_color_reset"
                sudo systemctl stop buildkit.service
            fi
        else
            printf 'La unidad systemd %b%s%b ya esta deteniendo.\n' "$g_color_gray1" "buildkit.service" "$g_color_reset"
        fi

        if systemctl is-active buildkit.socket 2>&1 > /dev/null; then
            if [ $l_user_is_root -eq 0 ]; then
                printf 'La unidad systemd %b%s%b se esta deteniendo: "%b%s%b".\n' "$g_color_cian1" "buildkit.socket" "$g_color_reset" \
                       "$g_color_gray1" "systemctl stop containerd.socket" "$g_color_reset"
                systemctl stop buildkit.socket
            else
                printf 'La unidad systemd %b%s%b se esta deteniendo: "%b%s%b".\n' "$g_color_cian1" "buildkit.socket" "$g_color_reset" \
                       "$g_color_gray1" "sudo systemctl stop buildkit.socket" "$g_color_reset"
                sudo systemctl stop buildkit.socket
            fi
        else
            printf 'La unidad systemd %b%s%b ya esta deteniendo.\n' "$g_color_gray1" "containerd.socket" "$g_color_reset"
        fi

    fi

    if [ $p_root_mode -ne 0 ]; then
        if systemctl --user is-active containerd.service 2>&1 > /dev/null; then
            sleep 1
            printf 'La unidad systemd %b%s%b se esta deteniendo: "%b%s%b".\n' "$g_color_cian1" "containerd.service" "$g_color_reset" \
                   "$g_color_gray1" "systemctl --user stop containerd.service" "$g_color_reset"
            systemctl --user stop containerd.service
        else
            printf 'La unidad systemd %b%s%b ya esta detenido.\n' "$g_color_gray1" "containerd.service" "$g_color_reset"
        fi
    else
        if systemctl is-active containerd.service 2>&1 > /dev/null; then
            if [ $l_user_is_root -eq 0 ]; then
                printf 'La unidad systemd %b%s%b se esta deteniendo: "%b%s%b".\n' "$g_color_cian1" "containerd.service" "$g_color_reset" \
                       "$g_color_gray1" "systemctl stop containerd.service" "$g_color_reset"
                systemctl stop containerd.service
            else
                printf 'La unidad systemd %b%s%b se esta deteniendo: "%b%s%b".\n' "$g_color_cian1" "containerd.service" "$g_color_reset" \
                       "$g_color_gray1" "sudo systemctl stop containerd.service" "$g_color_reset"
                sudo systemctl stop containerd.service
            fi
        else
            printf 'La unidad systemd %b%s%b ya esta deteniendo.\n' "$g_color_gray1" "containerd.service" "$g_color_reset"
        fi
    fi


    return 0
        
}







