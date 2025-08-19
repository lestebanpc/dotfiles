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

# Nombre del repositorio git o la ruta relativa del repositorio git respecto al HOME.
# - Si no se establece (valor vacio), se usara el valor '.files'.
# - Usado para generar la variable de entorno 'MY_REPO_PATH' usado en la configuración de programas como TMUX.
#g_repo_name='.files'

# Folder base donde se almacena los subfolderes de los programas.
# - Si no es un valor valido (no existe o es vacio), su valor sera el valor por defecto "/var/opt/tools".
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

# Si su valor es 0, se cargara (importara como libreria), dentro de profile del usuario el archivo, las funciones
# genericas "~/${g_repo_name}/shell/bash/lib/mod_myfunc.bash" de utilidades cuando esta en la red local dei
# 'my house', tales como:
# > 'start_music' y 'stop_music': monta la unidades de musica, establece acceso exlusivo de la tarjeta de sonido
#    e iniciar el servidor MDP.
# > 'set_first_dns_server': vuelve a establece el servidor DNS cuando se usa intefaces de red bridge.
# Cualquier otro valor, no se cargara este script.
# Su valor por defecto es 1 (no se carga el script).
#g_load_myfunc=0

# Si su valor es 0, se cargara (importara como libreria), dentro de profile del usuario el archivo, las funciones
# genericas "~/${g_repo_name}/shell/bash/lib/mod_myfunc.bash" sobre WSL.
# Cualquier otro valor, no se cargara este script.
# Su valor por defecto es 1 (no se carga el script).
g_load_wslfunc=0


#-----------------------------------------------------------------------------------
# Variables globales de configuracion (para Linux WSL)
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
# My enviroment variables
#-----------------------------------------------------------------------------------

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
# My custom alias
#-----------------------------------------------------------------------------------

#alias kc='kubectl'
