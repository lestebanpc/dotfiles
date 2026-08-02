#
# > Para personalizar la logica del profile cree el archivo  '.custom_profile.ps1':
#   cp ~/.files/shell/powershell/login/linuxprofile/template_custom_profile.ps1 ~/.config/powershell/.custom_profile.ps1
#   vim ~/.config/powershell/.custom_profile.ps1
#

if(-not ${g_repo_name}) {
    $g_repo_name= '.files'
}

#------------------------------------------------------------------------------------------------
#Funciones Generales
#------------------------------------------------------------------------------------------------

. "${HOME}/${g_repo_name}/shell/powershell/lib/linux/mod_general.ps1"
