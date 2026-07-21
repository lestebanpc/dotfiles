#!/bin/bash

#
# Para habilitar su uso genere el arcivo '~/.custom_profile.bash':
#  cp ~/.files/shell/bash/login/profile/profile_config_template_basic_local.bash ~/.custom_profile.bash
#  cp ~/.files/shell/bash/login/profile/profile_config_template_basic_remote.bash ~/.custom_profile.bash
#  cp ~/.files/shell/bash/login/profile/profile_config_template_distrobox.bash ~/.custom_profile.bash
#  cp ~/.files/shell/bash/login/profile/profile_config_template_wsl.bash ~/.custom_profile.bash
#  vim ~/.custom_profile.bash
#

#-----------------------------------------------------------------------------------
# Variables globales de configuracion general
#-----------------------------------------------------------------------------------

# Ruta del tema de 'Oh-My-Posh' usada para establecer el prompt a usar.
# Si no se establecer (es vacio), se usara '~/${g_repo_name}/etc/cli/oh-my-posh/default_settings.json'
#g_prompt_theme=~/.files/etc/cli/oh-my-posh/lepc-montys-blue1.json

# Folder donde se almacena los binarios de tipo comando.
# - Si los comandos instalados por el script '~/${g_repo_name}/shell/bash/bin/linuxsetup/01_setup_binaries.bash'
#   se ha instalado en una ruta personalizado (diferente a '/usr/local/bin' o '~/.local/bin'), es obligatorio
#   establecer la ruta correcta en dicha variable.
# - Si no se especifica (es vacio), se considera la ruta estandar '/usr/local/bin'
#g_lnx_bin_path='/usr/local/bin'


#-----------------------------------------------------------------------------------
# Variables globales para generar variables de entorno
#-----------------------------------------------------------------------------------

# Nombre del repositorio git o la ruta relativa del repositorio git respecto al HOME.
# - Si no se establece (valor vacio), se usara el valor '.files'.
# - Usado para generar la variable de entorno 'MY_REPO_PATH' usado en la configuración de programas como TMUX.
#g_repo_name='.files'

# Folder base donde se almacena los subfolderes de los programas.
# - Si no es un valor valido (no existe o es vacio), su valor sera el valor por defecto "/var/opt/tools".
# - Si es un directorio valido, se valor sera usadoo para definir la  variable de entorno de usuario 'MY_TOOLS_PATH'
# - Esta variable es usado en la configuración de programas como TMUX, VIM o NeoVIM.
#g_tools_path='/var/opt/tools'

# Tipo de origin de la sesion del profile.
# > Usando esta variable se determina el valor de la variable de entorno del usuario 'MY_SESSION_SRC'.
# Sus valores son:
#  > 0 Si se usa sesion remota SSH (ya se de un 'desktop server' o 'headless server').
#  > 1 Si se realiza una sesion local usando 'Console Linux'.
#  > 2 Si se usa sesion dentro del escritorio del servidor (ya sea local desktop o remote desktop).
#  > Si no se especifica, se calcula automaticamente.
#g_session_src=''

# Definir el tipo de entorno donde los shell del usuario se va a configurar.
# > Es usado por el profile del usuario (usando su script '~/.profile.config') cuyo valor es calculado durante la
#   instalación ('04_install_profile.bash') pero puede ser modificado despues de la instalación.
# > Usando esta variable se determina el valor de la variable de entorno del usuario 'MY_ENV_TYPE'.
# Su valores son:
#  > 0 Los script se ejecutan en un 'Headless Server'
#      > El script se ejecutan en un servidor donde no se tiene un gestor de ventanas (usualmente no se cuenta con GPU).
#      > No cuenta con aplicaciones GUI (no cuenta con emulador de terminal GUI).
#      > Se puede conectar localmente usando el emulador de terminal CLI 'Linux Console'.
#      > Se puede conectar remotamente usando SSH con su emulador de terminal externo (usualmente GUI) favorito.
#  > 1 Los script se ejecutan en un 'Desktop Server'
#      > El script se ejecutan en un servidor donde se tiene un gestor de ventanas (siempre cuenta con GPU).
#      > Cuenta con aplicaciones GUI, incluyendo un emulador de terminal GUI que permite ejecutar scrript localmente.
#      > Se puede ejecutar script localmente:
#        > Conectandose al escritorio del servidor (ingresando localmente al escritorio del servidor o conectandose
#          remotamente usando un programa de gestion de escritorio remoto como VNC) y usando el emulador de terminal GUI
#          existente en el servidor.
#        > Muy poco usual, conectandose localmente pero usando el emulador de terminal CLI 'Linux Console'.
#      > Se puede ejecutar script remotamente usando SSH con su emulador de terminal externo (usualmente GUI) favorito.
#  > 2 Los script se ejecutan en un contenedor dentro de un 'Desktop Server' y este tiene acceso a la GPU de este servidor.
#      > Los script de ejecutan dentro de proceso local de un 'Desktop Server' pero en un entorno aislado (contenedor)
#        pero que tiene acceso a GPU y progrmadas GUI del servidor.
#      > Aparte de tener acceso a la GPU tiene acceso a todo lo necesario para interactuar con estos (como bus de mensajes).
#      > No estan diseñados para que se conecten remotamente por ssh.
#      > Por defecto los contenedores no tiene acceso a la GPU del servidor donde se ejecuta.
#      > Ejemplo: Contenedores Distrobox o Toolbox en Linux.
#  > 3 Los script de ejecutan en un VM local dentro de un 'Desktop Server' tiene acceso a la GPU del servidor.
#      > Los script de ejecutan dentro de proceso remoto de un 'Desktop Server' (dentro de una VM) pero que tiene acceso a GPU
#        y progrmadas GUI del servidor.
#      > Aparte de tener acceso a la GPU tiene acceso a todo lo necesario para interactuar con estos (como bus de mensajes).
#      > No estan diseñados para que se conecten remotamente por ssh.
#      > Ejemplo: La VM ligera WSL2 que esta integrada con Windows en modo escritorio.
#  > Si no se define, su valor por defecto es '0' (Headless Server).
g_enviroment_type=3


#-----------------------------------------------------------------------------------
# Variables globales de configuracion para Linux WSL
#-----------------------------------------------------------------------------------

# Folder base, donde se almacena el programas, comando y afines usados por Windows.
# - Si no se ingresa un valor valido o no existe, se asignara su valor por defecto "/mnt/c/tools" (es decir "c:\apps").
# - En este folder almacena la siguiente estructura de folderes donde estan:
#     > "${g_win_base_path}/tools"     : subfolder donde se almacena los subfolder de los programas.
#     > "${g_win_base_path}/cmds/bin" : subfolder donde se almacena los comandos.
#     > "${g_win_base_path}/cmds/doc" : subfolder donde se almacena documentacion del comando.
#     > "${g_win_base_path}/cmds/etc" : subfolder donde se almacena archivos adicionales del comando.
#     > "${g_win_base_path}/fonts" : subfolder donde se almacena los archivos de fuentes tipograficas.
#$g_win_base_path='/mnt/d/apps'


#-----------------------------------------------------------------------------------
# Variables de entorno (requeridos por el profile)
#-----------------------------------------------------------------------------------

# Variables de entorno comunes y usuados por varios programas
#export EDITOR="vim"
#export VISUAL="vim"
#export SYSTEMD_EDITOR="vim"

# La variable de entorno 'TMUX_NESTED' es usado por 'tmux' e indica si el tmux actual se ejecuta dentro de otro tmux padre.
# Es usado para definir para cambiar el prefijo de 'CTRL + b' (root tmux)  a 'Ctrl + a' (nested tmux).
#   > 0 ('true' ), es un 'nested tmux' (el tmux se ejecuta dentro de otro tmux en una mismo emulador de terminal).
#   > 1 ('false'), es un 'root tmux'.
# Si no se define, su valor por defecto es 1 ('false'), es decir el tmux no esta dentro de otro.
#export TMUX_NESTED=1

# Definir el identificador del emulador de terminal a usar.
# > Useló cuando desea usar OSC-52 y solo en ciertos escenarios especiales:
#   > Si si emulador de terminal soporta OSC-52 pero no genera la variable de entorno 'TERM_PROGRAM' o tiene un
#     valor que no esta en la lista
#   > Cuando usara pseudo-terminales creadas por programas (tmux, ssh, etc.) donde no se puede identificar que terminal se
#     esta usando.
# > En vim/nvim/tmux es usado para determinar, de manera automatica, el mecanismo de escritura al clipboard.
# > Si 'TERM_PROGRAM' es 'foot', 'WezTerm', 'contour', 'iTerm.app', 'kitty' o 'alacritty', se usara OSC-52 para
#   escribir al clipboard ('paste').
#export TERM_PROGRAM='foot'

# La variable de entorno 'CIPBOARD' define el mecanismo de escritura de clipboard que usara un determino programa CLI.
# > Los valores de la variable 'CLIPBOARD_MODE' son:
#   > 0 : No habilita la escritura en el clipboard.
#   > 1 : Implementar un mecanismo usando OSC-52 (la terminal debe soportarlo).
#   > 2 : Implementar un mecanismo usando comandos externos de gestion de clipboard.
#   > 9 : Determinar automaticamente el mecanismo a usar.
# > Actualmente, los programas que lo usan son: VIM, NeoVIM y TMUX
#   > En VIM/NeoVIM, si no se define (o su valor es ''), el modo de escritura depende del valor de la variable VIM
#     'g:clipboard_writer_mode', y si este no se define, el modo de escritura se calculara automaticamente.
#   > En VIM/NeoVIM, si no se define (o su valor es ''), el modo de escritura depende del valor de opcion a nivel server
#     de tmux '@clipboard_writer_mode', y si este no se define, el modo de escritura se calculara automaticamente.
#export CLIPBOARD_MODE=0

# La variable de entorno 'YANK_TO_CB' es usado por VIM/NeoVIM, el es usado cuando se realize un 'yank' (en forma interactiva)
# este se pueda se copie automaticamente al clipboard.
# Su valor puede ser
#    > 0 ('true' ), si se cuando realiza un yank este se copiara automaticamente al clipboard.
#    > 1 ('false'), si realiza un yank este NO se copiara al clipboard.
# Si no se define, su valor depende de la variable VIM 'g:yank_to_clipboard', si este no se define, su valor es por defecto
# es 1 ('false').
#export YANK_TO_CB=1

# Variable usado para definir la ruta del folder padre donde estan los repositorios git.
# > Usos :
#   - Por WezTerm
#     > Listar los folderes git para crear workspace wezterm usando dicha ruta.
#   - Por script `~/.local/bin/tmuxu`
#     > El comando `s` (alias de `tmuxu new_session`) usa dicha valor si no se especifica las opción `-g GIT_FOLDER`.
# > Si no se define, se valor sera: '~/code'
#export MY_GIT_PATH="$HOME/code"

# Variable usado para definir la ruta del folder padre donde estan los repositorios git.
# > Usos :
#   - Por script `~/.local/bin/tmuxu`
#     > El comando `s` (alias de `tmuxu new_session`) usa dicha valor si no se especifica las opción `-w WORK_FOLDER`.
# > Si no se define, se valor sera: '~/works' o '~/work' (en ese orden de prioridad).
#export MY_WORK_PATH="$HOME/works"


#-----------------------------------------------------------------------------------
# Variables de entorno (personalizacion)
#-----------------------------------------------------------------------------------

# Modificar la variable de entorno PATH
#[ -d "${MY_TOOLS_PATH}/scrcpy" ] && PATH="$PATH:${MY_TOOLS_PATH}/scrcpy"
#[ -d "${MY_TOOLS_PATH}/mytool/bin" ] && PATH="$PATH:${MY_TOOLS_PATH}/mytool/bin"
#[ -d "${HOME}/mytool/bin" ] && PATH="$PATH:${HOME}/mytool/bin"

#export PATH


#-----------------------------------------------------------------------------------
# Alias
#-----------------------------------------------------------------------------------

#alias kc='kubectl'


#-----------------------------------------------------------------------------------
# Otros
#-----------------------------------------------------------------------------------

# Otros
