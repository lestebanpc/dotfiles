#!/bin/bash

# Para habilitar el uso de este archivo de configurar, deberará:
# > Copiarlo en la ruta:
#   cp ~/.files/shell/bash/bin/linuxsetup/lib/setup_config_template.bash ~/.files/shell/bash/bin/linuxsetup/.setup_config.bash
# > Descomentar y cambiar los valores deseados
#
#
# Consideraciones:
#
# 1. El script "04_setup_packages" no requiere el uso de este archivo de configuración y permite realizar instalaciones de paquetes del SO
#    para todos los usuarios.
#
# 2. Los demas script permiten instalar/actualizar: el profile del usuario y los comandos/programas (para un usuario o para todos los usuarios).
#    > Aunque un comandos es un programa, aqui referimos a comandos como un solo binario ejecutable y a un programa como un conjunto de binarios.
#    > Los archivos de configuración requeridos para configurar un profile, comandos/programas se almacena en el "Target Home" del usuario OBJETIVO.
#    > El configuración del profile, los comandos y programas siempre DEPENDE del usuario OBJETIVO (aun cuando se configure los comandos/programas
#      para todos los usuarios), estos debido a que estos escript REQUIEREN de los archivos de configuración almacena en el "Target Home" del usuario
#      OBJETIVO (por ejemplo, para un adecuado funcionamiento de 'ssh', 'delta', ...).
#
# 3. El archivo de configuración, consideran 4 zonas/rutas diferenciadas:
#    > Folder "${g_targethome_path}" que representa al "Target Home" (o home del usuario OBJETIVO)
#      - Siempre tiene un subdirectorio "${g_repo_name}" que representa el directorio git.
#      - Para la configuración de comandos/programas representa el lugar donde se obtendran las configuracion para estos comandos/programas
#        (independiente si el comando/programa es un usado solo por el usuario OBJETIVO o por todos los usuarios del SO).
#    > Folder "${g_shell_path}" que representado a la ruta donde estan los script de instalación.
#      - Usualmente se se usa los script existentes en el repositorio del home del usuario OBJETIVO ('${g_shell_path}/${g_repo_name}/shell'),
#        pero puede usar los script ubicados en otra ruta.
#      - Tiene la estructura de subfolderes:
#          ./bash/
#              ./bin/
#                  ./linuxsetup/             <- Requerido en el proceso de instalación en Linux
#                      ./00_setup_summary.bash
#                      ./01_setup_binaries.bash
#                      ./04_install_profile.bash
#                      ./05_update_profile.bash
#                      ./03_setup_repo_os_pkgs.bash
#                      ........................
#                      ........................
#                      ........................
#              ./lib/
#                  ./mod_common.bash        <- Requerido en el proceso de instalación en Linux
#                  ........................
#                  ........................
#          ./sh/
#              ........................
#              ........................
#              ./lib/
#                  ./mod_common.sh          <- Requerido en el proceso de instalación en Linux
#                  ........................
#          ........................
#          ........................
#    > Folder "${g_cmd_base_path}" que representado a la ruta base donde se instalarán los comandos, archivos de ayuda y archivos fuentes.
#      - Si este folder esta dentro del "Target Home", los comandos SOLO pueden ser usuados por el usuario OBJETIVO.
#      - Si este folder esta fuera  del "Target Home", los comandos pueden ser usuados por todos los usuarios del SO pero SOLO el usuario que es
#        onwer de ese folder podra realizar las configuraciones respectivas.
#    > Folder "${g_programs_path}" que representado a la ruta base donde se instalarán los programas.
#      - Si este folder esta dentro del "Target Home", los programas SOLO pueden ser usuados por el usuario OBJETIVO.
#      - Si este folder esta fuera  del "Target Home", los programas pueden ser usuados por todos los usuarios del SO pero SOLO el usuario que es
#        onwer de ese folder podra realizar las configuraciones respectivas.
#
# 4. Si no se especifica estos directorio, se usara la estructura de folder por defecto:
#       ~/               <- ${g_targethome_path}
#          .files        <- ${g_targethome_path}/${g_repo_name} o ${g_repo_path}
#              ./etc/
#                  ........................
#                  ........................
#              ./vim/
#                  ........................
#                  ........................
#              ./nvim/
#                  ........................
#                  ........................
#              ./tmux/
#                  ........................
#                  ........................
#              ./shell/  <- ${g_shell_path}
#                  ........................
#                  ........................
#              ./wezterm/
#                  ........................
#                  ........................
#              ./etc/
#                  ........................
#                  ........................
#              ./vim/
#                  ........................
#                  ........................
#              ./nvim/
#                  ........................
#                  ........................
#              ./tmux/
#                  ........................
#                  ........................
# 5. El usuario runner (el usuario que ejecuta este script de instalación) solo puede ser:
#    - Es el usuario objetivo (onwer del "target home").
#    - El usuario root en modo suplantacion del usurio objetivo.
#      Este caso, el root realizará la configuración requerida para el usuario objetivo (usando sudo), nunca realizara configuración para el propio usuario root.
# 6. Solo el owner de los folderes del programas y comandos (incluyendo los archivos ayuda y los archivos de fuentes) puede realizar configuracioes (instalacion o
#    actualización de programas/comandos). Todos los archivos creados durante esta configuracion se crearan con este owner.
# 7. El script de setup de comandos y programas, escoge el folder adecuado de tal fomar que el runner tenga permisos para instalar comandos y programas.
# 8. El usuario runner (ya sea usuario objetivo o root como suplantacion) solo puede escoger folderes comandos/programas que tengan como owner:
#    - El usuario objetivo (si el usuario runner es root en modo suplantacion, se requiere realizar un 'chown' de los archivos/carpetas creadas para el Usuario
#      objetivo sea el owner).
#    - Usuario root (si el usuario runner no es root, va a requerir usar sudo con root para poder configurar programas/comandos).
#    Los folderes de programas/comandos con otros tipos de owner, seran rechazados por el script, obligando a cambiar el usuario objetivo para pueda realizar
#    dicho setup.
#


##############################################################################################
# Todos los scripts (excepto "04_setup_packages")
##############################################################################################

#Ruta del home del usuario OBJETIVO al cual se configurara su profile y donde esta el repositorio git.
#Este valor se obtendra segun orden prioridad:
# - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
# - El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config" (debe ser diferente de vacio)
# - Si ninguno de los anteriores se establece, se la ruta sera calculado en base de la ruta del script de instalación y el nombre del repositorio 'g_repo_name'.
# - Si no se puede cacluar este valor, se detendra el proceso de instalación/actualización
#g_targethome_path='/home/lucianoepc'

#Nombre del repositorio git o la ruta relativa del repositorio git respecto al home de usuario OBJETIVO (al cual se desea configurar el profile del usuario).
#Este valor se obtendra segun orden prioridad:
# - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
# - El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config" (debe ser diferente de vacio)
# - Si ninguno de los anteriores se establece, se usara el valor '.files'.
#g_repo_name='.files'

# Folder base donde se almacena los subfolderes de los programas.
# - Solo el owner del folder puede realizar instalacion/actualizacion de programas.
#     > Si el el folder esta dentro del home de un usuario, los programas instalados solo podran ser usuados por el usario.
#     > Si estan fuera del home de los usuarios, los programas instalados pueden ser usuados por todos los usuarios.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si el folder no tiene como onwer el usuario objetivo o root, sera condiserado invalido
# - Si no es un valor valido, la funcion "get_program_path" asignara un sus posibles valores (segun orden de prioridad):
#     > "/var/opt/tools"
#     > "~/tools"
# - Si el folder no existe y no es folder predeterminado, intentara crear con el onwer:
#     > Si el folder esta dentro del home del usuario objetivo, se creara el folder con el owner del usuario objetivo.
#     > Si el folder esta fuera del home del usuario objetivo, el owner del folder de 'root'.
#g_programs_path='/var/opt/tools'

# Folder base donde se almacena data temporal que sera eliminado automaticamente despues completar la configuración.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es valido, la funcion "get_temp_path" asignara segun orden de prioridad a '/var/tmp' o '/tmp'.
# - Tener en cuenta que en muchas distribuciones el folder '/tmp' esta en la memoria y esta limitado a su tamaño.
#g_temp_path='/var/tmp'


##############################################################################################
# Usado por los script "00_setup_summary.bash", "01_setup_binaries.bash"
##############################################################################################

# Folder base donde se almacena el comando y sus archivos afines.
# - Solo el owner del folder puede realizar instalacion/actualizacion de comandos.
#     > Si el el folder esta dentro del home de un usuario, los comandos instalados solo podran ser usuados por el usario.
#     > Si estan fuera del home de los usuarios, los comandos instalados pueden ser usuados por todos los usuarios.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura), dentro
#   de este folder se creara/usara la siguiente estructura de folderes:
#     > "${g_cmd_base_path}/bin"         : subfolder donde se almacena los comandos.
#     > "${g_cmd_base_path}/man/man1"    : subfolder donde se almacena archivos de ayuda man1.
#     > "${g_cmd_base_path}/man/man5"    : subfolder donde se almacena archivos de ayuda man5.
#     > "${g_cmd_base_path}/man/man7"    : subfolder donde se almacena archivos de ayuda man7.
#     > "${g_cmd_base_path}/share/fonts" : subfolder donde se almacena las fuentes.
# - Si el folder no tiene como onwer el usuario objetivo o root, sera condiserado invalido
# - Si no es un valor valido, la funcion "get_command_path" asignara un sus posibles valores (segun orden de prioridad):
#     > Si tiene permisos administrativos, usara los folderes predeterminado para todos los usuarios:
#        - "/usr/local/bin"      : subfolder donde se almacena los comandos.
#        - "/usr/local/man/man1" : subfolder donde se almacena archivos de ayuda man1.
#        - "/usr/local/man/man5" : subfolder donde se almacena archivos de ayuda man5.
#        - "/usr/local/man/man7" : subfolder donde se almacena archivos de ayuda man7.
#        - "/usr/share/fonts"    : subfolder donde se almacena las fuentes.
#     > Caso contrario, se usara los folderes predeterminado para el usuario:
#        - "~/.local/bin"         : subfolder donde se almacena los comandos.
#        - "~/.local/man/man1"    : subfolder donde se almacena archivos de ayuda man1.
#        - "~/.local/man/man5"    : subfolder donde se almacena archivos de ayuda man5.
#        - "~/.local/man/man7"    : subfolder donde se almacena archivos de ayuda man7.
#        - "~/.local/share/fonts" : subfolder donde se almacena las fuentes.
# - Si el valor es vaciom se usara el los folderes predeterminado para todos los usuarios.
# - Si el folder no existe y no es folder predeterminado, intentara crear con el onwer:
#     > Si el folder esta dentro del home del usuario objetivo, se creara el folder con el owner del usuario objetivo.
#     > Si el folder esta fuera del home del usuario objetivo, el owner del folder de 'root'.
#g_cmd_base_path=''


##############################################################################################
# Usado por los script "01_setup_binaries.bash"
##############################################################################################

# Folder base, generados solo para Linux WSL, donde se almacena el programas, comando y afines usados por Windows.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es un valor valido, se asignara su valor por defecto "/mnt/c/cli" (es decir "c:\cli").
# - En este folder se creara/usara la siguiente estructura de folderes:
#     > "${g_win_base_path}/prgs"     : subfolder donde se almacena los subfolder de los programas.
#     > "${g_win_base_path}/cmds/bin" : subfolder donde se almacena los comandos.
#     > "${g_win_base_path}/cmds/doc" : subfolder donde se almacena documentacion del comando.
#     > "${g_win_base_path}/cmds/etc" : subfolder donde se almacena archivos adicionales del comando.
#     > "${g_win_base_path}/fonts" : subfolder donde se almacena los archivos de fuentes tipograficas.
#g_win_base_path='/mnt/d/cli'


##############################################################################################
# Usado por los script "01_setup_binaries.bash", "05_update_profile.bash"
##############################################################################################

# Folder base, generados solo para Linux WSL, donde se almacena el programas, comando y afines usados por Windows.
# Usado solo durante la instalación. Define si se instala solo la ultima version de un programa.
# Por defecto es 1 (considerado 'false'). Solo si su valor es '0', es considera 'true'.
#g_setup_only_last_version=0


##############################################################################################
# Usado por los script "04_install_profile.bash"
##############################################################################################

# Tipo de profile a configurar
# > 0 - Local  - Usado para su equipo local o un equipo remoto pero que se accede desde escritorio.
# > 1 - Remote - Usado por una VM accedido por comando ssh, cuyo owner soy yo
# > 2 - Remote - Usado por una VM accedido por comando ssh, cuyo owner NO soy yo
#g_profile_type=0
