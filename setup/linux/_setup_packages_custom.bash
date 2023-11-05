#!/bin/bash


#ID de los paquetes y sus rutas bases
#Menu dinamico: Listado de repositorios que son instalados por las opcion de menu dinamicas
#  - Cada repositorio tiene un ID interno del un repositorios y un identifificador realizar: 
#    ['internal-id']='external-id'
#  - Por ejemplo para el repositorio GitHub 'stedolan/jq', el item se tendria:
#    ['jq']='stedolan/jq'
gA_packages=(
        ['xclip']='xclip'
        ['xsel']='xsel'
        ['python']='python3'
        ['python-pip']='python3-pip'
        ['skopeo']='skopeo'
    )


#WARNING: Un cambio en el orden implica modificar los indices de los eventos:
#         'install_initialize_menu_option', 'install_finalize_menu_option', 'uninstall_initialize_menu_option' y 'uninstall_finalize_menu_option'
#Menu dinamico: Titulos de las opciones del menú
#  - Cada entrada define un opcion de menú. Su valor define el titulo.
ga_menu_options_title=(
    "CLI para portapales X11"
    "RTE Python3"
    "Gestión de imagenes de contenedores"
    )

#WARNING: Un cambio en el orden implica modificar los indices de los eventos:
#         'install_initialize_menu_option', 'install_finalize_menu_option', 'uninstall_initialize_menu_option' y 'uninstall_finalize_menu_option'
#Menu dinamico: Repositorios de programas asociados asociados a una opciones del menu.
#  - Cada entrada define un opcion de menú. 
#  - Su valor es un cadena con ID de repositorios separados por comas.
#Notas:
#  > En la opción de 'ContainerD', se deberia incluir opcionalmente 'bypass4netns' pero su repo no presenta el binario.
#    El binario se puede encontrar en nerdctl-full.
ga_menu_options_packages=(
    "xclip,xsel"
    "python,python-pip"
    "skopeo"
    )



#Parametros de entrada - Agumentos y opciones:
#  1 > Nombre del paquete generico 
#  2 > El tipo de distribucion Linux (valor de retorno devulto por get_linux_type_id) 
#      00 : Distribución de Linux desconocido
#      01 : Ubuntu
#      02 : Fedora
#Parametros de salida :
#  STDOUT           : El nombre real para el sistema operativo indicado
#  Valor de retorno :
#    0 > OK
#    1 > No OK
get_package_name() {

    if [ -z "$1" ]; then
        return 1
    fi

    local p_os_type=$2
    #local l_aux

    case "$1" in

        #value2)

        #    #Si es Ubuntu
        #    if [ $p_os_type -eq 1 ]; then
        #        echo "value1"
        #    #Si es Fedora
        #    elif [ $p_os_type -eq 2 ]; then
        #        echo "value2"
        #    else
        #        return 1
        #    fi 
        #    ;;

        *)
            echo "$1"
            ;;
    esac

    return 0 


}

#Instalacion de un paquete del SO
#Parametros de entrada - Agumentos y opciones:
#  1 > Nombre del paquete 
#  2 > El tipo de distribucion Linux (valor de retorno devulto por get_linux_type_id) 
#      00 : Distribución de Linux desconocido
#      01 : Ubuntu
#      02 : Fedora
#Parametros de salida :
#  Valor de retorno :
#    0 > OK
#    1 > No OK
#    9 > Parametros de entrada invalido
install_os_package() {

    local p_package_name=$1
    local p_os_type=$2
    local l_status=0

    case "$p_os_type" in

        #Si es Ubuntu
        1)

            #Distribución: Ubuntu
            if [ $g_is_root -eq 0 ]; then
               apt-get install "$p_package_name"
            else
               sudo apt-get install "$p_package_name"
            fi
            l_status=$?
            ;;

        #Si es Fedora
        2)

            #Distribución: Fedora
            if [ $g_is_root -eq 0 ]; then
               dnf install "$p_package_name"
            else
               sudo dnf install "$p_package_name"
            fi
            l_status=$?
            ;;

        *)
            printf 'La instalación del paquete "%s" en el SO (tipo "%s") aun no esta implementado\n' "$p_package_name" "$p_os_type"
            l_status=110
            ;;
    esac

    if [ $l_status -eq 110 ]; then
        return 9
    elif [ $l_status -ne 0 ]; then
        return 1
    fi

    return 0 

}



#Desinstalacion de un paquete del SO
#Parametros de entrada - Agumentos y opciones:
#  1 > Nombre del paquete 
#  2 > El tipo de distribucion Linux (valor de retorno devulto por get_linux_type_id) 
#      00 : Distribución de Linux desconocido
#      01 : Ubuntu
#      02 : Fedora
#Parametros de salida :
#  Valor de retorno :
#    0 > OK
#    1 > No OK
#    9 > Parametros de entrada invalido
uninstall_os_package() {

    local p_package_name=$1
    local p_os_type=$2
    local l_status=0

    case "$p_os_type" in

        #Si es Ubuntu
        1)

            #Distribución: Ubuntu
            if [ $g_is_root -eq 0 ]; then
               apt-get purge "$p_package_name"
               apt-get autoremove
            else
               sudo apt-get purge "$p_package_name"
               sudo apt-get autoremove
            fi
            l_status=$?
            ;;

        #Si es Fedora
        2)

            #Distribución: Fedora
            if [ $g_is_root -eq 0 ]; then
               dnf erase "$p_package_name"
            else
               sudo dnf erase "$p_package_name"
            fi
            l_status=$?
            ;;

        *)
            printf 'La desinstalación del paquete "%s" en el SO (tipo "%s") aun no esta implementado\n' "$p_package_name" "$p_os_type"
            l_status=110
            ;;
    esac

    if [ $l_status -eq 110 ]; then
        return 9
    elif [ $l_status -ne 0 ]; then
        return 1
    fi

    return 0 

}



#
#La inicialización del menú opcion de instalación (codigo que se ejecuta antes de instalar el paquete)
#
#Los argumentos de entrada son:
#  1 > Index (inicia en 0) de la opcion de menu elegista para instalar (ver el arreglo 'ga_menu_options_title').
#
#El valor de retorno puede ser:
#  0 > Si inicializo con exito.
#  1 > No se inicializo por opcion del usuario.
#  2 > Hubo un error en la inicialización.
#
install_initialize_menu_option() {

    #1. Argumentos
    local p_option_relative_idx=$1

    #2. Inicialización
    local l_status
    local l_repo_id
    local l_artifact_index
    #local l_option_name="${ga_menu_options_title[${p_option_idx}]}"
    #local l_option_value=$((1 << p_option_idx))


    #3. Realizar validaciones segun la opcion de menu escogida
    #case "$p_option_relative_idx" in

    #    6)
    #        ;;
    #    

    #    *)
    #        return 0
    #        ;;
    #esac

    #Por defecto, se debe continuar con la instalación
    return 0


}


#
#La finalización del menú opcion de instalación (codigo que se ejecuta despues de instalar todos los paquetes de la opcion de menú)
#
#Los argumentos de entrada son:
#  1 > Index de la opcion de menu elegista para instalar (ver el arreglo 'ga_menu_options_title').
#
#El valor de retorno puede ser:
#  0 > Si finalizo con exito.
#  1 > No se finalizo por opcion del usuario.
#  2 > Hubo un error en la finalización.
#
install_finalize_menu_option() {

    #Argumentos
    local p_option_relative_idx=$1

    #local l_option_name="${ga_menu_options_title[${p_option_idx}]}"
    #local l_option_value=$((1 << p_option_idx))


    #Realizar validaciones segun la opcion de menu escogida
    local l_version
    local l_status

    case "$p_option_relative_idx" in

        #RTE Python
        1)

            #Adicionar packetes basicos al python instalado

            #1. Instalación de Herramienta para mostrar arreglo json al formato tabular
            l_version=$(pip3 list | grep jtbl 2> /dev/null)
            #l_version=$(jtbl -v 2> /dev/null)
            l_status=$?
            #if [ $l_status -ne 0 ]; then
            if [ -z "$l_version" ]; then

                print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
                echo "Instalando el comando 'jtbl' (modulo python) para mostrar arreglos json en una consola en formato tabular."
                
                #Se instalar a nivel usuario
                pip3 install jtbl
            fi

            #2. Instalación de Herramienta para generar la base de compilacion de Clang desde un make file
            l_version=$(pip3 list | grep compiledb 2> /dev/null)
            #l_version=$(compiledb -h 2> /dev/null)
            l_status=$?
            #if [ $l_status -ne 0 ] || [ -z "$l_version"]; then
            if [ -z "$l_version" ]; then

                print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
                echo "Instalando el comando 'compiledb' (modulo python) para generar una base de datos de compilacion Clang desde un make file."
                
                #Se instalar a nivel usuario
                pip3 install compiledb
            fi

            #3. Instalación de la libreria de refactorización de Python (https://github.com/python-rope/rope)
            l_version=$(pip3 list | grep rope 2> /dev/null)
            l_status=$?
            if [ -z "$l_version" ]; then

                print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
                echo "Instalando la libreria python 'rope' para refactorización de Python (https://github.com/python-rope/rope)."
                
                #Se instalara a nivel usuario
                pip3 install rope
            fi

            ;;

        *)
            return 0
            ;;
    esac

    #Por defecto, se debe continuar con la instalación
    return 0

}



#Codigo que se ejecuta cuando se inicializa la opcion de menu de desinstalación.
#
#Los argumentos de entrada son:
#  1 > Index de la opcion de menu elegista para desinstalar (ver el arreglo 'ga_menu_options_title').
#
#El valor de retorno puede ser:
#  0 > Si inicializo con exito.
#  1 > No se inicializo por opcion del usuario.
#  2 > Hubo un error en la inicialización.
#
uninstall_initialize_menu_option() {

    #1. Argumentos
    local p_option_relative_idx=$1

    #2. Inicialización
    local l_status
    #local l_artifact_index
    #local l_option_name="${ga_menu_options_title[${p_option_idx}]}"
    #local l_option_value=$((1 << p_option_idx))
    
    #3. Preguntar antes de eliminar los archivos
    printf 'Se va ha iniciar con la desinstalación de los siguientes packages: '
    
    #Obtener los repositorios a configurar
    local l_aux="${ga_menu_options_packages[$l_i]}"
    local IFS=','
    local la_repos=(${l_aux})
    IFS=$' \t\n'

    local l_n=${#la_repos[@]}
    local l_repo_names=''
    local l_repo_id
    for((l_j=0; l_j < ${l_n}; l_j++)); do

        l_repo_id="${la_repos[${l_j}]}"
        l_aux="${gA_packages[${l_repo_id}]}"
        if [ -z "$l_aux" ]; then
            l_aux="$l_repo_id"
        fi

        if [ $l_j -eq 0 ]; then
            l_repo_names="'${g_color_opaque}${l_aux}${g_color_reset}'" 
        else
            l_repo_names="${l_repo_names}, '${g_color_opaque}${l_aux}${g_color_reset}'"
        fi

    done
    printf '%b\n' "$l_repo_names"

    printf "%b¿Desea continuar con la desinstalación de estos packages?%b (ingrese 's' para 'si' y 'n' para 'no')%b [s]" "$g_color_warning" "$g_color_opaque" "$g_color_reset"
    read -rei 's' -p ': ' l_option
    if [ "$l_option" != "s" ]; then
        printf 'Se cancela la desinstalación de los packages\n'
        return 1
    fi

    #4. Realizar validaciones segun la opcion de menu escogida
    #case "$p_option_relative_idx" in

    #    6)
    #        #Container Runtime 'ContainerD'
    #        l_repo_id='containerd'
    #        

    #        #Si esta iniciado pero no acepta detenerlo
    #        if [ $l_status -eq 2 ]; then
    #            return 1
    #        fi
    #        ;;

    #    *)
    #        return 0
    #        ;;
    #esac

    #Por defecto, se debe continuar con la instalación
    return 0

}

#Codigo que se ejecuta cuando se finaliza la opcion de menu de desinstalación.
#
#Los argumentos de entrada son:
#  1 > Index de la opcion de menu elegista para desinstalar (ver el arreglo 'ga_menu_options_title').
#
#El valor de retorno puede ser:
#  0 > Si finalizo con exito.
#  1 > No se finalizo por opcion del usuario.
#  2 > Hubo un error en la finalización.
#
uninstall_finalize_menu_option() {

    #Argumentos
    local p_option_relative_idx=$1

    #local l_option_name="${ga_menu_options_title[${p_option_idx}]}"
    #local l_option_value=$((1 << p_option_idx))


    #Realizar validaciones segun la opcion de menu escogida

    #Por defecto, se debe continuar con la instalación
    return 0

}



