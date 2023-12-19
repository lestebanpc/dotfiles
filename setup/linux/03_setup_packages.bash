#!/bin/bash


#Inicialización Global {{{

#Funciones generales, determinar el tipo del SO y si es root
. ~/.files/terminal/linux/functions/func_utility.bash

#Obtener informacion basica del SO
if [ -z "$g_os_type" ]; then

    #Determinar el tipo del SO con soporte a interprete shell POSIX
    get_os_type
    declare -r g_os_type=$?

    #Obtener informacion de la distribución Linux
    if [ $g_os_type -le 1 ]; then
        get_linux_type_info
    fi

fi

#Obtener informacion basica del usuario
if [ -z "$g_user_is_root" ]; then

    #Determinar si es root y el soporte de sudo
    get_user_options

fi

#Funciones de utilidad
. ~/.files/setup/linux/_common_utility.bash


#Menu dinamico: Offset del indice donde inicia el menu dinamico.
#               Generalmente el menu dinamico no inicia desde la primera opcion personalizado del menú.
g_offset_option_index_menu_install=1
g_offset_option_index_menu_uninstall=0

#Valores de la opcion especiales del menu (no estan vinculado a un paquete especifico):
# > Actualizar todos paquetes del sistema operativo (Opción 1 del arreglo del menu)
g_opt_update_installed_pckg=$((1 << 0))


#Parametros (argumentos) basicos del script
gp_uninstall=1          #(0) Para instalar/actualizar
                        #(1) Para desintalar

#Tipo de ejecucion del script principal
gp_type_calling=0       #(0) Ejecución interactiva del script (muestra el menu).
                        #(1) Ejecución no-interactiva del script para instalar/actualizar un conjunto de respositorios
                        #(2) Ejecución no-interactiva del script para instalar/actualizar un solo paquete

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

#Personalización: Funciones modificables para el instalador.
. ~/.files/setup/linux/_setup_packages_custom.bash



#}}}



#Funcionalidad interna {{{


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
   
        #3.1. Mostrar el titulo
        print_line '─' $g_max_length_line  "$g_color_opaque"

        #Si se ejecuta en forma interactiva
        if [ $gp_type_calling -eq 0 ]; then
            printf -v l_title_template 'Opción %b%s%b: %b%s%b' "$g_color_opaque" "$l_option_value" "$g_color_reset" "$g_color_subtitle" "${ga_menu_options_title[${p_option_relative_idx}]}" "$g_color_reset"
        #Si se ejecuta en forma no-interactiva
        else
            printf -v l_title_template 'Grupo de paquetes: %b%s%b' "$g_color_subtitle" "${ga_menu_options_title[${p_option_relative_idx}]}" "$g_color_reset"
        fi

        print_text_in_center2 "$l_title_template" $g_max_length_line 
        print_line '─' $g_max_length_line "$g_color_opaque"

        #3.2. Inicializar la opcion si aun no ha sido inicializado.
        install_initialize_menu_option $p_option_relative_idx
        l_status=$?

        #3.3. Si se inicializo no se realizo con exito.
        if [ $l_status -ne 0 ]; then
            printf 'No se ha completo la inicialización de la opción del menu elegida...\n'
            l_result=2
        fi

        printf '\n'

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

            #Si se ejecuta en forma interactiva
            if [ $gp_type_calling -eq 0 ]; then
                printf -v l_title_template "%s(%s/%s)%s> El paquete '%s%s%s' %s%%s%s %s(opción de menu %s)%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
                      "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$l_option_value" "$g_color_reset"
            #Si se ejecuta en forma no-interactiva
            else
                printf -v l_title_template "%s(%s/%s)%s> El paquete '%s%s%s' %s%%s%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
                      "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
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

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "no procesado"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El package "%s" tiene parametros invalido que impiden su analisis. Se analizó al procesar la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            #  2 > El package ya esta instalado.
            elif [ $l_status_first_setup -eq 2 ]; then

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "no procesado"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El package "%s" ya esta instalado. Se analizó al procesar la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            #Estados de un proceso iniciado:
            #  0 > El paquete inicio la instalación y lo termino con exito.
            elif [ $l_status_first_setup -eq 0 ]; then

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "se acaba de instalar"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El package "%s" se acaba de instalar cuando se proceso la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            #  1 > El paquete inicio la instalación y lo termino con error.
            elif [ $l_status_first_setup -eq 1 ]; then

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "se acaba de instalar con error"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El package "%s" se acaba de instalar con error cuando se proceso la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

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

            #Si se ejecuta en forma interactiva
            if [ $gp_type_calling -eq 0 ]; then
                printf -v l_title_template "%s(%s/%s)%s> El paquete '%s%s%s' %s%%s%s %s(opción de menu %s)%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
                      "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$l_option_value" "$g_color_reset"
            #Si se ejecuta en forma no-interactiva
            else
                printf -v l_title_template "%s(%s/%s)%s> El paquete '%s%s%s' %s%%s%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
                      "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
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
                   "$g_color_warning" "$l_repo_id" "$g_color_reset"
            printf 'Corrija el error para continuar con configuración de los demas paquetes de la opción del menú.\n\n'

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
                          "$g_color_warning" "$l_repo_id" "$g_color_reset"
            printf 'Corrija el error para continuar con configuración de los demas packages de la opción del menú.\n\n'

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
                          "$g_color_warning" "$l_repo_id" "$g_color_reset"
            printf 'Corrija el error para continuar con configuración de los demas packages de la opción del menú.\n\n'

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
            printf 'El paquete "%s" ya esta instalado. Se continua con el proceso de instalación.\n\n' "$l_repo_id"
            #continue

        #B. Estados de un proceso iniciado:
        #   1 > El paquete inicio la instalación y lo termino con exito.
        elif [ $l_processed_repo -eq 1 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            l_flag_process_next_repo=1
            l_exits_error=0

            printf '%bError al instalar el paquete%b "%s" en %s\n' "$g_color_warning" "$g_color_reset" "$l_repo_name_aux" "$l_aux"
            printf 'Corrija el error para continuar con configuración de los demas paquetes de la opción del menú.\n\n'

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


#
#Parametros de entrada (argumentos de entrada son):
#  1 > Opciones de menu ingresada por el usuario 
#  2 > Indice relativo de la opcion en el menú de opciones (inicia con 0 y solo considera el indice del menu dinamico).
#
#Parametros de salida (El valor de retorno). Sus valores pueder ser
#    0 > La opcion de menu se desintaló con exito (se inicializo, se configuro los paquetes y se finalizo existosamente).
#    1 > No se ha inicio la desinstalacíon de la opcion del menu debido a que no se cumple las precondiciones requeridas (no se desintaló, ni se se inicializo/finalizo).
#    2 > La inicialización de la opción no termino con exito.
#    3 > Alguno de lo paquetes fallo en desinstalacíon. Ello provoca que se detiene el proceso (y no se invoca a la finalización).
#    4 > La finalización de la opción no termino con exito. 
#   98 > El paquetes vinculados a la opcion del menu no tienen parametros configurados correctos. 
#   99 > Argumentos ingresados son invalidos
#
#Parametros de salida (variables globales):
#    > '_gA_processed_repo' retona el estado de procesamiento de los paquetes hasta el momento procesados por el usuario. 
#           
function _uninstall_menu_options() {

    #1. Argumentos 
    local p_input_options=-1
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_input_options=$1
    fi

    local p_option_relative_idx=-1
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        p_option_relative_idx=$2
    fi


    if [ $p_input_options -le 0 ]; then
        return 99
    fi


    #1. Obtener los paquetes a configurar
    local l_aux="${ga_menu_options_packages[$p_option_relative_idx]}"

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
    local l_result       #  > No se escogio la opcion de menu para configurarlo/desinstalarlo
                         #0 > Se configuro con exito (se inicializo, se configuro/desinstalo todos los paquetes y se finalizo exitosamente).
                         #1 > No se inicio su inicialización (tampoco se configuro/desinstalo, ni se finalizo).
                         #2 > La inicialización de la opción termino con errores.
                         #3 > Alguno de los paquetes fallo en configurarse/desinstalarse, se detiene el proceso (no se invoca a la finalización).
                         #4 > La finalización de la opción no termino con exito. 

    local l_option_value=$((1 << (p_option_relative_idx + g_offset_option_index_menu_uninstall)))

    if [ $((p_input_options & l_option_value)) -ne $l_option_value ]; then
        #No inicializar ni instalar
        l_result=1 
    fi

    #echo "index: ${p_option_relative_idx}, input: ${p_input_options}, value: ${l_option_value}"

    #3. Inicializar la opción del menu
    local l_status
    local l_title_template

    #Si se escogio la opcion para instalarlo, mostrar el titulo de la opcion de menu e inicializarlo
    if [ -z "$l_result" ]; then
   
        #3.1. Mostrar el titulo
        print_line '─' $g_max_length_line  "$g_color_opaque"

        #Si se ejecuta en forma interactiva
        if [ $gp_type_calling -eq 0 ]; then
            printf -v l_title_template "Opción %s%s%s '%s%s%s'" "$g_color_opaque" "$l_option_value" "$g_color_reset" "$g_color_subtitle" "${ga_menu_options_title[${p_option_relative_idx}]}" "$g_color_reset"
        #Si se ejecuta en forma no-interactiva
        else
            printf -v l_title_template "Grupo de paquetes: '%s%s%s'" "$g_color_subtitle" "${ga_menu_options_title[${p_option_relative_idx}]}" "$g_color_reset"
        fi

        print_text_in_center2 "$l_title_template" $g_max_length_line 
        print_line '─' $g_max_length_line "$g_color_opaque"

        #3.2. Inicializar la opcion si aun no ha sido inicializado.
        uninstall_initialize_menu_option $p_option_relative_idx

        l_status=$?

        #3.3. Si se inicializo con error (cancelado por el usuario u otro error) 
        if [ $l_status -ne 0 ]; then
            printf 'No se ha completo la inicialización de la opción del menu elegida...\n'
            l_result=2
        fi

        printf '\n'

    fi


    #4. Recorriendo todos los paquetes, opcionalmente procesarlo, y almacenando el estado en la variable '_gA_processed_repo'
    local l_status
    local l_repo_id
    local l_j
    local l_k

    local la_aux
    local la_previous_options_idx
    local l_status_first_setup
    local l_repo_name_aux
    local l_processed_repo
    local l_exits_error=1

    local l_flag_process_next_repo=1      #(0) Se debe intentar procesar (intalar/actualizar o desinstalar) los paquete de la opción del menu.
                                          #(1) No se debe intentar procesar los paquetes de la opción del menú.
    if [ -z "$l_result" ]; then
        l_flag_process_next_repo=0
    fi

    #Se desintanla en orden inverso a la instalación
    for((l_j=(l_n-1); l_j >= 0; l_j--)); do

        #Nombre a mostrar del respositorio
        l_repo_id="${la_repos[$l_j]}"
        l_repo_name_aux="${gA_packages[$l_repo_id]:-$l_repo_id}"

        #4.1. Obtener el estado del paquete antes de su instalación.
        l_aux="${_gA_processed_repo[$l_repo_id]:--1|}"
        
        IFS='|'
        la_aux=(${l_aux})
        IFS=$' \t\n'

        l_status_first_setup=${la_aux[0]}    #'g_uninstall_repository' solo se puede mostrar el titulo del paquete cuando ninguno de los estados es [4, infinito>.
                                             # -1 > El paquete no se ha iniciado su analisis ni su proceso.
                                             #  0 > Se inicio la desinstalación y termino existosamente
                                             #  1 > Se inicio la desinstalación y termino con errores
                                             #  2 > No se inicio la desinstalación: El paquete ya esta instalado 
                                             #  3 > No se inicio la desinstalación: Parametros invalidos (impiden que se inicie su analisis/procesamiento).


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

            #4.2.3. No mostrar titulo, ni información alguna en los casos [4, infinito>
            if [ $l_status_first_setup -ge 4 ]; then
                continue
            fi

            #4.2.4. Calcular la plantilla del titulo.
            #Si se ejecuta en forma interactiva
            if [ $gp_type_calling -eq 0 ]; then
                printf -v l_title_template "%s(%s/%s)%s> El paquete '%s%s%s' %s%%s%s %s(opción de menu %s)%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
                      "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$l_option_value" "$g_color_reset"
            #Si se ejecuta en forma no interactiva
            else
                printf -v l_title_template "%s(%s/%s)%s> El paquete '%s%s%s' %s%%s%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
                      "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
            fi

            #El primer paquete donde se ha analizado si se puede o no ser procesado.
            l_k=${la_previous_options_idx[0]}
            l_aux=$((1 << (l_k + g_offset_option_index_menu_install)))

            #4.2.5. Mostrar el titulo y mensaje en los casos donde hubo error antes de procesarse y/o durante el procesamiento


            #Estados de un proceso no iniciado:
            #  3 > Al paquete tiene parametros invalidos que impiden su procesamiento.
            if [ $l_status_first_setup -eq 3 ]; then

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "no procesado"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El paquete "%s" tiene parametros invalidos que impiden su procesamiento. Se analizó con la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            #  2 > El paquete no esta instalado.
            elif [ $l_status_first_setup -eq 2 ]; then

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "no procesado"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El paquete "%s" ya esta instalado. Se analizó con la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            #Estados de un proceso iniciado:
            #  0 > El paquete inicio la desinstalación y lo termino con exito.
            elif [ $l_status_first_setup -eq 0 ]; then

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "se acaba de instalar"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El paquete "%s" se acaba de desinstalar en la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"


            #  1 > El paquete inicio la desinstalación y lo termino con error.
            elif [ $l_status_first_setup -eq 1 ]; then

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "se acaba de instalar con error"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El paquete "%s" se acaba de desinstalar con error en la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"


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

            #Si se ejecuta en forma interactiva
            if [ $gp_type_calling -eq 0 ]; then
                printf -v l_title_template "%s(%s/%s)%s> El paquete '%s%s%s' %s%%s%s %s(opción de menu %s)%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
                      "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$l_option_value" "$g_color_reset"
            #Si se ejecuta en forma no interactiva
            else
                printf -v l_title_template "%s(%s/%s)%s> El paquete '%s%s%s' %s%%s%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
                      "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
            fi
        fi
        
        g_uninstall_package "$l_repo_id" "$l_title_template" 
        l_status=$?   #'g_uninstall_package' solo se puede mostrar el titulo del paquete cuando no es [4, infinito>
                      #   0 > Se inicio la desinstalación y termino existosamente
                      #   1 > Se inicio la desinstalación y termino con errores
                      #   2 > No se inicio la desinstalación: El paquete no esta instalado 
                      #   3 > No se inicio la desinstalación: No se obtuvo el nombre real del paquete
                      #   4 > No se inicio la desinstalación: No se obtuvo información si el paquete esta instalado o no
                      #   5 > No se inicio la desinstalación: Se envio otros parametros invalidos
                      # 120 > No se inicio la desinstalación: No se permitio almacenar las credenciales para sudo 

        #Se requiere almacenar las credenciales para realizar cambios con sudo.
        if [ $l_status -eq 120 ]; then
            return 120
        fi

        #4.4. Si no se inicio el analisis para evaluar ... ¿se debe iniciar proceso de configuración?: No


        #     5>  No se inicio la desinstalación: Se envio otros parametros invalidos
        if [ $l_status -eq 5 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            l_flag_process_next_repo=1
            l_exits_error=0

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="0|${la_previous_options_idx[@]}"

            printf '%bNo se pudo iniciar el procesamiento del paquete "%s"%b debido a los parametros incorrectos enviados.\n' \
                          "$g_color_warning" "$l_repo_id" "$g_color_reset"
            printf 'Corrija el error para continuar con desinstalación de los demas paquetes de la opción del menú.\n\n'

            #echo "B > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue

        fi

        #     4> No se inicio la desinstalación: No se obtuvo información si el paquete esta instalado o no
        if [ $l_status -eq 4 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            l_flag_process_next_repo=1
            l_exits_error=0

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="0|${la_previous_options_idx[@]}"

            printf '%bNo se pudo iniciar el procesamiento del paquete "%s"%b debido a no se pudo determinar si este esta instalado o no.\n' \
                          "$g_color_warning" "$l_repo_id" "$g_color_reset"
            printf 'Corrija el error para continuar con desinstalación de los demas paquetes de la opción del menú.\n\n'

            #echo "B > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue

        fi

        #     3> No se inicio la desinstalación: No se obtuvo el nombre real del paquete
        if [ $l_status -eq 3 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            l_flag_process_next_repo=1
            l_exits_error=0
            printf '\n'

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="0|${la_previous_options_idx[@]}"

            printf '%bNo se pudo iniciar el procesamiento del paquete "%s"%b debido a no se obtuvo el nombre real del paquete.\n' \
                          "$g_color_warning" "$l_repo_id" "$g_color_reset"
            printf 'Corrija el error para continuar con desinstalación de los demas paquetes de la opción del menú.\n\n'

            #echo "B > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue

        fi


        #4.5. Si se inicio el pocesamiento del paquete
        l_processed_repo=$l_status
        l_aux="Linux '${g_os_subtype_name}'"

        #4.5.2. Almacenar la información del procesamiento
        la_previous_options_idx+=(${p_option_relative_idx})
        _gA_processed_repo["$l_repo_id"]="${l_processed_repo}|${la_previous_options_idx[@]}"
        #echo "F > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""


        #4.5.3. Mostrar información adicional

        #A. Estados de un proceso no iniciado:
        #   2 > Al paquete no esta instalado
        if [ $l_processed_repo -eq 2 ]; then

            #No se considera un error, continue con el procesamiento de los siguientes paquetes.
            printf 'El paquete "%s" no esta instalado. Se continua con el proceso de desinstalación.\n\n' "$l_repo_id"

        #B. Estados de un proceso iniciado:
        #   1 > Al paquete se desinstalo con errores
        elif [ $l_processed_repo -eq 1 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            l_flag_process_next_repo=1
            l_exits_error=0

            printf '%bError al desintalar %b el respositorio "%s" en %s\n' "$g_color_warning" "$g_color_reset" "$l_repo_name_aux" "$l_aux"
            printf 'Corrija el error para continuar con desinstalación de los demas paquetes de la opción del menú.\n\n'

        #   0 > El paquete inicio la desinstalación y lo termino con exito.
        #elif [ $l_processed_repo -eq 0 ]; then
        else

            #No se considera un error, continue con el procesamiento de los siguientes paquetes.
            printf '\n'

        fi


    done

    #Calcular el estado despues del procesamiento de paquetes
    if [ -z "$l_result" ]; then

        #Si se inicio la desinstalación de algun paquete y se obtuvo error
        if [ $l_exits_error -eq 0 ]; then
            l_result=3
        fi
    fi

    #5. Iniciar la finalización (solo si no hubo error despues de la procesamiento de respositorios)
    if [ -z "$l_result" ]; then

        #5.1. Inicializar la opcion si aun no ha sido inicializado.
        #printf 'Se inicia la finalización de la opción del menu...\n'
        uninstall_finalize_menu_option $p_option_relative_idx
        l_status=$?

        #5.2. Si se inicializo con exito.
        if [ $l_status -eq 0 ]; then

            l_result=0

        #5.3. Si en la inicialización hubo un error.
        else

            printf 'No se completo la finalización de la opción del menu.\n'
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
#   0 > Se inicio la desinstalación y termino existosamente
#   1 > Se inicio la desinstalación y termino con errores
#   2 > No se inicio la desinstalación: El paquete no esta instalado 
#   3 > No se inicio la desinstalación: No se obtuvo el nombre real del paquete
#   4 > No se inicio la desinstalación: No se obtuvo información si el paquete esta instalado o no
#   5 > No se inicio la desinstalación: Se envio otros parametros invalidos
# 120 > No se inicio la desinstalación: No se permitio almacenar las credenciales para sudo 
#           
function g_uninstall_package() {

    #1. Argumentos 
    local p_package_id="$1"
    local p_package_title_template="$2"

    #1. Inicializaciones
    local l_status=0
    local l_package_name_default="${gA_packages[$p_package_id]}"
    local l_package_name

    #3. Mostrar el titulo
    if [ ! -z "$p_package_title_template" ]; then

        print_line '-' $g_max_length_line  "$g_color_opaque"
        printf "${p_package_title_template}\n" "se desinstalará"
        print_line '-' $g_max_length_line  "$g_color_opaque"

    fi

    #2. Obtener el nombre del paquete para el sistema operativo
    l_package_name=$(get_package_name "$p_package_id" "$l_package_name_default" ${g_os_subtype_id})
    l_status=$?

    if [ $l_status -eq 9 ]; then
        printf 'No se pudo obtener el nombre real del paquete "%s"\n' "$l_package_name_default"
        return 3
    fi
    
    #3. ¿El paquete esta instalado?
    is_package_installed "$l_package_name" $g_os_subtype_id $l_status
    l_status=$?
    #echo "Package to install: ${l_package_name} - ${g_os_subtype_id} - ${l_status}"

    if [ $l_status -eq 9 ]; then
        printf 'No se pudo obtener información del paquete "%s"\n' "$l_package_name_default"
        return 4

    elif [ $l_status -eq 1 ]; then
        #printf 'El paquete "%s" no esta instalado\n' "$l_package_name_default"
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

    uninstall_os_package "$l_package_name" $g_os_subtype_id
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
    local l_status=0
    local l_package_name_default="${gA_packages[$p_package_id]}"
    local l_package_name

    #3. Mostrar el titulo
    if [ ! -z "$p_package_title_template" ]; then

        print_line '-' $g_max_length_line  "$g_color_opaque"
        printf "${p_package_title_template}\n" "se instalará"
        print_line '-' $g_max_length_line  "$g_color_opaque"

    fi

    #2. Obtener el nombre del paquete para el sistema operativo
    l_package_name=$(get_package_name "$p_package_id" "$l_package_name_default" ${g_os_subtype_id})
    l_status=$?
    #echo "Package> ID: ${p_package_id} - NameGeneral: ${l_package_name_default} - Name: ${l_package_name} - SearchType: ${l_status}"

    if [ $l_status -eq 9 ]; then
        printf 'No se pudo obtener el nombre real del paquete "%s"\n' "$l_package_name_default"
        return 3
    fi
    
    #3. ¿El paquete esta instalado?
    is_package_installed "$l_package_name" $g_os_subtype_id $l_status
    l_status=$?
    #echo "Package ${l_package_name} installing - Status: ${l_status} - OS: ${g_os_subtype_id}"

    if [ $l_status -eq 9 ]; then
        printf 'No se pudo obtener información del  paquete "%s"\n' "$l_package_name"
        return 4

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

    install_os_package "$l_package_name" $g_os_subtype_id
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
function g_install_packages() {
    
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
    local l_flag=0
    local l_title
    if [ $gp_type_calling -eq 0 ]; then


        #Instalacion de paquetes del SO
        l_flag=$(( $p_input_options & $g_opt_update_installed_pckg ))
        if [ $g_opt_update_installed_pckg -eq $l_flag ]; then

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

            print_line '─' $g_max_length_line  "$g_color_opaque"
            printf -v l_title "Actualizar los paquetes del SO '%s%s %s%s'" "$g_color_subtitle" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
            print_text_in_center2 "$l_title" $g_max_length_line 
            print_line '─' $g_max_length_line "$g_color_opaque"

            upgrade_os_packages $g_os_subtype_id            

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
    #   Si no se invoca interactivamente y se almaceno las credencial en este script, será el script caller el que sea el encargado de caducarlo
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

    #3. Inicializaciones cuando se invoca directamente el script
    #local l_flag=0
    #if [ $gp_type_calling -eq 0 ]; then

    #fi

    #5. Instalar los paquetes selecionados por las opciones de menú dinamico.
    local l_i=0
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
    #   Si no se invoca interactivamente y se almaceno las credencial en este script, será el script caller el que sea el encargado de caducarlo
    if [ $g_status_crendential_storage -eq 0 ] && [ $gp_type_calling -eq 0 ]; then
    #if [ $g_status_crendential_storage -eq 0 ] && [ $g_is_credential_storage_externally -ne 0 ]; then
        clean_sudo_credencial
    fi

}


function g_install_main() {

    #1. Pre-requisitos
   
    #2. Mostrar el Menu
    print_line '─' $g_max_length_line "$g_color_title" 
    print_text_in_center "Menu de Opciones (Install/Upgrade)" $g_max_length_line "$g_color_title"
    print_line '-' $g_max_length_line  "$g_color_opaque"
    printf " (%bq%b) Salir del menu\n" "$g_color_title" "$g_color_reset"
    printf " (%ba%b) Actualizar los paquetes existentes del SO y los binarios de los paquetes existentes\n" "$g_color_title" "$g_color_reset"
    printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"

    get_length_menu_option $g_offset_option_index_menu_install
    local l_max_digits=$?

    printf "     (%b%0${l_max_digits}d%b) Actualizar los paquetes existentes del sistema operativo\n" "$g_color_title" "$g_opt_update_installed_pckg" "$g_color_reset"

    show_dynamic_menu 'Instalar' $g_offset_option_index_menu_install $l_max_digits
    print_line '-' $g_max_length_line "$g_color_opaque"

    #3. Mostrar la ultima parte del menu y capturar la opcion elegida
    local l_flag_continue=0
    local l_options=""
    local l_value_option_a=$g_opt_update_installed_pckg
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_opaque" "$g_color_reset"
        read -r l_options

        case "$l_options" in
            a)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                g_install_packages $l_value_option_a 0
                ;;

            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                ;;


            0)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_opaque" 
                ;;

            [1-9]*)
                if [[ "$l_options" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    print_line '─' $g_max_length_line "$g_color_title" 
                    printf '\n'
                    g_install_packages $l_options 0
                else
                    l_flag_continue=0
                    printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                    print_line '-' $g_max_length_line "$g_color_opaque" 
                fi
                ;;

            *)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_opaque" 
                ;;
        esac
        
    done

}


function g_uninstall_main() {


    #Mostar el menu principal 
    print_line '─' $g_max_length_line "$g_color_title" 

    print_text_in_center "Menu de Opciones (Uninstall)" $g_max_length_line "$g_color_title"
    print_line '-' $g_max_length_line  "$g_color_opaque"
    printf " (%bq%b) Salir del menu\n" "$g_color_title" "$g_color_reset"
    printf " ( ) Para desintalar ingrese un opción o la suma de las opciones que desea configurar:\n"

    get_length_menu_option $g_offset_option_index_menu_uninstall
    local l_max_digits=$?

    show_dynamic_menu 'Desinstalar' $g_offset_option_index_menu_uninstall $l_max_digits
    print_line '-' $g_max_length_line "$g_color_opaque"

    #Capturar la opcion de menu y completar el menu
    local l_flag_continue=0
    local l_options=""
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_opaque" "$g_color_reset"
        read -r l_options

        case "$l_options" in

            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                ;;


            0)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"

                print_line '-' $g_max_length_line "$g_color_opaque" 
                ;;


            [1-9]*)
                if [[ "$l_options" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    print_line '─' $g_max_length_line "$g_color_title" 
                    printf '\n'
                    g_uninstall_packages $l_options 0
                else
                    l_flag_continue=0
                    printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                    print_line '-' $g_max_length_line "$g_color_opaque" 
                fi
                ;;

            *)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_opaque" 
                ;;
        esac
        
    done

}


g_usage() {

    printf '%bUsage:\n\n' "$g_color_opaque"
    printf '  > Desintalar paquetes de manera interactiva (muestra el menú):\n'
    printf '    %b~/.files/setup/linux/03_setup_packages.bash uninstall\n%b' "$g_color_info" "$g_color_opaque"
    printf '  > Instalar/Actualizar los paquetes de manera interactiva (muestra el menú):\n'
    printf '    %b~/.files/setup/linux/03_setup_packages.bash\n%b' "$g_color_info" "$g_color_opaque"
    printf '  > Instalar/Actualizar uno o mas paquetes en forma no interactiva (sin menú):\n'
    printf '    %b~/.files/setup/linux/03_setup_packages.bash 1 MENU-OPTIONS\n%b' "$g_color_info" "$g_color_opaque"
    printf '  > Instalar/Actualizar un paquete en forma no interactiva (sin menú):\n'
    printf '    %b~/.files/setup/linux/03_setup_packages.bash 2 PACKAGE-ID%b\n\n' "$g_color_info" "$g_color_reset"

}


#}}}





#1. Argumentos fijos del script


#Argumento 1: ¿instalar/actualizar o desintalar?
if [[ "$1" =~ ^[0-9]+$ ]]; then
    gp_type_calling=$1
elif [ "$1" = "uninstall" ]; then
    gp_uninstall=0
elif [ ! -z "$1" ]; then
    printf 'Argumentos invalidos.\n\n'
    g_usage
    exit 80
fi


#2. Codigo de ejecución del programa (incluye el uso los argumentos variables)
_g_result=0
_g_status=0

#Aun no se ha solicitado almacenar temporalmente las credenciales para el sudo
g_status_crendential_storage=-1
#La credencial no se almaceno por un script externo.
g_is_credential_storage_externally=1

#2.1. Desintalar los artefactos de un repoistorio
if [ $gp_uninstall -eq 0 ]; then

    #Validar los requisitos
    fulfill_preconditions $g_os_subtype_id $gp_type_calling 1 0
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then
        g_uninstall_main
    else
        _g_result=111
    fi

#2.2. Instalar y actualizar los artefactos de un paquete
else

    #2.2.1. Por defecto, mostrar el menu para escoger lo que se va instalar
    if [ $gp_type_calling -eq 0 ]; then
    
        #Validar los requisitos
        fulfill_preconditions $g_os_subtype_id $gp_type_calling 1 0
        _g_status=$?

        #Iniciar el procesamiento
        if [ $_g_status -eq 0 ]; then
            g_install_main
        else
            _g_result=111
        fi
    
    #2.2.2. No mostrar el menu. Instalando los paquetes especificados por las opciones indicas en '$2'
    elif [ $gp_type_calling -eq 1 ]; then
    
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
        fulfill_preconditions $g_os_subtype_id $gp_type_calling 1 0
        _g_status=$?

        #Iniciar el procesamiento
        if [ $_g_status -eq 0 ]; then
            g_install_packages $gp_opciones
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
    
    #2.2.3. Instalando un solo repostorio del ID indicao por '$2'
    else
    
        #Parametros del script usados hasta el momento:
        # 1> Tipo de configuración: 1 (instalación/actualización).
        # 2> ID del paquete a instalar: identificado interno del respositorio
        # 3> El estado de la credencial almacenada para el sudo.
        gp_repo_id="$2"
        if [ -z "$gp_repo_id" ]; then
           echo "Parametro 2 \"$2\" debe ser un ID de paquete valido"
           exit 110
        fi

        if [[ "$3" =~ ^[0-2]$ ]]; then
            g_status_crendential_storage=$3

            if [ $g_status_crendential_storage -eq 0 ]; then
                g_is_credential_storage_externally=0
            fi
        fi
    
        #Validar los requisitos
        fulfill_preconditions $g_os_subtype_id $gp_type_calling 1 0
        _g_status=$?

        #Iniciar el procesamiento
        if [ $_g_status -eq 0 ]; then
            g_install_package "$gp_repo_id" ""
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


