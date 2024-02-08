#!/bin/bash

#Parametros de entrada:
#  1> La ruta relativa (o absoluta) de un archivos del repositorio
#Parametros de salida: 
#  STDOUT> La ruta base donde esta el repositorio
function _get_current_repo_path() {

    #Obteniendo la ruta absoluta del parametro ingresado
    local l_path=''
    l_path=$(realpath "$1" 2> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ]; then
        echo "$HOME"
        return 1
    fi

    #Obteniendo la ruta base
    l_path=${l_path%/.files/*}
    echo "$l_path"
    return 0
}

#Inicialización Global {{{

declare -r g_repo_path=$(_get_current_repo_path "${BASH_SOURCE[0]}")

#Si lo ejecuta un usuario diferente al actual (al que pertenece el repositorio)
#UID del Usuario y GID del grupo (diferente al actual) que ejecuta el script actual
g_other_calling_user=''


#Funciones generales, determinar el tipo del SO y si es root
. ${g_repo_path}/.files/terminal/linux/functions/func_utility.bash

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
if [ -z "$g_user_is_root" ]; then

    #Determinar si es root y el soporte de sudo
    # > 'g_user_is_root'                : 0 si es root. Caso contrario no es root.
    # > 'g_user_sudo_support'           : Si el so y el usuario soportan el comando 'sudo'
    #    > 0 : se soporta el comando sudo con password
    #    > 1 : se soporta el comando sudo sin password
    #    > 2 : El SO no implementa el comando sudo
    #    > 3 : El usuario no tiene permisos para ejecutar sudo
    #    > 4 : El usuario es root (no requiere sudo)
    get_user_options

fi


#Funciones de utilidad
. ${g_repo_path}/.files/setup/linux/_common_utility.bash


#Tipo de ejecucion del script principal
gp_type_calling=0       #(0) Ejecución mostrando el menu del opciones (siempre es interactiva).
                        #(1) Ejecución sin el menu de opciones, interactivo - instalar/actualizar un conjunto de repositorios
                        #(2) Ejecución sin el menu de opciones, no interactivo - instalar/actualizar un conjunto de repositorios

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


declare -r g_default_list_package_ids='curl,unzip,openssl,tmux'

#}}}




#Funciones principales y el menú {{{


#
#Parametros de entrada (Argumentos):
# 1> Opciones de menu a ejecutar: entero positivo.
# 2> ID de los repositorios de comandos a configurar, separados por coma. Si no desea configurarse ninguno envie "EMPTY".
# 3> ID de los paquetes del repositorio del SO a instalar, separados por coma. Si no desea configurarse ninguno envie "EMPTY".
#    Si envia "DEFAULT" se instalará paquete basicos por defecto que son: Curl, UnZip, OpenSSL y Tmux.
# 4> Flag '0' para limpiar el cache de paquetes del sistema operativo. Caso contrario, use 1.
# 5> Actualizar los paquetes del SO. Por defecto es 1 (false), si desea actualizar use 0.
function g_install_options() {
    
    #1. Argumentos 
    local p_input_options=-1
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_input_options=$1
    fi

    #if [ $p_input_options -le 0 ]; then
    #    echo "ERROR: Argumento de opciones \"${p_input_options}\" es incorrecta"
    #    return 99
    #fi

    local p_list_repo_ids=""
    if [ ! -z "$2" ] && [ "$2" != "EMPTY" ]; then
        p_list_repo_ids="$2"
    fi

    local p_list_pckg_ids="$g_default_list_package_ids"
    if [ ! -z "$3" ]; then
        p_list_pckg_ids="$3"
    fi

    local p_flag_clean_os_cache=1
    if [ "$4" = "0" ]; then
        p_flag_clean_os_cache=0
    fi

    local p_flag_upgrade_os_pkgs=1
    if [ "$5" = "0" ]; then
        p_flag_upgrade_os_pkgs=0
    fi

    #2.Inicialización
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi

    #Flag '0' cuando no se realizo ninguna instalacion de paquetes
    local l_exist_packages_installed=1

    #3. Opción> Paquetes basicos: Curl, OpenSSL y Tmux
    local l_status=0
    local l_option=32
    if [ $p_input_options -gt 0 ] && [ $(( $p_input_options & $l_option )) -eq $l_option ] && [ ! -z "$p_list_pckg_ids" ]; then

        #Solo soportado para los que tenga acceso a root
        if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

            #Mostrar el titulo de instalacion
            print_line '─' $g_max_length_line  "$g_color_blue1"
            printf "> Instalando '%b%s%b'\n" "$g_color_cian1" "${p_list_pckg_ids//,/, }" "$g_color_reset"
            print_line '─' $g_max_length_line "$g_color_blue1"

            #Parametros:
            # 1> Tipo de ejecución: 2/4 (ejecución sin menu, para instalar/actualizar un grupo paquetes)
            # 2> Paquetes a instalar 
            # 3> El estado de la credencial almacenada para el sudo
            # 4> Actualizar los paquetes del SO antes. Por defecto es 1 (false).
            if [ $l_is_noninteractive -eq 1 ]; then
                ${g_repo_path}/.files/setup/linux/04_setup_packages.bash 2 "$p_list_pckg_ids" $g_status_crendential_storage $p_flag_upgrade_os_pkgs
                l_status=$?
            else
                ${g_repo_path}/.files/setup/linux/04_setup_packages.bash 4 "$p_list_pckg_ids" $g_status_crendential_storage $p_flag_upgrade_os_pkgs
                l_status=$?
            fi

            if [ $l_exist_packages_installed -ne 0 ]; then
                l_exist_packages_installed=0
            fi

            #Si no se acepto almacenar credenciales
            if [ $l_status -eq 120 ]; then
                return 120
            #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
            elif [ $l_status -eq 119 ]; then
                g_status_crendential_storage=0
            #Si no se paso las precondiciones iniciales
            elif [ $l_status -eq 111 ]; then
                return $l_status
            fi

        fi

    fi

    #4. Opción> Comandos Basicos
    l_option=64
    if [ $p_input_options -gt 0 ] && [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

        #Solo soportado para los que tenga acceso a root
        if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

            #Mostrar el titulo de instalacion
            print_line '─' $g_max_length_line  "$g_color_blue1"
            if [ $g_os_subtype_id -eq 1 ]; then
                printf "> Instalando %bComandos Basicos%b: '%bbat, jq, yq, ripgrep, delta, oh-my-posh%b, etc.'\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
            else
                printf "> Instalando %bComandos Basicos%b: '%bfzf, bat, jq, yq, ripgrep, delta, oh-my-posh%b, etc.'\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
            fi
            print_line '─' $g_max_length_line "$g_color_blue1"

            #Parametros:
            # 1> Tipo de ejecución: 1/3 (ejecución sin menu para instalar/actualizar un respositorio especifico)
            # 2> Opciones de menu de Repositorio a instalar/acutalizar: 
            # 3> El estado de la credencial almacenada para el sudo.
            # 4> Install only last version: por defecto es 1 (false). Solo si ingresa 0 es (true).
            # 5> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID"
            if [ $l_is_noninteractive -eq 1 ]; then
                ${g_repo_path}/.files/setup/linux/01_setup_commands.bash 1 4 $g_status_crendential_storage 0 "$g_other_calling_user"
                l_status=$?
            else
                ${g_repo_path}/.files/setup/linux/01_setup_commands.bash 3 4 $g_status_crendential_storage 0 "$g_other_calling_user"
                l_status=$?
            fi

            #Si no se acepto almacenar credenciales
            if [ $l_status -eq 120 ]; then
                return 120
            #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
            elif [ $l_status -eq 119 ]; then
               g_status_crendential_storage=0
            #Si no se paso las precondiciones iniciales
            elif [ $l_status -eq 111 ]; then
                return $l_status
            fi

        fi

    fi

    #5. Opción> Programas basicos: NodeJs y sus paquetes globales, Python/Pip, VIM y NeoVIM
    local l_prg_options=0
    local l_aux=''

    if [ $p_input_options -gt 0 ]; then

        #Determinar los programas a instalar: NodeJs, sus paquetes globales y Python/Pip
        l_option=128
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            l_prg_options=$((l_prg_options + 8 + 16 + 64))
            printf -v l_aux "'%bNodeJS%b' %b(incluye paquetes globales basicos)%b, '%bPython%b'" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
        fi

        #Determinar los programas a instalar: VIM
        l_option=256
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            l_prg_options=$((l_prg_options + 128))
            if [ -z "$l_aux" ]; then
                printf -v l_aux "'%bVIM%b'" "$g_color_cian1" "$g_color_reset"
            else
                printf -v l_aux "${l_aux}, '%bVIM%b'" "$g_color_cian1" "$g_color_reset"
            fi
        fi

        #Determinar los programas a instalar: NeoVIM
        l_option=512
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            l_prg_options=$((l_prg_options + 1024))
            if [ -z "$l_aux" ]; then
                printf -v l_aux "'%bNeoVIM%b'" "$g_color_cian1" "$g_color_reset"
            else
                printf -v l_aux "${l_aux}, '%bNeoVIM%b'" "$g_color_cian1" "$g_color_reset"
            fi
        fi

    fi

    if [ $l_prg_options -gt 0 ]; then

       #Solo soportado para los que tenga acceso a root
       if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

           #Mostrar el titulo de instalacion
           print_line '─' $g_max_length_line  "$g_color_blue1"
           printf "> Instalando %bProgramas basicos%b: %b\n" "$g_color_cian1" "$g_color_reset" "$l_aux"
           print_line '─' $g_max_length_line "$g_color_blue1"

           #Solo actualizar los paquetes del SO, si no se hizo antes
           if [ $p_flag_upgrade_os_pkgs -eq 0 ] && [ $l_exist_packages_installed -ne 0 ]; then
               l_prg_options=$((l_prg_options + 1))
           fi

           #Parametros:
           # 1> Tipo de ejecución: 1/2 (ejecución sin menu, interactiva y no-interactiva)
           # 2> Paquetes a instalar: 40 (Python y sus paquetes) + 80 (NodeJS y sus paquetes) + 128 (VIM) + 1024 (NeoVIM)
           # 3> El estado de la credencial almacenada para el sudo
           # 4> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID"
           if [ $l_is_noninteractive -eq 1 ]; then
               ${g_repo_path}/.files/setup/linux/02_setup_profile.bash 1 $l_prg_options $g_status_crendential_storage "$g_other_calling_user"
               l_status=$?
           else
               ${g_repo_path}/.files/setup/linux/02_setup_profile.bash 2 $l_prg_options $g_status_crendential_storage "$g_other_calling_user"
               l_status=$?
           fi

           if [ $l_exist_packages_installed -ne 0 ]; then
               l_exist_packages_installed=0
           fi

           #Si no se acepto almacenar credenciales
           if [ $l_status -eq 120 ]; then
               return 120
           #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
           elif [ $l_status -eq 119 ]; then
               g_status_crendential_storage=0
            #Si no se paso las precondiciones iniciales
            elif [ $l_status -eq 111 ]; then
                return $l_status
           fi

       fi

   fi

   #6. Opción> LSP/DAP de .NET : Omnisharp-Roslyn, NetCoreDbg
   l_option=1024
   if [ $p_input_options -gt 0 ] && [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

       #Solo soportado para los que tenga acceso a root
       if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

           #Mostrar el titulo de instalacion
           print_line '─' $g_max_length_line  "$g_color_blue1"
           printf "> Instalando %bLSP/DAP de .NET%b: '%bOmnisharp-Roslyn%b' y '%bNetCoreDbg%b'\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
                  "$g_color_cian1" "$g_color_reset"
           print_line '─' $g_max_length_line "$g_color_blue1"

           #Parametros:
           # 1> Tipo de ejecución: 2/4 (ejecución sin menu para instalar/actualizar un respositorio especifico)
           # 2> Repsitorio a instalar/actualizar: 
           # 3> El estado de la credencial almacenada para el sudo
           # 4> Install only last version: por defecto es 1 (false). Solo si ingresa 0 es (true).
           # 5> Flag '0' para mostrar un titulo si se envia, como parametro 2, un solo repositorio a configurar. Por defecto es '1' 
           # 6> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID"
           if [ $l_is_noninteractive -eq 1 ]; then
               
               ${g_repo_path}/.files/setup/linux/01_setup_commands.bash 2 "roslyn,netcoredbg" $g_status_crendential_storage 0 1 "$g_other_calling_user"
               l_status=$?
           else
               ${g_repo_path}/.files/setup/linux/01_setup_commands.bash 4 "roslyn,netcoredbg" $g_status_crendential_storage 0 1 "$g_other_calling_user"
               l_status=$?
           fi

           #Si no se acepto almacenar credenciales
           if [ $l_status -eq 120 ]; then
               return 120
           #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
           elif [ $l_status -eq 119 ]; then
              g_status_crendential_storage=0
            #Si no se paso las precondiciones iniciales
            elif [ $l_status -eq 111 ]; then
                return $l_status
           fi

       fi

    fi

    #7. Opción> LSP/DAP de Java : Jdtls
    l_option=2048
    if [ $p_input_options -gt 0 ] && [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

        #Solo soportado para los que tenga acceso a root
        if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

            #Mostrar el titulo de instalacion
            print_line '─' $g_max_length_line  "$g_color_blue1"
            printf "> Instalando %bLSP/DAP de Java%b: '%bJdtls%b'\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
            print_line '─' $g_max_length_line "$g_color_blue1"

            #Parametros:
            # 1> Tipo de ejecución: 2/4 (ejecución sin menu para instalar/actualizar un respositorio especifico)
            # 2> Repsositorio a instalar/acutalizar: 
            # 3> El estado de la credencial almacenada para el sudo.
            # 4> Install only last version: por defecto es 1 (false). Solo si ingresa 0 es (true).
            # 5> Flag '0' para mostrar un titulo si se envia, como parametro 2, un solo repositorio a configurar. Por defecto es '1' 
            # 6> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID"
            if [ $l_is_noninteractive -eq 1 ]; then
                ${g_repo_path}/.files/setup/linux/01_setup_commands.bash 2 "jdtls" $g_status_crendential_storage 0 1 "$g_other_calling_user"
                l_status=$?
            else
                ${g_repo_path}/.files/setup/linux/01_setup_commands.bash 4 "jdtls" $g_status_crendential_storage 0 1 "$g_other_calling_user"
                l_status=$?
            fi

            #Si no se acepto almacenar credenciales
            if [ $l_status -eq 120 ]; then
                return 120
            #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
            elif [ $l_status -eq 119 ]; then
               g_status_crendential_storage=0
            #Si no se paso las precondiciones iniciales
            elif [ $l_status -eq 111 ]; then
                return $l_status
            fi

        fi

    fi

    #8. Opción> Lista de repositorios de comandos adicionales a instalar
    if [ ! -z "$p_list_repo_ids" ]; then

        #Solo soportado para los que tenga acceso a root
        if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

            #Mostrar el titulo de instalacion
            print_line '─' $g_max_length_line  "$g_color_blue1"
            printf "> Instalando repositorios %bcomandos/programas%b: '%b%s%b'\n" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$p_list_repo_ids" "$g_color_reset"
            print_line '─' $g_max_length_line "$g_color_blue1"

            #Parametros:
            # 1> Tipo de ejecución: 2/4 (ejecución sin menu para instalar/actualizar un respositorio especifico)
            # 2> Repsositorio a instalar/acutalizar: 
            # 3> El estado de la credencial almacenada para el sudo
            # 4> Install only last version: por defecto es 1 (false). Solo si ingresa 0 es (true).
            # 5> Flag '0' para mostrar un titulo si se envia, como parametro 2, un solo repositorio a configurar. Por defecto es '1' 
            # 6> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID"
            if [ $l_is_noninteractive -eq 1 ]; then
                
                ${g_repo_path}/.files/setup/linux/01_setup_commands.bash 2 "$p_list_repo_ids" $g_status_crendential_storage 0 1 "$g_other_calling_user"
                l_status=$?
            else
                ${g_repo_path}/.files/setup/linux/01_setup_commands.bash 4 "$p_list_repo_ids" $g_status_crendential_storage 0 1 "$g_other_calling_user" 
                l_status=$?
            fi

            #Obligar a limpiar el cache: ¿algunos instalacion, instala paquetes?
            if [ $l_exist_packages_installed -ne 0 ]; then
                l_exist_packages_installed=0
            fi

            #Si no se acepto almacenar credenciales
            if [ $l_status -eq 120 ]; then
                return 120
            #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
            elif [ $l_status -eq 119 ]; then
               g_status_crendential_storage=0
            #Si no se paso las precondiciones iniciales
            elif [ $l_status -eq 111 ]; then
                return $l_status
            fi

        fi

    fi


    #9. Opción> Configurar el profile del usuario y VIM/NeoVIM como IDE/Developer
    l_prg_options=0
    l_aux=''
    local l_python_pkg_opts=32

    if [ $p_input_options -gt 0 ]; then

        #Determinar si se configura el profile del usuario (se obligara a recrear lo enlaces simbolicos)    
        l_option=1
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            l_prg_options=$((l_prg_options + 2 + 4))
            printf -v l_aux "el %bprofile del usario%b" "$g_color_cian1" "$g_color_reset"
        fi

        #Determinar si se configura VIM como IDE (incluye los paquetes de usuario de Python)
        l_option=4
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

            l_prg_options=$((l_prg_options + 512 + l_python_pkg_opts))
            #Evitar que se vuelva a usar en NeoVIM como IDE
            l_python_pkg_opts=0

            if [ -z "$l_aux" ]; then
                printf -v l_aux "%bVIM%b como %bIDE%b" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
            else
                printf -v l_aux "${l_aux}, %bVIM%b como %bIDE%b" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
            fi

        #Si VIM no es IDE, determinar si se configura como Editor
        else

            l_option=2
            if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

                l_prg_options=$((l_prg_options + 256))
                if [ -z "$l_aux" ]; then
                    printf -v l_aux "%bVIM%b como %bEditor%b" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
                else
                    printf -v l_aux "${l_aux}, %bVIM%b como %bEditor%b" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
                fi

            fi

        fi

        #Determinar si se configura NeoVIM como IDE (incluye los paquetes de usuario de Python)
        l_option=16
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

            l_prg_options=$((l_prg_options + 4096 + l_python_pkg_opts))
            #Evitar que se vuelva a usar
            #l_python_pkg_opts=0

            if [ -z "$l_aux" ]; then
                printf -v l_aux "%bNeoVIM%b como %bIDE%b" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
            else
                printf -v l_aux "${l_aux}, %bNeoVIM%b como %bIDE%b" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
            fi

        #Si NeoVIM no es IDE, determinar si se configura como Editor
        else

            l_option=8
            if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

                l_prg_options=$((l_prg_options + 2048))
                if [ -z "$l_aux" ]; then
                    printf -v l_aux "%bNeoVIM%b como %bEditor%b" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
                else
                    printf -v l_aux "${l_aux}, %bNeoVIM%b como %bEditor%b" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
                fi

            fi

        fi

    fi

    if [ $l_prg_options -gt 0 ]; then

        #Solo soportado para los que tenga acceso a root
        if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

            #Mostrar el titulo de instalacion
            print_line '─' $g_max_length_line  "$g_color_blue1"
            printf "> Configurar %b\n" "$l_aux"
            print_line '─' $g_max_length_line "$g_color_blue1"

            #Parametros:
            # 1> Tipo de ejecución: 1/2 (ejecución sin menu, interactiva y no-interactiva)
            # 2> Opciones a configurar: 2 (Profile) + 4 (Recrear enlaces simbolicos) + 64 (VIM como IDE) + 512 (NeoVIM como IDE)
            # 3> El estado de la credencial almacenada para el sudo
            # 4> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID"
            if [ $l_is_noninteractive -eq 1 ]; then
                ${g_repo_path}/.files/setup/linux/02_setup_profile.bash 1 $l_prg_options $g_status_crendential_storage "$g_other_calling_user"
                l_status=$?
            else
                ${g_repo_path}/.files/setup/linux/02_setup_profile.bash 2 $l_prg_options $g_status_crendential_storage "$g_other_calling_user"
                l_status=$?
            fi

            #Si no se acepto almacenar credenciales
            if [ $l_status -eq 120 ]; then
                return 120
            #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
            elif [ $l_status -eq 119 ]; then
                g_status_crendential_storage=0
            #Si no se paso las precondiciones iniciales
            elif [ $l_status -eq 111 ]; then
                return $l_status
            fi

        fi

    fi

    if [ $p_flag_clean_os_cache -eq 0 ] && [ $l_exist_packages_installed -eq 0 ]; then
        printf 'Clean packages cache...\n'
        clean_os_cache $g_os_subtype_id $l_is_noninteractive
    fi

    #10. Si se invoco interactivamente y se almaceno las credenciales, caducarlo.
    #   Si no se invoca usando el menú y se almaceno las credencial en este script, será el script caller el que sea el encargado de caducarlo
    if [ $g_status_crendential_storage -eq 0 ] && [ $gp_type_calling -eq 0 ]; then
    #if [ $g_status_crendential_storage -eq 0 ] && [ $g_is_credential_storage_externally -ne 0 ]; then
        clean_sudo_credencial
    fi


}    

function _show_menu_install_core() {

    #0. Parametros
    local l_pckg_ids="${1//,/, }"

    #1. Menu
    print_text_in_center "Menu de Opciones (Install/Configuration)" $g_max_length_line "$g_color_green1"
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf " (%bq%b) Salir del menu\n" "$g_color_green1" "$g_color_reset"

    local l_max_digits=4

    printf " ( ) Configuración personalizado para el usuario:\n"
    printf "     (%b%0${l_max_digits}d%b) Configurar el %bprofile del usuario%b\n" "$g_color_green1" "1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Configurar %bVIM%b    como %bEditor%b\n" "$g_color_green1" "2" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Configurar %bVIM%b    como %bIDE%b %b(incluye paquetes de usuario basicos de python)%b\n" "$g_color_green1" "4" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Configurar %bNeoVIM%b como %bEditor%b\n" "$g_color_green1" "8" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Configurar %bNeoVIM%b como %bIDE%b %b(incluye paquetes de usuario basicos de python)%b\n" "$g_color_green1" "16" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"

    printf " ( ) Programas requeridos a instalar %b(usualmente instalado como root)%b:\n" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Paquetes  basicos: %b%s%b\n" "$g_color_green1" "32" "$g_color_reset" "$g_color_gray1" "$l_pckg_ids" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Comandos  basicos: %bfzf, bat, jq, yq, ripgrep, delta, oh-my-posh, etc.%b\n" "$g_color_green1" "64" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Programas basicos: %bNodeJS (incluye paquetes globales basicos) y Python%b\n" "$g_color_green1" "128" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Programas basicos: %bVIM%b\n" "$g_color_green1" "256" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Programas basicos: %bNeoVIM%b\n" "$g_color_green1" "512" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) LSP/DAP de .NET  : %bOmnisharp-Roslyn, NetCoreDbg%b\n" "$g_color_green1" "1024" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) LSP/DAP de Java  : %bJdtls%b\n" "$g_color_green1" "2048" "$g_color_reset" "$g_color_gray1" "$g_color_reset"

    print_line '-' $g_max_length_line "$g_color_gray1"

}


function g_install_main() {

    #0. Parametros
    local p_list_pckg_ids="$g_default_list_package_ids"
    if [ ! -z "$1" ]; then
        p_list_pckg_ids="$1"
    fi

    p_flag_clean_os_cache=1
    if [ "$2" = "0" ]; then
        p_flag_clean_os_cache=0
    fi

    #1. Pre-requisitos
   
    #2. Mostrar el Menu
    print_line '─' $g_max_length_line "$g_color_green1" 
    _show_menu_install_core "$p_list_pckg_ids"

    #3. Mostar la ultima parte del menu y capturar la opcion elegida
    local l_flag_continue=0
    local l_options=""
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_gray1" "$g_color_reset"
        read -r l_options

        case "$l_options" in

            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                printf '\n'
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
                    printf '\n'

                    g_install_options $l_options "EMPTY" "$p_list_pckg_ids" $p_flag_clean_os_cache 0

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


#}}}





#Codigo Global {{{

g_usage() {

    printf 'Usage:\n'
    printf '  > %bDesintalar repositorios mostrando el menú de opciones%b:\n' "$g_color_cian1" "$g_color_reset" 
    printf '    %b~/.files/setup/linux/00_setup_summary.bash uninstall\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '  > %bInstalar repositorios mostrando el menú de opciones (interactivo)%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/00_setup_summary.bash\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/00_setup_summary.bash 0 LIST-PCKG-IDS CLEAN-OS-CACHE\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '  > %bInstalar/Actualizar un grupo de opciones sin mostrar el menú%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/00_setup_summary.bash CALLING_TYPE MENU-OPTIONS\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/00_setup_summary.bash CALLING_TYPE MENU-OPTIONS LIST-REPO-IDS\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/00_setup_summary.bash CALLING_TYPE MENU-OPTIONS LIST-REPO-IDS LIST-PCKG-IDS SUDO-STORAGE-OPTIONS CLEAN-OS-CACHE UPGRADE-OS-PACKAGES OTHER-USERID\n\n%b' \
           "$g_color_yellow1" "$g_color_reset"
    printf 'Donde:\n'
    printf '  > %bCALLING_TYPE%b es 1 si es interactivo y 2 si es no-interactivo.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bMENU-OPTIONS%b Las opciones de menu a instalar. Si no desea especificar coloque 0.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bLIST-REPO-IDS %bID de los repositorios de comandos a configurar, separados por coma. Si no desea configurarse ninguno envie "EMPTY".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bLIST-PCKG-IDS %b.ID de los paquetes del repositorio del SO, separados por coma, a instalar si elige la opcion de menu 32. Si desea usar el los los paquetes por defecto envie "EMPTY".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bLos paquete basicos por defecto que son: Curl, UnZip, OpenSSL y Tmux.%b\n' "$g_color_gray1" "$g_color_reset"
    printf '  > %bSUDO-STORAGE-OPTIONS %bes el estado actual de la credencial almacenada para el sudo. Use -1 o un non-integer, si las credenciales aun no se han almacenado.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bSi es root por lo que no se requiere almacenar la credenciales, use 2. Caso contrario, use 0 si se almaceno la credencial y 1 si no se pudo almacenar las credenciales.%b\n' \
           "$g_color_gray1" "$g_color_reset"
    printf '  > %bCLEAN-OS-CACHE%b es 0 si se limpia el cache de paquetes instalados. Por defecto es 1.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bUPGRADE-OS-PACKAGES%b Actualizar los paquetes del SO. Por defecto es 1 (false), si desea actualizar use 0.\n%b' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bOTHER-USERID %bEl GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID".%b\n\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}


#1. Argumentos fijos del script

#Argumento 1: Indica el tipo de invocación
if [ -z "$1" ]; then
    gp_type_calling=0
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    gp_type_calling=$1
else
    printf 'Argumentos invalidos.\n\n'
    g_usage
    exit 110
fi

if [ $gp_type_calling -lt 0 ] || [ $gp_type_calling -gt 2 ]; then
    printf 'Argumentos invalidos.\n\n'
    g_usage
    exit 110
fi


#2. Logica principal del script (incluyendo los argumentos variables)
_g_result=0
_g_status=0

#Aun no se ha solicitado almacenar temporalmente las credenciales para el sudo
g_status_crendential_storage=-1
#La credencial no se almaceno por un script externo.
g_is_credential_storage_externally=1


#Instalar y actualizar los artefactos de un repositorio

#2.1. Por defecto, mostrar el menu para escoger lo que se va instalar
if [ $gp_type_calling -eq 0 ]; then

    #Parametros del script usados hasta el momento:
    # 1> Tipo de invocación (sin menu): 1/2
    # 2> ID de los paquetes del repositorio, separados por coma, que se mostrara en el menu para que pueda instalarse. Si desea usar el por defecto envie "EMPTY".
    #    Los paquete basicos, por defecto, que se muestran en el menu son: Curl,UnZip, OpenSSL y Tmux
    # 3> Flag '0' para limpiar el cache de paquetes del sistema operativo. Caso contrario, use 1.
    _gp_list_pckg_ids="$g_default_list_package_ids"
    if [ ! -z "$2" ] && [ "$2" != "EMPTY" ]; then
        _gp_list_pckg_ids="$2"
    fi

    _gp_flag_clean_os_cache=1
    if [ "$3" = "0" ]; then
        _gp_flag_clean_os_cache=0
    fi

    #Validar los requisitos (algunas opciones requiere root y otros no)
    fulfill_preconditions $g_os_subtype_id 0 1 1 "$g_repo_path"
    _g_status=$?


    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then
        g_install_main "$_gp_list_pckg_ids" $_gp_flag_clean_os_cache
    else
        _g_result=111
    fi

#2.2. Instalando los repositorios especificados por las opciones indicas en '$2'
#elif [ $gp_type_calling -eq 1 ] || [ $gp_type_calling -eq 2 ]; then
else

    #Parametros del script usados hasta el momento:
    # 1> Tipo de invocación (sin menu): 1/2
    # 2> Opciones de menu a ejecutar: entero positivo.
    # 3> ID de los repositorios de comandos a configurar, separados por coma. Si no desea configurarse ninguno envie "EMPTY".
    # 4> ID de los paquetes del repositorio del SO, separados por coma, a instalar si elige la opcion de menu 32. Si desea usar el los los paquetes por defecto envie "EMPTY".
    #    Los paquetes por defecto que son: Curl, UnZip, OpenSSL y Tmux.
    # 5> El estado de la credencial almacenada para el sudo.
    # 6> Flag '0' para limpiar el cache de paquetes del sistema operativo. Caso contrario, use 1.
    # 7> Actualizar los paquetes del SO. Por defecto es 1 (false), si desea actualizar use 0.
    # 8> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID"
    _gp_opciones=0
    if [ "$2" = "0" ]; then
        _gp_opciones=-1
    elif [[ "$2" =~ ^[0-9]+$ ]]; then
        _gp_opciones=$2
    else
        echo "Opciones de menu a instalar (parametro 2) \"$2\" no es valido."
        exit 110
    fi

    _gp_list_repo_ids="EMPTY"
    if [ ! -z "$3" ]; then
        _gp_list_repo_ids="$3"
    fi

    _gp_list_pckg_ids="$g_default_list_package_ids"
    if [ ! -z "$4" ] && [ "$4" != "EMPTY" ]; then
        _gp_list_pckg_ids="$4"
    fi

    if [[ "$5" =~ ^[0-2]$ ]]; then
        g_status_crendential_storage=$5

        if [ $g_status_crendential_storage -eq 0 ]; then
            g_is_credential_storage_externally=0
        fi

    fi

    _gp_flag_clean_os_cache=1
    if [ "$6" = "0" ]; then
        _gp_flag_clean_os_cache=0
    fi

    _gp_flag_upgrade_os_pkgs=1
    if [ "$7" = "0" ]; then
        _gp_flag_upgrade_os_pkgs=0
    fi

    #Solo si el script e  ejecuta con un usuario diferente al actual (al que pertenece el repositorio)
    g_other_calling_user=''
    if [ "$g_repo_path" != "$HOME" ] && [ ! -z "$8" ]; then
        if [[ "$8" =~ ^[0-9]+:[0-9]+$ ]]; then
            g_other_calling_user="$8"
        else
            echo "Parametro 8 \"$8\" debe ser tener el formado 'UID:GID'."
            exit 110
        fi
    fi

    #Validar los requisitos (algunas opciones requiere root y otros no)
    fulfill_preconditions $g_os_subtype_id 1 0 1 "$g_repo_path"
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then

        g_install_options $_gp_opciones "$_gp_list_repo_ids" "$_gp_list_pckg_ids" $_gp_flag_clean_os_cache $_gp_flag_upgrade_os_pkgs
        _g_status=$?

        #Informar si se nego almacenar las credencial cuando es requirido
        if [ $_g_status -eq 120 ]; then
            _g_result=120
        #Si la credencial se almaceno en este script (localmente). avisar para que lo cierre el caller
        elif [ $g_is_credential_storage_externally -ne 0 ] && [ $g_status_crendential_storage -eq 0 ]; then
            _g_result=119
        #Si no se paso las precondiciones iniciales
        elif [ $_g_status -eq 111 ]; then
            _g_result=111
        fi

    else
        _g_result=111
    fi


fi
    

exit $_g_result


#}}}


