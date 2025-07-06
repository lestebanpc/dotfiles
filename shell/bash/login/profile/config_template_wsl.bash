#!/bin/bash

#
# Para habilitar su uso genere el arcivo '~/.config.bash':
#  cp ~/.files/shell/bash/login/profile/config_template_wsl.bash ~/.config.bash
#  vim ~/.config.bash
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
# - Si es un directorio valido se Convertira en la variable de entorno 'MY_PRGS_PATH' usado en la configuración
#   de programas como TMUX.
#g_programs_path='/var/opt/tools'

# Folder donde se almacena los binarios de tipo comando.
# - Si los comandos instalados por el script '~/${g_repo_name}/shell/bash/bin/linuxsetup/01_setup_binaries.bash'
#   se ha instalado en una ruta personalizado (diferente a '/usr/local/bin' o '~/.local/bin'), es obligatorio
#   establecer la ruta correcta en dicha variable.
# - Si no se especifica (es vacio), se considera la ruta estandar '/usr/local/bin'
#g_bin_cmdpath='/usr/local/bin'

# Ruta del tema de 'Oh-My-Posh' usada para establecer el prompt a usar.
# Si no se establecer (es vacio), se usara '~/${g_repo_name}/etc/oh-my-posh/default_settings.json'
#g_prompt_theme=~/.files/etc/oh-my-posh/lepc-montys-blue1.json

# Si su valor es 0, se cargara (ejecutara como importacion de libreria) dentro de profile del usuario el archivo.
# de mis funciones definidas en "~/${g_repo_name}/shell/bash/lib/mod_myfunc.bash" usados por mi PC.
# Cualquier otro valor, no se cargara este script. Su valor por defecto es 1 (no se carga el script).
#g_load_myfunc=0

# Si su valor es 0, se cargara (ejecutara como importacion de libreria) dentro de profile del usuario el archivo.
# de las funciones genericas "~/${g_repo_name}/shell/bash/lib/mod_myfunc.bash" sobre WSL.
# Cualquier otro valor, no se cargara este script. Su valor por defecto es 1 (no se carga el script).
g_load_wslfunc=0


#-----------------------------------------------------------------------------------
# Variables globales de configuracion (para Linux WSL)
#-----------------------------------------------------------------------------------

# Folder base, donde se almacena el programas, comando y afines usados por Windows.
# - Si no se ingresa un valor valido o no existe, se asignara su valor por defecto "/mnt/c/cli" (es decir "c:\cli").
# - En este folder almacena la siguiente estructura de folderes donde estan:
#     > "${g_win_base_path}/prgs"     : subfolder donde se almacena los subfolder de los programas.
#     > "${g_win_base_path}/cmds/bin" : subfolder donde se almacena los comandos.
#     > "${g_win_base_path}/cmds/doc" : subfolder donde se almacena documentacion del comando.
#     > "${g_win_base_path}/cmds/etc" : subfolder donde se almacena archivos adicionales del comando.
#     > "${g_win_base_path}/fonts" : subfolder donde se almacena los archivos de fuentes tipograficas.
#$g_win_base_path='/mnt/d/cli'


#-----------------------------------------------------------------------------------
# My enviroment variables
#-----------------------------------------------------------------------------------

# Definir el identificador del emulador de terminal a usar.
# > Useló en pseudo-terminales creadas por programas (tmux, ssh, etc.) donde no se puede identificar que terminal se esta usando.
# > En vim/nvim/tmux es usado para determinar, de manera automatica, el mecanismo de escritura al clipboard.
# > Si 'TERM_PROGRAM' tiene algunos de los siguientes valores 'foot', 'Wezterm', 'contour', 'iTerm.app', 'kitty',
#   'alacritty'; se usara OSC-52 para escribir al clipboard ('paste').
#export TERM_PROGRAM='foot'

# La variable de entorno 'SET_CIPBOARD' define, de fomra manual, el mecanismo de escritura de clipboard en 'tmux':
# > 0 : No habilita la escritura en el clipboard.
# > 1 : Habilita la escritura usando el caracter de escape ANSI OSC-52 (la terminal debe soportarlo)
# > 2 : Habilita la escritura usando comandos externos (requiere tener instalado 'xsel', 'xclip' or 'wl-copy').
#export SET_CLIPBOARD=1

# La variable de entorno 'CIPBOARD' define, de fomra manual, el mecanismo de escritura de clipboard en 'vim'/'nvim':
# > 0 : Usar el mecanismo nativo de VIM/NeoVIM (siempre que este esta habilitado).
# > 1 : Implementar un mecanismo usando OSC-52 (la terminal debe soportarlo).
# > 2 : Implementar un mecanismo usando comandos externos de gestion de clipboard.
#export CLIPBOARD=0


#-----------------------------------------------------------------------------------
# My custom alias
#-----------------------------------------------------------------------------------

#alias kc='kubectl'
