#!/bin/bash

#Inicialización Global {{{


#Colores principales usados para presentar información (menu,...)
g_color_reset="\x1b[0m"
g_color_green1="\x1b[32m"
g_color_gray1="\x1b[90m"
g_color_cian1="\x1b[36m"
g_color_yellow1="\x1b[33m"
g_color_red1="\x1b[31m"
g_color_blue1="\x1b[34m"

#Tamaño de la linea del menu
g_max_length_line=130

declare -r g_empty_str='EMPTY'

#}}}

#Validar si la carpeta esta creado y tiene permiso de escritura, si no lo esta intenta crearlo.
# - Si esta creada pero no tiene permisos de escritura, intenta establecer el owner solicitando acceso a root.
# - Si no esta creada intenta crearlo solicitando acceso a root.
#
#Parametro de salida:
#  00 > OK   La carpeta existe y se tiene acceso a escritura.
#  01 > OK   La carpeta existe, no tenia permiso de escritura, pero se establecio como owner.
#  02 > OK   La carpeta no existe, pero se creo con permisos de escritura (owner del folder).
#  03 > NOOK La carpeta existe, pero no se tiene permisos para establecer como owner. 
#  04 > NOOK La carpeta no existe, pero no se tiene permisos para crearlo. 
#  99 > NOOK Parametro invalidos.
#
function _try_create_standard_prg_path() {

    #1. Argumentos 
    local p_path_programs="$1"

    if [ -z "$p_path_programs" ]; then
        return 99
    fi
    
    #2. Si existe la carpeta, validar si tiene permisos de escritura, si no se tiene intentarlo establecer.
    local l_status
    local l_group_name
    if [ -d "$p_path_programs" ]; then

        #2.1. Si tiene acceso de escritura
        if [ -w "$p_path_programs" ]; then
            return 0
        fi

        #2.2. Si no tiene acceso de escritura, establecer permisos de escritura (para los usuarios no son root)
        # > 1 : se soporta el comando sudo sin password
        if [ $g_user_sudo_support -eq 1 ]; then

            #Establecer como owner
            if l_group_name=$(id -gn 2> /dev/null); then
                sudo chown ${USER}:${l_group_name} "$p_path_programs"
            else
                sudo chown ${USER} "$p_path_programs"
            fi

            return 0

        # > 0 : se soporta el comando sudo con password (solo si es interactivo)
        elif [ $g_user_sudo_support -eq 0 ] && [ $p_is_noninteractive -ne 0 ]; then

            printf 'Se requiere establecer como owner la carpeta "%b%s%b" de programas, para ello se requiere usar sudo con root...\n' "$g_color_gray1" "$p_path_programs" "$g_color_reset"

            #Establecer como owner
            if l_group_name=$(id -gn 2> /dev/null); then
                sudo chown ${USER}:${l_group_name} "$p_path_programs"
                l_status=$?
            else
                sudo chown ${USER} "$p_path_programs"
                l_status=$?
            fi

            #Creando subdirectorios opcionales
            if [ $l_status -eq 0 ]; then
                return 1
            else
                return 3
            fi

        fi

        # Cualquier otro caso, no se tiene permisos
        return 3

    fi

    #3. Si no existe intentar crearlo si tiene permiso para ello

    # > 4 : El usuario es root (no requiere sudo)
    if [ $g_user_sudo_support -eq 4 ]; then

        mkdir -pm 755 "$p_path_programs"
        l_status=$?

        mkdir -pm 755 "$p_path_programs/sharedkeys"
        mkdir -pm 755 "$p_path_programs/sharedkeys/tls"
        mkdir -pm 755 "$p_path_programs/sharedkeys/ssh"

        if [ ! -z "$p_other_calling_user" ]; then
            chown -R "$p_other_calling_user" "$p_path_programs"
        fi

        return 2

    # > 1 : se soporta el comando sudo sin password
    elif [ $g_user_sudo_support -eq 1 ]; then

        sudo mkdir -pm 755 "$p_path_programs"
        l_status=$?

        #Establecer como owner
        if l_group_name=$(id -gn 2> /dev/null); then
            sudo chown ${USER}:${l_group_name} "$p_path_programs"
        else
            sudo chown ${USER} "$p_path_programs"
        fi

        #Creando subdirectorios opcionales
        mkdir -pm 755 "$p_path_programs/sharedkeys"
        mkdir -pm 755 "$p_path_programs/sharedkeys/tls"
        mkdir -pm 755 "$p_path_programs/sharedkeys/ssh"

        return 2

    # > 0 : se soporta el comando sudo con password (solo si es interactivo)
    elif [ $g_user_sudo_support -eq 0 ] && [ $p_is_noninteractive -ne 0 ]; then

        printf 'Se requiere crear la carpeta "%b%s%b" de programas, para ello se requiere usar sudo con root...\n' "$g_color_gray1" "$p_path_programs" "$g_color_reset"
        if sudo mkdir -pm 755 "$p_path_programs"; then

            #Establecer como owner
            if l_group_name=$(id -gn 2> /dev/null); then
                sudo chown ${USER}:${l_group_name} "$p_path_programs"
                l_status=$?
            else
                sudo chown ${USER} "$p_path_programs"
                l_status=$?
            fi

            #Creando subdirectorios opcionales
            if [ $l_status -eq 0 ]; then

                mkdir -pm 755 "$p_path_programs/sharedkeys"
                mkdir -pm 755 "$p_path_programs/sharedkeys/tls"
                mkdir -pm 755 "$p_path_programs/sharedkeys/ssh"
                return 2

            fi

            #Cualquier otro caso, no se tiene permisos
            return 4

        fi

        #Cualquier otro caso, no se tiene permisos
        return 4

    fi

    #Cualquier otro caso, no se tiene permisos
    return 4

}


#
#Establece el ruta de los programas (incluyen mas de 1 comando) 'g_path_programs' a instalar.
#Orden de prioridad:
#  > La carpeta ingresada como parametro 3, siempre que existe y el usuario de ejecución tiene permisos de escritura,
#  > La carpeta '/var/opt/tools', si existe y tiene permisos de escritura. Si no tiene permisos intenta adicionarlo, si no existe intenta crearlo,
#  > La carpeta '/opt/tools', si '/var/opt/tools' existe pero no se tiene permisos de escritura o no existe y no se tiene permisos para crearlo.
#  > La carpeta '~/tools', si '/opt/tools' existe pero no se tiene permisos de escritura o no existe y no se tiene permisos para crearlo.
#
#Parametros de entrada:
# 1> Path base donde se encuentra el repositorio de los script de instalación (por defecto es '$HOME')
# 2> Flag '0' si no es interactivo, '1' si es interactivo
# 3> Ruta donde se ubicaran los programas descargsdos
#    Si es vacio, no se se usara las carpetas '/var/opt/tools' o '~/tools'
# 4> 'UID:GID' solo si se ejecuta un usuario root y es diferente al usuario que pertenece este script de instalación (es decir donde esta el repositorio)
#Parametros de salida:
#  > Variables globales: 'g_path_programs'
#  > Valor de retorno
#     00> Si es establecio sin errores
#     01> Si existe errores en la conversion: el directorio programa existe no existe y no se ha podido crearse automaticamente
function set_program_path() {

    local p_path_base
    if [ -z "$1" ]; then
        p_path_base="$HOME"
    else
        p_path_base="$1"
    fi

    local p_is_noninteractive=1
    if [ "$2" = "0" ]; then
        p_is_noninteractive=0
    fi

    local p_path_programs="$3"

    #Si se ejecuta un usuario root y es diferente al usuario que pertenece este script de instalación (es decir donde esta el repositorio)
    #UID del Usuario y GID del grupo (diferente al actual) que ejecuta el script actual
    local p_other_calling_user
    if [ ! -z "$4" ]; then
        p_other_calling_user="$4"
    fi


    #1. Si es directorio personalizado del usuario y tienes acceso de escritura
    if  [ ! -z "$p_path_programs" ] && [ "$p_path_programs" != "/var/opt/tools" ] && [ -d "$p_path_programs" ] && [ -w "$p_path_programs" ]; then
        g_path_programs="$p_path_programs"
        return 0
    fi

    #2. Intento de usar el directorio por defecto '/var/opt/tools'
    local l_status

    if [ -d "/var/opt" ]; then

        # 00 > OK   La carpeta existe y se tiene acceso a escritura.
        # 01 > OK   La carpeta existe, no tenia permiso de escritura, pero se establecio como owner.
        # 02 > OK   La carpeta no existe, pero se creo con permisos de escritura (owner del folder).
        # 03 > NOOK La carpeta existe, pero no se tiene permisos para establecer como owner. 
        # 04 > NOOK La carpeta no existe, pero no se tiene permisos para crearlo. 
        # 99 > NOOK Parametro invalidos.
        _try_create_standard_prg_path '/var/opt/tools'
        l_status=$?

        if [ $l_status -ge 0 ] && [ $l_status -le 2 ]; then
            g_path_programs="/var/opt/tools"
            return 0
        fi

        #Si la carpeta existe, pero no se puede establacer permisos de escritura (owner de la carpeta)
        if [ $l_status -eq 3 ]; then
            printf 'No se puede establecer como owner la carpeta "%b%s%b" de programas. %bSe intentara usar como carpeta de programas a "%b%s%b"...%b\n' \
                   "$g_color_gray1" "/var/opt/tools" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "/opt/tools"  "$g_color_gray1" "$g_color_reset"
        fi

        #Si la carpeta no existe y no se ha podido crear la carpeta
        if [ $l_status -eq 4 ]; then
            printf 'No se tiene permisos para crear la carpeta "%b%s%b" de programas. %bSe intentara usar como carpeta de programas a "%b%s%b"...%b\n' \
                   "$g_color_gray1" "/var/opt/tools" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "/opt/tools"  "$g_color_gray1" "$g_color_reset"
        fi

        if [ $l_status -gt 4 ]; then
            printf 'No se puede crear la carpeta "%b%s%b" de programas (code %s). %bSe intentara usar como carpeta de programas a "%b%s%b"...%b\n' \
                   "$g_color_gray1" "/var/opt/tools" "$g_color_reset" "$l_status" "$g_color_gray1" "$g_color_reset" "/opt/tools"  "$g_color_gray1" "$g_color_reset"
        fi

    else

        printf 'No existe la carpeta "%b%s%b". %bSe intentara usar como carpeta de programas a "%b%s%b"...%b\n' \
               "$g_color_gray1" "/var/opt" "$g_color_reset" "$l_status" "$g_color_gray1" "$g_color_reset" "/opt/tools"  "$g_color_gray1" "$g_color_reset"

    fi

    #3. Intento de usar el directorio por defecto '/opt/tools'
    if [ -d "/opt" ]; then

        # 00 > OK   La carpeta existe y se tiene acceso a escritura.
        # 01 > OK   La carpeta existe, no tenia permiso de escritura, pero se establecio como owner.
        # 02 > OK   La carpeta no existe, pero se creo con permisos de escritura (owner del folder).
        # 03 > NOOK La carpeta existe, pero no se tiene permisos para establecer como owner. 
        # 04 > NOOK La carpeta no existe, pero no se tiene permisos para crearlo. 
        # 99 > NOOK Parametro invalidos.
        _try_create_standard_prg_path '/opt/tools'
        l_status=$?

        if [ $l_status -ge 0 ] && [ $l_status -le 2 ]; then
            g_path_programs="/opt/tools"
            return 0
        fi

        #Si la carpeta existe, pero no se puede establacer permisos de escritura (owner de la carpeta)
        if [ $l_status -eq 3 ]; then
            printf 'No se puede establecer como owner la carpeta "%b%s%b" de programas. %bSe intentara usar como carpeta de programas a "%b%s%b"...%b\n' \
                   "$g_color_gray1" "/opt/tools" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "${p_path_base}/tools"  "$g_color_gray1" "$g_color_reset"
        fi

        #Si la carpeta no existe y no se ha podido crear la carpeta
        if [ $l_status -eq 4 ]; then
            printf 'No se tiene permisos para crear la carpeta "%b%s%b" de programas. %bSe intentara usar como carpeta de programas a "%b%s%b"...%b\n' \
                   "$g_color_gray1" "/opt/tools" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "${p_path_base}/tools"  "$g_color_gray1" "$g_color_reset"
        fi

        if [ $l_status -gt 4 ]; then
            printf 'No se puede crear la carpeta "%b%s%b" de programas (code %s). %bSe intentara usar como carpeta de programas a "%b%s%b"...%b\n' \
                   "$g_color_gray1" "/opt/tools" "$g_color_reset" "$l_status" "$g_color_gray1" "$g_color_reset" "${p_path_base}/tools"  "$g_color_gray1" "$g_color_reset"
        fi

    else
        printf 'No existe la carpeta "%b%s%b". %bSe intentara usar como carpeta de programas a "%b%s%b"...%b\n' \
               "$g_color_gray1" "/opt" "$g_color_reset" "$l_status" "$g_color_gray1" "$g_color_reset" "${p_path_base}/tools"  "$g_color_gray1" "$g_color_reset"
    fi


    #4. Usar la carpeta '~/tools' (si '/opt/tools' existe pero no se tiene permisos de escritura o no existe y no se tiene permisos para crearlo).
    # > 0 : se soporta el comando sudo con password (solo no es interactivo)
    # > 2 : El SO no implementa el comando sudo
    # > 3 : El usuario no tiene permisos para ejecutar sudo
    g_path_programs="${p_path_base}/tools"

    #Si no existe crearlo
    if [ ! -d "$g_path_programs" ]; then

        mkdir -pm 755 "$g_path_programs"
        l_status=$?

        mkdir -pm 755 "$g_path_programs/sharedkeys"
        mkdir -pm 755 "$g_path_programs/sharedkeys/tls"
        mkdir -pm 755 "$g_path_programs/sharedkeys/ssh"

        if [ ! -z "$p_other_calling_user" ]; then
            chown -R "$p_other_calling_user" "$g_path_programs"
        fi

    fi

    return 0

}


#
#Establece la ruta de los comandos del binario/man/fuente, es decir 'g_path_bin'/'g_path_man'/'g_path_fonts'/'g_path_cmd_base', donde se instalará.
#Orden de prioridad:
#  > La carpeta ingresada como parametro 3, siempre que existe y el usuario de ejecución tiene permisos de escritura,
#  > La carpeta predeterminado para todos los usuarios ('/usr/local/bin', '/usr/local/man/man1' y '/usr/share/fonts'), si existe tenga permisos como root o sudo para root.
#  > La carpeta predeterminado para el usuario '~/.local', si en las carpeta anterior no tiene permisos de root o sudo para root.
#
#Parametros de entrada:
# 1> Path base donde se encuentra el repostorio de los script de instalación (por defecto es '$HOME')
# 2> Flag '0' si no es interactivo, '1' si es interactivo
# 3> Ruta base donde se ubicaran los programas descargados usando la rutas:
#      > Binarios   : PATH_BASE/bin
#      > Ayuda man1 : PATH_BASE/man/man1
#      > Fuentes    : PATH_BASE/share/fonts
#    Si es vacio, no se se usara las carpetas predeterminados
# 4> 'UID:GID' solo si se ejecuta un usuario root y es diferente al usuario que pertenece este script de instalación (es decir donde esta el repositorio)
#Parametros de salida:
#  > Variables globales: 'g_path_bin', 'g_path_man' y 'g_path_fonts'
#  > Valor de retorno
#     00> Si es establecio sin errores
#     01> Si el directorio programa existe no existe y no se ha podido crearse automaticamente
function set_command_path() {

    local p_path_base
    if [ -z "$1" ]; then
        p_path_base="$HOME"
    else
        p_path_base="$1"
    fi

    local p_is_noninteractive=1
    if [ "$2" = "0" ]; then
        p_is_noninteractive=0
    fi

    local p_path_command_base="$3"

    #Si se ejecuta un usuario root y es diferente al usuario que pertenece este script de instalación (es decir donde esta el repositorio)
    #UID del Usuario y GID del grupo (diferente al actual) que ejecuta el script actual
    local p_other_calling_user
    if [ ! -z "$4" ]; then
        p_other_calling_user="$4"
    fi

    
    g_path_cmd_base=''

    #1. Usar el directorio personalizado del usuario (siempre que existe y tienes acceso de escritura)
    #if [ ! -z "$p_path_command_base" ] && [ "$p_path_command_base" != "${g_path_base}/.local" ] && [ -d "$p_path_command_base" ] && [ -w "$p_path_command_base" ]; then
    if [ ! -z "$p_path_command_base" ] && [ -d "$p_path_command_base" ] && [ -w "$p_path_command_base" ]; then

        g_path_cmd_base="$p_path_command_base"
        g_path_bin="${p_path_command_base}/bin"
        g_path_man="${p_path_command_base}/man/man1"
        g_path_fonts="${p_path_command_base}/share/fonts"

        #Si no existe los folderes, crearlo
        if [ ! -d "$g_path_bin" ]; then
            mkdir -pm 755 "$g_path_bin"
            if [ ! -z "$p_other_calling_user" ]; then
                chown "$p_other_calling_user" "$g_path_bin"
            fi
        fi

        if [ ! -d "$g_path_man" ]; then
            mkdir -pm 755 "$g_path_man"
            if [ ! -z "$p_other_calling_user" ]; then
                chown "$p_other_calling_user" "$g_path_man"
            fi
        fi

        if [ ! -d "$g_path_fonts" ]; then
            mkdir -pm 755 "$g_path_fonts"
            if [ ! -z "$p_other_calling_user" ]; then
                chown "$p_other_calling_user" "$g_path_fonts"
            fi
        fi

        return 0
    fi

    #2. Usar la carpeta predeterminado para todos los usuarios, siempre que tenga permisos como root o sudo para root.
    #   Folderes: '/usr/local/bin', '/usr/local/man/man1' y '/usr/share/fonts'

    # > 4 : El usuario es root (no requiere sudo)
    if [ $g_user_sudo_support -eq 4 ]; then

        g_path_cmd_base=''
        g_path_bin='/usr/local/bin'
        g_path_man='/usr/local/man/man1'
        g_path_fonts='/usr/share/fonts'

        if [ ! -d "$g_path_man" ]; then
            mkdir -p "$g_path_man"
        fi

        if [ ! -d "$g_path_fonts" ]; then
            mkdir -p "$g_path_fonts"
        fi

        return 0

    # > 1 : se soporta el comando sudo sin password
    elif [ $g_user_sudo_support -eq 1 ]; then

        g_path_cmd_base=''
        g_path_bin='/usr/local/bin'
        g_path_man='/usr/local/man/man1'
        g_path_fonts='/usr/share/fonts'

        #if [ ! -d "$g_path_man" ]; then
        #    sudo mkdir -p "$g_path_man"
        #fi

        #if [ ! -d "$g_path_fonts" ]; then
        #    sudo mkdir -p "$g_path_fonts"
        #fi

        return 0

    # > 0 : se soporta el comando sudo con password (solo si es interactivo)
    elif [ $g_user_sudo_support -eq 0 ] && [ $p_is_noninteractive -eq 1 ]; then

        g_path_cmd_base=''
        g_path_bin='/usr/local/bin'
        g_path_man='/usr/local/man/man1'
        g_path_fonts='/usr/share/fonts'

        return 0

    else
        printf 'No se tiene permiso a la carpeta "%b%s%b" de programas. %bSe usara como carpeta de programas a "%b%s%b"...%b\n' \
               "$g_color_gray1" "/usr/local/bin" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "${p_path_base}/.local/bin"  "$g_color_gray1" "$g_color_reset"
    fi

    #3. Usar la carpeta predeterminado para el usuario '~/.local' (si en las carpeta anterior no tiene permisos de root o sudo para root).
    # > 0 : se soporta el comando sudo con password (solo no es interactivo)
    # > 2 : El SO no implementa el comando sudo
    # > 3 : El usuario no tiene permisos para ejecutar sudo
    g_path_cmd_base="${p_path_base}/.local"
    g_path_bin="${g_path_cmd_base}/bin"
    g_path_man="${g_path_cmd_base}/man/man1"
    g_path_fonts="${g_path_cmd_base}/share/fonts"

    #Si no existe crearlo
    if [ ! -d "${g_path_cmd_base}" ]; then

        mkdir -pm 755 "${g_path_cmd_base}"
        mkdir -pm 755 "$g_path_bin"
        mkdir -pm 755 "$g_path_man"
        mkdir -pm 755 "$g_path_man"

        if [ ! -z "$p_other_calling_user" ]; then
            chown -R "$p_other_calling_user" "${g_path_cmd_base}"
        fi

    else

        if [ ! -d "$g_path_bin" ]; then
            mkdir -p "$g_path_bin"
            if [ ! -z "$p_other_calling_user" ]; then
                chown "$p_other_calling_user" "$g_path_bin"
            fi
        fi

        if [ ! -d "$g_path_man" ]; then
            mkdir -p "$g_path_man"
            if [ ! -z "$p_other_calling_user" ]; then
                chown "$p_other_calling_user" "$g_path_man"
            fi
        fi

        if [ ! -d "$g_path_fonts" ]; then
            mkdir -p "$g_path_fonts"
            if [ ! -z "$p_other_calling_user" ]; then
                chown "$p_other_calling_user" "$g_path_fonts"
            fi
        fi

    fi

    return 0

}



#
#Establece la ruta de los archivos temporales, es decir 'g_path_temp', donde se descargaran archivos comprimidos del repositorio externos (como GitHub).
#Orden de prioridad:
#  > La carpeta ingresada como parametro 1, siempre que existe y el usuario de ejecución tiene permisos de escritura.
#  > La carpeta predeterminado para el usuario '/tmp', si en las carpeta anterior no tiene permisos de root o sudo para root.
#
#Parametros de entrada:
# 1> Ruta base donde se ubicaran los archivo temporales. Si es vacio, no se se usara la carpeta predeterminado '/tmp'.
#Parametros de salida:
#  > Variables globales: 'g_path_temp'
#  > Valor de retorno
#     00> Si es establecio sin errores
#     01> Si el directorio programa existe no existe y no se ha podido crearse automaticamente
function set_temp_path() {

    local p_path_temp="$1"

    #1. Usar el directorio personalizado del usuario (siempre que existe y tienes acceso de escritura)
    if [ ! -z "$p_path_temp" ] && [ -d "$p_path_temp" ] && [ -w "$p_path_temp" ]; then
        g_path_temp="$p_path_temp"
        return 0
    fi

    #2. Usar la carpeta predeterminado '/tmp'.
    if [ -d "/var/tmp" ] && [ -w "/var/tmp" ]; then
        g_path_temp="/var/tmp"
        return 0
    fi
    
    #3. Usar la carpeta predeterminado '/tmp'.
    g_path_temp="/tmp"
    return 0

}


#
#Parametros de entrada
# 1> Path por del programa.
#Parametros de salida
#  > SDTOUT: Version de NodeJS instalado
#  > Valores de retorno:
#     0 > Se obtuvo la version (esta instalado)
#     1 > No se obtuvo la version (no esta instalado)
#
function get_nodejs_version() {

    #Parametros
    local p_path=''
    if [ ! -z "$1" ]; then
        p_path="${1}/"
    fi

    #Obtener la version instalada
    local l_version
    l_version=$(${path}node --version 2> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ]; then
        return 1
    fi

    l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
    echo "$l_version"
    return 0
}

#
#Parametros de entrada
# 1> Path por defecto de todos los programas instalados por el instalador.
# 2> Flag es '0' si se muestra información cuando esta instalado excepto cuando se registra en el path.
# 3> Flag es '0' si se muestra información cuando se registra en el path.
#Parametros de salida
#  > Valores de retorno:
#     0 > Esta instalado (usando este instalador) y registrado en el PATH
#     1 > Esta instalado (usando este instalador) pero NO estaba registrado en el PATH
#     2 > Esta instalado pero fue instalado usando el gestor de paquetes (no requiere registro) 
#     3 > No esta instalado
#  > SDTOUT: Informacion si el parametro 2 es '0'
function check_nodejs() {

    #Parametros
    local p_path_programs="$1"

    local p_show_installed_info=1
    if [ "$2" = "0" ]; then
        p_show_installed_info=0
    fi

    local p_show_register_info=1
    if [ "$3" = "0" ]; then
        p_show_register_info=0
    fi

    #Obtener la version instalada
    local l_version
    local l_status

    #1. Si no esta instalado o fue instalado por gestor de paquetes (no se requiere adicionar al PATH)
    if [ ! -f "${p_path_programs}/nodejs/bin/node" ]; then

        l_version=$(node --version 2> /dev/null)
        l_status=$?
        if [ $l_status -ne 0 ]; then
            l_version=''
        fi

        if [ -z "$l_version" ]; then
            return 3
        fi

        if [ $p_show_installed_info -eq 0 ]; then
            l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
            printf 'NodeJS > NodeJS "%b%s%b" esta instalado.\n' "$g_color_gray1" "$l_version" "$g_color_reset"
        fi
        return 2

    fi

    #2. Si fue instalado por este instalador
    l_version=$(${p_path_programs}/nodejs/bin/node --version 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ]; then
        l_version=''
    fi

    #Si fue instalado incorrectamente
    if [ -z "$l_version" ]; then
        return 3
    fi

    #Si fue instalado correctamente, validar si esta registrado en el PATH
    echo "$PATH" | grep "${p_path_programs}/nodejs/bin" &> /dev/null
    l_status=$?

    #Si no esta instalado
    if [ $l_status -ne 0 ]; then

        if [ $p_show_register_info -eq 0 ]; then
            l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
            printf 'NodeJS > %bNodeJS "%b%s%b" esta instalado pero no esta en el $PATH del usuario%b.\n' \
                   "$g_color_red1" "$g_color_gray1" "$l_version" "$g_color_red1" "$g_color_reset"
            printf '         Se recomienda que adicione al PATH de su sesion actual de forma permanente, usando: %bPATH=%s/nodejs/bin:$PATH%b\n' \
                   "$g_color_gray1" "${p_path_programs}" "$g_color_reset"
        fi

        export PATH=${p_path_programs}/nodejs/bin:$PATH
        return 1

    fi

    #Si esta instalado
    if [ $p_show_installed_info -eq 0 ]; then
        l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
        printf 'NodeJS > NodeJS "%b%s%b" esta instalado.\n' "$g_color_gray1" "$l_version" "$g_color_reset"
    fi
    return 0

}

#
#Parametros de salida
#  > SDTOUT: Version de NodeJS instalado
#  > Valores de retorno:
#     0 > Se obtuvo la version (esta instalado)
#     1 > No se obtuvo la version (no esta instalado)
#
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


#
#Parametros de entrada
# 1> Path por del programa.
#Parametros de salida
#  > SDTOUT: Version de NodeJS instalado
#  > Valores de retorno:
#     0 > Se obtuvo la version (esta instalado)
#     1 > No se obtuvo la version (no esta instalado)
#
function get_neovim_version() {

    #Parametros
    local p_path=''
    if [ ! -z "$1" ]; then
        p_path="${1}/"
    fi

    #Obtener la version instalada
    local l_version
    l_version=$(${path}nvim --version 2> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ]; then
        return 1
    fi

    l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
    echo "$l_version"
    return 0
}


#
#Parametros de entrada
# 1> Path por defecto de todos los programas instalados por el instalador.
# 2> Flag es '0' si se muestra información cuando esta instalado excepto cuando se registra en el path.
# 3> Flag es '0' si se muestra información cuando se registra en el path.
#Parametros de salida
#  > Valores de retorno:
#     0 > Esta instalado (usando este instalador) y registrado en el PATH
#     1 > Esta instalado (usando este instalador) pero NO estaba registrado en el PATH
#     2 > Esta instalado pero fue instalado usando el gestor de paquetes (no requiere registro) 
#     3 > No esta instalado
#  > SDTOUT: Informacion si el parametro 2 es '0'
function check_neovim() {

    #Parametros
    local p_path_programs="$1"

    local p_show_installed_info=1
    if [ "$2" = "0" ]; then
        p_show_installed_info=0
    fi

    local p_show_register_info=1
    if [ "$3" = "0" ]; then
        p_show_register_info=0
    fi



    #Obtener la version instalada
    local l_version
    local l_status

    #1. Si no esta instalado o fue instalado por gestor de paquetes (no se requiere adicionar al PATH)
    if [ ! -f "${p_path_programs}/neovim/bin/nvim" ]; then

        l_version=$(nvim --version 2> /dev/null)
        l_status=$?
        if [ $l_status -ne 0 ]; then
            l_version=''
        fi

        if [ -z "$l_version" ]; then
            return 3
        fi

        if [ $p_show_installed_info -eq 0 ]; then
            l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
            printf 'NeoVIM > NeoVIM "%b%s%b" esta instalado.\n' "$g_color_gray1" "$l_version" "$g_color_reset"
        fi
        return 2

    fi

    #Actualmente en arm64 y alpine, solo se instala usaando el gestor de paquetes (el repositorios del SO)
    if [ "$g_os_architecture_type" = "aarch64" ] || [ $g_os_subtype_id -eq 1 ]; then

        #Si no se obtuvo la version antes, no esta instalado
        return 3

    fi

    #2. Si fue instalado por este instalador
    l_version=$(${p_path_programs}/neovim/bin/nvim --version 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ]; then
        l_version=''
    fi

    #Si fue instalado incorrectamente
    if [ -z "$l_version" ]; then
        return 3
    fi

    #Si fue instalado correctamente, validar si esta registrado en el PATH
    echo "$PATH" | grep "${p_path_programs}/neovim/bin" &> /dev/null
    l_status=$?

    #Si no esta instalado
    if [ $l_status -ne 0 ]; then

        if [ $p_show_register_info -eq 0 ]; then
            l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
            printf 'NeoVIM > %bNeoVIM "%b%s%b" esta instalado pero no esta en el $PATH del usuario%b.\n' \
                   "$g_color_red1" "$g_color_gray1" "$l_version" "$g_color_red1" "$g_color_reset"
            printf '         Se recomienda que adicione al PATH de su sesion actual de forma permanente, usando: %bPATH=%s/neovim/bin:$PATH%b\n' \
                   "$g_color_gray1" "${p_path_programs}" "$g_color_reset"
        fi

        export PATH=${p_path_programs}/neovim/bin:$PATH
        return 1

    fi

    #Si esta instalado
    if [ $p_show_installed_info -eq 0 ]; then
        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
        printf 'NeoVIM > NeoVIM "%b%s%b" esta instalado.\n' "$g_color_gray1" "$l_version" "$g_color_reset"
    fi
    return 0

}


#Parametros de entrada - Agumentos y opciones:
#  1 > El tipo de distribucion Linux (variable 'g_os_subtype_id' generado por 'get_linux_type_info') 
#  2 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
#  3 > Flag '0' si se requere curl
#  4 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
#  5 > Path base donde se encuentra el directorio de script de instalación
# Retorno:
#   0 - Se tiene los programas necesarios para iniciar la configuración
#   1 - No se tiene los programas necesarios para iniciar la configuración
function fulfill_preconditions() {

    #Argumentos
    local p_os_subtype_id="$1"

    local p_show_additional_info=1
    if [ "$2" = "0" ]; then
        p_show_additional_info=0
    fi 

    local p_require_curl=1
    if [ "$3" = "0" ]; then
        p_require_curl=0
    fi

    local p_require_root=1
    if [ "$4" = "0" ]; then
        p_require_root=0
    fi

    local p_path_base
    if [ -z "$5" ]; then
        p_path_base="$HOME"
    else
        p_path_base="$5"
    fi

    #Si se ejecuta un usuario root y es diferente al usuario que pertenece este script de instalación (es decir donde esta el repositorio)
    #UID del Usuario y GID del grupo (diferente al actual) que ejecuta el script actual
    local p_other_calling_user
    if [ ! -z "$6" ]; then
        p_other_calling_user="$6"
    fi

    #1. Validar si ejecuta dentro de un repostorio git
    if [ ! -d "${p_path_base}/.files/setup/linux" ]; then

        printf 'No existe los archivos necesarios para la instalación. Descarge el repostorio con los archivos: "%bgit clone https://github.com/lestebanpc/dotfiles.git ~/.files%b"\n' "$g_color_gray1" "$g_color_reset"
        return 1
    fi

    #2. Validar el SO
    if [ -z "$g_os_type" ]; then
        printf 'No es definido el tipo de SO\n' "$p_os_subtype_id"
        return 1
    fi

    if [ -z "$p_os_subtype_id" ]; then
        printf 'No es definido el tipo de distribucion Linux\n' "$p_os_subtype_id"
        return 1
    fi

    if [ $g_os_type -ne 0 ] && [ $g_os_type -ne 1 ]; then
        printf 'No esta implementado para el tipo SO "%s"\n' "$p_os_subtype_id"
        return 1
    fi

    #Actualmente solo esta habilitado para distribucion de la familia Alpine, Debian y Fedora.
    #if [ $p_os_subtype_id -lt 10 ] || [ $p_os_subtype_id -ge 50 ]; then
    if [ $p_os_subtype_id -lt 0 ] || [ $p_os_subtype_id -ge 50 ]; then
        printf 'No esta implementado para SO Linux de tipo "%s"\n' "$p_os_subtype_id"
        return 1
    fi

    #3. Validar la arquitectura de procesador
    if [ ! "$g_os_architecture_type" = "x86_64" ] && [ ! "$g_os_architecture_type" = "aarch64" ]; then
        printf 'No esta implementado para la arquitectura de procesador "%s"\n' "$g_os_architecture_type"
        return 1
    fi

    #6. Validar si existe los folderes de Windows sobre WSL
    if [ $g_os_type -eq 1 ] && [ ! -z "$g_path_programs_win" ] && [ ! -d "$g_path_programs_win" ]; then
        mkdir -p "$g_path_programs_win"
        mkdir -p "$g_path_bin_win"
        mkdir -p "$g_path_man_win"
        mkdir -p "$g_path_etc_win"
        mkdir -p "$g_path_doc_win"
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
    if [ $p_require_root -eq 0 ]; then
        if [ $g_user_sudo_support -eq 2 ] || [ $g_user_sudo_support -eq 3 ]; then
            printf 'ERROR: el usuario no tiene permisos para ejecutar sudo (o el SO no tiene implementa sudo y el usuario no es root).'
            return 1
        fi
    fi

    #9. Mostar información adicional (Solo mostrar info adicional si la ejecución es interactiva)
    if [ $p_show_additional_info -eq 0 ]; then

        printf '%bLinux distribution - Name   : (%s) %s\n' "$g_color_gray1" "${g_os_subtype_id}" "${g_os_subtype_name}"
        printf 'Linux distribution - Version: (%s) %s (%s)\n' "$g_os_subtype_id" "$g_os_subtype_version" "$g_os_subtype_version_pretty"
        printf 'Processor architecture type : %s\n' "$g_os_architecture_type"

        if [ ! -z "$g_path_programs" ]; then
            printf 'Default program path        : "%s"' "$g_path_programs"
            if [ $g_os_type -eq 1 ] && [ ! -z "$g_path_programs_win" ]; then
                printf ' (Windows "%s")\n' "$g_path_programs_win"
            else
                printf '\n'
            fi
        fi

        if [ ! -z "$g_path_bin" ]; then
            printf 'Default command path        : "%s"' "$g_path_bin"
            if [ $g_os_type -eq 1 ] && [ ! -z "$g_path_bin_win" ]; then
                printf ' (Windows "%s")\n' "$g_path_bin_win"
            else
                printf '\n'
            fi
        fi

        if [ ! -z "$g_path_temp" ]; then
            printf 'Temporary data path         : "%s"\n' "$g_path_temp"
        fi

        local l_aux='Root ('
        if [ $g_user_is_root -eq 0 ]; then
            l_aux="${l_aux}Yes)"
        else
            l_aux="${l_aux}No), Sudo Support ("
            if [ $g_user_sudo_support -eq 0 ]; then
                l_aux="${l_aux}Sudo with password)"
            elif [ $g_user_sudo_support -eq 1 ]; then
                l_aux="${l_aux}Sudo without password)"
            elif [ $g_user_sudo_support -eq 2 ]; then
                l_aux="${l_aux}OS not support sudo)"
            elif [ $g_user_sudo_support -eq 3 ]; then
                l_aux="${l_aux}No access to run sudo)"
            else
                l_aux="${l_aux}User is root. Don't need sudo"
            fi
        fi

        printf 'User info                   : %s\n' "$l_aux"

        if [ $p_require_curl -eq 0 ]; then
            l_curl_version=$(echo "$l_curl_version" | head -n 1 | sed "$g_regexp_sust_version1")
            printf '%bCURL version                : %s%b\n' "$g_color_gray1" "$l_curl_version" "$g_color_reset"
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
    if [ $g_user_sudo_support -eq 4 ]; then
        return 2
    # > 1 : Soporta el comando sudo sin password
    elif [ $g_user_sudo_support -eq 1 ]; then
        return 2
    # > 3 : El usuario no tiene permisos para ejecutar sudo
    elif [ $g_user_sudo_support -eq 3 ]; then
        printf 'El usuario no tiene permiso para ejecutar sudo. %bSolo se va instalar/configurar paquetes/programas que no requieren acceso de "root"%b\n' \
               "$g_color_red1" "$g_color_reset"
        return 3
    # > 2 : El SO no implementa el comando sudo
    elif [ $g_user_sudo_support -eq 4 ]; then
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
    if [ $g_user_sudo_support -eq 4 ]; then
        return 1
    # > 1 : Soporta el comando sudo sin password
    elif [ $g_user_sudo_support -eq 1 ]; then
        return 1
    # > 3 : El usuario no tiene permisos para ejecutar sudo
    elif [ $g_user_sudo_support -eq 3 ]; then
        return 1
    # > 2 : El SO no implementa el comando sudo
    elif [ $g_user_sudo_support -eq 4 ]; then
        return 1
    fi


    #3. Caducar las credecinales de root almacenadas temporalmente
    printf '\nCaducando el cache de temporal password de su "sudo"\n'
    sudo -k
    return 0
}

#Parametros de entrada
#  1> Ruta del origin donde esta el comprimido
#  2> Nombre de archivo comprimido
#  3> Ruta destino donde se descromprimira el archivo
#  4> El tipo de item de cada artefacto puede ser:
#     Comprimidos no tan pesados (se descomprimen y copian en el lugar deseado)
#       > 0 si es un .tar.gz
#       > 1 si es un .zip
#       > 2 si es un .gz
#       > 3 si es un .tgz
#       > 4 si es un .tar.xz
#Parametros de salida
#   > Valor de retorno: 0 si es exitoso
#   > Variable global 'g_filename_without_ext' con el nombre del archivo comprimido sin su extension
uncompress_program() {

    local p_path_source="$1"
    local p_compressed_filename="$2"
    local p_path_destination="$3"
    local p_compressed_filetype="$4"

    g_filename_without_ext=""

    # Si el tipo de item es 10 si es un comprimido '.tar.gz' no muy pesado (se descomprime en una ruta local y luego se copia a su destino)
    if [ $p_compressed_filetype -eq 0 ]; then

        #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
        printf 'tar -xf "%b%s/%s%b" -C "%b%s%b"\n' "$g_color_gray1" "$p_path_source" "$p_compressed_filename" "$g_color_reset" \
               "$g_color_gray1" "$p_path_destination" "$g_color_reset"
        tar -xf "${p_path_source}/${p_compressed_filename}" -C "${p_path_destination}"
        rm "${p_path_source}/${p_compressed_filename}"
        #chmod u+rw ${p_path_destination}/*

        g_filename_without_ext="${p_compressed_filename%.tar.gz}"

    # Si el tipo de item es 11 si es un comprimido '.zip' no muy pesado (se descomprime en una ruta local y luego se copia a su destino)
    elif [ $p_compressed_filetype -eq 1 ]; then

        #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
        printf 'unzip -q "%b%s/%s%b" -d "%b%s%b"\n' "$g_color_gray1" "$p_path_source" "$p_compressed_filename" "$g_color_reset" \
               "$g_color_gray1" "$p_path_destination" "$g_color_reset"
        unzip -q "${p_path_source}/${p_compressed_filename}" -d "${p_path_destination}"
        rm "${p_path_source}/${p_compressed_filename}"

        #FIX: Los archivos de themas de 'Oh-my-posh' no tienen permisos para usuarios en WSL
        chmod u+rw ${p_path_destination}/*

        g_filename_without_ext="${p_compressed_filename%.zip}"


    # Si el tipo de item es 12 si es un comprimido '.gz' no muy pesado (se descomprime en una ruta local y luego se copia a su destino)
    elif [ $p_compressed_filetype -eq 2 ]; then

        #Descomprimir el archivo en el directorio creado (no crear sub-folderes), por defecto elimina el comprimido
        printf 'cd "%b%s%b"\n' "$g_color_gray1" "$p_path_destination" "$g_color_reset"
        cd "${p_path_destination}"

        printf 'gunzip -q "%b%s/%s%b"\n' "$g_color_gray1" "$p_path_source" "$p_compressed_filename" "$g_color_reset"
        gunzip -q "${p_path_source}/${p_compressed_filename}"
        #chmod u+rw ${p_path_destination}/*

        g_filename_without_ext="${p_compressed_filename%.gz}"


    # Si el tipo de item es 13 si es un comprimido '.tgz' no muy pesado (se descomprime en una ruta local y luego se copia a su destino)
    elif [ $p_compressed_filetype -eq 3 ]; then

        #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
        printf 'tar -xf "%b%s/%s%b" -C "%b%s%b"\n' "$g_color_gray1" "$p_path_source" "$p_compressed_filename" "$g_color_reset" \
               "$g_color_gray1" "$p_path_destination" "$g_color_reset"
        tar -xf "${p_path_source}/${p_compressed_filename}" -C "${p_path_destination}"
        rm "${p_path_source}/${p_compressed_filename}"
        #chmod u+rw ${p_path_destination}/*

        g_filename_without_ext="${p_compressed_filename%.tgz}"

    # Si el tipo de item es 14 si es un comprimido '.tar.xz' no muy pesado (se descomprime en una ruta local y luego se copia a su destino)
    elif [ $p_compressed_filetype -eq 4 ]; then

        #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
        printf 'tar -xJf "%b%s/%s%b" -C "%b%s%b"\n' "$g_color_gray1" "$p_path_source" "$p_compressed_filename" "$g_color_reset" \
               "$g_color_gray1" "$p_path_destination" "$g_color_reset"
        tar -xJf "${p_path_source}/${p_compressed_filename}" -C "${p_path_destination}"
        rm "${p_path_source}/${p_compressed_filename}"
        #chmod u+rw ${p_path_destination}/*

        g_filename_without_ext="${p_compressed_filename%.tar.xz}"

    else
        return 1
    fi

    return 0
}

#Parametros de entrada
#  1> Nombre de archivo comprimido
#  2> El tipo de item de cada artefacto puede ser:
#     Comprimidos no tan pesados (se descomprimen y copian en el lugar deseado)
#       > 0 si es un .tar.gz
#       > 1 si es un .zip
#       > 2 si es un .gz
#       > 3 si es un .tgz
#       > 4 si es un .tar.xz
#Parametros de salida
#   > Valor de retorno: 0 si es exitoso
#   > STDOUT          : Nombre del archivo sin extension  
function compressed_program_name() {

    local p_compressed_filename="$1"
    local p_compressed_filetype="$2"

    local l_filename_without_ext=""


    # Si el tipo de item es 20, es un comprimido '.tar.gz' pesado por lo que se descomprimira directamente en el lugar deseado.
    if [ $p_compressed_filetype -eq 0 ]; then

        l_filename_without_ext="${p_compressed_filename%.tar.gz}"

    # Si el tipo de item es 21, es un comprimido '.zip' pesado por lo que se descomprimira directamente en el lugar deseado.
    elif [ $p_compressed_filetype -eq 1 ]; then

        l_filename_without_ext="${p_compressed_filename%.zip}"

    # Si el tipo de item es 22, es un comprimido '.gz' pesado por lo que se descomprimira directamente en el lugar deseado.
    elif [ $p_compressed_filetype -eq 2 ]; then

        l_filename_without_ext="${p_compressed_filename%.gz}"

    # Si el tipo de item es 23, es un comprimido '.tgz' pesado por lo que se descomprimira directamente en el lugar deseado.
    elif [ $p_compressed_filetype -eq 3 ]; then

        l_filename_without_ext="${p_compressed_filename%.tgz}"

    # Si el tipo de item es 24, es un comprimido '.tar.xz' pesado por lo que se descomprimira directamente en el lugar deseado.
    elif [ $p_compressed_filetype -eq 4 ]; then

        l_filename_without_ext="${p_compressed_filename%.tar.xz}"

    else
        return 1
    fi

    echo "$l_filename_without_ext"
    return 0
}


#Revisa los plugins de VIM/NeoVIM existe en modo Editor/IDE
#Parametro de entrada:
#  0 > Flag '0' si es NeoVIM
#Parametros de salida (valores de retorno):
#  0 > Si es esta configurado en modo Editor
#  1 > Si es esta configurado en modo IDE
#  2 > Si NO esta configurado
function check_vim_plugins() {

    #1. Argumentos
    local p_is_neovim=1
    if [ "$1" = "0" ]; then
        p_is_neovim=0
    fi


    #2. ¿Es IDE? (SOLO se analiza uno de los plugins descargados)
    local l_plugin_path="${HOME}/.vim/pack/ide/opt/coc.nvim"
    if [ $p_is_neovim -eq 0  ]; then
        l_plugin_path="${HOME}/.local/share/nvim/site/pack/ide/opt/nvim-cmp"
    fi

    if [ -d "$l_plugin_path" ]; then
        return 1
    fi

    #3. ¿Es Editor? (SOLO se analiza uno de los plugins descargados)
    l_plugin_path="${HOME}/.vim/pack/ui/opt/fzf"
    if [ $p_is_neovim -eq 0  ]; then
        l_plugin_path="${HOME}/.local/share/nvim/site/pack/ui/opt/fzf"
    fi

    if [ -d "$l_plugin_path" ]; then
        return 0
    fi

    #4. No es IDE ni Editor
    return 2

}


#Revisa el profile de VIM/NeoVIM y segun ello determina si VIM/NeoVIM esta configurado en modo Editor/IDE
#Parametro de entrada:
#  0 > Flag '0' si es NeoVIM
#Parametros de salida (valores de retorno):
#  0 > Si es esta configurado en modo Editor
#  1 > Si es esta configurado en modo IDE
#  2 > Si NO esta configurado
function check_vim_profile() {

    #1. Argumentos
    local p_is_neovim=1
    if [ "$1" = "0" ]; then
        p_is_neovim=0
    fi


    #2. Ruta base donde se instala el plugins/paquete
    local l_real_path
    local l_profile_path="${HOME}/.vimrc"
    if [ $p_is_neovim -eq 0  ]; then
        l_profile_path="${HOME}/.config/nvim/init.vim"
    fi

    #'vimrc_ide_linux_xxxx.vim'
    #'vimrc_basic_linux.vim'
    #'init_ide_linux_xxxx.vim'
    #'init_basic_linux.vim'
    l_real_path=$(readlink "$l_profile_path" 2> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ]; then
        return 2
    fi

    l_real_path="${l_real_path##*/}"

    #Si es NeoVIM
    if [ $p_is_neovim -eq 0  ]; then
        if [[ "$l_real_path" == init_ide_* ]]; then
            return 1 
        fi
        return 0
    fi

    #Si es VIM
    if [[ "$l_real_path" =~ vimrc_ide_* ]]; then
        return 1 
    fi
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
    if [ $g_user_is_root -eq 0 ]; then
        systemctl stop "$p_unit_name"
    else
        sudo systemctl stop "$p_unit_name"
    fi

    return 4

}



#Si un nodo k0s esta iniciado solicitar su detención y deternerlo.
#Parametros de entrada (argumentos y opciones):
#Opcionales:
#   1 > Flag '0' si se usara para desintalar, caso contrario se usara para instalar/actualizar.
#   2 > ID del repositorio
#   3 > Indice del artefato del repositorio que se desea instalar
#Parametros de salida (valor de retorno):
#   0 > El nodo no esta iniciado (no esta instalado o esta detenido).
#   1 > El nodo está iniciado pero NO se acepto deternerlo.
#   2 > El nodo esta iniciado y se acepto detenerlo.
function request_stop_k0s_node() {

    #1. Argumentos
    local p_is_uninstalling=1
    if [ "$1" = "0" ]; then
        p_is_uninstalling=0
    fi
    local p_repo_id="$2"
    local p_artifact_index=-1
    if [[ "$3" =~ ^[0-9]+$ ]]; then
        p_option_relative_idx=$3
    fi
    
    #2. Determinar el estado actual del demonio k0s
    local l_option
    local l_status
    local l_info

    #Si se no esta instalado o esta detenenido, salir
    l_info=$(sudo k0s status 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_info" ]; then
        return 0
    fi

    #Si esta detenido, salir
    local l_aux
    l_aux=$(echo "$l_info" | grep -e '^Process ID' 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_aux" ]; then
        return 0
    fi

    #Recuperar información adicional.
    local l_node_process_id=$(echo "$l_aux" | sed 's/.*: \(.*\)/\1/' 2> /dev/null)
    local l_nodo_type=$(echo "$l_info" | grep -e '^Role' | sed 's/.*: \(.*\)/\1/' 2> /dev/null)

    #3. Solicitar la detención del servicio
    printf "%bEl nodo k0s '%s' (PID: %s) esta iniciado y requiere detenerse para " "$g_color_red1" "$l_nodo_type" "$l_node_process_id"

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


    printf "¿Desea detener el nodo k0s?%b (ingrese 's' para 'si' y 'n' para 'no')%b [s]" "$g_color_gray1" "$g_color_reset"
    read -rei 's' -p ': ' l_option
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
            printf "resositorio.\nDetenga el nodo k0s '%s' y vuelva ejecutar el menú o acepte su detención para su " "$l_nodo_type"
        else
            printf "repositorio '%s'.\nDetenga el nodo k0s '%s' y vuelva ejecutar el menú o acepte su detención para su " "$p_repo_id" "$l_nodo_type"
        fi

        if [ $p_is_uninstalling -eq 0 ]; then
            printf 'desinstalación.%b\n' "$g_color_reset"
        else
            printf 'instalación.%b\n' "$g_color_reset"
        fi

        return 1

    fi


    #4. Detener el nodo k0s
    printf 'Deteniendo el nodo k0s %s ...\n' "$l_nodo_type"
    if [ $g_user_is_root -eq 0 ]; then
        k0s stop
    else
        sudo k0s stop
    fi
    return 2
}



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

        printf "     (%b%0${p_max_digits}d%b) %s %b%b%b> " "$g_color_green1" "$l_option_value" "$g_color_reset" \
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

