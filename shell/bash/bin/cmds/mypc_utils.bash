#!/bin/bash

# Colores principales usados
g_color_reset="\x1b[0m"
g_color_green1="\x1b[32m"
g_color_gray1="\x1b[90m"
g_color_cian1="\x1b[36m"
g_color_yellow1="\x1b[33m"
g_color_red1="\x1b[31m"
g_color_blue1="\x1b[34m"

# Obtener la del script
#g_script_path="${BASH_SOURCE[0]}"

g_cmd_name='mypc'

declare -a ga_exported_functions=(
    )

# Diccionario de sbucomandos. La key es 'id del subcomando' y value es 'la descripcion del subcomando'.
# > Segun el ID de subcomando, se debe tener 2 funciones bash cuyo nombre tiene dicho ID
#   > Funcion de ayuda del comando tiene el nombre 'm_usage_CMD-ID'.
#   > Funcion de controlador del comando tiene el nombre 'controller_CMD-ID'.
declare -A gA_subcmd_ids=(
        ['music']='Pemite inicializar el MPD y montar el directorio compartido de archivos de musica de la NAS'
        ['configdns']='Vuelve a sondear las prioridad de los servidor DNS de la interface de red br0'
    )


# Diccionario de sbucomandos. La key es 'alias' y value es 'ID del subcomando'.
declare -A gA_subcmd_alias=(
    )


# Expresiones regulares de sustitucion mas usuadas para las versiones

# La version 'x.y.z' esta la inicio o despues de caracteres no numericos
declare -r g_regexp_sust_version1='s/[^0-9]*\([0-9]\+\.[0-9.]\+\).*/\1/'



# -------------------------------------------------------------------------------------
# General functions
# -------------------------------------------------------------------------------------



# -------------------------------------------------------------------------------------
# Exported functions
# -------------------------------------------------------------------------------------



# -------------------------------------------------------------------------------------
# Subcomand Controller> Music
# -------------------------------------------------------------------------------------

m_usage_configdns() {

    local l_scmd_id='configdns'
    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '    %b%s %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s %s%b [args]%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h|--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}


m_set_first_dns_server() {

    #De las interfaces de red xxx y la brigde, validar
    # - Validar que el primer DNS esta activo
    # - Validar que el current DNS no sea el primer servidor DNS de la lista de algunas interfaces de red
    #Si alguno de ellos no lo estan homologados, reiniciarlo para que vuelva a escoger el primer servidor DNS

    #Reiniciar
    printf 'Reiniciando el "%bDNS Resolver%b" (%bsudo systemctl restart systemd-resolved.service%b)...\n' \
           "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    sudo systemctl restart systemd-resolved.service

    #Establecer los DNS a la interface brigde (copiar los DNS de la interface ....)
    sudo resolvectl dns br0 192.168.2.202 8.8.8.8 200.48.225.130


}


controller_configdns() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_configdns
                return 0
                ;;

            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_configdns
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes

    #5. Ejecutando el comando
    m_set_first_dns_server "$@"
    return 0

}




# -------------------------------------------------------------------------------------
# Subcomand Controller> Music
# -------------------------------------------------------------------------------------

m_usage_music() {

    local l_scmd_id='music'
    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '  > Ayuda:\n'
    printf '    %b%s %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  > Iniciar (%bmontar carpetas NFS de musica, configurar uso exclusivo de tarjeta de sonido, iniciar el servidor MDP%b):\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b%s %s%b start\n%b' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  > Detener (%bdetener el servidor MDP, desmontar carpetas NFS de musica%b):\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b%s %s%b stop\n%b' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h|--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}




m_start_music() {

    #1. Argumentos
    local p_card_id='D50s'
    if [ ! -z "$1" ]; then
        p_card_id="$1"
    fi

    local p_device_index=0
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        p_device_index=$2
    fi

    #2. Buscar si la tarjeta indicada existe (fue reconocida por el kernel)
    #
    #cat /proc/asound/cards | grep '\- D50s' -A 1
    # 3 [D50s           ]: USB-Audio - D50s
    #                      Topping D50s at usb-0000:08:00.3-6.2.1, high speed
    #cat /proc/asound/cards | grep '\- UMC204HD' -A 1
    # 4 [U192k          ]: USB-Audio - UMC204HD 192k
    #                      BEHRINGER UMC204HD 192k at usb-0000:08:00.3-6.2.2, high speed
    #
    local l_aux
    l_aux=$(cat /proc/asound/cards | grep '\['"$p_card_id"'\s*\]' -A 1 | head -n 2)
    local l_status=$?

    if [ $l_status -ne 0 ] || [ -z "$l_aux" ]; then
        printf 'La tarjeta de sonido con ID "%b%s%b" no esta instalado o no es reconocido por el kernel (revise "%b%s%b").\n' \
               "$g_color_gray1" "$p_card_id" "$g_color_reset" "$g_color_gray1" "cat /proc/asound/cards" "$g_color_reset"
        return 1
    fi

    #echo "$l_aux"

    local l_card_index
    l_card_index=$(echo "$l_aux" | head -n 1 | sed 's/^\s*\([0-9]\+\)\s.*$/\1/')
    l_status=$?
    if [ $l_status -ne 0 ]; then
        l_card_index=""
    fi

    local l_card_description
    l_card_description=$(echo "$l_aux" | tail -n 1 | sed 's/\s\+\(\w.*\)\sat\s.*/\1/')
    l_status=$?
    if [ $l_status -ne 0 ]; then
        l_card_description=""
    fi

    if [ -z "$l_card_index" ] || [ -z "$l_card_description" ]; then
        printf 'No se puede obtener el %bcard index%b de la tarjeta de sonido con ID "%b%s%b".\n' \
               "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$l_card_index" "$g_color_reset"
        return 2
    fi

    printf 'La tarjeta de sonido "%b%s%b", con ID "%b%s%b" e Index "%b%s%b", ha sido detectado por el kernel de Linux.\n' \
           "$g_color_cian1" "$l_card_description" "$g_color_reset" "$g_color_cian1" "$p_card_id" "$g_color_reset" \
           "$g_color_cian1" "$l_card_index" "$g_color_reset"

    #3. Identificar si el device existe (fue reconocida por el kernel)
    l_aux=$(aplay -l | grep '^card '"$l_card_index"':.*\sdevice\s'"$p_device_index")
    l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_aux" ]; then
        printf 'El device "%b%s%b" de la tarjeta de sonido "%b%s%b" no es reconocido por el kernel (revise "%b%s%b").\n' \
               "$g_color_gray1" "$p_device_index" "$g_color_reset" "$g_color_gray1" "$l_card_description" "$g_color_reset" \
               "$g_color_gray1" "aplay -l" "$g_color_reset"
        return 3
    fi


    #4. Obtener la tarjeta de sonido y el dispositivo actual. Si se requiere cambiarlos, hacerlo.
    l_aux=$(cat /etc/mpd.conf | grep -n '^\s*name\s*"ALSA Hi-Fi DAC"')
    l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_aux" ]; then

        printf 'Se requiere definir la seccion "%b%s%b" de nombre "%b%s%b" en el archivo "%b%s%b". Adicione:\n' \
               "$g_color_gray1" "audio_output" "$g_color_reset" "$g_color_gray1" "ALSA Hi-Fi DAC" "$g_color_reset" \
               "$g_color_gray1" "/etc/mpd.conf" "$g_color_reset"

        printf "%b#\n" "$g_color_yellow1"
        printf "# ALSA output:\n"
        printf "#\n"
        printf "audio_output {\n"
        printf "    type                \"alsa\"\n"
        printf "    name                \"ALSA Hi-Fi DAC\"\n"
        printf "    device              \"hw:3,0\"    #ID del soundcard y el ID del device es obtenido de 'aplay --list-devices'\n"
        printf "    auto_resample       \"no\"        #otherwise, ALSA will convert everything to PCM"\n
        printf "    auto_channels       \"no\"\n"
        printf "    auto_format         \"no\"\n"
        printf "    mixer_type          \"none\"\n"
        printf "    replay_gain_handler \"none\"\n"
        printf "#    dop                 \"yes\"       # Don't enable DoP unless you know you need it. Look in your DAC's manual.\n"
        printf "#    mixer_type          \"hardware\"  # optional\n"
        printf "#    mixer_device        \"default\"   # optional\n"
        printf "#    mixer_control       \"PCM\"       # optional\n"
        printf "#    mixer_index         \"0\"         # optional\n"
        printf "}%b\n" "$g_color_reset"

        return 4
    fi

    #Obtener la linea donde se encontro el nombre del output
    local l_line_nbr
    l_line_nbr=$(echo "$l_aux" | head -n 1 | sed 's/^\([0-9]*\):.*/\1/')
    l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_line_nbr" ]; then
        printf 'Se la seccion "%b%s%b" de nombre "%b%s%b" en el archivo "%b%s%b" no tiene el formato correcto.\n' \
               "$g_color_gray1" "audio_output" "$g_color_reset" "$g_color_gray1" "ALSA Hi-Fi DAC" "$g_color_reset" \
               "$g_color_gray1" "/etc/mpd.conf" "$g_color_reset"
        return 5
    fi

    #Obtener la linea con el campo "device"
    l_aux=$(sed -n "${l_line_nbr}"',/^\s*device\s/p;'"$((l_line_nbr + 10))"'q' /etc/mpd.conf | tail -n 1)
    l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_aux" ]; then
        printf 'Se la seccion "%b%s%b" de nombre "%b%s%b" en el archivo "%b%s%b" no tiene el campo "%b%s%b".\n' \
               "$g_color_gray1" "audio_output" "$g_color_reset" "$g_color_gray1" "ALSA Hi-Fi DAC" "$g_color_reset" \
               "$g_color_gray1" "/etc/mpd.conf" "$g_color_reset" "$g_color_gray1" "device" "$g_color_reset"
        printf "Valide que la sección tiene el formato siguiente:\n" "$g_color_gray1"

        printf "%b#\n" "$g_color_yellow1"
        printf "# ALSA output:\n"
        printf "#\n"
        printf "audio_output {\n"
        printf "    type                \"alsa\"\n"
        printf "    name                \"ALSA Hi-Fi DAC\"\n"
        printf "    device              \"hw:${l_card_index},${p_device_index}\"    #ID del soundcard y el ID del device es obtenido de 'aplay --list-devices'\n"
        printf "    auto_resample       \"no\"        #otherwise, ALSA will convert everything to PCM"\n
        printf "    auto_channels       \"no\"\n"
        printf "    auto_format         \"no\"\n"
        printf "    mixer_type          \"none\"\n"
        printf "    replay_gain_handler \"none\"\n"
        printf "#    dop                 \"yes\"       # Don't enable DoP unless you know you need it. Look in your DAC's manual.\n"
        printf "#    mixer_type          \"hardware\"  # optional\n"
        printf "#    mixer_device        \"default\"   # optional\n"
        printf "#    mixer_control       \"PCM\"       # optional\n"
        printf "#    mixer_index         \"0\"         # optional\n"
        printf "}%b\n" "$g_color_reset"

        return 6

    fi

    #Obtener el valor de campo device
    local l_device_value
    l_device_value=$(echo "$l_aux" | sed 's/^\s*device\s\+"\(.*\)".*/\1/')
    l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_device_value" ]; then
        printf 'Se la seccion "%b%s%b" de nombre "%b%s%b" %b(en el archivo "%s")%b tiene el campo "%b%s%b" con un valor incorrecto.\n' \
               "$g_color_gray1" "audio_output" "$g_color_reset" "$g_color_gray1" "ALSA Hi-Fi DAC" "$g_color_reset" \
               "$g_color_gray1" "/etc/mpd.conf" "$g_color_reset" "$g_color_gray1" "device" "$g_color_reset"

        return 7
    fi

    #Cambiar el valor de campo "device" archivo "/etc/mpd.conf"
    local l_device_new_value="hw:${l_card_index},${p_device_index}"
    if [ "$l_device_value" != "$l_device_new_value" ]; then

        printf 'Modificando el valor del campo %bdevice%b de "%b%s%b" de "%b%s%b" (seccion %b%s%b con nombre "%b%s%b" del archivo "%b%s%b") ...\n' \
               "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$l_device_value" "$g_color_reset" "$g_color_cian1" "$l_device_new_value" "$g_color_reset" \
               "$g_color_gray1" "audio_output" "$g_color_reset" "$g_color_gray1" "ALSA Hi-Fi DAC" "$g_color_reset" \
               "$g_color_gray1" "/etc/mpd.conf" "$g_color_reset"

        sudo sed -i "${l_line_nbr},$((l_line_nbr + 10))"' s/^\s*device\s\+"\(.*\)".*/    device              "'"$l_device_new_value"'"/' /etc/mpd.conf

    else
        printf 'El valor del campo %bdevice%b "%b%s%b" es el correcto (seccion %b%s%b con nombre "%b%s%b" del archivo "%b%s%b").\n' \
               "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$l_device_value" "$g_color_reset" "$g_color_gray1" "audio_output" "$g_color_reset" \
               "$g_color_gray1" "ALSA Hi-Fi DAC" "$g_color_reset" "$g_color_gray1" "/etc/mpd.conf" "$g_color_reset"
    fi

    #5. Validar si tiene los puntos de montaje configurados
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

    #6. Montar los punto de montaje de musica
    if cat /proc/mounts | grep '/nas/music/2.0' 2>&1 > /dev/null; then
        printf 'El punto de montaje "%b%s%b" ya esta montado.\n' "$g_color_cian1" "/nas/music/2.0" "$g_color_reset"
    else
        printf 'Montando el punto de montaje "%b%s%b" (%bsudo mount /nas/music/2.0%b)...\n' "$g_color_cian1" "/nas/music/2.0" "$g_color_reset" \
               "$g_color_gray1" "$g_color_reset"
        sudo mount /nas/music/2.0
    fi

    if cat /proc/mounts | grep '/nas/music/5.1' 2>&1 > /dev/null; then
        printf 'El punto de montaje "%b%s%b" ya esta montado.\n' "$g_color_cian1" "/nas/music/5.1" "$g_color_reset"
    else
        printf 'Montando el punto de montaje "%b%s%b" (%bsudo mount /nas/music/5.1%b)...\n' "$g_color_cian1" "/nas/music/5.1" "$g_color_reset" \
               "$g_color_gray1" "$g_color_reset"
        sudo mount /nas/music/5.1
    fi

    #7. Iniciando el domonio mdp
    if systemctl is-active mpd.service 2>&1 > /dev/null; then
        if [ "$l_device_value" = "$l_device_new_value" ]; then
            printf 'El demonio MDP "%bMusic Player Daemon%b" ya esta iniciado.\n' "$g_color_cian1" "$g_color_reset"
        else
            printf 'Reiniciando el demonio MDP "%bMusic Player Daemon%b" (%bsudo systemctl restart mpd.service%b)...\n' \
                   "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
            sudo systemctl restart mpd.service
        fi
    else
        printf 'Iniciando el demonio MDP "%bMusic Player Daemon%b" (%bsudo systemctl start mpd.service%b)...\n' \
               "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
        sudo systemctl start mpd.service
    fi

    return 0

}


m_stop_music() {

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


controller_music() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_music
                return 0
                ;;

            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_music
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes
    local l_subcmd="$1"

    if [ -z "$l_subcmd" ]; then
        printf '[%bERROR%b] El subcomando de "%b%s%b" no es especificado. Solo puede ser "%b%s%b" o "%b%s%b".\n\n' "$g_color_red1" "$g_color_reset" \
               "$g_color_gray1" "$g_cmd_name music" "$g_color_reset" "$g_color_gray1" "start" "$g_color_reset" "$g_color_gray1" "stop" "$g_color_reset"
        m_usage_music
        return 3
    fi

    if [ "$l_subcmd" != "start" ] && [ "$l_subcmd" != "stop" ]; then
        printf '[%bERROR%b] El subcomando de "%b%s%b" es invalido "%b%s%b". Solo puede ser "%b%s%b" o "%b%s%b".\n\n' "$g_color_red1" "$g_color_reset" \
               "$g_color_gray1" "$g_cmd_name music" "$g_color_reset" "$g_color_gray1" "$l_subcmd" "$g_color_reset" \
               "$g_color_gray1" "start" "$g_color_reset" "$g_color_gray1" "stop" "$g_color_reset"
        m_usage_music
        return 3
    fi

    shift

    #5. Ejecutando el comando
    if [ "$l_subcmd" = "start" ]; then
        m_start_music "$@"
    elif [ "$l_subcmd" = "stop" ]; then
        m_stop_music "$@"
    fi
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
    if ! command -v mpd >/dev/null 2>&1; then
        printf '[%bERROR%b] Se debe tener el comando "%b%s%b" instalado.\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" "mpd" "$g_color_reset"
        return 1
    fi


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


    #5. Ejecutando el controlador principal del subcomando

    "controller_${l_scmd_id}" "$@"
    return 0

}



# Ejecutar la funcion principal
main "$@"
_g_result=$?
exit $_g_result
