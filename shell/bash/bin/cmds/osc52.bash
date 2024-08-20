#!/bin/bash

#-------------------------------------------------------------------------------------------
#Modificado de 'https://chromium.googlesource.com/apps/libapps/+/HEAD/hterm/etc/osc52.sh'
#-------------------------------------------------------------------------------------------

# Max length of the OSC 52 sequence.  Sequences longer than this will not be sent to the terminal.
OSC_52_MAX_SEQUENCE="100000"


# Send a DCS sequence through tmux.
tmux_dcs() {
  printf '\033Ptmux;\033%s\033\\' "$1"
}

# Send a DCS sequence through screen.
screen_dcs() {
  # Screen limits the length of string sequences, so we have to break it up.
  # Going by the screen history:
  #   (v4.2.1) Apr 2014 - today: 768 bytes
  #   Aug 2008 - Apr 2014 (v4.2.0): 512 bytes
  #   ??? - Aug 2008 (v4.0.3): 256 bytes
  # Since v4.2.0 is only ~4 years old, we'll use the 256 limit.
  # We can probably switch to the 768 limit in 2022.
  local limit=256
  # We go 4 bytes under the limit because we're going to insert two bytes
  # before (\eP) and 2 bytes after (\e\) each string.
  echo "$1" | \
    sed -E "s:.{$(( limit - 4 ))}:&\n:g" | \
    sed -E -e 's:^:\x1bP:' -e 's:$:\x1b\\:' | \
    tr -d '\n'
}


#Parametros de entrada> Argumentos
#  3> Indica el formato que se usara para enviar al clipboard.
#    0 > Formato OSC 52 estandar que es enviado directmente una terminal que NO use como '$TERM' a GNU screen.
#    1 > Formato OSC52 es dividio en pequeños trozos y enmascador en formato DSC, para enviarlo directmente a una terminal 
#        basada en GNU ('$TERM' inicia con screen).
#    2 > Formato OSC52 se enmascara DSC enmascarado para TMUX (tmux requiere un formato determinado) y sera este el que 
#        decida si este debera reenvíarse a la terminal donde corre tmux (en este caso Tmux desenmacara y lo envia).
#
put_clipboard() {

    #Argumentos
    local p_use_stdin=1
    if [ "$1" = "0" ]; then
        p_use_stdin=0
    fi

    local p_flag_force=1
    if [ "$2" = "0" ]; then
        p_flag_force=0
    fi

    local p_format=$3
    local p_data="$4"

    #echo "use_stdin: $1"
    #echo "flag_force: $2"
    #echo "format: $3"
    #echo "data: $4"

    if [ -z "$p_data" ]; then
        return 9
    fi

    #Si el formato no se especifica, calcularlo
    if [ $p_format -eq -1 ]; then
        if [ ! -z "$TMUX" ]; then
            p_format=2
        else
            case "$TERM" in
                screen*)
                    p_format=1
                    ;;
                *)
                    p_format=0
                    ;;                
            esac
        fi
    fi

    #echo "format: $p_format"

    #Codificar la data en base64
    local l_base64_data
    l_base64_data="$(printf '%s' "$p_data" |  base64 -w 0)"
    #l_base64_data=$(printf '%s' "$p_data" |  base64 | tr -d '\n')
    if [ $? -ne 0 ]; then
        printf '[OSC52] No found base64 command\n'
        return 3
    fi

    #Si se supera la cantidad limite de caracteres salir
    local l_len=${#l_base64_data}
    if [ $p_flag_force -ne 0 ]; then
        if [ ${l_len} -gt ${OSC_52_MAX_SEQUENCE} ]; then
            printf '[OSC52] Text is too long to send to terminal: size=%s, limit=%s\n' "$l_len" "${OSC_52_MAX_SEQUENCE}"
            return 2
        fi
    fi

    #Formatear el texto en OSC52
    local l_osc52_data
    l_osc52_data="$(printf '\033]52;c;%s\a' "$l_base64_data")"

    #Enviar el texto al clipboard, segun el formato
    if [ $p_format -eq 1 ]; then
        screen_dcs "$l_osc52_data"
    elif [ $p_format -eq 2 ]; then
        tmux_dcs "$l_osc52_data"
    else
        printf '%s' "$l_osc52_data"
    fi

    return 0

}

_usage() {

    if [ ! -z "$1" ]; then
        printf '%s\n\n' "$1"
    fi

    cat <<EOF
Usage: osc52 [options] [string]
Send an arbitrary string to the terminal clipboard using the OSC 52 escape sequence as specified in xterm.

Examples:
  > The data can either be read from stdin:
    $ echo "hello world" | osc52 -i
    $ echo "hello world" | osc52 -it 2
  > Specified on the command line:
    $ osc52 "hello world"
    $ osc52 -t 2 "hello world"

Options:
  -h    This screen.
  -f    Ignore max byte limit (${OSC_52_MAX_SEQUENCE})
  -i    The command read the data of STDIN.
  -t    Format to send OSC52.
        0 - Envia la secuancia de escape OSC52 sin enmascararlo.
        1 - Envia la secuencia en trozos enmascarado en DSC, requerido para terminal GNU ('\$TERM' inicia con srcreen).
        2 - Envia la secuancia enmascarado en DSC para el formato Tmux. Tmux captura este valor y decide si lo reenvía
            o no la terminal.
        Otro valor, se intenta calcularlo automaticamente.
EOF

}


main() {

    #1. Opciones y Argumentos
    local l_use_stdin=1
    local l_flag_force=1
    local l_format=-1
    local l_data=''

    #2. Leer las opciones
    local l_option
    local l_aux
    while getopts "hift::" l_option; do

        case "$l_option" in
            h)
                _usage
                return 0
                ;;

            i)
                l_use_stdin=0
                ;;

            f)
                l_flag_force=0
                ;;

            t)
                l_aux="${OPTARG}"
                if [ "$l_aux" != "0" ] && [ "$l_aux" != "1" ] && [ "$l_aux" != "2" ]; then
                    _usage "Option '-t' has invalid value '%s'." "$l_aux"
                    return 9
                fi
                l_format=$l_aux                
                ;;

            *)
                _usage "Option '-%s' is invalid." "$l_option"
                return 9
                ;;
        esac

    done

    #3. Remover las opciones de arreglo de de argumentos y opciones '$@'
    shift $((OPTIND-1))

    #4. Leer los argumento
    if [ $l_use_stdin -eq 0 ]; then
        l_data=$(cat)
        #l_data=$(< /dev/stdin)
    else

        if [ -z "$1" ]; then
            _usage
            return 9
        fi
        l_data="$1"
    fi


    #5. Validaciones adicionales de las opciones y argumentos
    #if [ -z "$l_use_stdin" ] || [ -z "$l_flag_force" ]; then
    #    usage
    #fi

    #6. Invocar la funcion principal
    local l_status=0
    put_clipboard $l_use_stdin $l_flag_force $l_format "$l_data"
    return $l_status

}


#_main "$@"
main "$@"
_g_result=$?
exit $g_result
