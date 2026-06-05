#!/bin/bash

# Obtenido y modificado de https://github.com/junegunn/fzf-git.sh

# Constantes
g_fzf_height='60%'
g_fzf_popup_height='80%'
g_fzf_popup_width='99%'

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

g_cmd_name='springu'

declare -a ga_exported_functions=(
    )

# Diccionario de sbucomandos. La key es 'id del subcomando' y value es 'la descripcion del subcomando'.
# > Segun el ID de subcomando, se debe tener 2 funciones bash cuyo nombre tiene dicho ID
#   > Funcion de ayuda del comando tiene el nombre 'm_usage_CMD-ID'.
#   > Funcion de controlador del comando tiene el nombre 'controller_CMD-ID'.
declare -A gA_subcmd_ids=(
        ['encrypt']='Encripta una cadena usando el spring security'
        ['decrypt']='Desncripta una cadena usando el spring security'
    )


# Diccionario de sbucomandos. La key es 'alias' y value es 'ID del subcomando'.
declare -A gA_subcmd_alias=(
    )




# -------------------------------------------------------------------------------------
# General functions
# -------------------------------------------------------------------------------------



# -------------------------------------------------------------------------------------
# Exported functions
# -------------------------------------------------------------------------------------




# -------------------------------------------------------------------------------------
# Subcomand Controller> 'encrypt' y 'decrypt'
# -------------------------------------------------------------------------------------

# Requisitos:
# > jar 'spring-crypto-cli-1.2.0-jar-with-dependencies.jar'
#   > Descarguelo de la URL: https://github.com/mptechnology/spring-crypto-cli
#   > Copialo a la ruta '~/.local/lib' :
#     mkdir ~/.local/lib
#     cp spring-crypto-cli-1.2.0-jar-with-dependencies.jar ~/.local/lib/spring-crypto-cli.jar
g_crypto_jar="$HOME/.local/lib/spring-crypto-cli.jar"


m_usage_crypto() {

    local l_scmd_id="encrypt"
    if [ "$1" = "1" ]; then
        l_scmd_id="decrypt"
    fi

    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '    %b%s %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s %s%b MESSAGE%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s %s%b -k CRYPTO_KEY MESSAGE%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h|--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %b-k CRYPTO_KEY%b La clave de la encriptacion simetrica usada.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bSi no se especifica, se buscara el valor de la variable de entorno CRYPTO_KEY.%b\n\n' "$g_color_gray1" "$g_color_reset"

    printf 'Los argumentos usados son:\n'
    printf '  > %bMESSAGE%b Es el texto a %b%s%b.%b\n\n' "$g_color_green1" "$g_color_gray1" "$g_color_yellow1" "$l_scmd_id" \
           "$g_color_gray1" "$g_color_reset"

}


# Listar los procesos del SO
m_cryto_util() {

    local l_scmd="encrypt"
    if [ "$1" = "1" ]; then
        l_scmd="decrypt"
    fi

    local p_key="$2"
    local p_message="$3"

    if [ -z "$JAVA_HOME" ]; then
        java -jar "$g_crypto_jar" "$l_scmd" --key "$p_key" --message "$p_message"
    else
        "${JAVA_HOME}/bin/java" "$l_scmd" -jar "$g_crypto_jar" --key "$p_key" --message "$p_message"
    fi

}


m_controller_crypto() {

    #1. Procesar el 1er argumento
    local -i p_flag_encrypt=0
    if [ "$1" = "1" ]; then
        p_flag_encrypt=1
    fi

    shift


    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    local l_key=''

    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_crypto $p_flag_encrypt
                return 0
                ;;


            -k)
                if [ -z "$2" ]; then
                    printf '[%bERROR%b] Opción "%b%s%b" no puede tener un valor vacio.\n\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "$1" "$g_color_reset"
                    m_usage_crypto $p_flag_encrypt
                fi

                l_key="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_crypto $p_flag_encrypt
                return 3
                ;;


            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done

    #2. Si no especifico el 'key', obtenerlo de la variable de entorno 'CRYPTO_KEY'
    if [ ! -z "$CRYPTO_KEY" ]; then
        l_key='$CRYPTO_KEY'
    fi

    if [ -z "$l_key" ]; then
        printf '[%bERROR%b] Debe ingresar el "%b%s%b" ya sea usando la opcion "%b-%s%b" o la variable de entorno "%b%s%b".\n\n' "$g_color_red1" "$g_color_reset" \
               "$g_color_gray1" "crypto key" "$g_color_reset" "$g_color_gray1" "k" "$g_color_reset" "$g_color_gray1" "CRYPTO_KEY" "$g_color_reset"

        m_usage_crypto $p_flag_encrypt
        return 3
    fi

    #4. Leer los argumentos restantes
    local l_message="$1"

    if [ -z "$l_message" ]; then
        printf '[%bERROR%b] El argumeno mensaje es requerido.\n\n' "$g_color_red1" "$g_color_reset"
        m_usage_crypto $p_flag_encrypt
        return 3
    fi

    #5. Ejecutando el comando
    m_cryto_util $p_flag_encrypt "$l_key" "$l_message"
    return 0

}


controller_encrypt() {

    m_controller_crypto 0 "$@"
}


controller_decrypt() {

    m_controller_crypto 1 "$@"
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
    if [ -z "$JAVA_HOME" ]; then

        if ! command -v java >/dev/null 2>&1; then
            printf '[%bERROR%b] Se debe tener el comando "%b%s%b" instalado.\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" "java" "$g_color_reset"
            return 1
        fi

    else

        if [ ! -f "${JAVA_HOME}/bin/java" ]; then
            printf '[%bERROR%b] El comando "%b%s%b" no esta en el "${JAVA_HOME}/bin" (%b%s%b).\n' "$g_color_red1" "$g_color_reset" \
                   "$g_color_gray1" "java" "$g_color_reset" "$g_color_gray1" "${JAVA_HOME}/bin" "$g_color_reset"
            return 1
        fi

        if ! "${JAVA_HOME}/bin/java" --version >/dev/null 2>&1; then
            printf '[%bERROR%b] El comando "%b%s%b" es invalido.\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" "java" "$g_color_reset"
            return 1
        fi

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
