#!/bin/bash

################################################################################################
# Sincronizar la data de mis notas en obsidian ubicado en mi Google Drive 'lucianoepc@gmail.com'
################################################################################################

#Constantes: Colores
g_color_reset="\x1b[0m"
g_color_green1="\x1b[32m"
g_color_gray1="\x1b[90m"
g_color_cian1="\x1b[36m"
g_color_yellow1="\x1b[33m"
g_color_red1="\x1b[31m"
g_color_blue1="\x1b[34m"


_g_sync_vault () {

    #Sincronización bidireccional
    #_g_sync_vault "${l_remote_name}" "$l_local_path" 0 $l_path_position $l_flag_dry_run "$l_conflict_winner" "$l_losser_action" $l_flag_force
    #Homologación
    #_g_sync_vault "${l_remote_name}" "$l_local_path" 1 $l_path_position $l_flag_dry_run "$l_homologation_mode"
    #Sincronización unidireccional
    #_g_sync_vault "${l_remote_name}" "$l_local_path" 2 $l_path_position $l_flag_dry_run

    #1. Argumentos
    local p_remote_name="$1"
    local p_local_path="$2"
    local p_operation_type=$3
    local p_path_position=$4
    local p_flag_dry_run=$5

    local p_homologation_mode
    local p_conflict_winner
    local p_losser_action
    local p_flag_force

    if [ $p_operation_type -eq 0 ]; then
        p_conflict_winner="$6"
        p_losser_action="$7"
        p_force_sync=$8
    elif [ $p_operation_type -eq 1 ]; then
        p_homologation_mode="$6"
    elif [ $p_operation_type -ne 2 ]; then
        return 1
    fi

    #2. Validar si esta instalado 'rclone'
    local l_version
    local l_aux
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

    #3. Validar si se encuentra el comando 'jq'
    if ! jq --version &> /dev/null; then
        printf 'El binario %bjq%b no esta instalado o configurado.\n' "$g_color_gray1" "$g_color_reset"
        return 6
    fi

    #4. Validar si existe el vault ¿y esta configurado correctamente?
    l_aux=$(rclone config dump | jq -r ".${p_remote_name}.type")
    l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_aux" ] || [ "$l_aux" = "null" ]; then
        printf 'No se encuentra la configuracion "%b%s%b que se desea configurar.\n' "$g_color_gray1" "$p_remote_name" "$g_color_reset"
        return 7
    fi

    local l_remote_type="$l_aux"
    local l_remote_desc=''
    printf -v l_remote_desc 'Remote type "%b%s%b", Remote name "%b%s%b"' "$g_color_gray1" "$l_remote_type" "$g_color_reset" \
           "$g_color_gray1" "${p_remote_name}" "$g_color_reset"

    if [ $p_path_position -ne 0 ]; then
        printf 'Path1 is %blocal%b : "%b%s%b".\n' "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$p_local_path" "$g_color_reset"
        printf 'Path2 is %bremote%b: %b.\n' "$g_color_gray1" "$g_color_reset" "$l_remote_desc"
    else
        printf 'Path1 is %bremote%b: %b.\n' "$g_color_gray1" "$g_color_reset" "$l_remote_desc"
        printf 'Path2 is %blocal%b : "%b%s%b".\n' "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$p_local_path" "$g_color_reset"
    fi

    #5. Obtener los opciones a usar en rclone
    local l_options="-MvP --drive-skip-gdocs --modify-window 2s"
    if [ $p_flag_dry_run -eq 0 ]; then
        l_options="${l_options} --dry-run"
    fi

    l_aux=''
    if [ $p_operation_type -eq 0 ]; then

        #Sincronización bidireccional
        l_aux="sincronización bidireccional"
        l_options="${l_options} --compare size,modtime,checksum"
        if [ ! -z "$p_flag_force" ] && [ $p_flag_force -eq 0 ]; then
            l_options="${l_options} --force"
        fi

        if [ ! -z "$p_conflict_winner" ]; then
            l_options="${l_options} --conflict-resolve ${p_conflict_winner}"
        fi

        if [ ! -z "$p_losser_action" ]; then
            l_options="${l_options} --conflict-loser ${p_losser_action}"
        fi

    elif [ $p_operation_type -eq 1 ]; then

        #Homologación
        l_aux="homologación"
        l_options="${l_options} --compare size,modtime,checksum --resync"
        if [ ! -z "$p_homologation_mode" ]; then
            l_options="${l_options} --resync-mode ${p_homologation_mode}"
        fi

    elif [ $p_operation_type -ne 2 ]; then

        #Sincronización unidireccional
        l_aux="sincronización undireccional"
    fi

    #6.Obteniendo los parametros de rclone
    local l_parameters

    if [ $p_operation_type -eq 0 ]; then

        #Sincronización bidireccional
        if [ $p_path_position -ne 0 ]; then
            l_parameters="bisync ${p_local_path} ${p_remote_name}:/"
        else
            l_parameters="bisync ${p_remote_name}:/ ${p_local_path}"
        fi

    elif [ $p_operation_type -eq 1 ]; then

        #Homologación
        if [ $p_path_position -ne 0 ]; then
            l_parameters="bisync ${p_local_path} ${p_remote_name}:/"
        else
            l_parameters="bisync ${p_remote_name}:/ ${p_local_path}"
        fi

    elif [ $p_operation_type -eq 2 ]; then

        #Sincronización unidireccional
        if [ $p_path_position -ne 0 ]; then
            l_parameters="sync ${p_local_path} ${p_remote_name}:/"
        else
            l_parameters="sync ${p_remote_name}:/ ${p_local_path}"
        fi
    fi

    #7. Iniciar la sincronización
    printf 'Iniciando la %b%s%b entre path1 ' "$g_color_cian1" "$l_aux" "$g_color_reset"
    if [ $p_path_position -ne 0 ]; then
        if [ $p_operation_type -eq 2 ]; then
            printf '("%b%s%b") -> path2 (%b) donde solo se modifica el path2.\n' "$g_color_gray1" "$p_local_path" "$g_color_reset" "$l_remote_desc"
        else
            printf '("%b%s%b") Y path2 (%b)\n' "$g_color_gray1" "$p_local_path" "$g_color_reset" "$l_remote_desc"
        fi
    else
        if [ $p_operation_type -eq 2 ]; then
            printf '(%b) -> path2 ("%b%s%b") donde solo se modifica el path2.\n' "$l_remote_desc" "$g_color_gray1" "$p_local_path" "$g_color_reset"
        else
            printf '(%b) y path2 ("%b%s%b")\n' "$l_remote_desc" "$g_color_gray1" "$p_local_path" "$g_color_reset"
        fi
    fi

   printf 'Ejecutando "%brclone %s %s%b" ...\n' "$g_color_gray1" "$l_parameters" "$l_options" "$g_color_reset"
   rclone $l_parameters $l_options

}


declare -A gA_local_path=(
        ['note_it']="$HOME/notes/it_disiplines"
        ['note_sciences']="$HOME/notes/sciences_and_disiplines"
        ['note_management']="$HOME/notes/management_disiplines"
        ['note_personal']="$HOME/notes/personal"
        ['secret_personal']="$HOME/secrets/personal"
    )

_g_usage_sync_vault() {

    printf 'Usage:\n'
    printf '    %bsync_vault%b -h\n%b' "$g_color_yellow1" "$g_color_gray1" "$g_color_reset"
    printf '  > Sincronización unidireccional:\n'
    printf '    %bsync_vault%b [-t] [-p PATH_POSITION]%b VAULT_SUFIX 2\n%b' "$g_color_yellow1" "$g_color_gray1" "$g_color_yellow1" "$g_color_reset"
    printf '  > Homologación (previo a las sincronización bidireccional):\n'
    printf '    %bsync_vault%b [-t] [-p PATH_POSITION] [-m HOMOLOGATION_MODE]%b VAULT_SUFIX 1\n%b' "$g_color_yellow1" "$g_color_gray1" "$g_color_yellow1" "$g_color_reset"
    printf '  > Sincronización bidireccional:\n'
    printf '    %bsync_vault%b [-tf] [-p PATH_POSITION] [-w CONFLICT_WINNER] [-l LOSSER_ACTION]%b VAULT_SUFIX 0\n\n%b' "$g_color_yellow1" \
           "$g_color_gray1" "$g_color_yellow1" "$g_color_reset"
    printf 'Las opciones usados son:\n'
    printf '  > %b-h%b muestra la ayuda del comando.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %b-p PATH_POSITION%b indica el tipo de operacion. El valor de PATH_POSITION puede ser:%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    - %b%s%b Se realiza la %b%s%b desde path1 [%b%s%b] %b->%b path2 [%b%s%b] %s%b\n' "$g_color_cian1" "0" "$g_color_gray1" \
           "$g_color_cian1" "sincronización" "$g_color_gray1" "$g_color_cian1" "remote_path" "$g_color_gray1" \
           "$g_color_cian1" "$g_color_gray1" "$g_color_cian1" "local_path " "$g_color_gray1" "(valor por defecto)" "$g_color_reset"
    printf '    - %b%s%b Se realiza la %b%s%b desde path1 [%b%s%b] %b->%b path2 [%b%s%b] %s%b\n' "$g_color_cian1" "1" "$g_color_gray1" \
           "$g_color_cian1" "sincronización" "$g_color_gray1" "$g_color_cian1" "local_path " "$g_color_gray1" \
           "$g_color_cian1" "$g_color_gray1" "$g_color_cian1" "remote_path" "$g_color_gray1" "" "$g_color_reset"
    printf '  > %b-t%b Si se usa esta opcion se ejecuta en modo test (rclone es ejectado usando la opción "%b--dry-run%b").%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '  > %b-f%b Fuerzan que se realizen los cambios cuando los cambios son mas de 50% de archivos actuales.\n' \
           "$g_color_green1" "$g_color_gray1"
    printf '   Solo es considerado cuando se usa el subcomando bisync usando la opción "%b--force%b".%b\n' \
           "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '  > %b-m HOMOLOGATION_MODE%b Determina el archivo winner durante la homologación cuando este existe tanto en path1 y path2.\n' \
           "$g_color_green1" "$g_color_gray1"
    printf '    Solo es considerado cuando se usa "%brclone bisync --resync%b". Sus valores son:%b\n' \
           "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '    - %bpath1%b   El winner es el archivo de path1. (valor por defecto)%b\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '    - %bpath2%b   El winner es el archivo de path2.%b\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '    - %bnewer%b   El winner es el archivo mas recientemente modificado.%b\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '    - %bolder%b   El winner es el archivo mas antigua modificación.%b\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '    - %blarger%b  El winner es el archivo mas pesado.%b\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '    - %bsmaller%b El winner es el archivo mas liviano.%b\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '  > %b-w CONFLICT_WINNER%b Determina el winner cuando existe un conlficto durate la sincronizacion bidireccional (opcion %b--conflict-resolve%b).\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_cian1" "$g_color_gray1"
    printf '    El conflicto se da cuando tanto en path1 y path2 el archivo es nuevo/modificado y tienen diferente contenido. El winner del conflicto siempre\n'
    printf '    se preserva con su nombre, el looser puede ser renombrado o eliminado segun la opcion %b-l%b. Sus valors son:%b\n' \
           "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '    - %bnone%b    No se determina un winner. Ambos archivos se preservan con nombres cambiados. (valor por defecto)%b\n' "$g_color_cian1" \
           "$g_color_gray1" "$g_color_reset"
    printf '    - %bnewer%b   El winner es el archivo mas recientemente modificado.%b\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '    - %bolder%b   El winner es el archivo mas antigua modificación.%b\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '    - %blarger%b  El winner es el archivo mas pesado.%b\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '    - %bsmaller%b El winner es el archivo mas liviano.%b\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '    - %bpath1%b   El winner es el archivo de path1.%b\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '    - %bpath2%b   El winner es el archivo de path2.%b\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '  > %b-l LOSSER_ACTION%b Determina que se hara con el archivo looser cuando se da un conflicto (opcion %b--conflict-loser%b).\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_cian1" "$g_color_gray1"
    printf '    Si se usa la opcion "%b-w none%b" (no hay looser ni winner), esta accion aplica para ambos archivos. Sus valores son:%b\n' \
           "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '    - %bnum%b      Adiciona el sufijo ".conflict<n>" donde "<n>" es un correlativo. (valor por defecto)%b\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '    - %bpathname%b Adiciona el sufijo ".path1" o ".path2" segun sea el caso.%b\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '    - %bdelete%b   Elimina el looser, dejando solo el winner.%b\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf 'Los argumentos usados son:\n'
    print '  > %bVAULT_SUFIX%b Sufijo de vault a sincronizar/homologar.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bOPERATION_TYPE%b El tipo de operacion que se realiza entre path1 y path2. Sus valores puede ser:%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    - %b0%b Realiza la sincronización bidireccional. (valor por defecto)%b\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '    - %b1%b Realiza la homologación, el cual es requisito previo de una sincronizacion bidireccional.%b\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf '    - %b2%b Realiza la sincronizacion unidireccional path1 -> path2 (solo modifica path2)%b\n\n' "$g_color_cian1" "$g_color_gray1" "$g_color_reset"

}


m_sync_vault () {

    #1. Opciones
    local l_flag_dry_run
    local l_path_position
    local l_flag_force
    local l_homologation_mode
    local l_conflict_winner
    local l_losser_action


    #2. Leer las opciones
    #echo "OPTIND1: $OPTIND"
    local l_option
    local l_aux
    unset OPTIND

    while getopts ":hfl:m:tp:w:" l_option; do

        case "$l_option" in
            h)
                _g_usage_sync_vault
                return 0
                ;;

            t)
                l_flag_dry_run=0
                ;;

            f)
                l_flag_force=0
                ;;


            p)
                l_aux="${OPTARG}"
                #echo "l_path_position: ${l_aux}"
                if [ "$l_aux" != "0" ] && [ "$l_aux" != "1" ]; then
                    printf "Option '-p' has invalid value '%s'.\n\n" "$l_aux"
                    _g_usage_sync_vault
                    return 9
                fi
                l_path_position=$l_aux
                ;;

            m)
                l_aux="${OPTARG}"
                #echo "l_homologation_mode: ${l_aux}"
                case "$l_aux" in

                    "path1" | "path2" | "newer" | "older" | "larger" | "smaller")
                        l_homologation_mode="$l_aux"
                        ;;

                    *)
                        printf "Option '-m' has invalid value '%s'.\n\n" "$l_aux"
                        _g_usage_sync_vault
                        return 9
                        ;;
                esac
                ;;

            w)
                l_aux="${OPTARG}"
                #echo "l_conflict_winner: ${l_aux}"
                case "$l_aux" in

                    "none" | "newer" | "older" | "larger" | "smaller" | "path1" | "path2")
                        l_conflict_winner="$l_aux"
                        ;;

                    *)
                        printf "Option '-w' has invalid value '%s'.\n\n" "$l_aux"
                        _g_usage_sync_vault
                        return 9
                        ;;
                esac
                ;;

            l)
                l_aux="${OPTARG}"
                #echo "l_losser_action: ${l_aux}"
                case "$l_aux" in

                    "num" | "pathname" | "delete")
                        l_losser_action="$l_aux"
                        ;;

                    *)
                        printf "Option '-l' has invalid value '%s'.\n\n" "$l_aux"
                        _g_usage_sync_vault
                        return 9
                        ;;
                esac
                ;;


            :)
                l_aux="${OPTARG}"
                printf "Option '-%s' must have an value.\n\n" "$l_aux"
                _g_usage_sync_vault
                return 9
                ;;


            \?)
                l_aux="${OPTARG}"
                printf "Option '-%s' is invalid.\n\n" "$l_aux"
                _g_usage_sync_vault
                return 9
                ;;

        esac

    done

    #3. Remover las opciones de arreglo de de argumentos y opciones '$@'
    #echo "OPTIND2: $OPTIND"
    shift $((OPTIND-1))

    #4. Leer los argumentos
    local l_remote_name=''
    if [ ! -z "$1" ]; then
        l_remote_name="$1"
    else
        printf 'El 1er argumento debe especificar el sufijo del vault obsidian a sincronizar.\nLos sufijos validos son: '
        printf '"%b%s%b", "%b%s%b", "%b%s%b", "%b%s%b" y "%b%s%b".\n\n' "$g_color_gray1" "note_it" "$g_color_reset" \
               "$g_color_gray1" "note_personal" "$g_color_reset" "$g_color_gray1" "note_sciences" "$g_color_reset" \
               "$g_color_gray1" "note_management" "$g_color_reset" "$g_color_gray1" "secret_personal" "$g_color_reset"

        _g_usage_sync_vault
        return 8
    fi

    local l_operation_type=''
    if [ -z "$2" ] || [ "$2" = "0" ]; then
        l_operation_type=0
    elif [ "$2" = "1" ]; then
        l_operation_type=1
    elif [ "$2" = "2" ]; then
        l_operation_type=2
    else
        printf 'El 2do argumentos debe especificar un tipo de operacion "%b%s%b" valida.\n\n' "$g_color_gray1" "$2" "$g_color_reset"
        _g_usage_sync_vault
        return 8
    fi


    #5. Validaciones de los parametros (argumentos y opciones)

    #Validacion de nombre del vault
    l_aux="${gA_local_path[$l_remote_name]}"
    if [ -z "$l_aux" ]; then
        printf 'El sufijo "%b%s%b" del vault obsidian especificado no tiene una ruta local asociada.\nLos sufijos validos son: ' \
               "$g_color_gray1" "$l_remote_name" "$g_color_reset"
        printf '"%b%s%b", "%b%s%b", "%b%s%b", "%b%s%b" y "%b%s%b".\n\n' "$g_color_gray1" "note_it" "$g_color_reset" \
               "$g_color_gray1" "note_personal" "$g_color_reset" "$g_color_gray1" "note_sciences" "$g_color_reset" \
               "$g_color_gray1" "note_management" "$g_color_reset" "$g_color_gray1" "secret_personal" "$g_color_reset"
        _g_usage_sync_vault
        return 8
    fi

    #Validacion del ruta local del vault
    local l_local_path="$l_aux"
    if [ ! -d "$l_local_path" ]; then
        printf 'El directorio "%b%s%b" asociada al sufijos "%b%s%b" no existe.\n' \
               "$g_color_gray1" "$l_local_path" "$g_color_reset" "$g_color_gray1" "$l_remote_name" "$g_color_reset"
        return 1
    fi

    #6. Establecer el valor por defecto de la opciones generales
    if [ -z "$l_flag_dry_run" ]; then
        l_flag_dry_run=1
    fi

    if [ -z "$l_path_position" ]; then
        l_path_position=0
    fi


    #7. Establecer los valores por defecto de las opciones que dependen del tipo de operacion:
    if [ $l_operation_type -eq 0 ]; then

        #Sincronización bidireccional
        if [ $l_flag_dry_run -eq 0 ]; then
            if [ ! -z "$l_flag_force" ]; then
                printf "Option '%b-f%b' is going to be ingnored in bidirectional synchronization with test mode.\n" "$g_color_gray1" "$g_color_reset"
                l_flag_force=''
            fi
        else
            if [ -z "$l_flag_force" ]; then
                l_flag_force=1
            fi
        fi

        if [ ! -z "$l_homologation_mode" ]; then
            printf "Option '%b-m %s%b' is going to be ingnored in unidirectional synchronization.\n" "$g_color_gray1" "$l_homologation_mode" "$g_color_reset"
            l_homologation_mode=''
        fi

        if [ -z "$l_conflict_winner" ]; then
            l_conflict_winner='none'
        fi

        if [ -z "$l_losser_action" ]; then
            l_losser_action='num'
        fi

        _g_sync_vault "${l_remote_name}" "$l_local_path" 0 $l_path_position $l_flag_dry_run "$l_conflict_winner" "$l_losser_action" $l_flag_force

    elif [ $l_operation_type -eq 1 ]; then

        #Homologación
        if [ ! -z "$l_flag_force" ]; then
            printf "Option '%b-f%b' is going to be ingnored in unidirectional synchronization.\n" "$g_color_gray1" "$g_color_reset"
            l_flag_force=''
        fi

        if [ -z "$l_homologation_mode" ]; then
            l_homologation_mode='path1'
        fi

        if [ ! -z "$l_conflict_winner" ]; then
            printf "Option '%b-w %s%b' is going to be ingnored in unidirectional synchronization.\n" "$g_color_gray1" "$l_conflict_winner" "$g_color_reset"
            l_conflict_winner=''
        fi

        if [ ! -z "$l_losser_action" ]; then
            printf "Option '%b-l %s%b' is going to be ingnored in unidirectional synchronization.\n" "$g_color_gray1" "$l_losser_action" "$g_color_reset"
            l_losser_action=''
        fi

        _g_sync_vault "${l_remote_name}" "$l_local_path" 1 $l_path_position $l_flag_dry_run "$l_homologation_mode"


    elif [ $l_operation_type -eq 2 ]; then

        #Sincronización unidireccional
        if [ ! -z "$l_flag_force" ]; then
            printf "Option '%b-f%b' is going to be ingnored in unidirectional synchronization.\n" "$g_color_gray1" "$g_color_reset"
            l_flag_force=''
        fi

        if [ ! -z "$l_homologation_mode" ]; then
            printf "Option '%b-m %s%b' is going to be ingnored in unidirectional synchronization.\n" "$g_color_gray1" "$l_homologation_mode" "$g_color_reset"
            l_homologation_mode=''
        fi

        if [ ! -z "$l_conflict_winner" ]; then
            printf "Option '%b-w %s%b' is going to be ingnored in unidirectional synchronization.\n" "$g_color_gray1" "$l_conflict_winner" "$g_color_reset"
            l_conflict_winner=''
        fi

        if [ ! -z "$l_losser_action" ]; then
            printf "Option '%b-l %s%b' is going to be ingnored in unidirectional synchronization.\n" "$g_color_gray1" "$l_losser_action" "$g_color_reset"
            l_losser_action=''
        fi

        _g_sync_vault "${l_remote_name}" "$l_local_path" 2 $l_path_position $l_flag_dry_run


    fi

}

m_sync_vault "$@"
exit $?
