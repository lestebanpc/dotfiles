#!/bin/bash

[ -z "$g_repo_name" ] && g_repo_name='.files'

#Funciones generales
# shellcheck source=/home/lucianoepc/.files/shell/bash/lib/mod_general.bash
source ~/${g_repo_name}/shell/bash/lib/mod_general.bash

#Funciones FZF
# shellcheck source=/home/lucianoepc/.files/shell/bash/lib/mod_fzf.bash
source ~/${g_repo_name}/shell/bash/lib/mod_fzf.bash

#Funciones genericas para WSL
if [ "$g_load_wslfunc" = "0"  ]; then
    # shellcheck source=/home/lucianoepc/.files/shell/bash/lib/mod_wsl.bash
    source ~/${g_repo_name}/shell/bash/lib/mod_wsl.bash
fi

#Mis funciones de mi PC (sobre mi NAS, sincronizacion con obsidian, ...)
if [ "$g_load_myfunc" = "0"  ]; then
    # shellcheck source=/home/lucianoepc/.files/shell/bash/lib/mod_myfunc.bash
    source ~/${g_repo_name}/shell/bash/lib/mod_myfunc.bash
fi
