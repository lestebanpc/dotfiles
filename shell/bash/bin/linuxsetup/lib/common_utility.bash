#!/bin/bash


#Variables globales externo usuados:
#
#   # > 'g_shell_path'                : Ruta base de los shell
#   g_shell_path=~/.files/shell
#   # > 'g_runner_user'               : Usuario que ejecuta el script
#   g_runner_user="lucianoepc"
#   # > 'g_os_type'                   : 0 si es Linux non-WSL, 1 si es WSL
#   . ${g_shell_path}/bash/lib/mod_common.bash
#   get_os_type
#   g_os_type=$?
#   # > 'g_os_subtype_id'             : Tipo de distribucion Linux
#   # > 'g_os_subtype_name'           : Nombre de distribucion Linux
#   # > 'g_os_subtype_version'        : Version extendida de la distribucion Linux
#   # > 'g_os_subtype_version_pretty' : Version corta de la distribucion Linux
#   # > 'g_os_architecture_type'      : Tipo de la arquitectura del procesador
#   get_linux_type_info
#   # > 'g_runner_id'                 : ID del usuario actual (UID).
#   # > 'g_runner_user'               : Nombre del usuario actual.
#   # > 'g_runner_sudo_support'       : Si el so y el usuario soportan el comando 'sudo'
#   get_runner_options
#   # > 'g_repo_name'                 : Nombre o ruta relativa del repositorio a GIT.
#   g_repo_name=".files"
#


#------------------------------------------------------------------------------------------------------------------
#> Logica de inicialización {{{
#------------------------------------------------------------------------------------------------------------------
# Incluye variables globales constantes y variables globales que requieren ser calculados al iniciar el script.
#

#Colores principales usados para presentar información (menu,...)
g_color_reset="\x1b[0m"
g_color_green1="\x1b[32m"
g_color_gray1="\x1b[90m"
g_color_cian1="\x1b[36m"
g_color_yellow1="\x1b[33m"
g_color_red1="\x1b[31m"
g_color_blue1="\x1b[34m"

#Tamaño de la linea del menu
declare -r g_max_length_line=130

declare -r g_empty_str='EMPTY'


#Menu dinamico: Listado de repositorios que son instalados por las opcion de menu dinamicas
#  - Cada repositorio tiene un ID interno del un repositorios y un identifificador realizar:
#    ['internal-id']='external-id'
#  - Por ejemplo para el repositorio GitHub 'stedolan/jq', el item se tendria:
#    ['jq']='stedolan/jq'
declare -A gA_packages=(
    )

#Menu dinamico: Titulos de las opciones del menú
#  - Cada entrada define un opcion de menú. Su valor define el titulo.
declare -a ga_menu_options_title=(
    )

#Menu dinamico: Repositorios de programas asociados asociados a una opciones del menu.
#  - Cada entrada define un opcion de menú.
#  - Su valor es un cadena con ID de repositorios separados por comas.
declare -a ga_menu_options_packages=(
    )


#}}}




#------------------------------------------------------------------------------------------------------------------
#> Funciones Generales {{{
#------------------------------------------------------------------------------------------------------------------
#
# Incluye las variable globales usadas como parametro de entrada y salida de la funcion que no sea resuda por otras
# funciones, cuyo nombre inicia con '_g_'.
#

#Devuelve una cadena formado por el nombre de usuario owner y el nombre del grupo de acceso de un folder, separado un espacio.
function get_owner_of_folder() {

    local p_folder_path="$1"

    local l_owner=''
    local l_group=''

    local l_aux=''
    if l_aux=$(stat -c '%U' "$p_folder_path" 2> /dev/null); then
        l_owner="$l_aux"
    fi

    if l_aux=$(stat -c '%G' "$p_folder_path" 2> /dev/null); then
        l_group="$l_aux"
    fi

    if [ ! -z "$l_owner" ] && [ ! -z "$l_group" ]; then
        echo "${l_owner} ${l_group}"
        return 0
    fi

    local l_owner=()
    if l_aux=$(ls -ld "${p_folder_path}" | awk '{print $3" "$4}' 2> /dev/null); then

        if [ -z "$l_aux" ]; then
            return 1
        fi

        la_owners=(${l_aux})
        if [ ${#la_owners[@]} -lt 2 ]; then
            return 1
        fi

        l_owner="${la_owners[0]}"
        l_group="${la_owners[1]}"

        echo "${l_owner} ${l_group}"
        return 0
    fi

    return 1

}

#Obtener la informacion del target home (home del usuario OBJETIVO, donde se encuentan el repositorio con los archivos de configuración usados para configurar
#su profile, comandos y/o programas). Adicionalmente, validar si el usuario runner (responsable de configurar el home del setup) pueda ser uno de las
#siguientes opciones:
# - El onwer del home del setup.
# - Si no es onwer del home del setup, solo puede ser el usuario root (root realizará la configuracion para el owner del home del setup, nunca para root).
#Parametros de entrada:
#  1> Nombre del repositorio
#  2> Ruta del home del usuario donde se configura el profile y donde esta el repositorio git.
#Parametros de salida:
#  > Variables globales: 'g_targethome_path', 'g_repo_path', 'g_targethome_owner', 'g_targethome_group', 'g_runner_is_target_user'.
#  > Valor de retorno
#    0> Se pudo calucular los valores con existo y el usuario runner es valido para configurar el profile del usuario.
#    1> No se pudo calcular los valores con exito o el usuario runner no esta habilitado para configura el profile del usario.
function get_targethome_info() {

    if [ -z "$1" ]; then
        printf 'Debe especificar el nombre del repositorio del target home.\n'
        return 1
    fi
    local p_repo_name="$1"

    #Establecer el valor por defecto 'g_targethome_path', si no se especifo una valor valido (no existe).
    if [ -z "$2" ]; then
        if [[ "${g_shell_path}" == */${p_repo_name}/shell ]]; then
            g_targethome_path="${g_shell_path%/${p_repo_name}/shell}"
        else
            printf 'Debe especificar la ruta correcta del home del usuario objetivo (al cual se desaea configurar su profile).\n'
            return 1
        fi
    else
        g_targethome_path="$2"
    fi

    #Ruta base del respositorio git del usuario donde se instalar el profile del usuario.
    g_repo_path="${g_targethome_path}/${p_repo_name}"

    #El usuario runner debera tener permisos de lectura y escritura del home donde se configurara el profile.
    if [ ! -d "$g_targethome_path" ]; then
        printf 'El target home "%b%s%b" del usuario objetivo, no existe o el usario runner "%b%s%b" no tiene acceso.\n' \
               "$g_color_gray1" "$g_targethome_path" "$g_color_reset" "$g_color_gray1" "$g_runner_user" "$g_color_reset"
        return 1
    fi

    if [ ! -d "${g_targethome_path}/${p_repo_name}" ]; then
        printf 'El repositorio "%b%s%b" del target home, no existe o el usario runner "%b%s%b" no tiene acceso.\n' \
               "$g_color_gray1" "${g_targethome_path}/${p_repo_name}" "$g_color_reset" "$g_color_gray1" "$g_runner_user" "$g_color_reset"
        return 1
    fi

    #El usuario runner debera tener permisos de lectura y escritura del home donde se configurara el profile.
    if [ ! -w "$g_targethome_path" ]; then
        printf 'El usuario runner "%b%s%b" no tiene permiso de escritura al "%b%s%b" home del usuario objetivo.\n' \
               "$g_color_gray1" "$g_runner_user" "$g_color_reset" "$g_color_gray1" "$g_targethome_path" "$g_color_reset"
        return 1
    fi

    if [ ! -w "${g_targethome_path}/${p_repo_name}" ]; then
        printf 'El usuario runner "%b%s%b" no tiene de escritura al repositorio "%b%s%b" del target home.\n' \
               "$g_color_gray1" "$g_runner_user" "$g_color_reset" "$g_color_gray1" "${g_targethome_path}/${p_repo_name}" "$g_color_reset"
        return 1
    fi

    #Obteniendo el owner del home del usuario OBJETIVO (donde se configura el profile)
    local l_aux
    l_aux=$(get_owner_of_folder "$g_targethome_path")
    l_status=$?

    if [ $l_status -ne 0 ] || [ -z "$l_aux" ]; then
       printf 'No se pueden obtener el owner del target home "%b%s%b".\n' "$g_color_gray1" "$l_script_path" "$g_color_reset"
       return 1
    fi

    local la_owners=(${l_aux})
    g_targethome_owner="${la_owners[0]}"
    g_targethome_group="${la_owners[1]}"

    #Si el runner (usuario que ejecuta el script) es usuario objetivo: OK
    if [ "$g_runner_user" = "$g_targethome_owner" ]; then
        g_runner_is_target_user=0
        return 0
    fi


    #Si el runner no es el usuario objetivo o no es root
    if [ $g_runner_id -ne 0 ]; then
        printf 'El usuario runner "%b%s%b" (ID="%b%s%b") no puede usar el target home "%b%s%b". Este target home solo lo puede usar el usuario "%b%s%b" o el usuario "%broot%b". Cambie el target home o ejecute con otro usuario.\n' \
               "$g_color_gray1" "$g_runner_user" "$g_color_reset" "$g_color_gray1" "$g_runner_id" "$g_color_reset" "$g_color_gray1" "$g_targethome_path" "$g_color_reset" \
               "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
        return 1
    fi


    g_runner_is_target_user=1
    return 0

}

#Validar si la la carpeta base del programas y tiene los permisos correctos, y si no tiene, se intenta arreglarlo/repararlo.
#  > El owner del la carpeta define el usuario que DEBE instalar/actualizar los programas.
#  > El runner (usuario objetivo o usuario root en modo de suplantacion del usuario objetivo) solo puede instalar programas en folderes cuyo owner sea el usuario
#    objetivo o root.
#    - Si el folder del programa tiene un owner diferente a estos, en el script de instalacion, se debera cambiar el usuario objetivo al owner de esta carpeta para
#      que pueda realizar la instalacion.
#    - Si el runner requiere permisos de escritura en el folder de programas.
#  > Si el owner de la carpeta de programas es root:
#    - Si el usuario runner es el usuario objetivo (y no root en modo suplantacion) y no es root, se debera validar que este usuario tiene acceso a sudo con root.
#      - Si el sistema operativo NO soporte sudo y el usuario owner y el que ejecuto el script debe ser root.
#      - Si el sistema operativo soporta sudo y el usario ejecutor no es root, esta debe tener permisos para usar sudo como root.
#    - Todo los nuevos archivos/carpetas creados durante la instalacion tendran como owner a root.
#    - La carpeta estandar PODRIA ser '/var/opt/tools' o '/opt/tools', dependiendo del owner.
#  > Si el owner de la carpeta de programas es el usuario OBJETIVO, la instalacion/actualización de programas no requiere accesos a root.
#    - Si la carpeta esta dentro del home del usuario objetivo, los programas solo puede ser usados por el usuario objetivo.
#      - La carpeta estandar es '~/tools'.
#      - Solo se consideran como carpetas validas aquellas tenga como owner al usuario de su home.
#    - Si la carpeta esta fuera del home del usuario objetivo, los programas puede ser usados todos los usuarios (pero solo el usuario objetivo puede
#      instalar/actualizar los programas)
#      - La carpeta estandar PODRIA ser: '/var/opt/tools' o '/opt/tools'.
#    - Todo los nuevos archivos/carpetas creados durante la instalacion tendran como owner al usuario objetivo.
#    - Si el usuario runner es root en modo de suplantacion (del usuario objetivo), debera cambiar el owner de los folderes/archivos creados durante la instalacion.
#  > Si la carpeta enviada EXISTE:
#    - Si la carpeta no tiene los permisos correctos para la instalación de programas, SOLO se intentara reparar los permisos cuando el usuario runner
#      tenga los acceso que lo permita, caso contrario, se rechazara la carpeta (evitando el uso de SUDO para reparar errores de configuracion
#      de la carpeta enviada).
#    - No se crearan los subfolderes adicionales 'FOLDER_BASE/sharedkeys', 'FOLDER_BASE/sharedkeys/tls' y 'FOLDER_BASE/sharedkeys/ssh'.
#  > Si la carpeta enviada NO EXISTE:
#    - Si la carpeta padre existe, se intentara crear la carpeta y si se logra ello, sera considera como una carpeta valida para almacenar programas.
#    - Si el folder esta dentro de home del usuario objetivo, se intenta crear el folder con permisos 755 y cuyo owner sea el usuario objetivo.
#    - Si el folder esta fuera de home del usuario objetivo, se intenta crear el folder con permisos 755 y cuyo owner sea root.
#    - Se crearan los subfolderes adicionales 'FOLDER_BASE/sharedkeys', 'FOLDER_BASE/sharedkeys/tls' y 'FOLDER_BASE/sharedkeys/ssh'.
#Parametro de entrada> Argumentos de entrada:
#  01 > La ruta base de programas a normalizar.
#Parametros de entrada > Variables globales:
#  > 'g_targethome_path'
#Parametro de salida> Variables globales
#  > '_g_tools_options' que define caracteristicas del folder ingresado. Su valor puede ser 0 o la suma binario
#    de los siguientes flags:
#       > 00001 (1) - La carpeta de programas tiene como owner al usuario OBJETIVO.
#       > 00010 (2) - La carpeta de programas tiene como owner a root.
#       > 00100 (4) - La carpeta de programas esta en el "target home" (home del usuario OBJETIVO).
#       > 01000 (8) - La carpeta de programas NO es una ruta estandar  (ruta personalizada ingresada por el usuario)
#   > '_g_tools_owner' owner del folder de programas ingresado.
#   > '_g_tools_group' grupo de acceso del folder de programas ingresado.
#Parametro de salida> Valor de retorno:
#  > OK (Se establecio o se creo la carpeta existente con los permisos correctos para la instalación de programas para el usuario objetivo):
#    00 > La carpeta existe y tiene los permisos necesarios.
#    01 > La carpeta existe y se modifico los permisos necesarios.
#    02 > Se creo la carpeta con los permisos necesario para que el usuario
#  > NO OK (No se ha podido establecer o crear la carpeta con los permisos correctos para la instalación de programas para el usuario objetivo):
#    03 > La carpeta existe pero tiene como owner a un usuario diferente del usuario OBJETIVO o del usuario root.
#    04 > La carpeta existe pero no se puede establer los permisos necesarios.
#    05 > La carpeta no existe pero no se puede crear porque la carpeta padre no existe.
#    06 > La carpeta no existe y pero no se tiene los permisos correctos para crearlo.
#    07 > La carpeta no existe y pero ocurrio un error al crearlo.
#    99 > Parametro invalidos.
function _try_fix_tools_path() {

    #1. Argumentos
    local p_tools_path="$1"
    if [ -z "$p_tools_path" ]; then
        return 99
    fi

    #2. Calcular algunas de las opciones del folder ingresado
    _g_tools_options=0
    _g_tools_owner=''
    _g_tools_group=''

    #¿La carpeta esta en el home del usuario owner del home de setup (donde estan los archivos de configuración de profile, comandos y programas)?
    local l_folder_is_targethome=1
    if [[ "$p_tools_path" == ${g_targethome_path}/* ]]; then
        _g_tools_options=4
        l_folder_is_targethome=0
    fi

    #¿La carpeta es ruta estandar o una ruta personalizado (ingresada por el usuario)?
    if [ "$p_tools_path" != "/var/opt/tools" ] || [ "$p_tools_path" != "/opt/tools" ] || [ "$p_tools_path" != "${g_targethome_path}/tools" ]; then
        _g_tools_options=$(( _g_tools_options + 8 ))
    fi


    #3. Si la carpeta existe: intentar arreglar los permisos
    #   Solo intentara reparar los permisos cuando el usuario tenga los permisos y lo permita. Caso contrario, no intentara reparar la carpeta y lo rechazara.
    #   Es decir, evitara usar sudo para reparar errores de configuracion de la carpeta enviada.
    local l_aux=''
    local l_flag=1
    local la_owners=()

    if [ -d "$p_tools_path" ]; then

        #A. Obtener el owner del folder ingresado
        l_aux=$(get_owner_of_folder "$p_tools_path")
        if [ -z "$l_aux" ]; then
            printf 'No se pueden obtener el owner del folder "%b%s%b".\n' "$g_color_gray1" "$l_script_path" "$g_color_reset"
            return 99
        fi

        la_owners=(${l_aux})
        if [ ${#la_owners[@]} -lt 2 ]; then
            printf 'No se pueden obtener, de manera correcta, el owner del folder "%b%s%b".\n' "$g_color_gray1" "$l_script_path" "$g_color_reset"
            return 99
        fi
        _g_tools_owner="${la_owners[0]}"
        _g_tools_group="${la_owners[1]}"

        if [ "$_g_tools_owner" = "root" ]; then
            _g_tools_options=$(( _g_tools_options + 2 ))
        fi

        #B. Si el onwer de la carpeta NO es el usuario objetivo
        if [ "$_g_tools_owner" != "$g_targethome_owner" ]; then

            #B.1. Si el owner de la carpeta NO es root
            if [ "$_g_tools_owner" != "root" ]; then

                #Solo intentar reparar, cuando el folder esta dentro de home y el runner es root el modo de suplantacion (del usario objetivo).
                if [ $g_runner_is_target_user -ne 0 ] && [ $l_folder_is_targethome -eq 0 ]; then

                    chmod 755 "$p_tools_path"
                    chown "${g_targethome_owner}:${g_targethome_group}" "$p_tools_path"

                    #Creando subfolderes adicionales, si no existen
                    [ ! -d "$p_tools_path/sharedkeys" ] &&  mkdir -pm 755 "$p_tools_path/sharedkeys"
                    [ ! -d "$p_tools_path/sharedkeys/tls" ] &&  mkdir -pm 755 "$p_tools_path/sharedkeys/tls"
                    [ ! -d "$p_tools_path/sharedkeys/ssh" ] &&  mkdir -pm 755 "$p_tools_path/sharedkeys/ssh"

                    #Aceptar la carpeta
                    return 1

                fi

                #Cualquier otor caso, rechazar el folder ingresado
                return 4

            fi

            #B.2. Si el owner de la carpeta es root

            #Se rechazar el folder ingresado, si el usuario runner no tiene permisos para ejecutar como root
            # - El sistema operativo no soporte sudo y el usuario ejecutor no es root.
            # - El sistema operativo soporta sudo y el usario ejecutor no es root y no tiene permiso para sudo.
            if [ $g_runner_sudo_support -eq 3 ] || [ $g_runner_id -ne 0 -a  $g_runner_sudo_support -eq 2 ]; then
            #if [ $g_runner_sudo_support -eq 3 ] || [[ $g_runner_id -ne 0  &&  $g_runner_sudo_support -eq 2 ]]; then
            #if [ $g_runner_sudo_support -eq 3 ] || { [ $g_runner_id -ne 0 ] && [ $g_runner_sudo_support -eq 2 ]; }; then

                return 4

            fi

            #No arreglar permisos existente, dejar como esta.

            #Creando subfolderes adicionales, si no existen
            [ ! -d "$p_tools_path/sharedkeys" ] &&  mkdir -pm 755 "$p_tools_path/sharedkeys"
            [ ! -d "$p_tools_path/sharedkeys/tls" ] &&  mkdir -pm 755 "$p_tools_path/sharedkeys/tls"
            [ ! -d "$p_tools_path/sharedkeys/ssh" ] &&  mkdir -pm 755 "$p_tools_path/sharedkeys/ssh"

            #Aceptar la carpeta
            return 0

        fi

        #C. Si el onwer de la carpeta es el usuario objetivo
        _g_tools_options=$(( _g_tools_options + 1 ))

        #C.1. Si el runner es el usuario objetivo
        if [ $g_runner_is_target_user -eq 0 ]; then

            #Si no tiene permisos de escritura, intentar repararlo
            l_flag=1
            if [ ! -w "$p_tools_path" ]; then
                if ! chmod 755 "$p_tools_path" &> /dev/null; then
                    return 4
                fi
                l_flag=0
            fi

            #Creando subfolderes adicionales, si no existen
            [ ! -d "$p_tools_path/sharedkeys" ] &&  mkdir -pm 755 "$p_tools_path/sharedkeys"
            [ ! -d "$p_tools_path/sharedkeys/tls" ] &&  mkdir -pm 755 "$p_tools_path/sharedkeys/tls"
            [ ! -d "$p_tools_path/sharedkeys/ssh" ] &&  mkdir -pm 755 "$p_tools_path/sharedkeys/ssh"

            #Aceptar la carpeta enviada
            if [ $l_flag -eq 0 ]; then
                return 1
            fi
            return 0

        fi


        #C.2. Si el runner es root en modo de suplantacion del usuario objetivo

        #No arreglar permisos existente, dejar como esta.
        #chmod 755 "$p_tools_path"
        #return 1

        #Creando subfolderes adicionales, si no existen
        if [ ! -d "$p_tools_path/sharedkeys" ]; then
            mkdir -pm 755 "$p_tools_path/sharedkeys"
            chown "${g_targethome_owner}:${g_targethome_group}" "$p_tools_path/sharedkeys"
        fi

        if [ ! -d "$p_tools_path/sharedkeys/tls" ]; then
            mkdir -pm 755 "$p_tools_path/sharedkeys/tls"
            chown "${g_targethome_owner}:${g_targethome_group}" "$p_tools_path/sharedkeys/tls"
        fi

        if [ ! -d "$p_tools_path/sharedkeys/ssh" ]; then
            mkdir -pm 755 "$p_tools_path/sharedkeys/ssh"
            chown "${g_targethome_owner}:${g_targethome_group}" "$p_tools_path/sharedkeys/ssh"
        fi

        #Aceptar la carpeta
        return 0


    fi


    #4. Si la carpeta no existe, intentar crearlo
    #   Si la carpeta enviada no existe, pero se tiene los permisos par crear la carpeta y la carpet padre existe, se intentara crear la carpeta y si se logra
    #   esta sera considera como una carpeta valida para almacenar programas.
    #    - Si el folder esta dentro de home del usuario objetivo, se intenta crear el folder con permisos 755 y cuyo owner sea el usuario objetivo.
    #    - Si el folder esta fuera de home del usuario objetivo, se intenta crear el folder con permisos 755 y cuyo owner sea root.


    #El owner del folder a crear dependera de la ubicacion de este
    if [ $l_folder_is_targethome -eq 0 ]; then

        #El owner es el usuaro efectivo
        _g_tools_options=$(( _g_tools_options + 1 ))
        if [ "$g_targethome_owner" = "root" ]; then
            _g_tools_options=$(( _g_tools_options + 2 ))
        fi
        _g_tools_owner="$g_targethome_owner"
        _g_tools_group="$g_targethome_group"

    else

        #El owner es el root
        if [ "$g_targethome_owner" = "root" ]; then
            _g_tools_options=$(( _g_tools_options + 1 ))
        fi
        _g_tools_options=$(( _g_tools_options + 2 ))
        _g_tools_owner='root'
        _g_tools_group='root'

    fi

    #Validar que existe el folder padre
    l_aux="${p_tools_path%/*}"
    if [ ! -z "$l_aux" ] && [ ! -d "$l_aux" ]; then
        return 5
    fi

    #A. Si la carpeta a crear esta dentro del home del usuario objetivo
    if [ $l_folder_is_targethome -eq 0 ]; then

        #Crear el folder
        if ! mkdir -pm 755 "$p_tools_path" &> /dev/null; then
            return 7
        fi

        #Crear los folderes opcionales
        mkdir -pm 755 "$p_tools_path/sharedkeys"
        mkdir -pm 755 "$p_tools_path/sharedkeys/tls"
        mkdir -pm 755 "$p_tools_path/sharedkeys/ssh"

        #Si el runner ejecuta con root en modo de suplantacion del usuario objetivo
        if [ $g_runner_is_target_user -ne 0 ]; then
            chown -R "${g_targethome_owner}:${g_targethome_group}" "$p_tools_path"
        fi

        #Aceptar la carpeta enviada
        return 2

    fi


    #B. Si la carpeta a crear esta fuera del home del usuario objetivo (el owner sera root)

    #Se rechaza el folder ingresado, si el usuario runner no tiene permisos para ejecutar como root
    # - El sistema operativo no soporte sudo y el usuario ejecutor no es root.
    # - El sistema operativo soporta sudo y el usario ejecutor no es root y no tiene permiso para sudo.
    if [ $g_runner_sudo_support -eq 3 ] || [ $g_runner_id -ne 0 -a $g_runner_sudo_support -eq 2 ]; then
    #if [ $g_runner_sudo_support -eq 3 ] || { [ $g_runner_id -ne 0 ] && [ $g_runner_sudo_support -eq 2 ]; }; then
        return 6
    fi

    #Crear el folder
    # - Si runner es root (puede estar o no estar en modo suplantacion de usuario objetivo)
    if [ $g_runner_id -eq 0 ]; then

        if ! mkdir -pm 755 "$p_tools_path"; then
            return 7
        fi

        #Crear los folderes opcionales
        mkdir -pm 755 "$p_tools_path/sharedkeys"
        mkdir -pm 755 "$p_tools_path/sharedkeys/tls"
        mkdir -pm 755 "$p_tools_path/sharedkeys/ssh"

    # - Si runner NO es root y requiere sudo: sin password
    elif [ $g_runner_sudo_support -eq 1 ]; then

        if ! sudo mkdir -pm 755 "$p_tools_path"; then
            return 7
        fi

        #Crear los folderes opcionales
        sudo mkdir -pm 755 "$p_tools_path/sharedkeys"
        sudo mkdir -pm 755 "$p_tools_path/sharedkeys/tls"
        sudo mkdir -pm 755 "$p_tools_path/sharedkeys/ssh"

    # - Si runner NO es root y requiere sudo: con password
    else

        printf 'Se requiere crear la carpeta "%b%s%b" de programas con los permisos correctos, para ello se debe usar sudo con root...\n' \
               "$g_color_gray1" "$p_tools_path" "$g_color_reset"

        if ! sudo mkdir -pm 755 "$p_tools_path"; then
            return 7
        fi

        #Crear los folderes opcionales
        sudo mkdir -pm 755 "$p_tools_path/sharedkeys"
        sudo mkdir -pm 755 "$p_tools_path/sharedkeys/tls"
        sudo mkdir -pm 755 "$p_tools_path/sharedkeys/ssh"

    fi

    #Aceptar la carpeta enviada
    return 2

}



# Validar si el foler base de los comandos (y archivos como ayuda y fuente) tiene los permisos correctos, y si no tiene, se intenta arreglarlo/repararlo.
# Solo se necesita reparar folder existentes, pero no crearlos, estos se crearan cuando se requiere (eliminar codifo de creacion).
#  > El owner del la carpeta define el usuario que DEBE instalar/actualizar los programas.
#  > El runner (usuario objetivo o usuario root en modo de suplantacion del usuario objetivo) solo puede instalar comandos (y archivos afines como ayuda y las
#    fuentes) en folderes cuyo owner sea el usuario objetivo o root.
#    - Si el folder base de los programa tiene un owner diferente a estos, en el script de instalacion, se debera cambiar el usuario objetivo al owner de esta
#      carpeta para que pueda realizar la instalacion.
#    - Si el runner requiere permisos de escritura en el folder base de los comandos.
#  > Esta carpeta puede ser de 2 tipos:
#    > La carpeta reservada del sistema
#      - No tiene folder base pero el owner siempre es considerado como root.
#      - Los subfolderes de comandos (, ayuda y fuentes) NO estan dentro de un mismo folder padre, y son rutas reservadas por el SO:
#        - '/usr/local/bin' para comandos,
#        - '/usr/local/share/man/man1' para archivos de ayuda man1 y
#        - '/usr/local/share/fonts' para las fuentes.
#      - El runner debe ser root o un usuario con acceso a sudo con root.
#      - Los comandos (, ayuda y fuentes) se instalan para todos los usuarios.
#    > La carpeta que NO son reservada del sistema
#      - Los subfolderes de comandos (, ayuda y fuentes) estan dentro de un mismo folder padre:
#        - 'FOLDER_BASE/bin' para comandos,
#        - 'FOLDER_BASE/share/man/man1' para archivos de ayuda man1 y
#        - 'FOLDER_BASE/share/fonts' para las fuentes.
#      - El owner de la carpeta puede ser usuario objetivo o el usuario root. El runner puede ser el usuario objetivo o el usuario root de suplantacion.
#      - La carpeta puede estar dentro del home del usuario objetivo o fuera de este.
#      - Un caso especial: carpeta reservada para el usuario: '~/.local'
#  > Si el owner, del folder base de los comandos, es root:
#    - Si el usuario runner es el usuario objetivo (y no root en modo suplantacion) y no es root, se debera validar que este usuario tiene acceso a sudo con root.
#      - Si el sistema operativo NO soporte sudo y el usuario owner y el que ejecuto el script debe ser root.
#      - Si el sistema operativo soporta sudo y el usario ejecutor no es root, esta debe tener permisos para usar sudo como root.
#    - Todo los nuevos archivos/carpetas creados durante la instalacion tendran como owner a root.
#  > Si el owner del folder base de los comandos es el usuario OBJETIVO, la instalacion/actualización de comandos no requiere accesos a root.
#    - Si la carpeta esta dentro del home del usuario objetivo, los comandos solo puede ser usados por el usuario objetivo.
#      - Un caso especial: carpeta reservada para el usuario: '~/.local'
#      - Solo se consideran como carpetas validas aquellas tenga como owner al usuario de su home.
#    - Si la carpeta esta fuera del home del usuario objetivo, los comandos puede ser usados todos los usuarios (pero solo el usuario objetivo puede
#      instalar/actualizar los programas)
#    - Todo los nuevos archivos/carpetas creados durante la instalacion tendran como owner al usuario objetivo.
#    - Si el usuario runner es root en modo de suplantacion (del usuario objetivo), debera cambiar el owner de los folderes/archivos creados durante la instalacion.
#  > Si la carpeta enviada EXISTE:
#    - Si la carpeta no tiene los permisos correctos para la instalación de comandos, SOLO se intentara reparar los permisos cuando el usuario runner tenga los
#      acceso que lo permita, caso contrario, se rechazara la carpeta (evitando el uso de SUDO para reparar errores de configuracion de la carpeta enviada).
#    - Siempre se intenta crear los subfolderes 'FOLDER_BASE/bin', 'FOLDER_BASE/man' y 'FOLDER_BASE/share/fonts' si no existen y se tiene permisos.
#    - Si los subfolderes existe pero no tienen los permisos correctos, solo se repara si el runner lo permite sin usar sudo. Caso contrario se rechaza todo el folder.
#  > Si la carpeta enviada NO EXISTE:
#    - Si la carpeta padre existe, se intentara crear la carpeta y si se logra ello, sera considera como una carpeta valida para almacenar comandos.
#    - Si el folder esta dentro de home del usuario objetivo, se intenta crear el folder con permisos 755 y cuyo owner sea el usuario objetivo.
#    - Si el folder esta fuera de home del usuario objetivo, se intenta crear el folder con permisos 755 y cuyo owner sea root.
#    - Siempre se creara los subfolderes 'FOLDER_BASE/bin', 'FOLDER_BASE/man' y 'FOLDER_BASE/share/fonts' si no existen y se tiene permisos.
#Parametro de entrada> Argumentos de entrada:
#  01 > La ruta base de programas a normalizar. Si se desea validar las rutas predeterminado del sistema, envie un valor vacio.
#Parametros de entrada > Variables globales:
#  > 'g_targethome_path'
#Parametro de salida> Variables globales
#  > '_g_lnx_base_options' que define caracteristicas del folder ingresado. Su valor puede ser 0 o la suma binario
#    de los siguientes flags:
#       > 00001 (1) - La carpeta de comandos tiene como owner al usuario OBJETIVO.
#       > 00010 (2) - La carpeta de comandos tiene como owner a root.
#       > 00100 (4) - La carpeta de comandos esta en el "target home" (home del usuario OBJETIVO).
#       > 01000 (8) - La carpeta de comandos NO es del sistema ni '~/.local'.
#   > '_g_lnx_base_owner' owner del folder base de los comandos ingresado.
#   > '_g_lnx_base_group' grupo de acceso del folder base de comandos ingresado.
#Parametro de salida> Valor de retorno:
#  > OK (Se establecio o se creo la carpeta existente con los permisos correctos para la instalación de comandos para el usuario objetivo):
#    00 > La carpeta existe y tiene los permisos necesarios.
#    01 > La carpeta existe y se modifico los permisos necesarios.
#    02 > Se creo la carpeta con los permisos necesario para que el usuario
#  > NO OK (No se ha podido establecer o crear la carpeta con los permisos correctos para la instalación de comandos para el usuario objetivo):
#    03 > La carpeta existe pero tiene como owner a un usuario diferente del usuario OBJETIVO o del usuario root.
#    04 > La carpeta existe pero no se puede establer los permisos necesarios.
#    05 > La carpeta no existe pero no se puede crear porque la carpeta padre no existe.
#    06 > La carpeta no existe y pero no se tiene los permisos correctos para crearlo.
#    07 > La carpeta no existe y pero ocurrio un error al crearlo.
#    99 > Parametro invalidos.
function _try_fix_lnx_base_path() {

    #TODO : Eliminar la creacion, solo reparar los folderes existentes.

    #1. Argumentos
    local p_lnx_base_path="$1"

    #2. Calcular algunas de las opciones del folder ingresado
    _g_lnx_base_options=0
    _g_lnx_base_owner=''
    _g_lnx_base_group=''

    local l_folder_is_targethome=1

    #¿La carpeta esta en el home del usuario owner del home de setup (donde estan los archivos de configuración de profile, comandos y programas)?
    if [ ! -z "$p_lnx_base_path" ] && [[ "$p_lnx_base_path" == ${g_targethome_path}/* ]]; then
        _g_lnx_base_options=4
        l_folder_is_targethome=0
    fi

    if [ ! -z "$p_lnx_base_path" ] && [ "$p_lnx_base_path" != "${g_targethome_path}/.local" ]; then
        _g_lnx_base_options=$(( _g_lnx_base_options + 8 ))
    fi

    #3. Si la carpeta reservada por el sistema.
    local l_flag=1
    if [ -z "$p_lnx_base_path" ]; then

        #A. El owner del folder siempre es root.
        _g_lnx_base_owner='root'
        _g_lnx_base_group='root'
        _g_lnx_base_options=$(( _g_lnx_base_options + 2 ))
        if [ "$g_targethome_owner" = "root" ]; then
            _g_lnx_base_options=$(( _g_lnx_base_options + 1 ))
        fi

        #B. Si el runner es root
        if [ $g_runner_id -eq 0 ]; then

            #Crear los subfolderes si no existen
            l_flag=1
            if [ ! -d "/usr/local/share/man" ]; then
                mkdir -pm 755 /usr/local/share/man
                l_flag=0
            fi

            if [ ! -d "/usr/local/share/fonts" ]; then
                mkdir -pm 755 /usr/local/share/fonts
                l_flag=0
            fi

            #Aceptar la carpeta enviada
            if [ $l_flag -eq 0 ]; then
                return 1
            fi
            return 0

        fi

        #C. Si el runner es el usuario es el usuario objetivo

        #Si no tiene permisos de root (ser root o poder ejecutar SUDO), rechazar la carpeta
        if  [ $g_runner_sudo_support -eq 3 ] || [ $g_runner_id -ne 0 -a $g_runner_sudo_support -eq 2 ]; then
        #if  [ $g_runner_sudo_support -eq 3 ] || { [ $g_runner_id -ne 0 ] && [ $g_runner_sudo_support -eq 2 ]; }; then

            #Se rechazar los casos:
            # - El sistema operativo no soporte sudo y el usuario ejecutor no es root.
            # - El sistema operativo soporta sudo y el usario ejecutor no es root y no tiene permiso para sudo.
            return 3

        fi

        #Crear los subfolderes si no existen:
        l_flag=1

        # - Si es root
        if [ $g_runner_id -eq 0 ]; then

            if [ ! -d "/usr/local/share/man" ]; then
                mkdir -pm 755 /usr/local/share/man
                l_flag=0
            fi

            if [ ! -d "/usr/local/share/fonts" ]; then
                mkdir -pm 755 /usr/local/share/fonts
                l_flag=0
            fi


        # - Si no es root y requiere sudo: sin password
        elif [ $g_runner_sudo_support -eq 1 ]; then

            if [ ! -d "/usr/local/share/man" ]; then
                sudo mkdir -pm 755 /usr/local/share/man
                l_flag=0
            fi

            if [ ! -d "/usr/local/share/fonts" ]; then
                sudo mkdir -pm 755 /usr/local/share/fonts
                l_flag=0
            fi

        # - Si no es root y requiere sudo: con password
        else

            if [ ! -d "/usr/local/share/man" ]; then
                printf 'Se requiere permisos para crear la carpeta "%b%s%b", para ello se debe usar sudo con root...\n' \
                       "$g_color_gray1" "/usr/local/share/man" "$g_color_reset"
                sudo mkdir -pm 755 /usr/local/share/man
                l_flag=0
            fi

            if [ ! -d "/usr/local/share/fonts" ]; then
                if [ $l_flag -eq 1 ]; then
                    printf 'Se requiere permisos para crear la carpeta "%b%s%b", para ello se debe usar sudo con root...\n' \
                           "$g_color_gray1" "/usr/local/share/fonts" "$g_color_reset"
                    l_flag=0
                fi
                sudo mkdir -pm 755 /usr/local/share/fonts
            fi

        fi

        #Aceptar la carpeta
        if [ $l_flag -eq 0 ]; then
            return 1
        fi
        return 0

    fi

    #3. Si es una carpeta NO es la carpeta reservada para el sistema
    local l_aux=''
    local la_owners=()
    #3.1. Si existe la carpeta no reservada del sistema, intentar corregir permisos...
    if [ -d "$p_lnx_base_path" ]; then

        #A. Obtener el owner del folder ingresado
        l_aux=$(get_owner_of_folder "$p_lnx_base_path")
        if [ -z "$l_aux" ]; then
            printf 'No se pueden obtener el owner del folder "%b%s%b".\n' "$g_color_gray1" "$l_script_path" "$g_color_reset"
            return 99
        fi

        la_owners=(${l_aux})
        if [ ${#la_owners[@]} -lt 2 ]; then
            printf 'No se pueden obtener, de manera correcta, el owner del folder "%b%s%b".\n' "$g_color_gray1" "$l_script_path" "$g_color_reset"
            return 99
        fi
        _g_lnx_base_owner="${la_owners[0]}"
        _g_lnx_base_group="${la_owners[1]}"

        if [ "$_g_lnx_base_owner" = "root" ]; then
            _g_lnx_base_options=$(( _g_lnx_base_options + 2 ))
        fi

        #B. Si el onwer de la carpeta NO es el usuario objetivo
        if [ "$_g_lnx_base_owner" != "$g_targethome_owner" ]; then

            #B.1. Si el owner de la carpeta NO es root
            if [ "$_g_lnx_base_owner" != "root" ]; then

                #Solo intentar reparar, cuando el folder esta dentro de home y el runner es root el modo de suplantacion (del usario objetivo).
                if [ $g_runner_is_target_user -ne 0 ] && [ $l_folder_is_targethome -eq 0 ]; then

                    chmod 755 "$p_lnx_base_path"
                    chown "${g_targethome_owner}:${g_targethome_group}" "$p_lnx_base_path"
                    _g_lnx_base_options=$(( _g_lnx_base_options + 1 ))

                    #Creando los subfolderes si no existen
                    if [ ! -d "${p_lnx_base_path}/bin" ]; then
                        mkdir -pm 755 "${p_lnx_base_path}/bin"
                        chown "${g_targethome_owner}:${g_targethome_group}" "$p_lnx_base_path/bin"
                    fi

                    if [ ! -d "${p_lnx_base_path}/share" ]; then
                        mkdir -pm 755 "${p_lnx_base_path}/share"
                        chown "${g_targethome_owner}:${g_targethome_group}" "$p_lnx_base_path/share"
                    fi

                    if [ ! -d "${p_lnx_base_path}/share/man" ]; then
                        mkdir -pm 755 "${p_lnx_base_path}/share/man"
                        chown "${g_targethome_owner}:${g_targethome_group}" "$p_lnx_base_path/share/man"
                    fi

                    if [ ! -d "${p_lnx_base_path}/share/fonts" ]; then
                        mkdir -pm 755 "${p_lnx_base_path}/share/fonts"
                        chown "${g_targethome_owner}:${g_targethome_group}" "$p_lnx_base_path/share/fonts"
                    fi

                    #Aceptar la carpeta
                    return 1

                fi

                #Cualquier otor caso, rechazar el folder ingresado
                return 4

            fi

            #B.2. Si el owner de la carpeta es root
            if [ "$g_targethome_owner" = "root" ]; then
                _g_lnx_base_options=$(( _g_lnx_base_options + 1 ))
            fi

            #Se rechazar la carpeta, si el usuario runner no tiene permisos para ejecutar como root
            # - El sistema operativo no soporte sudo y el usuario ejecutor no es root.
            # - El sistema operativo soporta sudo y el usario ejecutor no es root y no tiene permiso para sudo.
            if [ $g_runner_sudo_support -eq 3 ] || [ $g_runner_id -ne 0 -a $g_runner_sudo_support -eq 2 ]; then
            #if [ $g_runner_sudo_support -eq 3 ] || { [ $g_runner_id -ne 0 ] && [ $g_runner_sudo_support -eq 2 ]; }; then

                return 4

            fi

            #No arreglar permisos existente, dejar como esta.

            #Creando los subfolderes si no existen
            if [ ! -d "${p_lnx_base_path}/bin" ]; then
                mkdir -pm 755 "${p_lnx_base_path}/bin"
                chown "${g_targethome_owner}:${g_targethome_group}" "$p_lnx_base_path/bin"
            fi

            if [ ! -d "${p_lnx_base_path}/share" ]; then
                mkdir -pm 755 "${p_lnx_base_path}/share"
                chown "${g_targethome_owner}:${g_targethome_group}" "$p_lnx_base_path/share"
            fi

            if [ ! -d "${p_lnx_base_path}/share/man" ]; then
                mkdir -pm 755 "${p_lnx_base_path}/share/man"
                chown "${g_targethome_owner}:${g_targethome_group}" "$p_lnx_base_path/share/man"
            fi

            if [ ! -d "${p_lnx_base_path}/share/fonts" ]; then
                mkdir -pm 755 "${p_lnx_base_path}/share/fonts"
                chown "${g_targethome_owner}:${g_targethome_group}" "$p_lnx_base_path/share/fonts"
            fi

            #Aceptar la carpeta
            return 0

        fi

        #C. Si el onwer de la carpeta es el usuario objetivo
        _g_lnx_base_options=$(( _g_lnx_base_options + 1 ))

        #C.1. Si el runner es el usuario objetivo
        if [ $g_runner_is_target_user -eq 0 ]; then

            #Si no tiene permisos de escritura, intentar repararlo
            l_flag=1
            if [ ! -w "$p_lnx_base_path" ]; then
                if ! chmod 755 "$p_lnx_base_path" &> /dev/null; then
                    return 4
                fi
                l_flag=0
            fi

            #Creando los subfolderes si no existen
            [ ! -d "${p_lnx_base_path}/bin" ] && mkdir -pm 755 "${p_lnx_base_path}/bin"
            [ ! -d "${p_lnx_base_path}/share" ] && mkdir -pm 755 "${p_lnx_base_path}/share"
            [ ! -d "${p_lnx_base_path}/share/man" ] && mkdir -pm 755 "${p_lnx_base_path}/share/man"
            [ ! -d "${p_lnx_base_path}/share/fonts" ] && mkdir -pm 755 "${p_lnx_base_path}/share/fonts"

            #Aceptar la carpeta enviada
            if [ $l_flag -eq 0 ]; then
               return 1
            fi
            return 0

        fi


        #C.2. Si el runner es root en modo de suplantacion del usuario objetivo

        #No arreglar permisos existente, dejar como esta.
        #chmod 755 "$p_lnx_base_path"
        #return 1

        #Creando los subfolderes si no existen
        if [ ! -d "${p_lnx_base_path}/bin" ]; then
            mkdir -pm 755 "${p_lnx_base_path}/bin"
            chown "${g_targethome_owner}:${g_targethome_group}" "$p_lnx_base_path/bin"
        fi

        if [ ! -d "${p_lnx_base_path}/share" ]; then
            mkdir -pm 755 "${p_lnx_base_path}/share"
            chown "${g_targethome_owner}:${g_targethome_group}" "$p_lnx_base_path/share"
        fi

        if [ ! -d "${p_lnx_base_path}/share/man" ]; then
            mkdir -pm 755 "${p_lnx_base_path}/share/man"
            chown "${g_targethome_owner}:${g_targethome_group}" "$p_lnx_base_path/share/man"
        fi

        if [ ! -d "${p_lnx_base_path}/share/fonts" ]; then
            mkdir -pm 755 "${p_lnx_base_path}/share/fonts"
            chown "${g_targethome_owner}:${g_targethome_group}" "$p_lnx_base_path/share/fonts"
        fi

        #Aceptar la carpeta
        return 0


    fi


    #3.2. Si no existe la carpeta no reservada del sistema, intentar crearlo ...

    #El owner del folder a crear dependera de la ubicacion de este
    if [ $l_folder_is_targethome -eq 0 ]; then

        #El owner es el usuario efectivo
        _g_lnx_base_owner="$g_targethome_owner"
        _g_lnx_base_group="$g_targethome_group"
        _g_lnx_base_options=$(( _g_lnx_base_options + 1 ))
        if [ "$g_targethome_owner" = "root" ]; then
            _g_lnx_base_options=$(( _g_lnx_base_options + 2 ))
        fi

    else

        #El owner es el root
        _g_lnx_base_owner="root"
        _g_lnx_base_group="root"
        if [ "$g_targethome_owner" = "root" ]; then
            _g_lnx_base_options=$(( _g_lnx_base_options + 1 ))
        fi
        _g_lnx_base_options=$(( _g_lnx_base_options + 2 ))

    fi

    #Validar que existe el folder padre
    l_aux="${p_lnx_base_path%/*}"
    if [ ! -z "$l_aux" ] && [ ! -d "$l_aux" ]; then
        return 5
    fi

    #A. Si la carpeta a crear esta dentro del home del usuario usuario objetivo
    if [ $l_folder_is_targethome -eq 0 ]; then

        #Crear el folder
        if ! mkdir -pm 755 "$p_lnx_base_path" &> /dev/null; then
            return 7
        fi

        #Creando los subfolderes si no existen
        if [ ! -d "${p_lnx_base_path}/bin" ]; then
            mkdir -pm 755 "${p_lnx_base_path}/bin"
            #Si el runner ejecuta con root en modo de suplantacion del usuario objetivo
            chown "${g_targethome_owner}:${g_targethome_group}" "$p_lnx_base_path/bin"
        fi

        if [ ! -d "${p_lnx_base_path}/share" ]; then
            mkdir -pm 755 "${p_lnx_base_path}/share"
            #Si el runner ejecuta con root en modo de suplantacion del usuario objetivo
            chown "${g_targethome_owner}:${g_targethome_group}" "$p_lnx_base_path/share"
        fi

        if [ ! -d "${p_lnx_base_path}/share/man" ]; then
            mkdir -pm 755 "${p_lnx_base_path}/share/man"
            #Si el runner ejecuta con root en modo de suplantacion del usuario objetivo
            chown "${g_targethome_owner}:${g_targethome_group}" "$p_lnx_base_path/share/man"
        fi

        if [ ! -d "${p_lnx_base_path}/share/fonts" ]; then
            mkdir -pm 755 "${p_lnx_base_path}/share/fonts"
            #Si el runner ejecuta con root en modo de suplantacion del usuario objetivo
            chown "${g_targethome_owner}:${g_targethome_group}" "$p_lnx_base_path/share/fonts"
        fi

        #Aceptar la carpeta enviada
        return 2

    fi


    #B. Si la carpeta a crear estar fuera del home del usuario objetivo (el owner sera root)

    #Se rechaza el folder ingresado, si el usuario runner no tiene permisos para ejecutar como root
    # - El sistema operativo no soporte sudo y el usuario ejecutor no es root.
    # - El sistema operativo soporta sudo y el usario ejecutor no es root y no tiene permiso para sudo.
    if [ $g_runner_sudo_support -eq 3 ] || [ $g_runner_id -ne 0 -a $g_runner_sudo_support -eq 2 ]; then
    #if [ $g_runner_sudo_support -eq 3 ] || { [ $g_runner_id -ne 0 ] && [ $g_runner_sudo_support -eq 2 ]; }; then
        return 6
    fi

    #Crear el folder
    # - Si runner es root (puede estar o no estar en modo suplantacion de usuario objetivo)
    if [ $g_runner_id -eq 0 ]; then

        if ! mkdir -pm 755 "$p_lnx_base_path"; then
            return 7
        fi


        #Creando los subfolderes si no existen
        mkdir -pm 755 "${p_lnx_base_path}/bin"
        mkdir -pm 755 "${p_lnx_base_path}/share"
        mkdir -pm 755 "${p_lnx_base_path}/share/man"
        mkdir -pm 755 "${p_lnx_base_path}/share/fonts"

    # - Si runner NO es root y requiere sudo: sin password
    elif [ $g_runner_sudo_support -eq 1 ]; then

        if ! sudo mkdir -pm 755 "$p_lnx_base_path"; then
            return 7
        fi


        #Creando los subfolderes si no existen
        sudo mkdir -pm 755 "${p_lnx_base_path}/bin"
        sudo mkdir -pm 755 "${p_lnx_base_path}/share"
        sudo mkdir -pm 755 "${p_lnx_base_path}/share/man"
        sudo mkdir -pm 755 "${p_lnx_base_path}/share/fonts"

    # - Si runner NO es root y requiere sudo: con password
    else

        printf 'Se requiere crear la carpeta "%b%s%b" de los comandos con los permisos correctos, para ello se debe usar sudo con root...\n' \
               "$g_color_gray1" "$p_lnx_base_path" "$g_color_reset"

        if ! sudo mkdir -pm 755 "$p_lnx_base_path"; then
            return 7
        fi

        #Creando los subfolderes si no existen
        sudo mkdir -pm 755 "${p_lnx_base_path}/bin"
        sudo mkdir -pm 755 "${p_lnx_base_path}/share"
        sudo mkdir -pm 755 "${p_lnx_base_path}/share/man"
        sudo mkdir -pm 755 "${p_lnx_base_path}/share/fonts"

    fi

    #Aceptar la carpeta enviada
    return 2


}


#
#Establece el ruta de los programas (incluyen mas de 1 comando) 'g_tools_path' a instalar.
#Orden de prioridad:
#  > La carpeta ingresada como parametro 3, siempre que existe y tenga por lo menos permiso de lectura.
#  > Si la carpeta esta en el home de usuario, el usuario debera tener permisos de escritura.
#  > Si la carpeta NO esta en el home de usuario, generalmente el owner sera root, el usuario debera tener permiso de lectura y el usuario debera tener
#    permisos para sudo o ser root.
#Solo se mostrara el log en los reintentos de conseguir la ruta, no se muestra al primer intento.
#Parametros de entrada > Argumentos:
# 1> Flag '0' si no es interactivo, '1' si es interactivo
# 2> Ruta donde se ubicaran los programas descargados
#    Si es vacio, se se usara las carpetas (segun orden de prioridad): '/var/opt/tools', '/opt/tools' o '~/tools'
#Parametros de entrada > Variables globales:
#  > 'g_targethome_path'
#Parametros de salida> Variables globales:
# > 'g_tools_path': la ruta del folder establecido
# > 'g_tools_options' que define caracteristicas del folder obtenido. Su valor puede ser 0 o la suma binario
#    de los siguientes flags:
#       > 00001 (1) - La carpeta de programas tiene como owner al usuario OBJETIVO.
#       > 00010 (2) - La carpeta de programas tiene como owner a root.
#       > 00100 (4) - La carpeta de programas esta en el "target home" (home del usuario OBJETIVO).
#       > 01000 (8) - La carpeta de programas NO es una ruta estandar  (ruta personalizada ingresada por el usuario)
# > 'g_tools_owner' owner del folder de programas ingresado.
# > 'g_tools_group' grupo de acceso del folder de programas ingresado.
#Parametro de salida> Valor de retorno:
#    0> Se establecio la ruta (el owner del home puede instalar programas en dicho folder).
#    1> No se establecio los directorio (no se tiene los permisos correctos para crear o modificar el folder para que el owner del home pueda instalar programas).
function get_tools_path() {

    #1. Argumentos de la funcion
    local p_is_noninteractive=1
    if [ "$1" = "0" ]; then
        p_is_noninteractive=0
    fi

    #2. Obtener el folder a usar en el primer intento
    local l_atttemp_id      #Indica el ID del intento para obtener la carpeta donde se instalaran los programas. Sus valores son:
                            # 3 - Se uso la carpeta personalizado
                            # 2 - Se uso la carpeta por defecto '/var/opt/tools'
                            # 1 - Se uso la carpeta por defecto '/opt/tools'
                            # 0 - Se uso la carpeta por defecto '~/tools'
    local la_additional_attemps=("${g_targethome_path}/tools" '/opt/tools' '/var/opt/tools')

    local l_tools_path="$2"
    if  [ -z "$l_tools_path" ]; then
        if [ -d "/var/opt" ]; then
            l_atttemp_id=2
        elif [ -d "/opt" ]; then
            l_atttemp_id=1
        else
            l_atttemp_id=0
        fi
        l_tools_path="${la_additional_attemps[$l_atttemp_id]}"
    fi

    #3. Realizar el 1er intento
    local l_status=0
    _g_tools_options=0

    #Parametro de salida> Valor de retorno:
    #  > OK (Se establecio o se creo la carpeta existente con los permisos correctos para la instalación de comandos para el usuario objetivo):
    #    00 > La carpeta existe y tiene los permisos necesarios.
    #    01 > La carpeta existe y se modifico los permisos necesarios.
    #    02 > Se creo la carpeta con los permisos necesario para que el usuario
    #  > NO OK (No se ha podido establecer o crear la carpeta con los permisos correctos para la instalación de comandos para el usuario objetivo):
    #    03 > La carpeta existe pero tiene como owner a un usuario diferente del usuario OBJETIVO o del usuario root.
    #    04 > La carpeta existe pero no se puede establer los permisos necesarios.
    #    05 > La carpeta no existe pero no se puede crear porque la carpeta padre no existe.
    #    06 > La carpeta no existe y pero no se tiene los permisos correctos para crearlo.
    #    07 > La carpeta no existe y pero ocurrio un error al crearlo.
    _try_fix_tools_path "$l_tools_path"
    l_status=$?

    #1er intento: OK> Se tiene los permisos correctos
    if [ $l_status -ge 0 ] && [ $l_status -le 2 ]; then
        g_tools_path="$l_tools_path"
        g_tools_options=$_g_tools_options
        g_tools_owner="$_g_tools_owner"
        g_tools_group="$_g_tools_group"
        return 0
    fi

    local l_aux=''
    #Obtener el identificador del intento, si aun no se ha obtenida (el argumento enviado por el usuario, tambien puede ser una carpeta por defecto)
    if  [ -z "$l_atttemp_id" ]; then
        if [ $(( _g_tools_options & 8 )) -eq 8 ]; then
            #Si se realizo el intento en la carpeta personalizada
            la_additional_attemps[3]="$l_tools_path"
            l_atttemp_id=3
        elif [ "$l_tools_path" = "${la_additional_attemps[2]}" ]; then
            l_atttemp_id=2
        elif [ "$l_tools_path" = "${la_additional_attemps[1]}" ]; then
            l_atttemp_id=1
        else
            l_atttemp_id=0
        fi
    fi

    #Mostrar lo log del intento fallido (si no es el ultimo posible)
    if [ $l_atttemp_id -eq 0 ]; then
        return 1
    fi


    # - Si la carpeta existe, pero no tiene el owner correcto.
    if [ $l_status -eq 3 ]; then
        printf 'La carpeta "%b%s%b" existe pero NO tiene como owner al usuario objetivo "%b%s%b" ni a "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
               "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
               "$g_color_gray1" "root" "$g_color_reset" "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
    fi

    # - Si la carpeta existe pero no se podido establecer los permisos.
    if [ $l_status -eq 4 ]; then
        printf 'La carpeta "%b%s%b" existe pero no tiene los permisos para que se instale programa del usuario objetivo "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
               "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
               "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
    fi

    # - La carpeta no existe pero no se puede crear porque la carpeta padre no existe.
    if [ $l_status -eq 5 ]; then
        l_aux="${la_additional_attemps[$l_atttemp_id]}"
        printf 'La carpeta "%b%s%b" no existe pero no puede crear porque la carpeta "%b%s%b" padre no existe. Se intentara con la carpeta "%b%s%b"...\n' \
               "$g_color_gray1" "$l_aux" "$g_color_reset" "$g_color_gray1" "${l_aux%/*}" "$g_color_reset" \
               "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
    fi

    # - La carpeta no existe y pero no se tiene los permisos correctos para crearlo.
    if [ $l_status -eq 6 ]; then
        printf 'La carpeta "%b%s%b" no existe pero no tiene los permisos para crearlo con los permisos para instalar programas del usuario objetivo "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
               "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
               "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
    fi

    # - La carpeta no existe y pero ocurrio un error al crearlo.
    if [ $l_status -ge 7 ]; then
        printf 'Ocurrio un error al crear la carpeta "%b%s%b" con los permisos para instalar programas del usuario objetivo "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
               "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
               "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
    fi

    #Decrementar el intento realizado
    ((l_atttemp_id= l_atttemp_id - 1))

    #4. Realizar el intento del folder '/var/opt/tools' (ID=2)
    if [ $l_atttemp_id -eq 2 ]; then

        #Parametro de salida> Valor de retorno:
        #  > OK (Se establecio o se creo la carpeta existente con los permisos correctos para la instalación de comandos para el usuario objetivo):
        #    00 > La carpeta existe y tiene los permisos necesarios.
        #    01 > La carpeta existe y se modifico los permisos necesarios.
        #    02 > Se creo la carpeta con los permisos necesario para que el usuario
        #  > NO OK (No se ha podido establecer o crear la carpeta con los permisos correctos para la instalación de comandos para el usuario objetivo):
        #    03 > La carpeta existe pero tiene como owner a un usuario diferente del usuario OBJETIVO o del usuario root.
        #    04 > La carpeta existe pero no se puede establer los permisos necesarios.
        #    05 > La carpeta no existe pero no se puede crear porque la carpeta padre no existe.
        #    06 > La carpeta no existe y pero no se tiene los permisos correctos para crearlo.
        #    07 > La carpeta no existe y pero ocurrio un error al crearlo.
        _try_fix_tools_path "${la_additional_attemps[$l_atttemp_id]}"
        l_status=$?

        #Intento del folder '/var/opt/tools': OK> Se tiene los permisos correctos
        if [ $l_status -ge 0 ] && [ $l_status -le 2 ]; then
            g_tools_path="${la_additional_attemps[$l_atttemp_id]}"
            g_tools_options=$_g_tools_options
            g_tools_owner="$_g_tools_owner"
            g_tools_group="$_g_tools_group"
            return 0
        fi

        # - Si la carpeta existe, pero no tiene el owner correcto.
        if [ $l_status -eq 3 ]; then
            printf 'La carpeta "%b%s%b" existe pero NO tiene como owner al usuario objetivo "%b%s%b" ni a "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
                   "$g_color_gray1" "root" "$g_color_reset" "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
        fi

        # - Si la carpeta existe pero no se podido establecer los permisos.
        if [ $l_status -eq 4 ]; then
            printf 'La carpeta "%b%s%b" existe pero no tiene los permisos para que se instale programa del usuario objetivo "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
                   "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
        fi

        # - La carpeta no existe pero no se puede crear porque la carpeta padre no existe.
        if [ $l_status -eq 5 ]; then
            l_aux="${la_additional_attemps[$l_atttemp_id]}"
            printf 'La carpeta "%b%s%b" no existe pero no puede crear porque la carpeta "%b%s%b" padre no existe. Se intentara con la carpeta "%b%s%b"...\n' \
                   "$g_color_gray1" "$l_aux" "$g_color_reset" "$g_color_gray1" "${l_aux%/*}" "$g_color_reset" \
                   "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
        fi

        # - La carpeta no existe y pero no se tiene los permisos correctos para crearlo.
        if [ $l_status -eq 6 ]; then
            printf 'La carpeta "%b%s%b" no existe pero no tiene los permisos para crearlo con los permisos para instalar programas del usuario objetivo "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
                   "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
        fi

        # - La carpeta no existe y pero ocurrio un error al crearlo.
        if [ $l_status -ge 7 ]; then
            printf 'Ocurrio un error al crear la carpeta "%b%s%b" con los permisos para instalar programas del usuario objetivo "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
                   "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
        fi


        #Decrementar el intento realizado
        ((l_atttemp_id= l_atttemp_id - 1))

    fi

    #5. Realizar el intento del folder '/var/tools' (ID=1)
    if [ $l_atttemp_id -eq 1 ]; then

        _try_fix_tools_path "${la_additional_attemps[$l_atttemp_id]}"
        l_status=$?

        #Intento del folder '/var/tools': OK> Se tiene los permisos correctos
        if [ $l_status -ge 0 ] && [ $l_status -le 2 ]; then
            g_tools_path="${la_additional_attemps[$l_atttemp_id]}"
            g_tools_options=$_g_tools_options
            g_tools_owner="$_g_tools_owner"
            g_tools_group="$_g_tools_group"
            return 0
        fi

        # - Si la carpeta existe, pero no tiene el owner correcto.
        if [ $l_status -eq 3 ]; then
            printf 'La carpeta "%b%s%b" existe pero NO tiene como owner al usuario objetivo "%b%s%b" ni a "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
                   "$g_color_gray1" "root" "$g_color_reset" "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
        fi

        # - Si la carpeta existe pero no se podido establecer los permisos.
        if [ $l_status -eq 4 ]; then
            printf 'La carpeta "%b%s%b" existe pero no tiene los permisos para que se instale programa del usuario objetivo "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
                   "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
        fi

        # - La carpeta no existe pero no se puede crear porque la carpeta padre no existe.
        if [ $l_status -eq 5 ]; then
            l_aux="${la_additional_attemps[$l_atttemp_id]}"
            printf 'La carpeta "%b%s%b" no existe pero no puede crear porque la carpeta "%b%s%b" padre no existe. Se intentara con la carpeta "%b%s%b"...\n' \
                   "$g_color_gray1" "$l_aux" "$g_color_reset" "$g_color_gray1" "${l_aux%/*}" "$g_color_reset" \
                   "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
        fi

        # - La carpeta no existe y pero no se tiene los permisos correctos para crearlo.
        if [ $l_status -eq 6 ]; then
            printf 'La carpeta "%b%s%b" no existe pero no tiene los permisos para crearlo con los permisos para instalar programas del usuario objetivo "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
                   "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
        fi

        # - La carpeta no existe y pero ocurrio un error al crearlo.
        if [ $l_status -ge 7 ]; then
            printf 'Ocurrio un error al crear la carpeta "%b%s%b" con los permisos para instalar programas del usuario objetivo "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
                   "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
        fi

        #Decrementar el intento realizado
        ((l_atttemp_id= l_atttemp_id - 1))

    fi


    #6. Realizar el intento del folder '~/tools' (ID=0)
    if [ $l_atttemp_id -eq 0 ]; then

        #Parametro de salida> Valor de retorno:
        #  > OK (Se establecio o se creo la carpeta existente con los permisos correctos para la instalación de comandos para el usuario objetivo):
        #    00 > La carpeta existe y tiene los permisos necesarios.
        #    01 > La carpeta existe y se modifico los permisos necesarios.
        #    02 > Se creo la carpeta con los permisos necesario para que el usuario
        #  > NO OK (No se ha podido establecer o crear la carpeta con los permisos correctos para la instalación de comandos para el usuario objetivo):
        #    03 > La carpeta existe pero tiene como owner a un usuario diferente del usuario OBJETIVO o del usuario root.
        #    04 > La carpeta existe pero no se puede establer los permisos necesarios.
        #    05 > La carpeta no existe pero no se puede crear porque la carpeta padre no existe.
        #    06 > La carpeta no existe y pero no se tiene los permisos correctos para crearlo.
        #    07 > La carpeta no existe y pero ocurrio un error al crearlo.
        _try_fix_tools_path "${la_additional_attemps[$l_atttemp_id]}"
        l_status=$?

        #Intento del folder '~/tools': OK> Se tiene los permisos correctos
        if [ $l_status -ge 0 ] && [ $l_status -le 2 ]; then
            g_tools_path="${la_additional_attemps[$l_atttemp_id]}"
            g_tools_options=$_g_tools_options
            g_tools_owner="$_g_tools_owner"
            g_tools_group="$_g_tools_group"
            return 0
        fi

        # - Si la carpeta existe, pero no tiene el owner correcto.
        if [ $l_status -eq 3 ]; then
            printf 'La carpeta "%b%s%b" existe pero NO tiene como owner al usuario objetivo "%b%s%b" ni a "%b%s%b".\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
                   "$g_color_gray1" "root" "$g_color_reset"
        fi

        # - Si la carpeta existe pero no se podido establecer los permisos.
        if [ $l_status -eq 4 ]; then
            printf 'La carpeta "%b%s%b" existe pero no tiene los permisos para que se instale programa del usuario objetivo "%b%s%b".\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset"
        fi

        # - La carpeta no existe pero no se puede crear porque la carpeta padre no existe.
        if [ $l_status -eq 5 ]; then
            l_aux="${la_additional_attemps[$l_atttemp_id]}"
            printf 'La carpeta "%b%s%b" no existe pero no puede crear porque la carpeta "%b%s%b" padre no existe.\n' \
                   "$g_color_gray1" "$l_aux" "$g_color_reset" "$g_color_gray1" "${l_aux%/*}" "$g_color_reset"
        fi

        # - La carpeta no existe y pero no se tiene los permisos correctos para crearlo.
        if [ $l_status -eq 6 ]; then
            printf 'La carpeta "%b%s%b" no existe pero no tiene los permisos para crearlo con los permisos para instalar programas del usuario objetivo "%b%s%b".\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset"
        fi

        # - La carpeta no existe y pero ocurrio un error al crearlo.
        if [ $l_status -ge 7 ]; then
            printf 'Ocurrio un error al crear la carpeta "%b%s%b" con los permisos para instalar programas del usuario objetivo "%b%s%b".\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset"
        fi


        #Decrementar el intento realizado
        #((l_atttemp_id= l_atttemp_id - 1))

    fi


    #Si no hay mas intentos
    return 1

}


#
#Establece la ruta de los comandos del binario/man/fuente, es decir 'g_lnx_bin_path'/'g_lnx_man_path'/'g_lnx_fonts_path'/'g_lnx_base_path', donde se instalará.
#Orden de prioridad:
#  > La carpeta ingresada como parametro 3, siempre que existe,
#  > La carpeta predeterminado del sistema ('/usr/local/bin', '/usr/local/share/man', '/usr/local/share/fonts' y '/usr/local/share/icons'), si existe tenga
#    permisos como root o sudo para root.
#  > La carpeta predeterminado para el usuario ubicada en '~/.local', si en las carpeta anterior no tiene permisos de root o sudo para root.
#  > Si la carpeta esta en el home de usuario, el usuario debera tener permisos de escritura.
#  > Si la carpeta NO esta en el home de usuario, generalmente el owner sera root, el usuario debera tener permiso de lectura y el usuario debera tener
#    permisos para sudo o ser root.
#Parametros de entrada > Argumentos:
# 1> Flag '0' si no es interactivo, '1' si es interactivo
# 2> Ruta base personalizada donde se ubicaran los comandos descargado, las cuales tendran, la siguiente estructura de carpetas:
#      > Binarios   : LNX_BASE_PATH/bin
#      > Ayuda man  : LNX_BASE_PATH/share/man/man1, LNX_BASE_PATH/share/man/man5, LNX_BASE_PATH/share/man/man7
#      > Fuentes    : LNX_BASE_PATH/share/fonts
#      > Imagenes   : LNX_BASE_PATH/share/icons
#    Si es vacio, no se se usara las carpetas predeterminados
#Parametros de entrada > Variables globales:
#  > 'g_targethome_path'
#Parametros de salida > Variables globales:
#  > 'g_lnx_base_path' siempre es vacio cuando se usa la ruta predeterminado del sistema (para todos los usuario)
#  > 'g_lnx_bin_path', 'g_lnx_man_path', 'g_lnx_fonts_path'
#  > 'g_lnx_base_options' que define caracteristicas del folder obtenido. Su valor puede ser 0 o la suma binario
#    de los siguientes flags:
#       > 00001 (1) - La carpeta de comandos tiene como owner al usuario OBJETIVO.
#       > 00010 (2) - La carpeta de comandos tiene como owner a root.
#       > 00100 (4) - La carpeta de comandos esta en el "target home" (home del usuario OBJETIVO).
#       > 01000 (8) - La carpeta de comandos NO es del sistema ni '~/.local'.
#    Solo se debe usar cuando se pudo generar una ruta de folder para los programas (valor de retorno 0).
#  > 'g_lnx_base_owner' owner del folder base de los comandos ingresado.
#  > 'g_lnx_base_group' grupo de acceso del folder base de comandos ingresado.
#Parametros de salida > Valor de retorno
#  0> Se establecio la ruta (el owner del home puede instalar programas en dicho folder).
#  1> No se establecio los directorio (no se tiene los permisos correctos para crear o modificar el folder para que el owner del home pueda instalar programas).
function g_lnx_paths() {

    #1. Argumentos
    local p_is_noninteractive=1
    if [ "$1" = "0" ]; then
        p_is_noninteractive=0
    fi

    #2. Obtener el folder a usar en el primer intento
    local l_lnx_base_path="$2"
    local l_atttemp_id      #Indica el ID del intento para obtener la carpeta donde se instalaran los comandos, fuentes y archivos de ayuda.
                            #Sus valores son:
                            # 2 - Se uso la carpeta personalizado
                            # 1 - Se uso la carpeta por defecto del sistema para todos lo usuaris
                            # 0 - Se uso la carpeta por defecto '~/.local'
    local la_additional_attemps=("${g_targethome_path}/.local" '/usr/local')

    #3. Realizar el 1er intento
    local l_status=0
    _g_lnx_base_options=0

    #Parametro de salida> Valor de retorno:
    #  > OK (Se establecio o se creo la carpeta existente con los permisos correctos para la instalación de comandos para el usuario objetivo):
    #    00 > La carpeta existe y tiene los permisos necesarios.
    #    01 > La carpeta existe y se modifico los permisos necesarios.
    #    02 > Se creo la carpeta con los permisos necesario para que el usuario
    #  > NO OK (No se ha podido establecer o crear la carpeta con los permisos correctos para la instalación de comandos para el usuario objetivo):
    #    03 > La carpeta existe pero tiene como owner a un usuario diferente del usuario OBJETIVO o del usuario root.
    #    04 > La carpeta existe pero no se puede establer los permisos necesarios.
    #    05 > La carpeta no existe pero no se puede crear porque la carpeta padre no existe.
    #    06 > La carpeta no existe y pero no se tiene los permisos correctos para crearlo.
    #    07 > La carpeta no existe y pero ocurrio un error al crearlo.
    _try_fix_lnx_base_path "$l_lnx_base_path"
    l_status=$?

    #1er intento: OK> Se tiene los permisos correctos
    if [ $l_status -ge 0 ] && [ $l_status -le 2 ]; then
        if [ -z "$l_lnx_base_path" ]; then
            g_lnx_base_path="/usr/local"
            g_lnx_bin_path="/usr/local/bin"
            g_lnx_man_path="/usr/local/share/man"
            g_lnx_fonts_path="/usr/local/share/fonts"
            g_lnx_icons_path="/usr/local/share/icons"
        else
            g_lnx_base_path="$l_lnx_base_path"
            g_lnx_bin_path="${g_lnx_base_path}/bin"
            g_lnx_man_path="${g_lnx_base_path}/share/man"
            g_lnx_fonts_path="${g_lnx_base_path}/share/fonts"
            g_lnx_icons_path="${g_lnx_base_path}/share/icons"
        fi
        g_lnx_base_options=$_g_lnx_base_options
        g_lnx_base_owner="$_g_lnx_base_owner"
        g_lnx_base_group="$_g_lnx_base_group"
        return 0
    fi

    #Obtener el identificador del intento, si aun no se ha obtenida (el argumento enviado por el usuario, tambien puede ser una carpeta por defecto)
    if [ $(( _g_lnx_base_options & 8 )) -eq 8 ]; then
        #Si se realizo el intento en la carpeta personalizada
        l_atttemp_id=2
        la_additional_attemps[2]="$l_lnx_base_path"
    elif [ -z "$l_lnx_base_path" ]; then
        l_atttemp_id=1
    else
        l_atttemp_id=0
    fi

    #Mostrar lo log del intento fallido (si no es el ultimo posible)
    if [ $l_atttemp_id -eq 0 ]; then
        return 1
    fi

    local l_aux=''
    # - Si la carpeta existe, pero no tiene el owner correcto.
    if [ $l_status -eq 3 ]; then
        printf 'La carpeta "%b%s%b" existe pero NO tiene como owner al usuario objetivo "%b%s%b" ni a "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
               "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
               "$g_color_gray1" "root" "$g_color_reset" "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
    fi

    # - Si la carpeta existe pero no se podido establecer los permisos.
    if [ $l_status -eq 4 ]; then
        printf 'La carpeta "%b%s%b" existe pero no tiene los permisos para que se instale comandos del usuario objetivo "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
               "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
               "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
    fi

    # - La carpeta no existe pero no se puede crear porque la carpeta padre no existe.
    if [ $l_status -eq 5 ]; then
        l_aux="${la_additional_attemps[$l_atttemp_id]}"
        printf 'La carpeta "%b%s%b" no existe pero no puede crear porque la carpeta "%b%s%b" padre no existe. Se intentara con la carpeta "%b%s%b"...\n' \
               "$g_color_gray1" "$l_aux" "$g_color_reset" "$g_color_gray1" "${l_aux%/*}" "$g_color_reset" \
               "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
    fi

    # - La carpeta no existe y pero no se tiene los permisos correctos para crearlo.
    if [ $l_status -eq 6 ]; then
        printf 'La carpeta "%b%s%b" no existe pero no tiene los permisos para crearlo con los permisos para instalar comandos del usuario objetivo "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
               "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
               "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
    fi

    # - La carpeta no existe y pero ocurrio un error al crearlo.
    if [ $l_status -ge 7 ]; then
        printf 'Ocurrio un error al crear la carpeta "%b%s%b" con los permisos para instalar comandos del usuario objetivo "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
               "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
               "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
    fi


    #Decrementar el intento realizado
    ((l_atttemp_id= l_atttemp_id - 1))

    #4. Realizar el intento del folder del sistema (ID=1)
    if [ $l_atttemp_id -eq 1 ]; then

       #Parametro de salida> Valor de retorno:
       #  > OK (Se establecio o se creo la carpeta existente con los permisos correctos para la instalación de comandos para el usuario objetivo):
       #    00 > La carpeta existe y tiene los permisos necesarios.
       #    01 > La carpeta existe y se modifico los permisos necesarios.
       #    02 > Se creo la carpeta con los permisos necesario para que el usuario
       #  > NO OK (No se ha podido establecer o crear la carpeta con los permisos correctos para la instalación de comandos para el usuario objetivo):
       #    03 > La carpeta existe pero tiene como owner a un usuario diferente del usuario OBJETIVO o del usuario root.
       #    04 > La carpeta existe pero no se puede establer los permisos necesarios.
       #    05 > La carpeta no existe pero no se puede crear porque la carpeta padre no existe.
       #    06 > La carpeta no existe y pero no se tiene los permisos correctos para crearlo.
       #    07 > La carpeta no existe y pero ocurrio un error al crearlo.
        _try_fix_lnx_base_path ""
        l_status=$?

        #Intento del folder del sistema: OK> Se tiene los permisos correctos
        if [ $l_status -ge 0 ] && [ $l_status -le 2 ]; then
            g_lnx_base_path="/usr/local"
            g_lnx_bin_path="/usr/local/bin"
            g_lnx_man_path="/usr/local/share/man"
            g_lnx_fonts_path="/usr/local/share/fonts"
            g_lnx_icons_path="/usr/local/share/icons"
            g_lnx_base_options=$_g_lnx_base_options
            g_lnx_base_owner="$_g_lnx_base_owner"
            g_lnx_base_group="$_g_lnx_base_group"
            return 0
        fi

        # - Si la carpeta existe, pero no tiene el owner correcto.
        if [ $l_status -eq 3 ]; then
            printf 'La carpeta "%b%s%b" existe pero NO tiene como owner al usuario objetivo "%b%s%b" ni a "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
                   "$g_color_gray1" "root" "$g_color_reset" "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
        fi

        # - Si la carpeta existe pero no se podido establecer los permisos.
        if [ $l_status -eq 4 ]; then
            printf 'La carpeta "%b%s%b" existe pero no tiene los permisos para que se instale comandos del usuario objetivo "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
                   "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
        fi

        # - La carpeta no existe pero no se puede crear porque la carpeta padre no existe.
        if [ $l_status -eq 5 ]; then
            l_aux="${la_additional_attemps[$l_atttemp_id]}"
            printf 'La carpeta "%b%s%b" no existe pero no puede crear porque la carpeta "%b%s%b" padre no existe. Se intentara con la carpeta "%b%s%b"...\n' \
                   "$g_color_gray1" "$l_aux" "$g_color_reset" "$g_color_gray1" "${l_aux%/*}" "$g_color_reset" \
                   "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
        fi

        # - La carpeta no existe y pero no se tiene los permisos correctos para crearlo.
        if [ $l_status -eq 6 ]; then
            printf 'La carpeta "%b%s%b" no existe pero no tiene los permisos para crearlo con los permisos para instalar comandos del usuario objetivo "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
                   "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
        fi

        # - La carpeta no existe y pero ocurrio un error al crearlo.
        if [ $l_status -ge 7 ]; then
            printf 'Ocurrio un error al crear la carpeta "%b%s%b" con los permisos para instalar comandos del usuario objetivo "%b%s%b". Se intentara con la carpeta "%b%s%b"...\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
                   "$g_color_gray1" "${la_additional_attemps[$((l_atttemp_id - 1))]}" "$g_color_reset"
        fi


        #Decrementar el intento realizado
        ((l_atttemp_id= l_atttemp_id - 1))

    fi


    #5. Realizar el intento del folder '~/tools' (ID=0)
    if [ $l_atttemp_id -eq 0 ]; then

       #Parametro de salida> Valor de retorno:
       #  > OK (Se establecio o se creo la carpeta existente con los permisos correctos para la instalación de comandos para el usuario objetivo):
       #    00 > La carpeta existe y tiene los permisos necesarios.
       #    01 > La carpeta existe y se modifico los permisos necesarios.
       #    02 > Se creo la carpeta con los permisos necesario para que el usuario
       #  > NO OK (No se ha podido establecer o crear la carpeta con los permisos correctos para la instalación de comandos para el usuario objetivo):
       #    03 > La carpeta existe pero tiene como owner a un usuario diferente del usuario OBJETIVO o del usuario root.
       #    04 > La carpeta existe pero no se puede establer los permisos necesarios.
       #    05 > La carpeta no existe pero no se puede crear porque la carpeta padre no existe.
       #    06 > La carpeta no existe y pero no se tiene los permisos correctos para crearlo.
       #    07 > La carpeta no existe y pero ocurrio un error al crearlo.
        _try_fix_lnx_base_path "${la_additional_attemps[$l_atttemp_id]}"
        l_status=$?

        #Intento del folder '~/.local': OK> Se tiene los permisos correctos
        if [ $l_status -ge 0 ] && [ $l_status -le 2 ]; then
            g_lnx_base_path="${la_additional_attemps[$l_atttemp_id]}"
            g_lnx_bin_path="${g_lnx_base_path}/bin"
            g_lnx_man_path="${g_lnx_base_path}/share/man"
            g_lnx_fonts_path="${g_lnx_base_path}/share/fonts"
            g_lnx_icons_path="${g_lnx_base_path}/share/icons"
            g_lnx_base_options=$_g_lnx_base_options
            g_lnx_base_owner="$_g_lnx_base_owner"
            g_lnx_base_group="$_g_lnx_base_group"
            return 0
        fi

        # - Si la carpeta existe, pero no tiene el owner correcto.
        if [ $l_status -eq 3 ]; then
            printf 'La carpeta "%b%s%b" existe pero NO tiene como owner al usuario objetivo "%b%s%b" ni a "%b%s%b".\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset" \
                   "$g_color_gray1" "root" "$g_color_reset"
        fi

        # - Si la carpeta existe pero no se podido establecer los permisos.
        if [ $l_status -eq 4 ]; then
            printf 'La carpeta "%b%s%b" existe pero no tiene los permisos para que se instale comandos del usuario objetivo "%b%s%b".\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset"
        fi

        # - La carpeta no existe pero no se puede crear porque la carpeta padre no existe.
        if [ $l_status -eq 5 ]; then
            l_aux="${la_additional_attemps[$l_atttemp_id]}"
            printf 'La carpeta "%b%s%b" no existe pero no puede crear porque la carpeta "%b%s%b" padre no existe.\n' \
                   "$g_color_gray1" "$l_aux" "$g_color_reset" "$g_color_gray1" "${l_aux%/*}" "$g_color_reset"
        fi

        # - La carpeta no existe y pero no se tiene los permisos correctos para crearlo.
        if [ $l_status -eq 6 ]; then
            printf 'La carpeta "%b%s%b" no existe pero no tiene los permisos para crearlo con los permisos para instalar comandos del usuario objetivo "%b%s%b".\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset"
        fi

        # - La carpeta no existe y pero ocurrio un error al crearlo.
        if [ $l_status -ge 7 ]; then
            printf 'Ocurrio un error al crear la carpeta "%b%s%b" con los permisos para instalar comandos del usuario objetivo "%b%s%b".\n' \
                   "$g_color_gray1" "${la_additional_attemps[$l_atttemp_id]}" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset"
        fi

        #Decrementar el intento realizado
        #((l_atttemp_id= l_atttemp_id - 1))

    fi


    #Si no hay mas intentos
    return 1

}



#
#Establece la ruta de los archivos temporales, es decir 'g_temp_path', donde se descargaran archivos comprimidos del repositorio externos (como GitHub).
#Orden de prioridad:
#  > La carpeta ingresada como parametro 1, siempre que existe y el usuario de ejecución tiene permisos de escritura.
#  > La carpeta predeterminado para el usuario '/tmp', si en las carpeta anterior no tiene permisos de root o sudo para root.
#El usuario runner siempre debe tener permiso de escritura en esta carpeta.
#Parametros de entrada:
# 1> Ruta base donde se ubicaran los archivo temporales. Si es vacio, no se se usara la carpeta predeterminado '/tmp'.
#Parametros de salida:
#  > Variables globales: 'g_temp_path'
#  > Valor de retorno
#    0> Se establecio la ruta y la ruta es la enviada por el usuario.
#    1> Se establecio la ruta y la ruta es la predeterminado para todos los usuarios ('/var/tmp').
#    2> Se establecio la ruta y la ruta es la predeterminado para todos los usuarios ('/tmp'). Usarla con moderacion,
#       en muchas distribuciones es un filesystem que esta en la memoria y tiene un tamaño limitado.
function get_temp_path() {

    local p_path_temp="$1"

    #1. Usar el directorio personalizado del usuario (siempre que existe y tienes acceso de escritura)
    if [ ! -z "$p_path_temp" ] && [ -d "$p_path_temp" ] && [ -w "$p_path_temp" ]; then
        g_temp_path="$p_path_temp"
        return 0
    fi

    #2. Usar la carpeta predeterminado '/tmp'.
    if [ -d "/var/tmp" ] && [ -w "/var/tmp" ]; then
        g_temp_path="/var/tmp"
        return 1
    fi

    #3. Usar la carpeta predeterminado '/tmp'.
    g_temp_path="/tmp"
    return 2

}



#Parametros de entrada - Agumentos y opciones:
#  1 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
#  2 > Flag '0' si se requere curl
#  3 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
#Retorno:
#  0 - Se tiene los programas necesarios para iniciar la configuración
#  1 - No se tiene los programas necesarios para iniciar la configuración
function fulfill_preconditions() {

    #Argumentos
    local p_show_additional_info=1
    if [ "$1" = "0" ]; then
        p_show_additional_info=0
    fi

    local p_require_curl=1
    if [ "$2" = "0" ]; then
        p_require_curl=0
    fi

    local p_require_root=1
    if [ "$3" = "0" ]; then
        p_require_root=0
    fi



    #2. Validar el SO
    if [ -z "$g_os_type" ]; then
        printf 'No es definido el tipo de SO\n' "$g_os_subtype_id"
        return 1
    fi

    if [ -z "$g_os_subtype_id" ]; then
        printf 'No es definido el tipo de distribucion Linux\n' "$g_os_subtype_id"
        return 1
    fi

    if [ $g_os_type -ne 0 ] && [ $g_os_type -ne 1 ]; then
        printf 'No esta implementado para el tipo SO "%s"\n' "$g_os_subtype_id"
        return 1
    fi

    #Actualmente solo esta habilitado para distribucion de la familia Alpine, Debian y Fedora.
    #if [ $g_os_subtype_id -lt 10 ] || [ $g_os_subtype_id -ge 70 ]; then
    if [ $g_os_subtype_id -lt 0 ] || [ $g_os_subtype_id -ge 70 ]; then
        printf 'No esta implementado para SO Linux de tipo "%s"\n' "$g_os_subtype_id"
        return 1
    fi

    #3. Validar la arquitectura de procesador
    if [ ! "$g_os_architecture_type" = "x86_64" ] && [ ! "$g_os_architecture_type" = "aarch64" ]; then
        printf 'No esta implementado para la arquitectura de procesador "%s"\n' "$g_os_architecture_type"
        return 1
    fi

    #6. Validar si existe los folderes de Windows sobre WSL
    if [ $g_os_type -eq 1 ] && [ ! -z "$g_win_tools_path" ] && [ ! -d "$g_win_tools_path" ]; then
        mkdir -p "$g_win_tools_path"
        mkdir -p "$g_win_bin_path"
        mkdir -p "$g_win_etc_path"
        mkdir -p "$g_win_docs_path"
        mkdir -p "$g_win_fonts_path"
    fi

    #7. El programa instalados: ¿Esta 'curl' instalado?
    local l_curl_version
    if [ $p_require_curl -eq 0 ]; then
        l_curl_version=$(curl --version 2> /dev/null)
        if [ -z "$l_curl_version" ]; then

            printf '\nERROR: CURL no esta instalado, debe instalarlo para descargar los artefactos a instalar/actualizar.\n'
            printf '%bBinarios: https://curl.se/download.html\n' "$g_color_gray1"
            printf 'Paquete Ubuntu/Debian:\n'
            printf '          apt-get install curl\n'
            printf 'Paquete CentOS/Fedora:\n'
            printf '          dnf install curl\n%b' "$g_color_reset"

            return 1
        fi
    fi

    #8. Lo que se instalar requiere permisos de root.
    if [ $p_require_root -eq 0 ] && [ $g_runner_id -ne 0 ]; then
        if [ $g_runner_sudo_support -eq 3 ] || [ $g_runner_id -ne 0 -a  $g_runner_sudo_support -eq 2 ]; then
            #Se rechazar el folder ingresado, si el usuario runner no tiene permisos para ejecutar como root
            # - El sistema operativo no soporte sudo y el usuario ejecutor no es root.
            # - El sistema operativo soporta sudo y el usario ejecutor no es root y no tiene permiso para sudo.
            printf 'ERROR: el usuario runner (Name="%b%s%b", ID="%b%s%b") no es root o tiene permisos para ejecutar sudo (SudoSupport="").\n' \
                   "$g_color_gray1" "$g_runner_user" "$g_color_reset" "$g_color_gray1" "$g_runner_id" "$g_color_reset" "$g_color_gray1" \
                   "$g_runner_sudo_support" "$g_color_reset"
            return 1
        fi
    fi

    #9. Mostar información adicional (Solo mostrar info adicional si la ejecución es interactiva)
    if [ $p_show_additional_info -eq 0 ]; then

        printf '%bDistribution Name     : "%s" (Id= "%s")\n' "$g_color_gray1" "${g_os_subtype_name}" "${g_os_subtype_id}"
        printf 'Distribution Version  : "%s" (PrettyVersion= "%s") (Id= "%s")\n' "$g_os_subtype_version" "$g_os_subtype_version_pretty" "${g_os_subtype_id}"
        printf 'Processor Type        : "%s"\n' "$g_os_architecture_type"

        local l_aux=''
        if [ $g_runner_id -ne 0 ]; then
            if [ $g_runner_sudo_support -eq 0 ]; then
                l_aux="(Sudo with password)"
            elif [ $g_runner_sudo_support -eq 1 ]; then
                l_aux="(Sudo without password)"
            elif [ $g_runner_sudo_support -eq 2 ]; then
                l_aux="(OS not support sudo)"
            elif [ $g_runner_sudo_support -eq 3 ]; then
                l_aux="(No access to run sudo)"
            else
                l_aux="(Don't need sudo)"
            fi
        fi

        printf 'Runner                : "%s" (UID= "%s") %s\n' "$g_runner_user" "$g_runner_id" "$l_aux"

        if [ ! -z "$g_targethome_owner" ]; then
            printf 'Target user           : "%s" (Home= "%s") (Repository= "%s") (Group= "%s")\n' "$g_targethome_owner" "$g_targethome_path" "$g_repo_name" \
                   "$g_targethome_group"
        fi

        if [ ! -z "$g_tools_path" ]; then
            printf 'Tools path            : "%s" (Owner= "%s") (Group= "%s")' "$g_tools_path" "$g_tools_owner" "$g_tools_group"

            if [ "$g_setup_only_last_version" = "0" ]; then
                printf ' (SetupOnlyLastVersion= "true")'
            else
                printf ' (SetupOnlyLastVersion= "false")'
            fi

            if [ $g_os_type -eq 1 ] && [ ! -z "$g_win_tools_path" ]; then
                printf ' (Windows= "%s")' "$g_win_tools_path"
            fi

            printf '\n'

        fi

        if [ ! -z "$g_lnx_bin_path" ]; then
            printf 'Linux base path       : "%s" (Bin= "%s") (Owner= "%s") (Group= "%s")' "$g_lnx_base_path" "$g_lnx_bin_path" \
                   "$g_tools_owner" "$g_tools_group"
            if [ $g_os_type -eq 1 ] && [ ! -z "$g_win_bin_path" ]; then
                printf ' (Windows= "%s")\n' "$g_win_bin_path"
            else
                printf '\n'
            fi
        fi

        if [ ! -z "$g_temp_path" ]; then
            printf 'Temporary data path   : "%s"\n' "$g_temp_path"
        fi


        if [ $p_require_curl -eq 0 ]; then
            l_curl_version=$(echo "$l_curl_version" | head -n 1 | sed "$g_regexp_sust_version1")
            printf '%bCURL version          : "%s"%b\n' "$g_color_gray1" "$l_curl_version" "$g_color_reset"
        fi

    fi
    return 0

}

# Almacena temporalmente las credenciales del usuario para realizar sudo
# Retorno:
#   0 - Se requiere almacenar credenciales se almaceno las credenciales.
#   1 - NO se requiere almacenar credenciales (es root, el usuario no requiere ingresar las credenciales para sudo).
#   2 - Se requiere almacenar credenciales pero NO se pudo almacenar las credenciales.
#   3 - El usuario no tiene permisos para sudo.
#   4 - El sistema operativo no implementa sudo.
function storage_sudo_credencial() {

    #1. Los casos donde no se requiere almacenar el password

    # > 4 : El usuario es root (no requiere sudo)
    if [ $g_runner_sudo_support -eq 4 ]; then
        return 2
    # > 1 : Soporta el comando sudo sin password
    elif [ $g_runner_sudo_support -eq 1 ]; then
        return 2
    # > 3 : El usuario no tiene permisos para ejecutar sudo
    elif [ $g_runner_sudo_support -eq 3 ]; then
        printf 'El usuario no tiene permiso para ejecutar sudo. %bSolo se va instalar/configurar paquetes/programas que no requieren acceso de "root"%b\n' \
               "$g_color_red1" "$g_color_reset"
        return 3
    # > 2 : El SO no implementa el comando sudo
    elif [ $g_runner_sudo_support -eq 4 ]; then
        printf 'El SO no implementa el comando sudo. %bSolo se va instalar/configurar paquetes/programas que no requieren acceso de "root"%b\n' \
               "$g_color_red1" "$g_color_reset"
        return 4
    fi

    #2. Almacenar el password (si se soporta el comando sudo pero con password)
    sudo -v
    if [ $? -ne 0 ]; then
        printf 'ERROR: Se requiere alamcenar temporalmente su credencial para realizar sudo ("sudo -v")\n\n'
        return 1
    fi
    printf '\n'
    return 0
}


# Elimina (caduca) las credenciales del usuario para realizar sudo
# Retorno:
#   0 - Se elimino las credencial en el storage temporal
#   1 - NO se requiere almacenar las credenciales para sudo
function clean_sudo_credencial() {

    #1. Los casos donde no se requiere almacenar el password

    # > 4 : El usuario es root (no requiere sudo)
    if [ $g_runner_sudo_support -eq 4 ]; then
        return 1
    # > 1 : Soporta el comando sudo sin password
    elif [ $g_runner_sudo_support -eq 1 ]; then
        return 1
    # > 3 : El usuario no tiene permisos para ejecutar sudo
    elif [ $g_runner_sudo_support -eq 3 ]; then
        return 1
    # > 2 : El SO no implementa el comando sudo
    elif [ $g_runner_sudo_support -eq 4 ]; then
        return 1
    fi


    #3. Caducar las credecinales de root almacenadas temporalmente
    printf '\nCaducando el cache de temporal password de su "sudo"\n'
    sudo -k
    return 0
}



#Si la unidad servicio 'containerd' esta iniciado, solicitar su detención y deternerlo
#Parametros de entrada (argumentos y opciones):
#   1 > Nombre completo de la unidad de systemd
#Opcionales:
#   2 > Flag '0' si se usara para desintalar, caso contrario se usara para instalar/actualizar.
#   3 > Flag '0' si no es interactivo, '1' si es interactivo
#   4 > ID del repositorio
#   5 > Indice del artefacto del repositorio que se desea instalar
#Parametros de salida (valor de retorno):
#   0 > La unidad systemd NO esta instalado y NO esta iniciado
#   1 > La unidad systemd esta instalado pero NO esta iniciado (esta detenido)
#   2 > La unidad systemd esta iniciado pero NO se acepto deternerlo
#   3 > La unidad systemd iniciado se acepto detenerlo a nivel usuario
#   4 > La unidad systemd iniciado se acepto detenerlo a nivel system
function request_stop_systemd_unit() {

    #1. Argumentos
    local p_unit_name="$1"

    local p_is_uninstalling=1
    if [ "$2" = "0" ]; then
        p_is_uninstalling=0
    fi

    local p_is_noninteractive=1
    if [ "$3" = "0" ]; then
        p_is_noninteractive=0
    fi

    local p_repo_id="$4"

    local p_artifact_index=-1
    if [[ "$5" =~ ^[0-9]+$ ]]; then
        p_option_relative_idx=$5
    fi

    #2. Averigur el estado actual de la unidad systemd
    local l_option
    local l_status
    local l_is_user=0

    exist_systemd_unit "$p_unit_name" $l_is_user
    l_status=$?   #  1 > La unidad instalada pero aun no esta en cache (no ha sido ejecutada desde el inicio del SO)
                  #  2 > La unidad instalada, en cache, pero marcada para no iniciarse ('unmask', 'inactive').
                  #  3 > La unidad instalada, en cache, pero no iniciado ('loaded', 'inactive').
                  #  4 > La unidad instalada, en cache, iniciado y aun ejecutandose ('loaded', 'active'/'running').
                  #  5 > La unidad instalada, en cache, iniciado y esperando peticionese ('loaded', 'active'/'waiting').
                  #  6 > La unidad instalada, en cache, iniciado y terminado ('loaded', 'active'/'exited' or 'dead').
                  #  7 > La unidad instalada, en cache, iniciado pero se desconoce su subestado.
                  # 99 > La unidad instalada, en cache, pero no se puede leer su información.

    if [ $l_status -eq 0 ]; then

        #Averiguar si esta instalado a nivel system
        l_is_user=1
        exist_systemd_unit "$p_unit_name" $l_is_user
        l_status=$?

        if [ $l_status -eq 0 ]; then
            return 0
        fi
    fi

    #Si se no esta iniciado, salir
    if [ $l_status -lt 4 ] || [ $l_status -gt 7 ]; then
        return 1
    fi

    #3. Solicitar la detención del servicio
    printf "%bLa unidad systemd '%s' esta iniciado y requiere detenerse para " "$g_color_red1" "$p_unit_name"

    if [ $p_is_uninstalling -eq 0 ]; then
        printf 'desinstalar '
    else
        printf 'instalar '
    fi

    if [ $p_artifact_index -lt 0 ]; then
        printf 'un artefacto del '
    else
        printf 'el artefacto[%s] del ' "$p_artifact_index"
    fi

    if [ -z "$p_repo_id" ]; then
        printf 'resositorio.\n'
    else
        printf "repositorio '%s'.\n" "$p_repo_id"
    fi

    if [ $p_is_noninteractive -ne 0 ]; then
        printf "¿Desea detener la unidad systemd?%b (ingrese 's' para 'si' y 'n' para 'no')%b [s]" "$g_color_gray1" "$g_color_reset"
        read -rei 's' -p ': ' l_option
    else
        l_option='s'
    fi

    if [ "$l_option" != "s" ]; then

        if [ $p_is_uninstalling -eq 0 ]; then
            printf '%bNo se desinstalará ' "$g_color_gray1"
        else
            printf '%bNo se instalará ' "$g_color_gray1"
        fi

        if [ $p_artifact_index -lt 0 ]; then
            printf 'un artefacto del '
        else
            printf 'el artefacto[%s] del ' "$p_artifact_index"
        fi

        if [ -z "$p_repo_id" ]; then
            printf "resositorio.\nDetenga el servicio '%s' y vuelva ejecutar el menú o acepte su detención para su " "$p_unit_name"
        else
            printf "repositorio '%s'.\nDetenga el servicio '%s' y vuelva ejecutar el menú o acepte su detención para su " "$p_repo_id" "$p_unit_name"
        fi

        if [ $p_is_uninstalling -eq 0 ]; then
            printf 'desinstalación.%b\n' "$g_color_reset"
        else
            printf 'instalación.%b\n' "$g_color_reset"
        fi

        return 2

    fi

    #4. Detener la unidad systemd

    #Si la unidad systemd esta a nivel usuario
    if [ $l_is_user -eq 0 ]; then
        printf 'Deteniendo la unidad "%s" a nivel usuario ...\n' "$p_unit_name"
        systemctl --user stop "$p_unit_name"
        return 3
    fi


    printf 'Deteniendo la unidad "%s" a nivel sistema ...\n' "$p_unit_name"
    if [ $g_runner_id -eq 0 ]; then
        systemctl stop "$p_unit_name"
    else
        sudo systemctl stop "$p_unit_name"
    fi

    return 4

}


#Parametros:
# 1 > Offset del indice donde inicia el menu dinamico (usualmente, el menu dinamico no inicia desde la primera opcion del dinamico menú).
get_length_menu_option() {

    local p_offset_option_index=$1

    local l_nbr_options=${#ga_menu_options_packages[@]}
    local l_max_digits_aux="$((1 << (p_offset_option_index + l_nbr_options)))"

    return ${#l_max_digits_aux}
}


#Menu dinamico: Listado de repositorios que son instalados por las opcion de menu dinamicas
#El menu dinamico muestra una opción de menú que es:
#   ([Correlativo]) [Etiquete del opción de menu] [Titulo de la opción de menu]: [Listado de los repositorio que se configurará]
#Parametros de entrada:
#  1> Etiqueta de la opción de menú.
#     Texto que aparece al costado del opción ('Instalar o actualizar' o 'Desintalar')
#  2> Offset del indice donde inicia el menu dinamico (usualmente, el menu dinamico no inicia desde la primera opcion del dinamico menú).
#  3> Numero maximo de digitos de una opción del menu personalizado.
#Variables de entrada
#  ga_menu_options_title > Listado titulos de una opción de menú.
#  ga_menu_options_packages > Listado de ID de repositorios configurados por una opción de menú.
#  gA_packages       > Diccionario de identificadores de repositorios configurados por una opción de menú.
show_dynamic_menu() {

    #Argumentos
    local p_option_tag=$1
    local p_offset_option_index=$2
    local p_max_digits=$3


    #Espacios vacios al inicio del menu
    local l_empty_space
    local l_aux=$((8 + p_max_digits))
    printf -v l_empty_space ' %.0s' $(seq $l_aux)

    #Recorreger las opciones dinamicas del menu personalizado
    local l_i=0
    local l_j=0
    local IFS=','
    local la_repos
    local l_option_value
    local l_n
    local l_repo_names
    local l_repo_id



    for((l_i=0; l_i < ${#ga_menu_options_packages[@]}; l_i++)); do

        #Si no tiene repositorios a instalar, omitirlos
        l_option_value=$((1 << (p_offset_option_index + l_i)))

        l_aux="${ga_menu_options_packages[$l_i]}"
        #if [ -z "$l_aux" ] || [ "$l_aux" = "-" ]; then
        #    printf "     (%b%0${p_max_digits}d%b) %s\n" "$g_color_green1" "$l_option_value" "$g_color_reset" "${ga_menu_options_title[$l_i]}"
        #    continue
        #fi

        #Obtener los repositorios a configurar
        IFS=','
        la_repos=(${l_aux})
        IFS=$' \t\n'

        printf "     (%b%${p_max_digits}d%b) %s %b%b%b> " "$g_color_green1" "$l_option_value" "$g_color_reset" \
               "$p_option_tag" "$g_color_green1" "${ga_menu_options_title[$l_i]}" "$g_color_reset"

        l_n=${#la_repos[@]}
        if [ $l_n -gt 3 ]; then
            printf "\n${l_empty_space}"
        fi

        l_repo_names=''
        for((l_j=0; l_j < ${l_n}; l_j++)); do

            l_repo_id="${la_repos[${l_j}]}"
            l_aux="${gA_packages[${l_repo_id}]}"
            if [ -z "$l_aux" ] || [ "$l_aux" = "$g_empty_str" ]; then
                l_aux="$l_repo_id"
            fi

            if [ $l_j -eq 0 ]; then
                l_repo_names="'${g_color_gray1}${l_aux}${g_color_reset}'"
            else
                if [ $l_j -eq 6 ]; then
                    l_repo_names="${l_repo_names},\n${l_empty_space}'${g_color_gray1}${l_aux}${g_color_reset}'"
                else
                    l_repo_names="${l_repo_names}, '${g_color_gray1}${l_aux}${g_color_reset}'"
                fi
            fi

        done

        printf '%b\n' "$l_repo_names"

    done


}

#La funcion considerara la ruta de un folder como: "${g_targethome_path}/PATH_THAT_MUST_EXIST/PATH_THAT_MAYNOT_EXIST", donde
#  > 'PATH_THAT_MUST_EXIST' es parte de la ruta del folder que debe existir y tener permisos de escritura, si no lo esta, arroajara el error 2.
#  > 'PATH_THAT_MAYNOT_EXIST' es la parte de la ruta del folder que puede o no existir, por lo que requiere ser creada.
#  > No se altero el permiso de los folderes existentes, solo de los nuevos a crear.
#Parametros de entrada> Argumentos y opciones
#  1> Ruta 'PATH_THAT_MUST_EXIST', relativa al home del usuario, que debera existir.
#  2> Ruta 'PATH_THAT_MAYNOT_EXIST', relativa al home del usuario, que pueda que no exista por lo que se intentara crearlo.
#     Para establecer los permisos correctos, se recomienda que el folder padra existe con el permiso correcto.
#Parametros de entrada> Variables globales
# - 'g_targethome_path', 'g_runner_user', 'g_targethome_owner', 'g_targethome_group'
#Parametos de salida> Valor de retorno
#  0> Se creo todo (o parte de) la ruta indicada con exito.
#  1> El folder ya existe y no se creo ningun folder.
#  2> NOOK: El folder que debe existir no existe o no se tiene permisos de escritura.
#  3> NOOK: Error en la creacion del folder.
function create_folderpath_on_home() {

    local p_folderpath_must_exist="$1"
    local p_folderpath_maynot_exist="$2"

    #2. Inicializaciones

    #3. Validar que la ruta que debe existir existe y tener permisos de escritura
    local l_target_base_path="${g_targethome_path}"
    if [ ! -z "$p_folderpath_must_exist" ]; then

        l_target_base_path="${g_targethome_path}/${p_folderpath_must_exist}"
        if [ ! -d "$l_target_base_path" ] || [ ! -w "$l_target_base_path" ]; then
            return 2
        fi
    fi

    if [ -z "$p_folderpath_maynot_exist" ]; then
        return 0
    fi

    #4. Creando los folderes del ruta que no puede existir
    local IFS='/'
    la_foldernames=($p_folderpath_maynot_exist)
    local l_i=0
    local l_n=${#la_foldernames[@]}
    local l_foldername=""
    local l_flag_created=1
    for(( l_i=0; l_i < ${l_n}; l_i++ )); do

        #Obtener el folder
        l_foldername="${la_foldernames[${l_i}]}"
        if [ -z "$l_foldername" ]; then
            continue
        fi
        l_target_base_path="${l_target_base_path}/${l_foldername}"

        #Si el folder existe, no hacer nada continuar con el sigueinte de la ruta
        if [ -d "$l_target_base_path" ]; then
            continue
        fi

        #Si no existe crearlo con los permisos deseados:
        l_flag_created=0
        printf 'Creando la carpeta "%b%s%b"...\n' "$g_color_gray1" "${l_target_base_path}" \
               "$g_color_reset"
        mkdir -pm 755 "$l_target_base_path"

        #Si el runner es root en modo suplantacion del usuario objetivo
        if [ $g_runner_is_target_user -ne 0 ]; then
            chown "${g_targethome_owner}:${g_targethome_group}" "${l_target_base_path}"
        fi

    done

    if [ $l_flag_created -ne 0 ]; then
        return 1
    fi
    return 0

}

#Parametros en entrega> Argumentos y Opciones
# 1 > Ruta source, relativa al home del usuario objetiov, donde esta el archivo que se desea crear el enlace simbolico.
# 2 > Nombre del archivo origin (source) que se desea crear su enlace simbolico.
# 3 > Ruta folder destino (target), relativa al home folder, donde se creara el enlace simbolico.
# 4 > Nombre del enlace simbolico que se desea crear.
# 5 > Etiqueta que se muestra al inicio de cada linea de texto escrita en el SDTOUT.
# 6 > Flag '0' si se desea sobrescribir un enlace simbolico ya existente.
#Parametros de salida (valores de retorno):
# 0 > Ya existe el enlace simbolico y no se realizo ningun cambio.
# 1 > Ya existe el enlace simbolico pero se ha recreado en enlace simbolico.
# 2 > Se creo el enlace simbolico
# 3 > NOOK: No existe el source path.
# 4 > NOOK: No existe el folder donde esta se creara el enlace simbolico.
function create_filelink_on_home() {

    local p_source_path="$1"
    local p_source_filename="$2"
    local p_target_path="$3"
    local p_target_link="$4"
    local p_tag="$5"
    local p_override_target_link=1
    if [ "$6" = "0" ]; then
        p_override_target_link=0
    fi

    #2. Inicializaciones
    if [ -z "$p_source_path" ]; then
        p_source_path="${g_targethome_path}"
    else
        p_source_path="${g_targethome_path}/${p_source_path}"
    fi

    if [ -z "$p_target_path" ]; then
        p_target_path="${g_targethome_path}"
    else
        p_target_path="${g_targethome_path}/${p_target_path}"
        if [ ! -d "$p_target_path" ]; then
            printf "%s%bEl folder '%b%s%b' donde se crea el enlace simbolico no existe.%b\n" "$p_tag" "$g_color_red1" "$g_color_gray1" \
                   "$p_target_path" "$g_color_red1" "$g_color_reset"
        fi
    fi
    local l_target_fulllink="${p_target_path}/${p_target_link}"

    local l_source_fullfilename="${p_source_path}/${p_source_filename}"
    if [ ! -f "$l_source_fullfilename" ]; then
        printf "%s%bEl archivo '%b%s%b' source del enlace simbolico no existe.%b\n" "$p_tag" "$g_color_red1" "$g_color_gray1" \
               "$l_source_fullfilename" "$g_color_red1" "$g_color_reset"
    fi

    local l_status=0
    local l_aux
    if [ -h "$l_target_fulllink" ] && [ -f "$l_target_fulllink" ]; then
        if [ $p_override_target_link -eq 0 ]; then
            ln -snf "$l_source_fullfilename" "$l_target_fulllink"
            printf "%sEl enlace simbolico '%s' se ha re-creado %b(ruta real '%s')%b\n" "$p_tag" "$l_target_fulllink" "$g_color_gray1" "$l_source_fullfilename" \
                   "$g_color_reset"
            l_status=1

            #Si el runner es root en modo suplantacion del usuario objetivo
            if [ $g_runner_is_target_user -ne 0 ]; then
                chown -h "${g_targethome_owner}:${g_targethome_group}" "${l_target_fulllink}"
            fi

        else
            l_aux=$(readlink "$l_target_fulllink")
            printf "%sEl enlace simbolico '%s' ya existe %b(ruta real '%s')%b\n" "$p_tag" "$l_target_fulllink" "$g_color_gray1" "$l_aux" "$g_color_reset"
            l_status=0
        fi
    else
        ln -snf "$l_source_fullfilename" "$l_target_fulllink"
        printf "%sEl enlace simbolico '%s' se ha creado %b(ruta real '%s')%b\n" "$p_tag" "$l_target_fulllink" "$g_color_gray1" "$l_source_fullfilename" \
               "$g_color_reset"
        l_status=2

        #Si el runner es root en modo suplantacion del usuario objetivo
        if [ $g_runner_is_target_user -ne 0 ]; then
            chown -h "${g_targethome_owner}:${g_targethome_group}" "${l_target_fulllink}"
        fi

    fi

    return $l_status

}



#Parametros en entraga> Argumentos y Opciones
# 1 > Ruta de folder origin (source) relativa al home folder, que se desea crear su enlace simbolico.
# 2 > Ruta del folder destino (target) relativa al home folder.
# 3 > Nombre del enlace simbolico que se desea crear (ubicado en el folder indicado por el parametro 3).
# 4 > Etiqueta que se muestra al inicio de cada linea de texto escrita en el SDTOUT.
# 5 > Flag '0' si se desea sobrescribir un enlace simbolico ya existente.
#Parametros de salida (valores de retorno):
# 0 > Ya existe el enlace simbolico y no se realizo ningun cambio.
# 1 > Ya existe el enlace simbolico pero se ha recreado en enlace simbolico.
# 2 > Se creo el enlace simbolico
function create_folderlink_on_home() {

    local p_source_path="$1"
    local p_target_path="$2"
    local p_target_link="$3"
    local p_tag="$4"
    local p_override_target_link=1
    if [ "$5" = "0" ]; then
        p_override_target_link=0
    fi

    #2. Inicializaciones
    if [ -z "$p_source_path" ]; then
        p_source_path="${g_targethome_path}"
    else
        p_source_path="${g_targethome_path}/${p_source_path}"
        if [ ! -d "$p_source_path" ]; then
            printf "%s%bEl folder '%b%s%b' source del enlace simbolico no existe.%b\n" "$p_tag" "$g_color_red1" "$g_color_gray1" \
                   "$p_source_path" "$g_color_red1" "$g_color_reset"
        fi
    fi

    if [ -z "$p_target_path" ]; then
        p_target_path="${g_targethome_path}"
    else
        p_target_path="${g_targethome_path}/${p_target_path}"
        if [ ! -d "$p_target_path" ]; then
            printf "%s%bEl folder '%b%s%b' donde se crea el enlace simbolico no existe.%b\n" "$p_tag" "$g_color_red1" "$g_color_gray1" \
                   "$p_target_path" "$g_color_red1" "$g_color_reset"
        fi
    fi

    local l_target_fulllink="${p_target_path}/${p_target_link}"
    local l_status=0
    local l_aux

    if [ -h "$l_target_fulllink" ] && [ -d "$l_target_fulllink" ]; then
        if [ $p_override_target_link -eq 0 ]; then
            ln -snf "${p_source_path}/" "$l_target_fulllink"
            printf "%sEl enlace simbolico '%s' se ha re-creado %b(ruta real '%s')%b\n" "$p_tag" "$l_target_fulllink" "$g_color_gray1" "$p_source_path" "$g_color_reset"
            l_status=1

            #Si el runner es root en modo suplantacion del usuario objetivo
            if [ $g_runner_is_target_user -ne 0 ]; then
                chown -h "${g_targethome_owner}:${g_targethome_group}" "${l_target_fulllink}"
            fi

        else
            l_aux=$(readlink "$l_target_fulllink")
            printf "%sEl enlace simbolico '%s' ya existe %b(ruta real '%s')%b\n" "$p_tag" "$l_target_fulllink" "$g_color_gray1" "$l_aux" "$g_color_reset"
            l_status=0
        fi
    else
        ln -snf "${p_source_path}/" "$l_target_fulllink"
        printf "%sEl enlace simbolico '%s' se ha creado %b(ruta real '%s')%b\n" "$p_tag" "$l_target_fulllink" "$g_color_gray1" "$p_source_path" "$g_color_reset"
        l_status=2

        #Si el runner es root en modo suplantacion del usuario objetivo
        if [ $g_runner_is_target_user -ne 0 ]; then
            chown -h "${g_targethome_owner}:${g_targethome_group}" "${l_target_fulllink}"
        fi

    fi

    return $l_status
}

#Copia un archivo si este no existe. Si es un enlace simbolico, lo remplaza
#Parametros en entrega> Argumentos y Opciones
# 1 > Ruta absoluta origin (source) donde esta el archivo que se desea copiar a HOME.
# 2 > Nombre del archivo origin (source) que se desea copiar a HOME.
# 3 > Ruta folder destino (target), relativa al home folder, donde se copiara el archivo.
# 4 > Nombre del archivo destino (source) en caso que se desea renombrarlo.
#     Si desea mantener el nombre coloque vacio o el mismo nombre.
# 5 > Flag '0' si se desea sobrescribir el archivo si este ya existe.
# 6 > Etiqueta que se muestra al inicio de cada linea de texto escrita en el SDTOUT.
#Parametros de salida (valores de retorno):
# 0 > Se copio en archivo: se ha creado el archivo.
# 1 > Se copio en archivo: se eliminado el enlace simbolico y creado el archivo.
# 2 > Se copio el archivo: se ha sobrescrito el archivo.
# 3 > NO se copio debido a que ya existe y no se realizo ningun cambio.
function copy_file_on_home() {

    local p_source_path="$1"
    local p_source_filename="$2"

    local p_target_path="${g_targethome_path}"
    if [ ! -z "$3" ]; then
        p_target_path="${g_targethome_path}/$3"
    fi

    local p_target_filename="$p_source_filename"
    if [ ! -z "$4" ]; then
        p_target_filename="$4"
    fi

    local p_override_file=1
    if [ "$5" = "0" ]; then
        p_override_file=0
    fi

    local p_tag="$6"

    #2. Inicializaciones
    local l_result=0

    #Si es un enlace simbolico (este roto o no): por defecto no permite remplazar al enlace
    if [ -h "${p_target_path}/${p_target_filename}" ]; then

        printf '%sEliminando el enlace simbolico "%b%s%b" ...\n' "$p_tag" "$g_color_gray1" "${p_target_path}/${p_target_filename}" "$g_color_reset"
        unlink "${p_target_path}/${p_target_filename}"
        l_result=1

    else

        if [ -f "${p_target_path}/${p_target_filename}" ]; then

            if [ $p_override_file -ne 0 ]; then
                printf '%sEl archivo "%b%s%b" ya existe ...\n' "$p_tag" "$g_color_gray1" "${p_target_path}/${p_target_filename}" "$g_color_reset"
                l_result=3
                return $l_result
            fi

            printf "%sSobre-escribiendo el archivo '%b%s%b' (copia de '%b%s%b')\n" "$p_tag" "$g_color_gray1" "${p_target_path}/${p_target_filename}" \
                   "$g_color_reset" "$g_color_gray1" "${p_source_path}/${p_source_filename}" "$g_color_reset"
            l_result=2

        else

            l_result=0

        fi

    fi

    cp "${p_source_path}/${p_source_filename}" "${p_target_path}/${p_target_filename}"
    #Si el runner es root en modo suplantacion del usuario objetivo
    if [ $g_runner_is_target_user -ne 0 ]; then
        chown "${g_targethome_owner}:${g_targethome_group}" "${p_target_path}/${p_target_filename}"
    fi

    return $l_result


}



#}}}



#------------------------------------------------------------------------------------------------------------------
#> Funciones generales para la configuracion de Development enviromnent {{{
#------------------------------------------------------------------------------------------------------------------
#


# Parametros de salida
#  > Valores de retorno:
#     0 > OK.
#     1 > NO se encuentra la ubicacion del binario 'node' (no instalado o no registrado en el PATH)
#     2 > Ocurrio un error al obtener el owner del folder
#  > SDTOUT: El usuario onwer de la carpeta de binarios de NodeJS
function get_owner_of_nodejs() {

    #1. Parametros
    local p_tools_path="$1"

    #2. Obtener la ruta donde esta los binarios de nodojs
    local l_nodejs_bin_path=''

    if [ -z "$p_tools_path" ] || [ ! -f "${p_tools_path}/nodejs/bin/node" ]; then

        l_nodejs_bin_path=$(which node)
        if [ -z "$l_nodejs_bin_path" ]; then
            return 1
        fi

        l_nodejs_bin_path=${l_nodejs_bin_path%/node}

    else
        l_nodejs_bin_path="${p_tools_path}/nodejs/bin"
    fi


    #3. Obtener el owner del folder
    local l_aux=''
    l_aux=$(get_owner_of_folder "$l_nodejs_bin_path")
    local l_status=$?

    if [ $l_status -ne 0 ] || [ -z "$l_aux" ]; then
        return 2
    fi

    local -a la_owners=(${l_aux})
    echo "${la_owners[0]}"
    return 0

}


# Parametros de entrada
#  1> Path por defecto donde estan todos los programas instalados por el instalador.
# Parametros de salida
#  > Valores de retorno:
#     0 > Esta instalado (usando este instalador) y registrado en el PATH
#     1 > Esta instalado (usando este instalador) pero NO estaba registrado en el PATH
#     2 > Esta instalado pero fue instalado usando el gestor de paquetes (no requiere registro)
#     3 > No esta instalado
#  > SDTOUT: La version de NodeJS instalada
function get_nodejs_version() {

    #Parametros
    local p_tools_path="$1"

    #Obtener la version instalada
    local l_version
    local l_status

    #1. Si no se envio una ruta valida de programas del instalador o no fue instalado por el instalador
    if [ -z "$p_tools_path" ] || [ ! -f "${p_tools_path}/nodejs/bin/node" ]; then

        l_version=$(node --version 2> /dev/null)
        l_status=$?
        if [ $l_status -ne 0 ]; then
            l_version=''
        fi

        if [ -z "$l_version" ]; then
            return 3
        fi

        l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
        echo "$l_version"
        return 2

    fi

    #2. Si fue instalado por este instalador
    l_version=$(${p_tools_path}/nodejs/bin/node --version 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ]; then
        l_version=''
    fi

    #Si fue instalado incorrectamente
    if [ -z "$l_version" ]; then
        return 3
    fi

    # Si fue instaaldo correctamente
    l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
    echo "$l_version"

    #Si fue instalado correctamente, validar si esta registrado en el PATH
    echo "$PATH" | grep "${p_tools_path}/nodejs/bin" &> /dev/null
    l_status=$?

    #Si no esta registrado en el PATH
    if [ $l_status -ne 0 ]; then

        export PATH="${p_tools_path}/nodejs/bin:$PATH"
        return 1

    fi

    #Si esta registrado en el PATH
    return 0

}


# Parametros de salida
#  > SDTOUT: La version de Python, Pip y PipX separado por espaciones
#            Si no esta instalado python (y por dende, ninguna sus componenbtes), devolvera vacio.
#            Si no se tiene la version de una de las componentes su valor sera 'NONE'.
#  > Valores de retorno:
#     X > Donde X es la suma de binaria de los siguientes valores:
#         1 > Si esta instalado python.
#         2 > Si esta instalado pip.
#         4 > Si esta instalado pipx.
#    Los cuales puede ser:
#     0 > No esta instalado python.
#     1 > Instalado python sin los gestor de paquetes pip y pipx
#     3 > Instalado python y solo el gestor de paquetes pip
#     5 > Instalado python y solo el gestor de paquetes pipx
#     7 > Instalado python y los gestor de paquetes pip y pipx
function get_python_versions() {

    # TODO Considerar cuando no es python del sistema y cuando es un venv
    #      ¿que vim/neovim siempre usen el pyhton/nodejs del sistema?

    # Validar si esta instalado python
    local l_version
    l_version=$(python3 --version 2> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ]; then
        return 0
    fi

    local l_result=1
    l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
    local l_versions="$l_version"

    # Validar si esta instalado pip
    l_version=$(pip3 --version 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ]; then
        l_version=''
        l_versions="${l_versions} NONE"
    else
        ((l_result = l_result + 2))
        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
        l_versions="${l_versions} ${l_version}"
    fi

    # Validar si esta instalado pipx
    l_version=$(pipx --version 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ]; then
        l_version=''
        l_versions="${l_versions} NONE"
    else
        ((l_result = l_result + 4))
        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
        l_versions="${l_versions} ${l_version}"
    fi

    echo "$l_versions"
    return $l_result

}



#Parametros de salida
#  > SDTOUT: Version de NodeJS instalado
#  > Valores de retorno:
#     0 > Se obtuvo la version (esta instalado)
#     1 > No se obtuvo la version (no esta instalado)
function get_vim_version() {

    #Obtener la version instalada
    local l_version
    l_version=$(vim --version 2> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ]; then
        return 1
    fi

    l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
    echo "$l_version"
    return 0
}



#Parametros de entrada
# 1> Path por defecto de todos los programas instalados por el instalador.
#Parametros de salida
#  > Valores de retorno:
#     0 > Esta instalado (usando este instalador) y registrado en el PATH
#     1 > Esta instalado (usando este instalador) pero NO estaba registrado en el PATH
#     2 > Esta instalado pero fue instalado usando el gestor de paquetes (no requiere registro)
#     3 > No esta instalado
#  > SDTOUT: La version de Neovim
function get_neovim_version() {

    #Parametros
    local p_tools_path="$1"

    #Obtener la version instalada
    local l_version
    local l_status

    #1. Si no se envio una ruta valida de programas del instalador o no fue instalado por el instalador
    if  [ -z "$p_tools_path" ] || [ ! -f "${p_tools_path}/neovim/bin/nvim" ]; then

        l_version=$(nvim --version 2> /dev/null)
        l_status=$?
        if [ $l_status -ne 0 ]; then
            l_version=''
        fi

        if [ -z "$l_version" ]; then
            return 3
        fi

        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
        echo "$l_version"
        return 2

    fi

    #Actualmente en arm64 y alpine, solo se instala usaando el gestor de paquetes (el repositorios del SO)
    if [ "$g_os_architecture_type" = "aarch64" ] || [ $g_os_subtype_id -eq 1 ]; then

        #Si no se obtuvo la version antes, no esta instalado
        return 3

    fi

    #2. Si fue instalado por este instalador
    l_version=$(${p_tools_path}/neovim/bin/nvim --version 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ]; then
        l_version=''
    fi

    #Si fue instalado incorrectamente
    if [ -z "$l_version" ]; then
        return 3
    fi

    #Si fue instalado correctamente
    l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
    echo "$l_version"

    #Si fue instalado correctamente, validar si esta registrado en el PATH
    echo "$PATH" | grep "${p_tools_path}/neovim/bin" &> /dev/null
    l_status=$?

    #Si no esta en el PATH
    if [ $l_status -ne 0 ]; then

        export PATH="${p_tools_path}/neovim/bin:$PATH"
        return 1

    fi

    #Si esta en el PATH
    return 0

}



# Instalar RTE Node.JS
# Parametro de salida:
# > Valor de retorno:
#      00> Si NodeJS esta instalado o si se instaló correctamente.
#      01> Si NodeJS no se logro instalarse.
#     120> Si no se acepto almacenar la credencial para su instalación
install_nodejs() {

    #0. Argumentos
    local p_show_title=1
    if [ "$1" = "0" ]; then
        p_show_title=0
    fi

    local p_tools_path="$2"

    #1. Validar si 'nodejs' esta instado (puede no estar en el PATH)
    local l_version=''
    local l_status

    l_version=$(get_nodejs_version "$p_tools_path")
    l_status=$?

    #echo "l_version=${l_version}, l_status=${l_status}"

    if [ ! -z "$l_version" ]; then
        printf 'NodeJS > NodeJS %b%s%b ya esta instalado.\n' "$g_color_gray1" "$l_version" "$g_color_reset"
        return 0
    fi

    #2. Mostrar el titulo principal
    if [ $p_show_title -eq 0 ]; then
        print_line '-' $g_max_length_line  "$g_color_gray1"
    fi

    printf 'NodeJS > %bInstalando NodeJS%b\n' "$g_color_cian1" "$g_color_reset"

    if [ $p_show_title -eq 0 ]; then
        print_line '-' $g_max_length_line  "$g_color_gray1"
    fi


    #3. Instalar NodeJS
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi

    printf 'Se instalara NodeJS usando el script de instalación "%b%s%b" ...\n' "$g_color_gray1" "01_setup_binaries.bash" "$g_color_reset"

    printf 'Warning: %bLa ruta personalizada de instalación de programas solo puede ser ingresado por archivo "%b%s%b" de configuración%b.\n' \
           "$g_color_yellow1" "$g_color_gray1" "config.bash" "$g_color_yellow1" "$g_color_reset"
    printf '         No soporta rutas personalizada por argumentos del script de instalación. Las rutas predeterminado a usar pueden ser "%b/var/opt/tools%b" o "%b~/tools%b".\n' \
           "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"

    #Parametros del script usados hasta el momento:
    # 1> Tipo de llamado: 2/4 (sin menu interactivo/no-interactivo).
    # 2> Listado de ID del repositorios a instalar separados por coma.
    # 3> Ruta base del home del usuario al cual se configurara su profile y donde esta el repositorio git.
    # 4> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
    # 5> Ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado
    #    "/var/opt/tools" o "~/tools".
    # 6> Ruta base donde se almacena los comandos ("CMD_LNX_BASE_PATH/bin"), archivos man1 ("CMD_LNX_BASE_PATH/man/man1") y fonts ("CMD_LNX_BASE_PATH/share/fonts").
    # 7> Ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado.
    # 8> El estado de la credencial almacenada para el sudo.
    # 9> Install only last version: por defecto es 1 (false). Solo si ingresa 0, se cambia a 0 (true).
    #10> Flag '0' para mostrar un titulo si se envia un repositorio en el parametro 2. Por defecto es '1'
    #11> Flag para filtrar el listado de repositorios segun el tipo de progrmas. '0' solo programas del usuario, '1' solo programas que no son de usuario.
    #    Otro valor, no hay filtro. Valor por defecto es '2'.
    #12> Flag '0' si desea almacenar la ruta de programas elegido en '/tmp/prgpath.txt'. Por defecto es '1'.
    if [ $l_is_noninteractive -eq 1 ]; then
        ${g_shell_path}/bash/bin/linuxsetup/01_setup_binaries.bash 2 "nodejs" "$g_targethome_path" "$g_repo_name" "" "" "" \
            $g_status_crendential_storage 1 1 2 0
        l_status=$?
    else
        ${g_shell_path}/bash/bin/linuxsetup/01_setup_binaries.bash 4 "nodejs" "$g_targethome_path" "$g_repo_name" "" "" "" \
            $g_status_crendential_storage 1 1 2 0
        l_status=$?
    fi

    #No se cumplen las precondiciones obligatorios
    if [ $l_status -eq 111 ]; then
        return 111
    #Si no se acepto almacenar credenciales
    elif [ $l_status -eq 120 ]; then
        return 120
    #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
       g_status_crendential_storage=0
    fi


    #4. Volver a validar si las componentes fueron instalados
    #  > Valores de retorno:
    #     0 > Esta instalado (usando este instalador) y registrado en el PATH
    #     1 > Esta instalado (usando este instalador) pero NO estaba registrado en el PATH
    #     2 > Esta instalado pero fue instalado usando el gestor de paquetes (no requiere registro)
    #     3 > No esta instalado
    l_version=$(get_nodejs_version "$p_tools_path")
    l_status=$?

    if [ $l_status -ge 3 ]; then
        return 1
    fi

    if [ $l_status -eq 1 ]; then
        printf 'Registrando, de manera temporal, la ruta "%b%s/nodejs/bin%b" de NodeJS en la variable de entorno "%bPATH%b".\n' "$g_color_gray1" \
               "$l_tools_path" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
        export PATH="${l_tools_path}/nodejs/bin:$PATH"
    fi
    return 0

}



# Instalar RTE Python3
# Parametro de salida:
# > Valor de retorno:
#      00> Si Python, Pip y Pipx estan instalado o si se instaló correctamente.
#      01> Si Python esta instalado, pero no se puede instalar pip o pipx.
#      02> Si Python, Pip y Pipx no estan instalados.
#     111> No se cumplio con requesitos obligatorios (Detener todo el proceso.
#     120> No se almaceno el password para sudo (solo cuando se requiere).
install_python() {

    #0. Argumentos
    local p_show_title=1
    if [ "$1" = "0" ]; then
        p_show_title=0
    fi

    #1. Validar si 'python', 'pip' y 'pipx' estan instalados
    local l_aux
    l_aux=$(get_python_versions)
    local l_status=$?
    local la_versions=(${l_aux})

    #echo "l_status=${l_status}, l_aux=${l_aux}"

    # Determinar la componentes instalados
    local l_flag_setup_python=0
    local l_flag_setup_pip=0
    local l_flag_setup_pipx=0

    if [ $l_status -ne 0 ]; then

        l_flag_setup_python=1

        # ¿Instalar python y sus gestores de paquetes?
        local l_option=2
        if [ $(( $l_status & $l_option )) -eq $l_option ]; then
            l_flag_setup_pip=1
        fi

        l_option=4
        if [ $(( $l_status & $l_option )) -eq $l_option ]; then
            l_flag_setup_pipx=1
        fi

    fi

    # Si tanto python como pip y pipx esta instalado
    if [ $l_flag_setup_python -ne 0 ] && [ $l_flag_setup_pip -ne 0 ] && [ $l_flag_setup_pipx -ne 0 ]; then
        printf 'Python > Python %b%s%b ya esta instalado.\n' "$g_color_gray1" "${la_versions[0]}" "$g_color_reset"
        printf '       > El gestor de paquetes pip %b%s%b ya esta instalado.\n' "$g_color_gray1" "${la_versions[1]}" "$g_color_reset"
        printf '       > El gestor de paquetes pipx %b%s%b ya esta instalado.\n' "$g_color_gray1" "${la_versions[2]}" "$g_color_reset"
        return 0
    fi

    # No instalar si no tiene acceso a sudo
    if [ $g_runner_sudo_support -eq 3 ] || { [ $g_runner_id -ne 0 ] && [ $g_runner_sudo_support -eq 2 ]; }; then
        printf 'Python > %bPython NO puede ser instalado debido a que carece de accesos a root%b.\n' "$g_color_red1" "$g_color_reset"
        return 1
    fi


    #2. Inicializacion y el titulo

    # Listado de paquetes instalar
    local l_packages_to_install=''
    l_aux=''

    if [ $l_flag_setup_python -eq 0 ]; then

        l_packages_to_install='python'
        printf -v l_aux '"%bPython%b"' "$g_color_cian1" "$g_color_reset"

    fi

    if [ $l_flag_setup_pip -eq 0 ]; then

        if [ -z "$l_packages_to_install" ]; then
            l_packages_to_install='python-pip'
            printf -v l_aux '"%bPip%b"' "$g_color_cian1" "$g_color_reset"
        else
            l_packages_to_install="${l_packages_to_install},python-pip"
            printf -v l_aux '%b, "%bPip%b"' "$l_aux" "$g_color_cian1" "$g_color_reset"
        fi

    fi

    if [ $l_flag_setup_pipx -eq 0 ]; then

        if [ -z "$l_packages_to_install" ]; then
            l_packages_to_install='python-pipx'
            printf -v l_aux '"%bPipx%b"' "$g_color_cian1" "$g_color_reset"
        else
            l_packages_to_install="${l_packages_to_install},python-pipx"
            printf -v l_aux '%b, "%bPipx%b"' "$l_aux" "$g_color_cian1" "$g_color_reset"
        fi

    fi

    # Mostrar el titulo
    printf '\n'

    if [ $p_show_title -eq 0 ]; then
        print_line '-' $g_max_length_line  "$g_color_gray1"
    fi

    printf 'Python > %bInstalando%b %b\n' "$g_color_cian1" "$g_color_reset" "$l_aux"

    if [ $p_show_title -eq 0 ]; then
        print_line '-' $g_max_length_line  "$g_color_gray1"
    fi

    # Mostrar lo instalado
    if [ $l_flag_setup_python -ne 0 ]; then
        printf 'Python > Python %b%s%b ya esta instalado.\n' "$g_color_gray1" "${la_versions[0]}" "$g_color_reset"
    fi

    if [ $l_flag_setup_pip -ne 0 ]; then
        printf '       > El gestor de paquetes pip %b%s%b ya esta instalado.\n' "$g_color_gray1" "${la_versions[1]}" "$g_color_reset"
    fi

    if [ $l_flag_setup_pipx -ne 0 ]; then
        printf '       > El gestor de paquetes pipx %b%s%b ya esta instalado.\n' "$g_color_gray1" "${la_versions[2]}" "$g_color_reset"
    fi


    #3. Instalación o python o 'pip' o 'pipx'
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi

    # Parametros:
    # 1> Tipo de ejecución: 1 (ejecución no-interactiva para instalar/actualizar un grupo paquetes)
    # 2> Repositorios a instalar/acutalizar: 16 (RTE Python y Pip. Tiene Offset=1)
    # 3> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
    # 4> El estado de la credencial almacenada para el sudo
    if [ $l_is_noninteractive -eq 1 ]; then
        ${g_shell_path}/bash/bin/linuxsetup/03_setup_repo_os_pkgs.bash 2 "$l_packages_to_install" $g_status_crendential_storage
        l_status=$?
    else
        ${g_shell_path}/bash/bin/linuxsetup/03_setup_repo_os_pkgs.bash 4 "$l_packages_to_install" $g_status_crendential_storage
        l_status=$?
    fi

    #No se cumplen las precondiciones obligatorios
    if [ $l_status -eq 111 ]; then
        return 111
    #Si no se acepto almacenar credenciales
    elif [ $l_status -eq 120 ]; then
        return 120
    #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
       g_status_crendential_storage=0
    fi


    #4. Volver a validar si las componentes fueron instalados
    l_aux=$(get_python_versions)
    l_status=$?

    # Si NO estan instalados python, pip y pipx
    if [ $l_status -eq 0 ]; then
        return 2
    fi

    # Si estan instalados python, pip y pipx
    if [ $l_status -eq 7 ]; then
        return 0
    fi

    # Si falta instalar o pip o pipx
    return 1

}


# Instalar VIM
# Parametros de salida:
# > Valor de retorno:
#      00> Si VIM esta instalado o si se instaló correctamente.
#      01> Si VIM no se logro instalarse.
#      99> Si no se solicito instalar VIM
#     120> Si no se acepto almacenar la credencial para su instalación
install_vim() {

    #0. Argumentos
    local p_show_title=1
    if [ "$1" = "0" ]; then
        p_show_title=0
    fi


    #1. Validar si 'vim' esta instado
    local l_version=''
    local l_status

    l_version=$(get_vim_version)
    l_status=$?

    if [ ! -z "$l_version" ]; then

        printf 'VIM > VIM %b%s%b ya esta instalado.\n' "$g_color_gray1" "$l_version" "$g_color_reset"
        return 0
    fi

    # No instalar si no tiene acceso a sudo
    if [ $g_runner_sudo_support -eq 3 ] || { [ $g_runner_id -ne 0 ] && [ $g_runner_sudo_support -eq 2 ]; }; then
        printf 'VIM > %bVIM puede ser instalado debido a que carece de accesos a root. Se recomienda su instalación%b.\n' "$g_color_red1" "$g_color_reset"
        return 1
    fi


    #2. Mostrar el titulo principal
    if [ $p_show_title -eq 0 ]; then
        print_line '-' $g_max_length_line  "$g_color_gray1"
    fi

    printf 'VIM > %bInstalando VIM%b\n' "$g_color_cian1" "$g_color_reset"

    if [ $p_show_title -eq 0 ]; then
        print_line '-' $g_max_length_line  "$g_color_gray1"
    fi


    #3. Instalar VIM
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi

    # Parametros:
    # 1> Tipo de ejecución: 2 (ejecución no-interactiva para instalar/actualizar un respositorio especifico)
    # 2> Packete a instalar/acutalizar.
    # 3> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
    # 4> El estado de la credencial almacenada para el sudo
    if [ $l_is_noninteractive -eq 1 ]; then
        ${g_shell_path}/bash/bin/linuxsetup/03_setup_repo_os_pkgs.bash 2 'vim' $g_status_crendential_storage
        l_status=$?
    else
        ${g_shell_path}/bash/bin/linuxsetup/03_setup_repo_os_pkgs.bash 4 'vim' $g_status_crendential_storage
        l_status=$?
    fi

    # No se cumplen las precondiciones obligatorios
    if [ $l_status -eq 111 ]; then
        return 111
    # Si no se acepto almacenar credenciales
    elif [ $l_status -eq 120 ]; then
        return 120
    # Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
       g_status_crendential_storage=0
    fi

    #4. Volver a validar si las componentes fueron instalados
    l_version=$(get_vim_version)
    l_status=$?

    if [ $l_status -ne 0 ]; then
        return 1
    fi

    return 0

}


# Instalar NoeVIM
# Parametros de salida:
# > Valor de retorno:
#      00> Si VIM esta instalado o si se instaló correctamente.
#      01> Si VIM no se logro instalarse.
#      99> Si no se solicito instalar VIM
#     120> Si no se acepto almacenar la credencial para su instalación
install_neovim() {

    #0. Argumentos
    local p_show_title=1
    if [ "$1" = "0" ]; then
        p_show_title=0
    fi

    local p_tools_path="$2"

    #1. Validar si 'nvim' esta instado (puede no estar en el PATH)
    local l_version=''
    local l_status

    l_version=$(get_neovim_version "$p_tools_path")
    l_status=$?

    if [ ! -z "$l_version" ]; then
        printf 'NeoVIM > NeoVIM %b%s%b ya esta instalado.\n' "$g_color_gray1" "$l_version" "$g_color_reset"
        return 0
    fi

    #2. Determinar el metodo de instalacion (descargar o instalar como paquete del SO
    local l_setup_os_package=1

    # Actualmente (2023), el repositorio no tiene binarios para arm64 y alpine, se debera usar los repositorios de los SO
    #if [ "$g_os_architecture_type" = "aarch64" ] || [ $g_os_subtype_id -eq 1 ]; then
    if [ $g_os_subtype_id -eq 1 ]; then

        # No instalar si no tiene acceso a sudo
        if [ $g_runner_sudo_support -eq 3 ] || { [ $g_runner_id -ne 0 ] && [ $g_runner_sudo_support -eq 2 ]; }; then
            printf 'NeoVIM > %bNeoVIM puede ser instalado debido a que carece de accesos a root. Se recomienda su instalación%b.\n' "$g_color_red1" "$g_color_reset"
            return 1
        fi

        l_setup_os_package=0

    fi


    #3. Mostrar el titulo principal
    if [ $p_show_title -eq 0 ]; then
        print_line '-' $g_max_length_line  "$g_color_gray1"
    fi

    printf 'NeoVIM > %bInstalando NeoVIM%b\n' "$g_color_cian1" "$g_color_reset"

    if [ $p_show_title -eq 0 ]; then
        print_line '-' $g_max_length_line  "$g_color_gray1"
    fi


    #4. Instalar NeoVIM
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi

    if [ $l_setup_os_package -eq 0 ]; then

        # Parametros:
        # 1> Tipo de ejecución: 2/4 (ejecución sin menu no-interactiva/interactiva para instalar/actualizar paquetes)
        # 2> Paquete a instalar/acutalizar.
        # 3> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
        # 4> El estado de la credencial almacenada para el sudo
        if [ $l_is_noninteractive -eq 1 ]; then
            ${g_shell_path}/bash/bin/linuxsetup/03_setup_repo_os_pkgs.bash 2 "nvim" $g_status_crendential_storage
            l_status=$?
        else
            ${g_shell_path}/bash/bin/linuxsetup/03_setup_repo_os_pkgs.bash 4 "nvim" $g_status_crendential_storage
            l_status=$?
        fi

        #Si no se acepto almacenar credenciales
        if [ $l_status -eq 120 ]; then
            return 120
        #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
        elif [ $l_status -eq 119 ]; then
           g_status_crendential_storage=0
        fi

    else

        printf 'Se instalara NeoVIM usando el script de instalación "%b%s%b" ...\n' "$g_color_gray1" "01_setup_binaries.bash" "$g_color_reset"

        printf 'Warning: %bLa ruta personalizada de instalación de programas solo puede ser ingresado por archivo "%b%s%b" de configuración%b.\n' \
               "$g_color_yellow1" "$g_color_gray1" "config.bash" "$g_color_yellow1" "$g_color_reset"
        printf '         No soporta rutas personalizada por argumentos del script de instalación. Las rutas predeterminado a usar pueden ser "%b/var/opt/tools%b" o "%b~/tools%b".\n' \
               "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"

        # Parametros del script usados hasta el momento:
        # 1> Tipo de llamado: 2/4 (sin menu interactivo/no-interactivo).
        # 2> Listado de ID del repositorios a instalar separados por coma.
        # 3> Ruta base del home del usuario al cual se configurara su profile y donde esta el repositorio git.
        # 4> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
        # 5> Ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado
        #    "/var/opt/tools" o "~/tools".
        # 6> Ruta base donde se almacena los comandos ("LNX_BASE_PATH/bin"), archivos man1 ("LNX_BASE_PATH/man/man1") y fonts ("LNX_BASE_PATH/share/fonts").
        # 7> Ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado.
        # 8> El estado de la credencial almacenada para el sudo.
        # 9> Install only last version: por defecto es 1 (false). Solo si ingresa 0, se cambia a 0 (true).
        #10> Flag '0' para mostrar un titulo si se envia un repositorio en el parametro 2. Por defecto es '1'
        #11> Flag para filtrar el listado de repositorios segun el tipo de progrmas. '0' solo programas del usuario, '1' solo programas que no son de usuario.
        #    Otro valor, no hay filtro. Valor por defecto es '2'.
        #12> Flag '0' si desea almacenar la ruta de programas elegido en '/tmp/prgpath.txt'. Por defecto es '1'.
        if [ $l_is_noninteractive -eq 1 ]; then

            ${g_shell_path}/bash/bin/linuxsetup/01_setup_binaries.bash 2 "neovim" "$g_targethome_path" "$g_repo_name" "" "" "" \
                $g_status_crendential_storage 1 1 2 0
            l_status=$?
        else
            ${g_shell_path}/bash/bin/linuxsetup/01_setup_binaries.bash 4 "neovim" "$g_targethome_path" "$g_repo_name" "" "" "" \
                $g_status_crendential_storage 1 1 2 0
            l_status=$?
        fi

        #No se cumplen las precondiciones obligatorios
        if [ $l_status -eq 111 ]; then
            return 111
        #Si no se acepto almacenar credenciales
        elif [ $l_status -eq 120 ]; then
            return 120
        #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
        elif [ $l_status -eq 119 ]; then
           g_status_crendential_storage=0
        fi

        #Validar si 'nvim' esta en el PATH
        local l_tools_path=$(cat /tmp/prgpath.txt | head -n 1)
        if [ -z "$l_tools_path" ] || [ -d "$l_tools_path/neovim/bin" ]; then
            printf 'La ruta de de instalación de programa es "%b%s%b".\n' "$g_color_gray1" "$l_tools_path" "$g_color_reset"
            echo "$PATH" | grep "${l_tools_path}/neovim/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf 'Registrando, de manera temporal, la ruta "%b%s/neovim/bin%b" de NeoVIM en la variable de entorno "%bPATH%b".\n' "$g_color_gray1" \
                       "$l_tools_path" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
                export PATH=${l_tools_path}/neovim/bin:$PATH
            fi
        else
            printf 'La ruta de instalación de programa "%b%s%b" obtenida es invalida.\n' "$g_color_gray1" "$l_tools_path" "$g_color_reset"
        fi

    fi

    #5. Volver a validar si las componentes fueron instalados
    l_version=$(get_neovim_version "$p_tools_path")
    l_status=$?

    if [ $l_status -ne 0 ]; then
        return 1
    fi

    return 0


}



#}}}
