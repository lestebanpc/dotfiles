#!/bin/bash

#Codigo respuesta con exito:
#    0  - OK (si se ejecuta directamente y o en caso de no hacerlo, no requiere alamcenar las credenciales de SUDO).
#  119  - OK (en caso que NO se ejecute directamente o interactivamente y se requiera credenciales de SUDO).
#         Las credenciales de SUDO se almaceno en este script (localmente). avisar para que lo cierre el caller
#Codigo respuesta con error:
#  110  - Argumentos invalidos.
#  111  - No se cumple los requisitos para ejecutar la logica principal del script.
#  120  - Se require permisos de root y se nego almacenar las credenciales de SUDO.
#  otro - Error en el procesamiento de la logica del script



#------------------------------------------------------------------------------------------------------------------
#> Logica de inicialización {{{
#------------------------------------------------------------------------------------------------------------------
# Incluye variables globales constantes y variables globales que requieren ser calculados al iniciar el script.
#

#Variable cuyo valor estab CALCULADO por '_get_shell_path_script':
#Representa la ruta base donde estan todos los script, incluyendo los script instalación:
#  > 'g_shell_path' tiene la estructura de subfolderes:
#     ./bash/
#         ./bin/
#             ./linuxsetup/
#                 ./00_setup_summary.bash
#                 ./01_setup_binaries.bash
#                 ./04_install_profile.bash
#                 ./05_update_profile.bash
#                 ./06_setup_python_pkgs.bash
#                 ........................
#                 ........................
#                 ........................
#         ./lib/
#             ./mod_common.bash
#             ........................
#             ........................
#     ./sh/
#         ........................
#         ........................
#     ........................
#     ........................
#  > 'g_shell_path' usualmente es '$HOME/.file/shell'.
g_shell_path=''


#Permite obtener  'g_shell_path' es cual es la ruta donde estan solo script, incluyendo los script instalacion.
#Parametros de entrada: Ninguno
#Parametros de salida> Variables globales: 'g_shell_path'
#Parametros de salida> Valor de retorno
#  0> Script valido (el script esta en la estructura de folderes de 'g_shell_path')
#  1> Script invalido
function _get_current_script_info() {

    #Obteniendo la ruta base de todos los script bash
    local l_aux=''
    local l_script_path="${BASH_SOURCE[0]}"
    l_script_path=$(realpath "$l_script_path" 2> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ]; then

        printf 'Error al obtener la ruta absoluta del script "%s" actual.\n' "$l_script_path"
        return 1

    fi

    if [[ "$l_script_path" == */bash/bin/linuxsetup/* ]]; then
        g_shell_path="${l_script_path%/bash/bin/linuxsetup/*}"
    else
        printf 'El script "%s" actual debe de estar en el folder padre ".../bash/bin/linuxsetup/".\n' "$l_script_path"
        return 1
    fi


    return 0

}

_get_current_script_info
_g_status=$?
if [ $_g_status -ne 0 ]; then
    exit 111
fi



#Funciones generales, determinar el tipo del SO y si es root
. ${g_shell_path}/bash/lib/mod_common.bash

#Obtener informacion basica del SO
if [ -z "$g_os_type" ]; then

    #Determinar el tipo de SO compatible con interprete shell POSIX.
    #  00 > Si es Linux no-WSL
    #  01 > Si es Linux WSL2 (Kernel de Linux nativo sobre Windows)
    #  02 > Si es Unix
    #  03 > Si es MacOS
    #  04 > Compatible en Linux en Windows: CYGWIN
    #  05 > Compatible en Linux en Windows: MINGW
    #  06 > Emulador Bash Termux para Linux Android
    #  09 > No identificado
    get_os_type
    declare -r g_os_type=$?

    #Obtener información de la distribución Linux
    # > 'g_os_subtype_id'             : Tipo de distribucion Linux
    #    > 0000000 : Distribución de Linux desconocidos
    #    > 0000001 : Alpine Linux
    #    > 10 - 29 : Familia Fedora
    #           10 : Fedora
    #           11 : CoreOS Stream
    #           12 : Red Hat Enterprise Linux
    #           19 : Amazon Linux
    #    > 30 - 49 : Familia Debian
    #           30 : Debian
    #           31 : Ubuntu
    # > 'g_os_subtype_name'           : Nombre de distribucion Linux
    # > 'g_os_subtype_version'        : Version extendida de la distribucion Linux
    # > 'g_os_subtype_version_pretty' : Version corta de la distribucion Linux
    # > 'g_os_architecture_type'      : Tipo de la arquitectura del procesador
    if [ $g_os_type -le 1 ]; then
        get_linux_type_info
    fi

fi

#Obtener informacion basica del usuario
if [ -z "$g_runner_id" ]; then

    #Determinar si es root y el soporte de sudo
    # > 'g_runner_id'                     : ID del usuario actual (UID).
    # > 'g_runner_user'                   : Nombre del usuario actual.
    # > 'g_runner_sudo_support'           : Si el so y el usuario soportan el comando 'sudo'
    #    > 0 : se soporta el comando sudo con password
    #    > 1 : se soporta el comando sudo sin password
    #    > 2 : El SO no implementa el comando sudo
    #    > 3 : El usuario no tiene permisos para ejecutar sudo
    #    > 4 : El usuario es root (no requiere sudo)
    get_runner_options
    _g_status=$?
    if [ $_g_status -ne 0 ]; then
        printf 'No se pueden obtener la información del usuario actual de ejecución del script: Name="%s", UID="%s".\n' "$g_runner_user" "$g_runner_id"
        exit 111
    fi

fi

if [ $g_runner_id -lt 0 ] || [ -z "$g_runner_user" ]; then
    printf 'No se pueden obtener la información del usuario actual de ejecución del script: Name="%s", UID="%s".\n' "$g_runner_user" "$g_runner_id"
    exit 111
fi


#Funciones de utilidad generalees para los instaladores:
. ${g_shell_path}/bash/bin/linuxsetup/lib/common_utility.bash



#Funciones modificables para el instalador.
. ${g_shell_path}/bash/bin/linuxsetup/lib/setup_python_pkgs_custom.bash


#}}}



#------------------------------------------------------------------------------------------------------------------
#> Funciones usadas durante la instalacion del paquete {{{
#------------------------------------------------------------------------------------------------------------------
#
# Incluye las variable globales usadas como parametro de entrada y salida de la funcion que no sea resuda por otras
# funciones, cuyo nombre inicia con '_g_'.
#



#Un diccionario que muestra el estado actual de los paquetes hasta el momento procesados (instalados o desinstalados) en un menú.
#Un arreglo de asociativo cuyo key es el ID del paquete hasta el momento procesados en el menu.
#El valor almacenado para un paquete es 'X|Y', donde:
# > 'X' es el estado de la primera configuración y sus valores son:
#     > -1 > El paquete aun no se ha se ha analizado (ni iniciado su proceso).
#     >  n > Si es durante la instalación los valores puede ser:
#             0 > Se inicio la instalación y termino existosamente
#             1 > Se inicio la instalación y termino con errores
#             2 > No se inicio la instalación: El paquete ya esta instalado
#             3 > No se inicio la instalación: Parametros invalidos (impiden que se inicie su analisis/procesamiento).
#     >  m > Si es durante la instalación los valores puede ser:
#             0 > Se inicio la desinstalación y termino existosamente
#             1 > Se inicio la desinstalación y termino con errores
#             2 > No se inicio la desinstalación: El paquete no esta instalado
#             3 > No se inicio la desinstalación: Parametros invalidos (impiden que se inicie su analisis/procesamiento).
# > 'Y' es un listado de indice relativo (de las opcion de menú) separados por espacios ' ' donde (hasta el momento) se usa el paquete.
#     El primer indice es de la primera opción del menu que instala los artefactos. Los demas opciones no vuelven a instalar el artefacto
declare -A _gA_processed_repo=()


#Parametros de entrada (argumentos de entrada son):
#  1 > Opciones de menu ingresada por el usuario
#  2 > Indice relativo de la opcion en el menú de opciones (inicia con 0 y solo considera el indice del menu dinamico).
#
#Parametros de salida (El valor de retorno). Sus valores pueder ser
#    0 > La opcion de menu se configuro con exito (se inicializo, se configuro los paquetes y se finalizo existosamente).
#    1 > No se inicio con la configuración de la opcion del menu (no se instalo, ni se se inicializo/finalizo).
#    2 > La inicialización de la opción no termino con exito.
#    3 > Alguno de lo paquetes fallo en configurarse (instalación/configuración). Ello provoca que se detiene el proceso (y no se invoca a la finalización).
#    4 > La finalización de la opción no termino con exito.
#   98 > El paquetes vinculados a la opcion del menu no han sido configurados correctamente.
#   99 > Argumentos ingresados son invalidos
#
#Parametros de salida (variables globales):
#    > '_gA_processed_repo' retona el estado de procesamiento de todos los paquetes hasta el momento procesados por el usuario.
#
function _install_menu_options() {

    #1. Argumentos
    local p_input_options=-1
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_input_options=$1
    fi

    local p_option_relative_idx=-1
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        p_option_relative_idx=$2
    fi


    if [ $p_input_options -le 0 ] || [ $p_option_relative_idx -lt 0 ]; then
        return 99
    fi


    #1. Obtener los paquetes a configurar
    local l_aux="${ga_menu_options_packages[$p_option_relative_idx]}"
    #echo "Input: ${p_input_options} , Repos[${p_option_relative_idx}]: ${l_aux}"

    if [ -z "$l_aux" ] || [ "$l_aux" = "-" ]; then
        return 98
    fi

    local IFS=','
    local la_repos=(${l_aux})
    IFS=$' \t\n'

    local l_n=${#la_repos[@]}
    if [ $l_n -le 0 ]; then
        return 98
    fi

    #2. ¿La opción actual ha sido elejido para configurarse?

    #Estado de menu de opciones
    local l_result       #  > No se escogio la opcion de menu para instalar/configurarlo
                         #0 > Se configuro con exito (se inicializo, se configuro/instalo todos los paquetes y se finalizo exitosamente).
                         #1 > No se inicio su inicialización (tampoco se configuro/instalo, ni se finalizo).
                         #2 > La inicialización de la opción termino con errores.
                         #3 > Alguno de los paquetes fallo en configurarse/instalarse, se detiene el proceso (no se invoca a la finalización).
                         #4 > La finalización de la opción no termino con exito.

    local l_option_value=$((1 << (p_option_relative_idx + g_offset_option_index_menu_install)))

    if [ $((p_input_options & l_option_value)) -ne $l_option_value ]; then
        l_result=1
    fi
    #echo "l_result: ${l_result}"

    #3. Inicializar la opción del menu
    local l_status
    local l_title_template

    #Si se escogio la opcion para instalarlo, mostrar el titulo de la opcion de menu e inicializarlo
    if [ -z "$l_result" ]; then

        #3.1. Mostrar el titulo del grupo de paquetes solo si si existe mas de 1 paquete
        if [ $l_n -gt 1 ]; then
            printf '\n'
            print_line '─' $g_max_length_line  "$g_color_gray1"
            if [ $gp_type_calling -eq 0 ]; then
                printf -v l_title_template 'Package Group (%b%s%b) > %b%s%b' "$g_color_gray1" "$l_option_value" "$g_color_reset" "$g_color_cian1" "${ga_menu_options_title[${p_option_relative_idx}]}" "$g_color_reset"
            else
                printf -v l_title_template 'Package Group > %b%s%b' "$g_color_cian1" "${ga_menu_options_title[${p_option_relative_idx}]}" "$g_color_reset"
            fi
            printf "${l_title_template}\n"
            print_line '─' $g_max_length_line "$g_color_gray1"
        fi


        #3.2. Inicializar la opcion si aun no ha sido inicializado.
        install_initialize_menu_option $p_option_relative_idx
        l_status=$?

        #3.3. Si se inicializo no se realizo con exito.
        if [ $l_status -ne 0 ]; then
            printf 'No se ha completo la inicialización de la opción del menu elegida...\n'
            l_result=2
        fi


    fi


    #4. Recorriendo los los paquetes, opcionalmente procesarlo, y almacenando el estado en la variable '_gA_processed_repo'
    local l_status
    local l_repo_id
    local l_j
    local l_k

    local la_aux
                      #   0 > Se inicio la instalación y termino existosamente
                      #   1 > Se inicio la Instalación y termino con errores
                      #   2 > No se inicio la instalación: El paquete ya esta instalado
    local la_previous_options_idx
    local l_status_first_setup
    local l_repo_name_aux
    local l_processed_repo
    local l_exits_error=1

    local l_flag_process_next_repo=1      #(0) Se debe intentar procesar (intalar/actualizar o desinstalar) los paquetes de la opción del menu.
                                          #(1) No se debe intentar procesar los paquetes de la opción del menú.
    if [ -z "$l_result" ]; then
        l_flag_process_next_repo=0
    fi

    for((l_j=0; l_j < ${l_n}; l_j++)); do

        #Nombre a mostrar del paquete
        l_repo_id="${la_repos[$l_j]}"
        l_repo_name_aux="${gA_packages[${l_repo_id}]:-${l_repo_id}}"
        if [ "$l_repo_name_aux" = "$g_empty_str" ]; then
            l_repo_name_aux="$l_repo_id"
        fi


        #4.1. Obtener el estado del paquete antes de su instalación.
        l_aux="${_gA_processed_repo[$l_repo_id]:--1|}"

        IFS='|'
        la_aux=(${l_aux})
        IFS=$' \t\n'

        l_status_first_setup=${la_aux[0]}    #'g_install_repository' solo se puede mostrar el titulo del paquete cuando ninguno de los estados es [4, infinito>.
                                             # -1 > El paquete no se ha iniciado su analisis ni su proceso.
                                             #  0 > Se inicio la instalación y termino existosamente
                                             #  1 > Se inicio la instalación y termino con errores
                                             #  2 > No se inicio la instalación: El paquete ya esta instalado
                                             #  3 > No se inicio la instalación: Parametros invalidos (impiden que se inicie su analisis/procesamiento).


        la_previous_options_idx=(${la_aux[1]})
        l_title_template=""
        #echo "Index '${p_option_relative_idx}/${l_j}', RepoID '${l_repo_id}', ProcessThisRepo '${l_flag_process_next_repo}', FisrtSetupStatus '${l_status_first_setup}', PreviousOptions '${la_previous_options_idx[@]}'"

        #4.2. Si el paquete ya ha pasado por el analisis para determinar si debe ser procesado o no
        if [ $l_status_first_setup -ne -1 ]; then

            #4.2.1. Almacenar la información del procesamiento.
            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="${l_status_first_setup}|${la_previous_options_idx[@]}"
            #echo "A > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""

            #4.2.2. Si ya no se debe procesar mas paquetes de la opción del menú.
            if [ $l_flag_process_next_repo -ne 0 ]; then
                continue
            fi

            #4.2.3. No mostrar titulo, ni información alguna en los casos [3, infinito>
            if [ $l_status_first_setup -ge 4 ]; then
                continue
            fi

            #4.2.4. Calcular la plantilla del titulo.

            if [ $l_n -eq 1 ]; then
                printf -v l_title_template "Package > '%s%s%s' %s%%s%s" "$g_color_cian1" "$l_repo_name_aux" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
            #Si se ejecuta usando el menú
            elif [ $gp_type_calling -eq 0 ]; then
                printf -v l_title_template "%sGroup (%s) >%s Package %s(%s/%s)%s > '%s%s%s' %s%%s%s" "$g_color_gray1" "$l_option_value" "$g_color_reset" "$g_color_gray1" \
                      "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_cian1" "$l_repo_name_aux" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
            #Si se ejecuta sin usar el menu
            else
                printf -v l_title_template "%sGroup >%s Package %s(%s/%s)%s > '%s%s%s' %s%%s%s" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$((l_j + 1))" \
                      "$l_n" "$g_color_reset" "$g_color_cian1" "$l_repo_name_aux" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
            fi

            #El primer package donde se ha analizado si se puede o no ser procesado.
            l_k=${la_previous_options_idx[0]}
            l_aux=$((1 << (l_k + g_offset_option_index_menu_install)))

            #4.2.5. Mostrar el titulo y mensaje en los casos donde hubo error antes de procesarse y/o durante el procesamiento

            #Estados de un proceso no iniciado:
                      #   0 > Se inicio la instalación y termino existosamente
                      #   1 > Se inicio la Instalación y termino con errores
                      #   2 > No se inicio la instalación: El paquete ya esta instalado
            #  3 > Al package tiene parametros invalidos que impiden su analisis.
            if [ $l_status_first_setup -eq 3 ]; then

                print_line '-' $g_max_length_line "$g_color_gray1"
                printf "${l_title_template}\n" "no procesado"
                print_line '-' $g_max_length_line "$g_color_gray1"

                printf 'El package "%s" tiene parametros invalido que impiden su analisis. Se analizó al procesar la opción del menu %s ("%s")\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            #  2 > El package ya esta instalado.
            elif [ $l_status_first_setup -eq 2 ]; then

                print_line '-' $g_max_length_line "$g_color_gray1"
                printf "${l_title_template}\n" "no procesado"
                print_line '-' $g_max_length_line "$g_color_gray1"

                printf 'El package "%s" ya esta instalado. Se analizó al procesar la opción del menu %s ("%s")\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            #Estados de un proceso iniciado:
            #  0 > El paquete inicio la instalación y lo termino con exito.
            elif [ $l_status_first_setup -eq 0 ]; then
                printf '\n'
                print_line '-' $g_max_length_line "$g_color_gray1"
                printf "${l_title_template}\n" "se acaba de instalar"
                print_line '-' $g_max_length_line "$g_color_gray1"

                printf 'El package "%s" se acaba de instalar cuando se proceso la opción del menu %s ("%s")\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            #  1 > El paquete inicio la instalación y lo termino con error.
            elif [ $l_status_first_setup -eq 1 ]; then
                printf '\n'
                print_line '-' $g_max_length_line "$g_color_gray1"
                printf "${l_title_template}\n" "se acaba de instalar con error"
                print_line '-' $g_max_length_line "$g_color_gray1"

                printf 'El package "%s" se acaba de instalar con error cuando se proceso la opción del menu %s ("%s")\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            fi

            continue

        fi


        #4.3. Si es la primera vez que se configurar (el paquetes de la opción del menu), inicie la configuración

        #Si no se debe procesar mas paquetes de la opción del menú.
        if [ $l_flag_process_next_repo -ne 0 ]; then
            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="${l_status_first_setup}|${la_previous_options_idx[@]}"
            continue
        fi

        if [ -z "$l_title_template" ]; then

            if [ $l_n -eq 1 ]; then
                printf -v l_title_template "Package > '%s%s%s' %s%%s%s" "$g_color_cian1" "$l_repo_name_aux" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
            #Si se ejecuta usando el menú
            elif [ $gp_type_calling -eq 0 ]; then
                printf -v l_title_template "%sGroup (%s) >%s Package %s(%s/%s)%s > '%s%s%s' %s%%s%s" "$g_color_gray1" "$l_option_value" "$g_color_reset" \
                      "$g_color_gray1" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_cian1" "$l_repo_name_aux" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
            #Si se ejecuta sin usar el menú
            else
                printf -v l_title_template "%sGroup >%s Package %s(%s/%s)%s > '%s%s%s' %s%%s%s" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" \
                       "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_cian1" "$l_repo_name_aux" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
            fi
        fi

        g_install_package "$l_repo_id" "$l_title_template"
        l_status=$?   #Solo se puede mostrar el titulo del packege cuando no retorna [6, infinito].
                      #   0 > Se inicio la instalación y termino existosamente
                      #   1 > Se inicio la instalación y termino con errores
                      #   2 > No se inicio la instalación: El paquete ya esta instalado
                      #   3 > No se inicio la instalación: No se obtuvo el nombre real del paquete
                      #   4 > No se inicio la instalación: No se obtuvo información si el paquete esta instalado o no
                      #   5 > No se inicio la instalación: Se envio otros parametros invalidos
                      # 120 > No se inicio la instalación: No se permitio almacenar las credenciales para sudo

        #Se requiere almacenar las credenciales para realizar cambios con sudo.
        if [ $l_status -eq 120 ]; then
            return 120
        fi

        #4.4. Si no se inicio el el proceso de configuración por no contar informacion correcta:

        #     3> No se obtuvo el nombre real del paquete
        if [ $l_status -eq 3 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            l_flag_process_next_repo=1
            l_exits_error=0

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="0|${la_previous_options_idx[@]}"

            printf '%bNo se pudo iniciar el procesamiento del paquete "%s"%b debido no se establecio el nombre real de paquete a instalar.\n' \
                   "$g_color_red1" "$l_repo_id" "$g_color_reset"
            printf 'Corrija el error para continuar con configuración de los demas paquetes de la opción del menú.\n'

            #echo "C > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue
        fi

        #     4> No se obtuvo información si el paquete esta instalado o no.
        if [ $l_status -eq 4 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            l_flag_process_next_repo=1
            l_exits_error=0

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="0|${la_previous_options_idx[@]}"

            printf '%bNo se pudo iniciar el procesamiento del paquete "%s"%b debido no se pudo obtener informacion del paquete en el SO.\n' \
                          "$g_color_red1" "$l_repo_id" "$g_color_reset"
            printf 'Corrija el error para continuar con configuración de los demas packages de la opción del menú.\n'

            #echo "B > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue

        fi

        #     5> Se tiene parametros invalidos que impiden que se instale
        if [ $l_status -eq 5 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            l_flag_process_next_repo=1
            l_exits_error=0

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="0|${la_previous_options_idx[@]}"

            printf '%bNo se pudo iniciar el procesamiento del paquete "%s"%b debido parametros invalidos del paquete en el SO.\n' \
                          "$g_color_red1" "$l_repo_id" "$g_color_reset"
            printf 'Corrija el error para continuar con configuración de los demas packages de la opción del menú.\n'

            #echo "B > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue

        fi



        #4.5. Si se inicio el pocesamiento del package.
        l_aux="Linux '${g_os_subtype_name}'"
        l_processed_repo=$l_status


        #4.5.2. Almacenar la información del procesamiento
        la_previous_options_idx+=(${p_option_relative_idx})
        _gA_processed_repo["$l_repo_id"]="${l_processed_repo}|${la_previous_options_idx[@]}"
        #echo "F > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""

        #4.5.3. Mostrar información adicional

        #A. Estados de un proceso no iniciado:
        #   2 > El paqueta ya esta instalado
        if [ $l_processed_repo -eq 2 ]; then

            #No se considera un error, continue con el procesamiento de los siguientes paquetes.
            printf 'El paquete "%s" ya esta instalado. Se continua con el proceso de instalación.\n' "$l_repo_id"
            #continue

        #B. Estados de un proceso iniciado:
        #   1 > El paquete inicio la instalación y lo termino con exito.
        elif [ $l_processed_repo -eq 1 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            l_flag_process_next_repo=1
            l_exits_error=0

            printf '%bError al instalar el paquete%b "%s" en %s\n' "$g_color_red1" "$g_color_reset" "$l_repo_name_aux" "$l_aux"
            printf 'Corrija el error para continuar con configuración de los demas paquetes de la opción del menú.\n'

        #   0 > El paquete inicio la instalación y lo termino con error.
        elif [ $l_processed_repo -eq 0 ]; then

            #No se considera un error, continue con el procesamiento de los siguientes paquetes.
            printf '\n'

        fi


    done

    #Establecer el estado despues del procesamiento
    if [ -z "$l_result" ]; then

        #Si se inicio la configuración de algun paquete y se obtuvo error
        if [ $l_exits_error -eq 0 ]; then
            l_result=3
        fi

    fi

    #5. Iniciar la finalización (solo si se proceso correctamente todos los paquetes de la opción de menú)
    if [ -z "$l_result" ]; then


        #5.1. Inicializar la opcion si aun no ha sido inicializado.
        install_finalize_menu_option $p_option_relative_idx
        l_status=$?

        #5.2. Si se inicializo con exito.
        if [ $l_status -eq 0 ]; then
            l_result=0
        else
            printf 'No se completo la finalización de la opción del menu ...\n'
            l_result=4
        fi

    fi

    return $l_result

}



#}}}



#Funcionalidad principales interna {{{


#
#Parametros de entrada (argumentos de entrada son):
#  1 > ID del paquete.
#  2 > La plantilla del titulo (si tiene un '%s', sera remplazado por "se instalará", "se actualizará" o "se configurará")
#      Si se envia una cadena vacia o no se especifica, no se mostrara el titulo.
#      Se usa "se configurará" si no se puede determinar si se instala o configura pero es necesario que se continue.
#
#Parametros de salida (El valor de retorno). Sus valores pueder ser
#   0 > Se inicio la instalación y termino existosamente
#   1 > Se inicio la Instalación y termino con errores
#   2 > No se inicio la instalación: El paquete ya esta instalado
#   3 > No se inicio la instalación: No se obtuvo el nombre real del paquete
#   4 > No se inicio la instalación: No se obtuvo información si el paquete esta instalado o no
#   5 > No se inicio la instalación: Se envio otros parametros invalidos
# 120 > No se inicio la instalación: No se permitio almacenar las credenciales para sudo
#
function g_install_package() {

    #1. Argumentos
    local p_package_id="$1"
    local p_package_title_template="$2"

    #1. Inicializaciones

    #3. Mostrar el titulo
    if [ ! -z "$p_package_title_template" ]; then

        printf '\n'
        print_line '-' $g_max_length_line  "$g_color_gray1"
        printf "${p_package_title_template} %s\n" "se instalará"
        print_line '-' $g_max_length_line  "$g_color_gray1"

    fi

    #2. Obtener el nombre del paquete para el sistema operativo
    local l_package_name_default="${gA_packages[$p_package_id]}"
    if [ "$l_package_name_default" = "$g_empty_str" ]; then
        l_package_name_default=""
    fi

    local l_package_name
    local l_search_type
    l_package_name=$(get_package_name "$p_package_id" "$l_package_name_default" ${g_os_subtype_id})
    l_search_type=$?
    #echo "Package> ID: ${p_package_id} - NameGeneral: ${l_package_name_default} - Name: ${l_package_name} - SearchType: ${l_search_type}"

    if [ $l_search_type -eq 9 ]; then
        printf 'No se pudo obtener el nombre real del paquete "%s"\n' "$l_package_name_default"
        return 3
    fi


    #3. El paquete ¿esta instalado?

    #Si el paquete esta vinculado a un programa principal, determinar si el programa existe
    local l_status=1
    local l_program_name=$(get_main_binary_of_package "$p_package_id")
    #printf 'El programa del paquete: "%s"\n' "$l_program_name"

    if [ ! -z "$l_program_name" ]; then

        #Validar si el programa existe
        #${l_program_name} --version
        ${l_program_name} --version &> /dev/null
        l_status=$?

        #Si el paquete ya esta instalado
        if [ $l_status -eq 0 ]; then
            #printf 'El paquete "%s" ya esta instalado\n' "$l_package_name"
            return 2
        fi

    fi

    #Si el programa del paquete NO existe, determinar si el paquete existe
    is_package_installed "$l_package_name" $g_os_subtype_id $l_search_type
    l_status=$?
    #echo "Package ${l_package_name} installing - Status: ${l_status} - OS: ${g_os_subtype_id}"

    if [ $l_status -eq 9 ]; then
        printf 'No se pudo obtener información del  paquete "%s"\n' "$l_package_name"
        return 4

    #Si el paquete ya esta instalado
    elif [ $l_status -eq 0 ]; then
        #printf 'El paquete "%s" ya esta instalado\n' "$l_package_name"
        return 2
    fi

    #4. Instalar el paquete

    #Solicitar credenciales para sudo y almacenarlas temporalmente
    if [ $g_status_crendential_storage -eq 0 ]; then
        storage_sudo_credencial
        g_status_crendential_storage=$?
        #Se requiere almacenar las credenciales para realizar cambio con sudo.
        #  Si es 0 o 1: la instalación/configuración es completar
        #  Si es 2    : el usuario no acepto la instalación/configuración
        #  Si es 3 0 4: la instalacion/configuración es parcial (solo se instala/configura, lo que no requiere sudo)
        if [ $g_status_crendential_storage -eq 2 ]; then
            return 120
        fi
    fi

    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 3 ] || [ $gp_type_calling -eq 4 ]; then
        l_is_noninteractive=0
    fi
    install_os_package "$l_package_name" $g_os_subtype_id $l_is_noninteractive
    l_status=$?

    #Si se invoco interactivamente y se almaceno las credenciales, caducarlo.
    #Si no se invoca interactivamente y se almaceno las credencial en este script, será el script caller el que sea el encargado de caducarlo
    #if [ $g_status_crendential_storage -eq 0 ] && [ $g_is_credential_storage_externally -ne 0 ] && [ $gp_type_calling -eq 2 ]; then
    #    clean_sudo_credencial
    #fi

    #printf 'Codigo develto: %s\n' "$l_status"
    if [ $l_status -eq 9 ]; then
        return 5
    fi

    return $l_status

}

#
#Parametros de entrada (Argumentos):
#  1 > Opciones relacionados con los paquetes que se se instalaran (entero que es suma de opciones de tipo 2^n).
#
function g_install_packages_byopc() {

    #1. Argumentos
    local p_input_options=-1
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_input_options=$1
    fi

    if [ $p_input_options -le 0 ]; then
        echo "ERROR: Argumento de opciones \"${p_input_options}\" es incorrecta"
        return 99
    fi

    #3. Inicializaciones cuando se invoca directamente el script
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 3 ] || [ $gp_type_calling -eq 4 ]; then
        l_is_noninteractive=0
    fi

    if [ $gp_type_calling -eq 0 ]; then

        #Instalacion de paquetes del SO
        if [ $(( $p_input_options & $g_opt_update_installed_pckg )) -eq $g_opt_update_installed_pckg ]; then

            #Solicitar credenciales para sudo y almacenarlas temporalmente
            if [ $g_status_crendential_storage -eq 0 ]; then
                storage_sudo_credencial
                g_status_crendential_storage=$?
                #Se requiere almacenar las credenciales para realizar cambio con sudo.
                #  Si es 0 o 1: la instalación/configuración es completar
                #  Si es 2    : el usuario no acepto la instalación/configuración
                #  Si es 3 0 4: la instalacion/configuración es parcial (solo se instala/configura, lo que no requiere sudo)
                if [ $g_status_crendential_storage -eq 2 ]; then
                    return 120
                fi
            fi

            printf '\n'
            print_line '─' $g_max_length_line  "$g_color_gray1"
            printf "OS > Actualizar los paquetes del SO '%b%s %s%b'\n" "$g_color_cian1" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
            print_line '─' $g_max_length_line "$g_color_gray1"

            upgrade_os_packages $g_os_subtype_id $l_is_noninteractive

        fi
    fi

    #5. Instalar los paquetes selecionados por las opciones de menú dinamico.
    local l_x=0
    local l_status
    #Limpiar los resultados anteriores
    _gA_processed_repo=()

    for((l_x=0; l_x < ${#ga_menu_options_packages[@]}; l_x++)); do

        _install_menu_options $p_input_options $l_x
        l_status=$?

        #Se requiere almacenar las credenciales para realizar cambios con sudo.
        if [ $l_status -eq 120 ]; then
            return 120
        fi

    done


    #6. Si se invoco interactivamente y se almaceno las credenciales, caducarlo.
    #   Si no se invoca usando el menú y se almaceno las credencial en este script, será el script caller el que sea el encargado de caducarlo
    if [ $g_status_crendential_storage -eq 0 ] && [ $gp_type_calling -eq 0 ]; then
    #if [ $g_status_crendential_storage -eq 0 ] && [ $g_is_credential_storage_externally -ne 0 ]; then
        clean_sudo_credencial
    fi

}

#
#Parametros de entrada (Argumentos):
#  1 > Flag '0' si se actualiza los paquetes SO.
#  2 > Listado de ID de paquetes separados por coma.
function g_install_packages_byid() {

    #1. Argumentos
    local p_upgrade_os_packages=1
    if [ "$1" = "0" ]; then
        p_upgrade_os_packages=0
    fi

    if [ -z "$2" ]; then
        echo "ERROR: Listado de paquetes \"${2}\" es invalido"
        return 99
    fi

    local IFS=','
    local pa_packages=(${2})
    IFS=$' \t\n'

    local l_n=${#pa_packages[@]}
    if [ $l_n -le 0 ]; then
        echo "ERROR: Listado de paquetes \"${2}\" es invalido"
        return 99
    fi

    #3. Inicializaciones cuando se invoca directamente el script
    local l_title
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 3 ] || [ $gp_type_calling -eq 4 ]; then
        l_is_noninteractive=0
    fi

    #Instalacion de paquetes del SO
    if [ $p_upgrade_os_packages -eq 0 ]; then

        #Solicitar credenciales para sudo y almacenarlas temporalmente
        if [ $g_status_crendential_storage -eq 0 ]; then
            storage_sudo_credencial
            g_status_crendential_storage=$?
            #Se requiere almacenar las credenciales para realizar cambio con sudo.
            #  Si es 0 o 1: la instalación/configuración es completar
            #  Si es 2    : el usuario no acepto la instalación/configuración
            #  Si es 3 0 4: la instalacion/configuración es parcial (solo se instala/configura, lo que no requiere sudo)
            if [ $g_status_crendential_storage -eq 2 ]; then
                return 120
            fi
        fi

        printf '\n'
        print_line '-' $g_max_length_line  "$g_color_gray1"
        printf "OS > Actualizar los paquetes del SO '%b%s %s%b'\n" "$g_color_cian1" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
        print_line '-' $g_max_length_line "$g_color_gray1"

        upgrade_os_packages $g_os_subtype_id $l_is_noninteractive

    fi

    #Solicitar credenciales para sudo y almacenarlas temporalmente
    if [ $g_status_crendential_storage -eq 0 ]; then
        storage_sudo_credencial
        g_status_crendential_storage=$?
        #Se requiere almacenar las credenciales para realizar cambio con sudo.
        #  Si es 0 o 1: la instalación/configuración es completar
        #  Si es 2    : el usuario no acepto la instalación/configuración
        #  Si es 3 0 4: la instalacion/configuración es parcial (solo se instala/configura, lo que no requiere sudo)
        if [ $g_status_crendential_storage -eq 2 ]; then
            return 120
        fi
    fi

    #5. Instalar los paquetes indicados
    local l_x=0
    local l_status
    local l_repo_id
    local l_repo_name
    local l_repo_name_aux
    local l_title_template=""

    for((l_x=0; l_x < ${l_n}; l_x++)); do

        #Nombre a mostrar del paquete
        l_repo_id="${pa_packages[$l_x]}"
        l_repo_name="${gA_packages[${l_repo_id}]}"
        if [ -z "$l_repo_name" ]; then
            printf 'El %bpaquete "%s"%b no esta definido en "gA_packages" para su instalacion.\n' \
                   "$g_color_red1" "$l_repo_id" "$g_color_reset"
            continue
        fi

        if [ "$l_repo_name" = "$g_empty_str" ]; then
            l_repo_name_aux="$l_repo_id"
        else
            l_repo_name_aux="$l_repo_name"
        fi

        l_title_template=""
        if [ $l_n -ne 1 ]; then
            printf -v l_title_template "Package %s(%s/%s)%s > '%s%s%s' %s%%s%s" "$g_color_gray1" "$((l_x + 1))" "$l_n" "$g_color_reset" "$g_color_cian1" \
                    "$l_repo_name_aux" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
        fi


        if [ "$l_repo_name" = "$g_empty_str" ]; then

            if [ ! -z "$l_title_template" ]; then
                printf '\n'
                print_line '-' $g_max_length_line  "$g_color_gray1"
                printf "${l_title_template} %s\n" "se instalará"
                print_line '-' $g_max_length_line  "$g_color_gray1"
            fi

            install_custom_packages "$l_repo_id"
            l_status=$?   #Solo se puede mostrar el titulo del packege cuando NO retorna [6, infinito].
                          #   0 > Se inicio la instalación y termino existosamente
                          #   1 > Se inicio la instalación y termino con errores
                          #   2 > No se inicio la instalación: El paquete ya esta instalado
                          #   5 > No se inicio la instalación: Se envio otros parametros invalidos
                          # 120 > No se inicio la instalación: No se permitio almacenar las credenciales para sudo

        else
            g_install_package "$l_repo_id" "$l_title_template"
            l_status=$?   #Solo se puede mostrar el titulo del packege cuando NO retorna [6, infinito].
                          #   0 > Se inicio la instalación y termino existosamente
                          #   1 > Se inicio la instalación y termino con errores
                          #   2 > No se inicio la instalación: El paquete ya esta instalado
                          #   3 > No se inicio la instalación: No se obtuvo el nombre real del paquete
                          #   4 > No se inicio la instalación: No se obtuvo información si el paquete esta instalado o no
                          #   5 > No se inicio la instalación: Se envio otros parametros invalidos
                          # 120 > No se inicio la instalación: No se permitio almacenar las credenciales para sudo
        fi

        #Se requiere almacenar las credenciales para realizar cambios con sudo.
        if [ $l_status -eq 120 ]; then
            return 120
        fi

        #4.4. Si no se inicio el el proceso de configuración por no contar informacion correcta:

        #     3> No se obtuvo el nombre real del paquete
        if [ $l_status -eq 3 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            printf '%bNo se pudo iniciar el procesamiento del paquete "%s"%b debido no se establecio el nombre real de paquete a instalar.\n' \
                   "$g_color_red1" "$l_repo_id" "$g_color_reset"
            printf 'Corrija el error para continuar con configuración de los demas paquetes de la opción del menú.\n'
            continue
        fi

        #     4> No se obtuvo información si el paquete esta instalado o no.
        if [ $l_status -eq 4 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            printf '%bNo se pudo iniciar el procesamiento del paquete "%s"%b debido no se pudo obtener informacion del paquete en el SO.\n' \
                          "$g_color_red1" "$l_repo_id" "$g_color_reset"
            printf 'Corrija el error para continuar con configuración de los demas packages de la opción del menú.\n'
            continue

        fi

        #     5> Se tiene parametros invalidos que impiden que se instale
        if [ $l_status -eq 5 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            printf '%bNo se pudo iniciar el procesamiento del paquete "%s"%b debido parametros invalidos del paquete en el SO.\n' \
                          "$g_color_red1" "$l_repo_id" "$g_color_reset"
            printf 'Corrija el error para continuar con configuración de los demas packages de la opción del menú.\n'
            continue

        fi



        #4.5. Si se inicio el pocesamiento del package.

        #A. Estados de un proceso no iniciado:
        #   2 > El paqueta ya esta instalado
        if [ $l_status -eq 2 ]; then

            #No se considera un error, continue con el procesamiento de los siguientes paquetes.
            printf 'El paquete "%s" ya esta instalado. Se continua con el proceso de instalación.\n' "$l_repo_id"
            #continue

        #B. Estados de un proceso iniciado:
        #   1 > El paquete inicio la instalación y lo termino con exito.
        elif [ $l_status -eq 1 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            printf '%bError al instalar el paquete%b "%s" en %s\n' "$g_color_red1" "$g_color_reset" "$l_repo_name_aux" "$l_aux"
            printf 'Corrija el error para continuar con configuración de los demas paquetes de la opción del menú.\n'

        #   0 > El paquete inicio la instalación y lo termino con error.
        elif [ $l_status -eq 0 ]; then

            #No se considera un error, continue con el procesamiento de los siguientes paquetes.
            printf '\n'

        fi

    done


    #6. Si se invoco interactivamente y se almaceno las credenciales, caducarlo.
    #   Si no se invoca usando el menú y se almaceno las credencial en este script, será el script caller el que sea el encargado de caducarlo
    if [ $g_status_crendential_storage -eq 0 ] && [ $gp_type_calling -eq 0 ]; then
    #if [ $g_status_crendential_storage -eq 0 ] && [ $g_is_credential_storage_externally -ne 0 ]; then
        clean_sudo_credencial
    fi

}


#
#Parametros de entrada (Argumentos):
#  1 > Opciones relacionados con los paquetes que se se instalaran (entero que es suma de opciones de tipo 2^n).
#
function g_uninstall_packages() {

    #1. Argumentos
    local p_input_options=-1
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_input_options=$1
    fi

    if [ $p_input_options -le 0 ]; then
        echo "ERROR: Argumento de opciones \"${p_input_options}\" es incorrecta"
        return 99
    fi

    #3. Inicializaciones cuando se muestra el menú
    #local l_flag=0
    #if [ $gp_type_calling -eq 0 ]; then

    #fi

    #5. Instalar los paquetes selecionados por las opciones de menú dinamico.
    local l_x=0
    local l_status
    #Limpiar los resultados anteriores
    _gA_processed_repo=()

    for((l_x=0; l_x < ${#ga_menu_options_packages[@]}; l_x++)); do

        _uninstall_menu_options $p_input_options $l_x
        l_status=$?

        #Se requiere almacenar las credenciales para realizar cambios con sudo.
        if [ $l_status -eq 120 ]; then
            return 120
        fi

    done


    #6. Si se invoco interactivamente y se almaceno las credenciales, caducarlo.
    #   Si no se invoca usando el menú y se almaceno las credencial en este script, será el script caller el que sea el encargado de caducarlo
    if [ $g_status_crendential_storage -eq 0 ] && [ $gp_type_calling -eq 0 ]; then
    #if [ $g_status_crendential_storage -eq 0 ] && [ $g_is_credential_storage_externally -ne 0 ]; then
        clean_sudo_credencial
    fi

}


function g_install_main() {

    #1. Pre-requisitos

    #2. Mostrar el Menu
    print_line '─' $g_max_length_line "$g_color_green1"
    print_text_in_center "Menu de Opciones (Install/Upgrade)" $g_max_length_line "$g_color_green1"
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf " (%bq%b) Salir del menu\n" "$g_color_green1" "$g_color_reset"
    printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"

    get_length_menu_option $g_offset_option_index_menu_install
    local l_max_digits=$?

    printf "     (%b%${l_max_digits}d%b) Actualizar todos los paquetes existentes del python\n" "$g_color_green1" "$g_opt_update_installed_pckg" "$g_color_reset"

    show_dynamic_menu 'Instalar' $g_offset_option_index_menu_install $l_max_digits
    print_line '-' $g_max_length_line "$g_color_gray1"

    #3. Mostrar la ultima parte del menu y capturar la opcion elegida
    local l_flag_continue=0
    local l_options=""
    local l_value_option_a=$g_opt_update_installed_pckg
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_gray1" "$g_color_reset"
        read -re l_options

        case "$l_options" in
            a)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"
                g_install_packages_byopc $l_value_option_a 0
                ;;

            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"
                ;;


            0)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_gray1" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_gray1"
                ;;

            [1-9]*)
                if [[ "$l_options" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    print_line '─' $g_max_length_line "$g_color_green1"
                    g_install_packages_byopc $l_options 0
                else
                    l_flag_continue=0
                    printf '%bOpción incorrecta%b\n' "$g_color_gray1" "$g_color_reset"
                    print_line '-' $g_max_length_line "$g_color_gray1"
                fi
                ;;

            *)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_gray1" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_gray1"
                ;;
        esac

    done

}


function g_uninstall_main() {


    #Mostar el menu principal
    print_line '─' $g_max_length_line "$g_color_green1"

    print_text_in_center "Menu de Opciones (Uninstall)" $g_max_length_line "$g_color_green1"
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf " (%bq%b) Salir del menu\n" "$g_color_green1" "$g_color_reset"
    printf " ( ) Para desintalar ingrese un opción o la suma de las opciones que desea configurar:\n"

    get_length_menu_option $g_offset_option_index_menu_uninstall
    local l_max_digits=$?

    show_dynamic_menu 'Desinstalar' $g_offset_option_index_menu_uninstall $l_max_digits
    print_line '-' $g_max_length_line "$g_color_gray1"

    #Capturar la opcion de menu y completar el menu
    local l_flag_continue=0
    local l_options=""
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_gray1" "$g_color_reset"
        read -re l_options

        case "$l_options" in

            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"
                ;;


            0)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_gray1" "$g_color_reset"

                print_line '-' $g_max_length_line "$g_color_gray1"
                ;;


            [1-9]*)
                if [[ "$l_options" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    print_line '─' $g_max_length_line "$g_color_green1"
                    g_uninstall_packages $l_options 0
                else
                    l_flag_continue=0
                    printf '%bOpción incorrecta%b\n' "$g_color_gray1" "$g_color_reset"
                    print_line '-' $g_max_length_line "$g_color_gray1"
                fi
                ;;

            *)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_gray1" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_gray1"
                ;;
        esac

    done

}


g_usage() {

    printf 'Usage:\n'
    printf '  > %bDesintalar paquetes mostrando el menú de opciones%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/06_setup_python_pkgs.bash uninstall\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/06_setup_python_pkgs.bash uninstall TARGET_PATH_TYPE VE_PATH\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '  > %bInstalar paquetes mostrando el menú de opciones (interactivo)%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/06_setup_python_pkgs.bash\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/06_setup_python_pkgs.bash 0 USE_CACHE TARGET_PATH_TYPE VE_PATH\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '  > %bInstalar/Actualizar un grupo de paquetes sin mostrar el menú%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/06_setup_python_pkgs.bash CALLING_TYPE MENU-OPTIONS USE_CACHE\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/06_setup_python_pkgs.bash CALLING_TYPE MENU-OPTIONS USE_CACHE TARGET_PATH_TYPE VE_PATH\n%b' "$g_color_yellow1" \
           "$g_shell_path" "$g_color_reset"
    printf '    %bDonde:%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    > %bCALLING_TYPE%b (para este escenario) es 1 si es interactivo y 3 si es no-interactivo.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bInstalar/Actualizar un listado paquete sin mostrar el  menú%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/06_setup_python_pkgs.bash CALLING_TYPE LIST-REPO-IDS%b\n' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/06_setup_python_pkgs.bash CALLING_TYPE LIST-REPO-IDS USE_CACHE%b\n' "$g_color_yellow1" \
           "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/06_setup_python_pkgs.bash CALLING_TYPE LIST-REPO-IDS USE_CACHE TARGET_PATH_TYPE VE_PATH%b\n' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %bDonde:%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    > %bCALLING_TYPE%b (para este escenario) es 2 si es interactivo y 4 si es no-interactivo.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    > %bLIST-REPO-IDS%b es un listado de ID de paquetes, gestioados por pip, separado por coma. Es obligatorio, por lo que enviar "" o "EMPTY" es considerado un error.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf 'Donde:\n'
    printf '  > %bUSE_CACHE %bindica que si se almacenara los paquetes y sus dependencias en el cache para reducir el tiempo de instalacion de las siguientes actualizacion.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %b - Si es 0 (valor por defecto en modo interactivo, es decir CALLING_TYPE es 0 o 1), se usara el cache.%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b - Si es diferente a 0 (valor por defecto en modo no interactivo, es decir CALLING_TYPE es 3), NO se usara el cache.%b\n' "$g_color_gray1" "$g_color_reset"
    printf '  > %bTARGET_PATH_TYPE %bindica que el lugar donde el paquete se instalar los paquetes.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %b - Si es 0 (valor por defecto), el paquete se instalará a nivel usuario "~/.local/bin".%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b - Si es 1, se instalara dentro del entorno virtual cuya ruta es VE_PATH.%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b - Si es 2, se instalara globalmente (no recomendado, requere usar "--break-system-packages").%b\n' "$g_color_gray1" "$g_color_reset"
    printf '  > %bVE_PATH %bindica ruta donde se creara el entorno virtual y donde se instalar los paquetes, solo si TARGET_PATH_TYPE es 1.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"


}


#}}}




#------------------------------------------------------------------------------------------------------------------
#> Logica principal del script {{{
#------------------------------------------------------------------------------------------------------------------

#1. Variables de los argumentos del script


#Parametros (argumentos) basicos del script
gp_uninstall=1          #(0) Para instalar/actualizar
                        #(1) Para desintalar

#Tipo de ejecucion del script principal
gp_type_calling=0       #(0) Ejecución mostrando el menu del opciones (siempre es interactiva).
                        #(1) Ejecución sin el menu de opciones, interactivo    - instalar/actualizar paquetes relacionados a opciones de menu
                        #(2) Ejecución sin el menu de opciones, interactivo    - instalar/actualizar paquetes de las lista de IDs
                        #(3) Ejecución sin el menu de opciones, no interactivo - instalar/actualizar paquetes relacionados a opciones de menu
                        #(4) Ejecución sin el menu de opciones, no interactivo - instalar/actualizar paquetes de la lista de IDs


#Argumento 1: ¿instalar/actualizar o desintalar?
if [ "$1" = "uninstall" ]; then
    gp_type_calling=0
    gp_uninstall=0
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    gp_type_calling=$1
elif [ ! -z "$1" ]; then
    printf 'Argumentos invalidos.\n\n'
    g_usage
    exit 110
fi

if [ $gp_type_calling -lt 0 ] || [ $gp_type_calling -gt 4 ]; then
    printf 'Argumentos invalidos.\n\n'
    g_usage
    exit 110
fi


#printf 'Parametro 1: %s\n' "$1"
#printf 'Parametro 2: %s\n' "$2"
#printf 'Parametro 3: %s\n' "$3"
#printf 'Parametro 4: %s\n' "$4"
#printf 'Parametro 5: %s\n' "$5"
#printf 'Parametro 6: %s\n' "$6"
#printf 'Parametro 7: %s\n' "$7"
#printf 'Parametro 8: %s\n' "$8"
#printf 'Parametro 9: %s\n' "$9"



#2. Variables globales cuyos valor puede ser modificados el usuario

#...



#3. Variables globales cuyos valor son AUTOGENERADOS internamente por el script


#Menu dinamico: Offset del indice donde inicia el menu dinamico.
#               Generalmente el menu dinamico no inicia desde la primera opcion personalizado del menú.
g_offset_option_index_menu_install=1
g_offset_option_index_menu_uninstall=0

#Valores de la opcion especiales del menu (no estan vinculado a un paquete especifico):
# > Actualizar todos paquetes del sistema operativo (Opción 1 del arreglo del menu)
g_opt_update_installed_pckg=$((1 << 0))


#Estado del almacenado temporalmente de las credenciales para sudo
# -1 - No se solicito el almacenamiento de las credenciales
#  0 - No es root: se almaceno las credenciales
#  1 - No es root: no se pudo almacenar las credenciales.
#  2 - Es root: no requiere realizar sudo.
g_status_crendential_storage=-1

#Si la credenciales de sudo es abierto externamente.
#  1 - No se abrio externamente
#  0 - Se abrio externamente (solo se puede dar en una ejecución no-interactiva)
g_is_credential_storage_externally=1




#4. LOGICA: Instalar y actualizar los paquetes de un repositorio
_g_result=0
_g_status=0

#4.1. Desintalar los artefactos de un repoistorio
if [ $gp_uninstall -eq 0 ]; then

    # 1> Keyword "uninstall".

    #Validar los requisitos
    #  1 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
    #  2 > Flag '0' si se requere curl
    #  3 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
    fulfill_preconditions 0 1 0
    _g_status=$?

    #Iniciar el procesamiento
    #if [ $_g_status -eq 0 ]; then
    #    g_uninstall_main
    #else
    #    _g_result=111
    #fi

#4.2. Instalar y actualizar los artefactos de un paquete
else

    #4.2.1. Por defecto, mostrar el menu para escoger lo que se va instalar
    if [ $gp_type_calling -eq 0 ]; then

        # 1> Tipo de configuración: 1 (instalación/actualización).

        #Validar los requisitos
        #  1 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
        #  2 > Flag '0' si se requere curl
        #  3 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
        fulfill_preconditions 0 1 0
        _g_status=$?

        #Iniciar el procesamiento
        if [ $_g_status -eq 0 ]; then
            g_install_main
        else
            _g_result=111
        fi

    #2.2.2. No mostrar el menu. Instalando los paquetes especificados por las opciones indicas en '$2'
    elif [ $gp_type_calling -eq 1 ] || [ $gp_type_calling -eq 3 ]; then

        #Parametros del script usados hasta el momento:
        # 1> Tipo de configuración: 1 (instalación/actualización).
        # 2> Opciones de menu a ejecutar: entero positivo.
        # 3> El estado de la credencial almacenada para el sudo.
        gp_opciones=0
        if [[ "$2" =~ ^[0-9]+$ ]]; then
            gp_opciones=$2
        else
            exit 110
        fi

        if [[ "$3" =~ ^[0-2]$ ]]; then
            g_status_crendential_storage=$3

            if [ $g_status_crendential_storage -eq 0 ]; then
                g_is_credential_storage_externally=0
            fi

        fi


        #Validar los requisitos
        #  1 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
        #  2 > Flag '0' si se requere curl
        #  3 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
        fulfill_preconditions 1 1 0
        _g_status=$?

        #Iniciar el procesamiento
        if [ $_g_status -eq 0 ]; then
            g_install_packages_byopc $gp_opciones
            _g_status=$?

            #Informar si se nego almacenar las credencial cuando es requirido
            if [ $_g_status -eq 120 ]; then
                _g_result=120
            #Si la credencial se almaceno en este script (localmente). avisar para que lo cierre el caller
            elif [ $g_is_credential_storage_externally -ne 0 ] && [ $g_status_crendential_storage -eq 0 ]; then
                _g_result=119
            fi
       else
           _g_result=111
       fi

    #2.2.3. Instalando un solo paquetes del ID indicao por '$2'
    else

        #Parametros del script usados hasta el momento:
        # 1> Tipo de configuración: 1 (instalación/actualización).
        # 2> ID del paquete a instalar: identificado interno del respositorio
        # 3> El estado de la credencial almacenada para el sudo.
        # 4> Actualizar los paquetes del SO antes. Por defecto es 1 (false).
        gp_repo_ids="$2"
        if [ -z "$gp_repo_ids" ] || [ "$gp_repo_ids" = "EMPTY" ]; then
           echo "Parametro 2 \"$2\" debe ser un listado de ID de paquetes"
           exit 110
        fi

        if [[ "$3" =~ ^[0-2]$ ]]; then
            g_status_crendential_storage=$4

            if [ $g_status_crendential_storage -eq 0 ]; then
                g_is_credential_storage_externally=0
            fi
        fi

        gp_upgrade_os_packages=1
        if [ "$4" = "0" ]; then
            gp_upgrade_os_packages=0
        fi


        #Validar los requisitos
        #  1 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
        #  2 > Flag '0' si se requere curl
        #  3 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
        fulfill_preconditions 1 1 0
        _g_status=$?

        #Iniciar el procesamiento
        if [ $_g_status -eq 0 ]; then
            g_install_packages_byid $gp_upgrade_os_packages "$gp_repo_ids"
            _g_status=$?

            #Informar si se nego almacenar las credencial cuando es requirido
            if [ $_g_status -eq 120 ]; then
                _g_result=120
            #Si la credencial se almaceno en este script (localmente). avisar para que lo cierre el caller
            elif [ $g_is_credential_storage_externally -ne 0 ] && [ $g_status_crendential_storage -eq 0 ]; then
                _g_result=119
            fi
        else
            _g_result=111
        fi

    fi

fi

exit $_g_result


#}}}
