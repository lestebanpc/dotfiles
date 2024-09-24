#!/bin/bash

[ -z "$g_repo_name" ] && g_repo_name='.files'

#Funciones generales
source ~/${g_repo_name}/shell/bash/lib/mod_general.bash

#Funciones FZF
source ~/${g_repo_name}/shell/bash/lib/mod_fzf.bash

#Mis funciones (sobre mi NAS, sincronizacion con obsidian, ...)
if [ "$g_load_myfunc" = "0"  ]; then
    source ~/${g_repo_name}/shell/bash/lib/mod_myfunc.bash
fi






