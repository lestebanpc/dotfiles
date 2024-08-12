#!/bin/bash

[ -z "$g_repo_name" ] && g_repo_name='.files'

#Funciones generales
source ~/${g_repo_name}/shell/bash/lib/mod_general.bash

#Funciones FZF
source ~/${g_repo_name}/shell/bash/lib/mod_fzf.bash

#Mis funciones sobre mi NAS 
source ~/${g_repo_name}/shell/bash/lib/mod_mynas.bash






