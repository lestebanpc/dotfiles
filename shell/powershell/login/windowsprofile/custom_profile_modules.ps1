
if(-not ${g_repo_name}) {
    $g_repo_name= '.files'
}

#------------------------------------------------------------------------------------------------
#Funciones Generales
#------------------------------------------------------------------------------------------------

. "${env:USERPROFILE}\${g_repo_name}\shell\powershell\lib\windows\mod_general.ps1"
