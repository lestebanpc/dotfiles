#!/bin/bash

#Constantes: Colores
g_color_reset="\x1b[0m"
g_color_green1="\x1b[32m"
g_color_gray1="\x1b[90m"
g_color_cian1="\x1b[36m"
g_color_yellow1="\x1b[33m"
g_color_red1="\x1b[31m"
g_color_blue1="\x1b[34m"

#Tamaño de la linea del menu
g_max_length_line=80


#Parametros de entrada:
#  1 > caracter de la cual esta formada la linea
#  2 > Tamaño de caracteres la linea
#  3 > Color de la linea
print_line() {

    printf '%b' "$3"
    #Usar -- para no se interprete como linea de comandos y puede crearse lienas con - (usado en opcion de un comando)
    printf -- "${1}%.0s" $(seq $2)
    printf '%b\n' "$g_color_reset" 

}


#----------------------------------------------------------------------------------
# LS_COLORS
#----------------------------------------------------------------------------------

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



#----------------------------------------------------------------------------------
# ANSI 16-Colors and ANSI 256-Colors
#----------------------------------------------------------------------------------

# La mayoria de los comandos built-in por el interprete shell soportan colores y estos colores lo
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

print_16_colors () {
	# The first 16 colours are spread over the whole spectru
	_print_run 0 16 
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


#----------------------------------------------------------------------------------
# ANSI True-Colors
#----------------------------------------------------------------------------------

#Obtenido de: https://github.com/gnachman/iTerm2/blob/master/tests/24-bit-color.sh
#Obtenido de: https://gist.githubusercontent.com/lifepillar/09a44b8cf0f9397465614e622979107f/raw/24-bit-color.sh

# This file echoes four gradients with 24-bit color codes to the terminal to demonstrate their functionality.
#  - The foreground escape sequence is ^[38;2;<r>;<g>;<b>m
#  - The background escape sequence is ^[48;2;<r>;<g>;<b>m
#  - <r> <g> <b> range from 0 to 255 inclusive.
#  - The escape sequence ^[0m returns output to default

SEPARATOR=':'

setBackgroundColor()
{
    echo -en "\x1b[48${SEPARATOR}2${SEPARATOR}$1${SEPARATOR}$2${SEPARATOR}$3""m"
}

resetOutput()
{
    echo -en "\x1b[0m\n"
}

# Gives a color $1/255 % along HSV
# Who knows what happens when $1 is outside 0-255
# Echoes "$red $green $blue" where
# $red $green and $blue are integers
# ranging between 0 and 255 inclusive
rainbowColor()
{ 
    let h=$1/43
    let f=$1-43*$h
    let t=$f*255/43
    let q=255-t

    if [ $h -eq 0 ]
    then
        echo "255 $t 0"
    elif [ $h -eq 1 ]
    then
        echo "$q 255 0"
    elif [ $h -eq 2 ]
    then
        echo "0 255 $t"
    elif [ $h -eq 3 ]
    then
        echo "0 $q 255"
    elif [ $h -eq 4 ]
    then
        echo "$t 0 255"
    elif [ $h -eq 5 ]
    then
        echo "255 0 $q"
    else
        # execution should never reach here
        echo "0 0 0"
    fi
}

print_true_colors () {

    for i in `seq 0 127`; do
        setBackgroundColor $i 0 0
        echo -en " "
    done
    resetOutput
    for i in `seq 255 128`; do
        setBackgroundColor $i 0 0
        echo -en " "
    done
    resetOutput
    
    for i in `seq 0 127`; do
        setBackgroundColor 0 $i 0
        echo -n " "
    done
    resetOutput
    for i in `seq 255 128`; do
        setBackgroundColor 0 $i 0
        echo -n " "
    done
    resetOutput
    
    for i in `seq 0 127`; do
        setBackgroundColor 0 0 $i
        echo -n " "
    done
    resetOutput
    for i in `seq 255 128`; do
        setBackgroundColor 0 0 $i
        echo -n " "
    done
    resetOutput
    
    for i in `seq 0 127`; do
        setBackgroundColor `rainbowColor $i`
        echo -n " "
    done
    resetOutput
    for i in `seq 255 128`; do
        setBackgroundColor `rainbowColor $i`
        echo -n " "
    done
    resetOutput

}


#----------------------------------------------------------------------------------
# Menu
#----------------------------------------------------------------------------------


function g_main_menu() {

    #1. Pre-requisitos
   
    #2. Mostrar el Menu
    print_line '─' $g_max_length_line "$g_color_green1" 
    printf " > %bMenu de Opciones%b\n" "$g_color_green1" "$g_color_reset"
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf " (%bq%b) Salir del menu\n" "$g_color_green1" "$g_color_reset"

    printf " (%ba%b) Mostrar colores de archivos/carpetas segun la variable de entorno '%bLSCOLORS%b'\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf " (%bb%b) Mostrar colores de  4-bits de la terminal: '%b%s%b'\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" 'ANSI 16-Colors' "$g_color_reset"
    printf " (%bc%b) Mostrar colores de  8-bits de la terminal: '%b%s%b'\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" 'ANSI 256-Colors' "$g_color_reset"
    printf " (%bd%b) Mostrar colores de 24-bits de la terminal: '%b%s%b'\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" 'ANSI True-Colors' "$g_color_reset"

    #printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"
    print_line '-' $g_max_length_line "$g_color_gray1"

    #3. Mostrar la ultima parte del menu y capturar la opcion elegida
    local l_flag_continue=0
    local l_options=""
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_gray1" "$g_color_reset"
        read -r l_options

        case "$l_options" in

            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                ;;


            a)
                l_flag_continue=1
                print_line '-' $g_max_length_line "$g_color_gray1"
                printf '\n'
                print_ls_colors
                printf '\n'
                ;;

            b)
                l_flag_continue=1
                print_line '-' $g_max_length_line "$g_color_gray1"
                printf '\n'
                print_16_colors
                printf '\n\n'
                ;;

            c)
                l_flag_continue=1
                print_line '-' $g_max_length_line "$g_color_gray1"
                printf '\n'
                print_256_colors
                printf '\n'
                ;;

            d)
                l_flag_continue=1
                print_line '-' $g_max_length_line "$g_color_gray1"
                printf '\n'
                print_true_colors
                ;;


            *)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_gray1" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_gray1" 
                ;;
        esac
        
    done

}



g_main_menu

