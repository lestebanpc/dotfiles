#!/bin/bash

#
# Para habilitar su uso genere el arcivo '~/.config.bash':
#  cp ~/.files/shell/bash/login/profile/config_template_nonwsl.bash ~/.config.bash
#  vim ~/.config.bash
#

#-----------------------------------------------------------------------------------
# Variables globales generales
#-----------------------------------------------------------------------------------

# Nombre del repositorio git o la ruta relativa del repositorio git respecto al HOME. 
# - Si no se establece (valor vacio), se usara el valor '.files'.
# - Usado para generar la variable de entorno 'MY_REPO_PATH' usado en el archivo de configuración de TMUX
#g_repo_name='.files'

# Folder base donde se almacena los subfolderes de los programas.
# - Si no es un valor valido (no existe o es vacio), su valor sera el valor por defecto "/var/opt/tools"
#g_programs_path='/var/opt/tools'

# Folder donde se almacena los binarios de tipo comando.
# - Si los comandos instalados por el script '~/${g_repo_name}/shell/bash/bin/linuxsetup/01_setup_binaries.bash' 
#   se ha instalado en una ruta personalizado (diferente a '/usr/local/bin' o '~/.local/bin'), es obligatorio
#   establecer la ruta correcta en dicha variable.
# - Si no se especifica (es vacio), se considera la ruta estandar '/usr/local/bin'
#g_bin_cmdpath='/usr/local/bin'

# Ruta del tema de 'Oh-My-Posh' usada para establecer el prompt a usar.
# Si no se establecer (es vacio), se usara '~/${g_repo_name}/etc/oh-my-posh/lepc-montys-1.omp.json'
#g_prompt_theme=~/.files/etc/oh-my-posh/lepc-montys-1.omp.json

# Si su valor es 0, se cargara (ejecutara como importacion de libreria) dentro de profile del usuario el archivo.
# de mis funciones definidas en "~/${g_repo_name}/shell/bash/lib/mod_myfunc.bash" usados por mi PC.
# Cualquier otro valor, no se cargara este script. Su valor por defecto es 1 (no se carga el script).
#g_load_myfunc=0

#-----------------------------------------------------------------------------------
# My custom alias
#-----------------------------------------------------------------------------------

#alias kc='kubectl'

