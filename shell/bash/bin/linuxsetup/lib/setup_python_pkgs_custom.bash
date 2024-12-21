#!/bin/bash

#------------------------------------------------------------------------------------------------------------------
#> Variables globales de inicialización y constantes {{{
#------------------------------------------------------------------------------------------------------------------

#ID de los paquetes y sus rutas bases
#Menu dinamico: Listado de repositorios que son instalados por las opcion de menu dinamicas
#  - Cada repositorio tiene un ID interno del un repositorios y un identifificador realizar: 
#    ['internal-id']='external-id'
#  - Por ejemplo para el repositorio GitHub 'stedolan/jq', el item se tendria:
#    ['jq']='stedolan/jq'
gA_packages=(
        ['curl']='curl'
        ['dotnetlib']="$g_empty_str"
    )


#WARNING: Un cambio en el orden implica modificar los indices de los eventos:
#         'install_initialize_menu_option', 'install_finalize_menu_option', 'uninstall_initialize_menu_option' y 'uninstall_finalize_menu_option'
#Menu dinamico: Titulos de las opciones del menú
#  - Cada entrada define un opcion de menú. Su valor define el titulo.
ga_menu_options_title=(
    "Paquetes basicos 1"
    "Paquetes basicos 2"
    "CLI de Oracle OCI"
    "CLI de Azure"
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
    "jtbl,compiledb,rope,pynvim,urlscan"
    "jtbl,compiledb,rope,pynvim,urlscan"
    ""
    ""
    )



#}}}


#------------------------------------------------------------------------------------------------------------------
#> Funciones de utilidad para la instalación/actualización
#------------------------------------------------------------------------------------------------------------------

#Funciones modificables de nivel 1 {{{


#Permite analizar si el binario existe en el SO, para determinar si el paquete esta instalado
#Parametros de entrada - Agumentos y opciones:
#  1 > ID de paquete
#Parametros de salida :
#  > STDOUT : El nombre del programa principal del paquete.
#    Si es empty, no se encuentra uno.
get_main_binary_of_package() {

    #Parametros
    local p_package_id="$1"


    #Obtener el nombre del programa asociado del paquete
    local l_program_name="$p_package_id"

    case "$p_package_id" in

        python)
            l_program_name="python3"
            ;;
        
        python-pip)
            l_program_name="pip3"
            ;;

    esac

    echo "$l_program_name" 

}


#Parametros de entrada - Agumentos y opciones:
#  1 > ID de paquete
#  2 > Nombre por defecto del paquete
#  3 > El tipo de distribucion Linux (variable 'g_os_subtype_id' generado por 'get_linux_type_info') 
#Parametros de salida :
#  > STDOUT           : El nombre real del paquete (segun el sistema operativo indicado)
#  > Valor de retorno : Tipo de busqueda del paquete
#    0 > Busqueda inexacta (texto buscado tiene que estar en cualquier parte del nombre del paquete)
#    1 > Busqueda exacta
#    9 > Error
get_package_name() {

    #Parametros
    if [ -z "$1" ] || [ -z "$2" ]; then
        return 9
    fi
    local p_package_id="$1"
    local p_package_name="$2"
    local p_os_subtype_id=$3

    #Obtener el nombre del paquete personalizado
    local l_package_name_custom="$p_package_name"
    #Por defecto la busqueda es inexacta, execto en alpine donde es exacta
    local l_search_type=0
    if [ $p_os_subtype_id -eq 1 ]; then
        l_search_type=1
    fi

    case "$p_package_id" in

        vim)

            #Si es un distribucion de la familia Debian
            if [ $p_os_subtype_id -ge 30 ] && [ $p_os_subtype_id -lt 50 ]; then

                #Si es Ubuntu
                l_package_name_custom="vim"
                l_search_type=1

            #Si es Alpine
            elif [ $p_os_subtype_id -eq 1 ]; then
                l_package_name_custom="vim"
                l_search_type=1
            fi 
            ;;

        python-pip)
            l_search_type=1

            #Si es Alpine
            if [ $p_os_subtype_id -eq 1 ]; then
                l_package_name_custom="py3-pip"
                l_search_type=1
            elif [ $p_os_subtype_id -eq 19 ]; then
                l_package_name_custom="python3-pip"
                l_search_type=1
            fi 
            ;;

        xvfb)

            #Si es un distribucion de la familia Debian
            if [ $p_os_subtype_id -ge 30 ] && [ $p_os_subtype_id -lt 50 ]; then
                #Si es Ubuntu
                l_package_name_custom="xvfb"
                l_search_type=1
            fi 
            ;;

        xauth)

            #Si es un distribucion de la familia Debian
            if [ $p_os_subtype_id -ge 30 ] && [ $p_os_subtype_id -lt 50 ]; then
                #Si es Ubuntu
                l_package_name_custom="xauth"
                l_search_type=1
            fi 
            ;;

    esac

    echo "$l_package_name_custom"
    return $l_search_type


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


#Parametro de entrada:
# 1> ID del repositorio 
#Parametros de salida:
#  > Valores de retorno
#      0 > Se inicio la instalación y termino existosamente
#      1 > Se inicio la instalación y termino con errores
#      2 > No se inicio la instalación: El paquete ya esta instalado 
#      5 > No se inicio la instalación: Se envio otros parametros invalidos
#    120 > No se inicio la instalación: No se permitio almacenar las credenciales para sudo
install_custom_packages() {

    local p_package_id="$1"
    local l_status=0

    case "$p_package_id" in

        dotnetlib)
            
            #Solo si tiene acceso a root
            if [ $g_runner_sudo_support -ne 2 ] && [ $g_runner_sudo_support -ne 3 ]; then
                install_dotnet_lib
                l_status=$?
            fi
            ;;
        
    esac


    #Si no se acepto almacenar credenciales
    if [ $l_status -eq 120 ]; then
        return 120
    #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
       g_status_crendential_storage=0
    fi

    #OK
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
    #local l_version
    #local l_status

    #case "$p_option_relative_idx" in

    #    #RTE Python
    #    3)

    #        ;;

    #    *)
    #        return 0
    #        ;;
    #esac

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
        if [ -z "$l_aux" ] || [ "$l_aux" = "$g_empty_str" ]; then
            l_aux="$l_repo_id"
        fi

        if [ $l_j -eq 0 ]; then
            l_repo_names="'${g_color_gray1}${l_aux}${g_color_reset}'" 
        else
            l_repo_names="${l_repo_names}, '${g_color_gray1}${l_aux}${g_color_reset}'"
        fi

    done
    printf '%b\n' "$l_repo_names"

    if [ $gp_type_calling -ne 3 ] && [ $gp_type_calling -ne 4 ]; then
        printf "%b¿Desea continuar con la desinstalación de estos packages?%b (ingrese 's' para 'si' y 'n' para 'no')%b [s]" "$g_color_red1" "$g_color_gray1" "$g_color_reset"
        read -rei 's' -p ': ' l_option
        if [ "$l_option" != "s" ]; then
            printf 'Se cancela la desinstalación de los packages\n'
            return 1
        fi
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



#}}}

