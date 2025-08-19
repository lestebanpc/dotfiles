#
# Para habilitar su uso genere el arcivo '~/.config/powershell/custom_profile.ps1':
#  cp ~/.files/shell/powershell/login/windowsprofile/custom_profile_template.ps1 "${env:USERPROFILE}/custom_profile.ps1"
#  vim "${env:USERPROFILE}/custom_profile.ps1"
#

#-----------------------------------------------------------------------------------
# Variables globales
#-----------------------------------------------------------------------------------

# Nombre del repositorio git o la ruta relativa del repositorio git respecto al HOME.
# - Si no se establece (valor vacio), se usara el valor '.files'.
#g_repo_name= '.files'

# Folder base donde se almacena los subfolderes de los programas.
# - Si no es un valor valido (no existe o es vacio), su valor sera el valor por defecto "C:\apps\tools"
#g_tools_path= 'D:\apps\tools'

# Folder donde se almacena los binarios de tipo comando.
# - Si no se establece (es vacio), se considera la ruta estandar 'C:\apps\cmds\bin'
#g_bin_path='D:\apps\cmds\bin'

# Ruta del tema de 'Oh-My-Posh' usada para establecer el prompt a usar.
# Si no se establecer (es vacio), se establece el valor por defecto '${env:USERPROFILE}\${g_repo_name}\etc\oh-my-posh\lepc-montys-green1.json'
#g_prompt_theme= "${env:USERPROFILE}\.files\etc\oh-my-posh\lepc-montys-green1.json"

#-----------------------------------------------------------------------------------
# My custom alias
#-----------------------------------------------------------------------------------
