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
# Inicializar/Finalizar la musica de la NAS 
################################################################################################

start_music() {

    #1. Argumentos
    local p_card_id='D50s'
    if [ ! -z "$1" ]; then
        p_card_id='$1'
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


################################################################################################
# Sincronizar la data de mis notas en obsidian ubicado en mi Google Drive 'lucianoepc@gmail.com'
################################################################################################

declare -A gA_localpath=(
        ['it']="$HOME/notes/it_disiplines"
        ['personal']="$HOME/notes/personal"
        ['sciences']="$HOME/notes/sciences_and_disiplines"
        ['management']="$HOME/notes/management_disiplines"
    )

_g_usage_bysync_vault() {

    printf 'Usage:\n'
    printf '    %b%sbisync_vault\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%sbisync_vault HOMOLOGATE PATH1_MUST_BE_LOCALPATH\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf 'Donde:\n'
    printf '  > %bHOMOLOGATE %bSi es 0, se inicia la homolagacion entre el path1 y el path2. Si no se especifica o es 1, no se homologa, se sincroniza%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bPATH1_MUST_BE_LOCALPATH%b Es 0, el path1 es la ruta local y path2 es la ruta remota (%blocalpath -> remotepath%b).\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_green1" "$g_color_gray1"
    printf '    Si no se especifica o es 1, path1 es ruta remota y path2 es la ruta ruta local (%bremotepath -> localpath%b).%b\n\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}


bisync_vault () {

    #1. Argumentos
    local p_vault_sufix=''
    if [ ! -z "$1" ]; then
        p_vault_sufix="$1"
    else
        printf 'Debe especificar el sufijo del vault obsidian a sincronizar.\nLos sufijos validos son: '
        printf '"%b%s%b", "%b%s%b", "%b%s%b" y "%b%s%b".\n' "$g_color_gray1" "it" "$g_color_reset" \
               "$g_color_gray1" "personal" "$g_color_reset" "$g_color_gray1" "sciences" "$g_color_reset" \
               "$g_color_gray1" "management" "$g_color_reset"
        _g_usage_bysync_vault
        return 1
    fi

    local p_homologate=1
    if [ "$2" = "0" ]; then
        p_homologate=0
    elif [ -z "$2" ] || [ "$2" = "1" ]; then
        p_homologate=1
    else
        _g_usage_bysync_vault
        return 1
    fi

    local p_path1_must_be_localpath=1
    if [ "$3" = "0" ]; then
        p_path1_must_be_localpath=0
    elif [ -z "$3" ] || [ "$3" = "1" ]; then
        p_path1_must_be_localpath=1
    else
        _g_usage_bysync_vault
        return 1
    fi

    #Validaciones de los parametros
    local l_aux
    l_aux="${gA_localpath[$p_vault_sufix]}"
    if [ -z "$l_aux" ]; then
        printf 'El sufijo "%b%s%b" del vault obsidian especificado no tiene una ruta local asociada.\nLos sufijos validos son: ' \
               "$g_color_gray1" "$p_vault_sufix" "$g_color_reset"
        printf '"%b%s%b", "%b%s%b", "%b%s%b" y "%b%s%b".\n' "$g_color_gray1" "it" "$g_color_reset" \
               "$g_color_gray1" "personal" "$g_color_reset" "$g_color_gray1" "sciences" "$g_color_reset" \
               "$g_color_gray1" "management" "$g_color_reset"
        _g_usage_bysync_vault
        return 2
    fi

    local l_localpath="$l_aux"
    if [ ! -d "$l_localpath" ]; then
        printf 'El directorio "%b%s%b" asociada al sufijos "%b%s%b" no existe.\n' \
               "$g_color_gray1" "$l_localpath" "$g_color_reset" "$g_color_gray1" "$p_vault_sufix" "$g_color_reset"
        return 3
    fi

    #2. Precondiciones

    #Validar si esta instalado 'rclone'
    local l_version=''
    l_aux=$(rclone --version 2> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_aux" ]; then
        printf 'El binario %brclone%b no esta instalado o configurado.\n' "$g_color_gray1" "$g_color_reset"
        return 4
    else
        l_version=$(echo "$l_aux" | head -n 1 | sed ${g_regexp_sust_version1})
    fi

    if [ -z "$l_version" ]; then
        printf 'No se puede determinar la version del %brclone%b instalado.\n' "$g_color_gray1" "$g_color_reset"
        return 5
    fi

    printf 'Comando %brclone%b : Version "%b%s%b".\n' "$g_color_gray1" "$g_color_reset" \
        "$g_color_gray1" "$l_version" "$g_color_reset"

    #Validar si se encuentra el comando 'jq'
    if ! jq --version &> /dev/null; then
        printf 'El binario %bjq%b no esta instalado o configurado.\n' "$g_color_gray1" "$g_color_reset"
        return 6
    fi

    #Validar si existe el vault ¿y esta configurado correctamente?
    l_aux=$(rclone config dump | jq -r ".gd_vault_${p_vault_sufix}.type")
    l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_aux" ] || [ "$l_aux" = "null" ]; then
        printf 'No se encuentra la configuracion "%bgd_vault_%s%b que se desea configurar.\n' "$g_color_gray1" "$g_color_reset"
        return 7
    fi

    if [ $p_path1_must_be_localpath -ne 0 ]; then
        printf 'Path1 (%bremote%b) : Provider type "%b%s%b".\n' "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$l_aux" "$g_color_reset"
        printf 'Path2 (%blocal%b ) : "%b%s%b".\n' "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$l_localpath" "$g_color_reset"
    else
        printf 'Path1 (%blocal%b ) : "%b%s%b".\n' "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$l_localpath" "$g_color_reset"
        printf 'Path2 (%bremote%b) : Provider type "%b%s%b".\n' "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$l_aux" "$g_color_reset"
    fi

    #Iniciar la sincronizacion
    local l_parameters="-MvP --compare size,modtime,checksum --drive-skip-gdocs --modify-window 2s"
    if [ $p_homologate -eq 0 ]; then
        l_parameters="${l_parameters} --resync"
    fi

    printf 'Iniciando la sincronizacion entre Path1 y Path2 ...\n'
    if [ $p_path1_must_be_localpath -ne 0 ]; then
        printf 'Ejecutando "%brclone bisync gd_vault_%s:/ %s %s%b" ...\n' "$g_color_gray1" \
               "$p_vault_sufix" "$l_localpath" "$l_parameters" "$g_color_reset"
        rclone bisync gd_vault_${p_vault_sufix}:/ $l_localpath $l_parameters
    else
        printf 'Ejecutando "%brclone bisync %s gd_vault_%s:/ %s%b" ...\n' "$g_color_gray1" \
              "$l_localpath" "$p_vault_sufix" "$l_parameters" "$g_color_reset"
        rclone bisync $l_localpath gd_vault_${p_vault_sufix}:/ $l_parameters
    fi

}






