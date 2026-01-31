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
# Variables globales de configuracion (generales)
#-----------------------------------------------------------------------------------

# Variables de entorno comunes y usuados por varios programas
#export EDITOR="vim"
#export VISUAL="vim"
#export SYSTEMD_EDITOR="vim"

# Nombre del repositorio git o la ruta relativa del repositorio git respecto al HOME.
# - Si no se establece (valor vacio), se usara el valor '.files'.
# - Usado para generar la variable de entorno 'MY_REPO_PATH' usado en la configuración de programas como TMUX.
#g_repo_name='.files'

# Folder base donde se almacena los subfolderes de los programas.
# - Si no es un valor valido (no existe o es vacio), su valor sera el valor por defecto "/var/opt/tools"
# - Si es un directorio valido se Convertira en la variable de entorno 'MY_TOOLS_PATH' usado en la configuración
#   de programas como TMUX.
#g_tools_path='/var/opt/tools'

# Folder donde se almacena los binarios de tipo comando.
# - Si los comandos instalados por el script '~/${g_repo_name}/shell/bash/bin/linuxsetup/01_setup_binaries.bash'
#   se ha instalado en una ruta personalizado (diferente a '/usr/local/bin' o '~/.local/bin'), es obligatorio
#   establecer la ruta correcta en dicha variable.
# - Si no se especifica (es vacio), se considera la ruta estandar '/usr/local/bin'
#g_lnx_bin_path='/usr/local/bin'

# Ruta del tema de 'Oh-My-Posh' usada para establecer el prompt a usar.
# Si no se establecer (es vacio), se usara '~/${g_repo_name}/etc/oh-my-posh/default_settings.json'
#g_prompt_theme=~/.files/etc/oh-my-posh/lepc-montys-blue1.json

# Tipo de origen de la sesion del profile.
# > Usando esta variable se determina el valor de la variable de entorno del usuario 'MY_SESSION_SRC'.
# Sus valores puede ser:
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
#        y programadas GUI del servidor.
#      > Aparte de tener acceso a la GPU tiene acceso a todo lo necesario para interactuar con estos (como bus de mensajes).
#      > No estan diseñados para que se conecten remotamente por ssh.
#      > Ejemplo: La VM ligera WSL2 que esta integrada con Windows en modo escritorio.
#  > Si no se define, su valor por defecto es '0' (Headless Server).
g_enviroment_type=2

# Permite cargar capacidades adicionales (funciones ubicados en "~/${g_repo_name}/shell/bash/lib/mod_myfunc.bash") requeridas
# cuando se esta en red local de 'my house'.
# Entre las capacidades que se tiene son:
#  > 'start_music' y 'stop_music'
#    Permite montar la unidades de musica, establece acceso exlusivo de la tarjeta de sonido e iniciar el servidor MDP.
#  > 'set_first_dns_server'
#    Vuelve a establece el servidor DNS primario/local cuando se usa intefaces de red bridge y pierde comunicación.
# Sus valores puede ser:
#  > 0 Se importara dentro de profile la capacidades adicionales
#  > Cualquier otro valor, no se cargara este script.
#    Su valor por defecto es 1 (no se carga el script).
#g_load_myfunc=0


#-----------------------------------------------------------------------------------
# Variables de entorno basicos
#-----------------------------------------------------------------------------------

# Variables de entorno comunes y usuados por varios programas
#export EDITOR="vim"
#export VISUAL="vim"
#export SYSTEMD_EDITOR="vim"

# La variable de entorno 'TMUX_NESTED' es usado por 'tmux' e indica si el tmux actual se ejecuta dentro de otro tmux padre.
# Es usado para:
#  > Definir para cambiar el prefijo de 'CTRL + b' (root tmux)  a 'Ctrl + a' (nested tmux).
# Sus valores son:
#  > 0 ('true' ), es un 'nested tmux' (el tmux se ejecuta dentro de otro tmux en una mismo emulador de terminal).
#  > 1 ('false'), es un 'root tmux'.
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

# La variable de entorno 'SET_CIPBOARD' define el mecanismo de escritura de clipboard que se usara en 'tmux':
# > 0 : No habilita la escritura en el clipboard.
# > 1 : Habilita la escritura usando el caracter de escape ANSI OSC-52 (la terminal debe soportarlo)
# > 2 : Habilita la escritura usando comandos externos (requiere tener instalado 'xsel', 'xclip' or 'wl-copy').
# >   : Se determina automaticamente el mecanismo a usar.
# Su no se define (valor ''), se determinara automaticamente el mecanismo a usar.
#export SET_CLIPBOARD=1

# La variable de entorno 'CIPBOARD' define el mecanismo de escritura de clipboard en un programa CLI.
# Actualmente, solo es usado por VIM/NeoVIM y su soporte incluye:
#  > Acciones de escritura al clipboard usanbdo el valor de los registros VIM.
#  > Escritura automatica al clipboard despues de realizar el yank (si esta habilitado la variable 'g:yank_to_clipboard'
#    o 'YANK_TO_CB').
# Los valores de la variable 'CLIPBOARD' son:
#  > 1 : Implementar un mecanismo usando OSC-52 (la terminal debe soportarlo).
#  > 2 : Implementar un mecanismo usando comandos externos de gestion de clipboard.
#  > 9 : Determinar automaticamente el mecanismo a usar.
# Si no se define, su valor depende de la variable VIM 'g:clipboard_osc52_format', si este no se define, el mecanismo
# es de escritura se descrubira automaticamente.
#export CLIPBOARD=0

# La variable de entorno 'YANK_TO_CB' es usado por VIM/NeoVIM, el es usado cuando se realize un 'yank' (en forma interactiva)
# este se pueda se copie automaticamente al clipboard.
# Su valor puede ser
#    > 0 ('true' ), si se cuando realiza un yank este se copiara automaticamente al clipboard.
#    > 1 ('false'), si realiza un yank este NO se copiara al clipboard.
# Si no se define, su valor depende de la variable VIM 'g:yank_to_clipboard', si este no se define, su valor es por defecto
# es 1 ('false').
#export YANK_TO_CB=1


#-----------------------------------------------------------------------------------
# Eliminar variables de entorno para que se puedan recalcular
#-----------------------------------------------------------------------------------

# Establecer el directorio de datos de tmux. No usar el default ('/tmp') debido a que es usado por host.
export TMUX_TMPDIR="/var/tmp"

# Variables autogeneradas por tmux
unset TMUX
unset TMUX_PANE

# Vairables autogeneradas y usadop por oh-my-tmux
unset TMUX_PROGRAM
unset TMUX_VERSION
unset TMUX_SOCKET
unset TMUX_CONF
unset TMUX_CUSTOM_CONF
unset TMUX_SHELL_PATH

unset TMUX_SET_CLIPBOARD


#-----------------------------------------------------------------------------------
# My custom alias
#-----------------------------------------------------------------------------------

#alias kc='kubectl'
