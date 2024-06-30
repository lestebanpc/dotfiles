# Descripción

Mi archivos de configuración
Las estructura folderes es:

- './etc/' contiene archivos de configuracion de programas que no sea codigo interpretado (como bash, lua, vimscript, tmux script, etc).
- './shell/' incluye todo codigo que ejecutado por el interprete shell de su SO (incluye archivos usados por programas de terceros, archivos de instalacion, funciones de utilidad, etc).
  Estan organizados por carpetas que representan la implementacion de un determinado interpre shell 'sh' (no es un implementacion de un interpre shell, pero obliga a usar el estandar POSIX), 'bash', 'zsh', ...
  Por cada implementacion de interprete shell, generalmente, se tiene las siguientes carpetas:
  - 'autocomplete/'
  - 'keybindings'
  - 'shared/' las cuales son funciones que puede ser reusadas por todo cualquier script del interprete existente.
  - 'functions/' las cuales son funciones especificias para un uso particular, por ejemplo usadas o expuestas al profile del usuario del so.
  - 'setup/' script usados para configurar el entorno del usuario.
- './keys/tls/' mis archivos de claves publicas (generalmente almacenados en formados certificados x509).
- Archivos de configuración que a su vez es codigo interpretado pero no es ejecutado por un interprete shell.
  - './vim/' archivos de configuracion de VIM (en VimScript)
  - './nvim/' archivos de configuracion de NeoVIM (en LUA y VimScript)
  - './tmux/' archivos de configuracion de TMUX (archivos de configuracion de tmux)
  - './wezterm/' archivos de configuracion de terminal Wezterm (en LUA)



# Configuración en Linux

Para la configuracion se puede usar una de las siguientes script de configuración.

- Script './shell/bash/setup/linux/01_setup_commands.bash' descarga y configura comandos (un binario) y programas (conjunto de binarios) de repositorio que no sean del SO (usualmente GitHub).
  Se recomienda si ejecute con un usuario que no sea root para que los binarios/programas sean compartidos para todos los usuario, pero podria usarlo.
  Los binarios lo instalara en:
  - Si tiene la opcion 'sudo' como root habilitada, creara '/var/opt/tools' (lo instara crear la primeraz vez que ejecuta el script), si no puede intentara en '/opt/tools'.
  - Si no lo tiene, lo instalará en '~/tools'.
    Los programas lo instalar en:
  - Si tiene la opcion 'sudo' habilitada, creara '/usr/local/bin'.
  - Si no lo tiene, lo instalará en '~/.local/bin'.
    Los fuentes Nerd-Fonts lo instalar en:
  - Si tiene la opcion 'sudo' habilitada, creara '/usr/share/fonts'.
  - Si no lo tiene, lo instalará en '~/.local/share/fonts'.
    Si usa WSL, este descarga los binarios/programas para Windows en las sigueente rutas:
  - Los programas los descargará en 'D:\CLI\Programs'.
  - Los comandos los descargará en 'D:\CLI\Commands\bin'. 
    Si por algun motivo tiene acceso a 'sudo' como root, pero desea instalarlo a nivel usuario ('~/.local/bin' y '~/tools'), debera modificar el script './shell/bash/shared/utility_general.bash' modificando la funcion 'get_user_options' descomentando la lineas que obligen a retornar 'g_user_sudo_support' con valor 3. 
- Script './shell/bash/setup/linux/02_setup_profile.bash' permite configurar los archivos mas usados del profile del usuario y configurar VIM/NeoVIM.
- Script './shell/bash/setup/linux/03_update_all.bash' permite actualizar los comandos/programas descargados de los repositorios que no son del SO, actualizar los plugin de VIM/NoeVIM.

No se usa un gestor de plugin para VIM/NeoVIM (esto me trajo algunos problemas al ser usado en contenedores), por lo que se uso paquetes nativo de VIM/NeoVIM. Para actualizar los paquetes de VIM/NeoVIM use la opción './shell/bash/setup/linux/03_update_all.bash'.

Los pasos recomandos para configurar su SO son:

1. Instalar comandos basicos 'git', 'curl', 'tmux' y 'rsync'
   
   ```shell
   #En Linux de la familia Fedora
   sudo dnf install git
   sudo dnf install curl
   sudo dnf install tmux
   sudo dnf install rsync
   
   #En Linux de la familia Debian
   ```
   
   Si desea instalar VIM como IDE de desarrollo debera tener instalado Python3.
   
   ```shell
   #En Linux de la familia Fedora
   sudo dnf install python3
   
   #En Linux de la familia Debian
   sudo apt-get install python3
   ```

2. Clonar el repositorio
   
   ```shell
   #Descargar el repositorio en ~/.files
   git clone https://github.com/lestebanpc/dotfiles.git ~/.files
   ```

3. Descarga y configurar comandos/programas basicos de los repositorios (usualmente Github).
   
   > Se puede ejecutar con root, pero no se recomienda si desea que los comandos sean para todos los usuarios. 
   
   Se debera escoger por lo menos la opcion 'b' que instala 'binarios basicos', las fuentes 'Nerd-Fonts' y NeoVIM (instalar 'Nerd-Fonts' es opcional si desea usar solo terminal, en cuyo caso la fuente 'Nerd-Fonts' siempre debe estar instalado en el SO donde ejecuta la terminal).
   Si desea trabajar VIM con IDE desarrollo ejecute tambien la opcion '1048576' que descargara y configurar la ultima version de NodeJS.
   
   ```shell
   #Mostrar el menu para instalar/actualizar comandos/programas:
   ~/.files/shell/bash/setup/linux/01_setup_commands.bash
   
   #Para mostrar los parametros del script, ingrese un parametro invalido como:
   ~/.files/shell/bash/setup/linux/01_setup_commands.bash x
   ```

4. Para un usuario especifico, configure los archivos del profile y VIM/NeoVIM: 
   
   Ingrese sesion al usuario que desea configurar el profile y ejecute el script siguiente.
   
   Si desea usar configurar el modo desarrollo (VIM/NeoVIM como IDE) use la opcion 'd' o 'f'.
   
   Si desea usar configurar el modo editor (VIM/NeoVIM basico) use la opcion 'c' o 'e'.
   
   ```bash
   #Mostrar el menu para configurar el profile y VIM/NeoVIM
   ~/.files/shell/bash/setup/linux/02_setup_profile.bash
   
   #Para mostrar los parametros del script, ingrese un parametro invalido como:
   ~/.files/shell/bash/setup/linux/02_setup_profile.bash
   ```

5. Cierre session y vuelva a iniciar (o crage nuevamente su profile) para registrar la variables del profile del usuario.

6. Si desea actualizar los plugins de VIM/NeoVIM, ejecute el script:
   
   ```bash
   #Mostrar el menu para actualizar los plugins de VIM/NeoVIM
   ~/.files/shell/bash/setup/linux/04_update_all.bash
   
   #Para mostrar los parametros del script, ingrese un parametro invalido como:
   ~/.files/shell/bash/setup/linux/04_update_all.bash
   ```

7. Configure la terminal.
   Debera configurar la fuente 'Nerd-Fonts'. La fuente recomendada es 'JetBrainsMono Nerd Font Mono'.

# Configuración en Windows

Para la configuracion se puede usar una de las siguientes script de configuración.

- Script '.\powershell\setup\windows\02_setup_profile_win.ps1' permite configurar los archivos mas usados del profile del usuario y configurar VIM/NeoVIM.
- Script '.\powershell\setup\windows\03_update_all_win.ps1' permite actualizar los comandos/programas descargados de los repositorios que no son del SO, actualizar los plugin de VIM/NoeVIM.

No se usa un gestor de plugin para VIM/NeoVIM (esto me trajo algunos problemas al ser usado en contenedores), por lo que se uso paquetes nativo de VIM/NeoVIM. Para actualizar los paquetes de VIM/NeoVIM use la opción './shell/powershell/setup/windows/03_update_all.ps1'.

Los pasos recomandos para configurar su SO son:

1. Instalar comandos basicos 'git', 'Powershell Core' (requiere .NET SDK o RTE instalado) y 'VIM' para Windows.
   
   ```shell
   #
   ```
   
   Si desea instalar VIM como IDE de desarrollo debera tener instalado NodeJS y Python3.
   
   ```shell
   #
   ```
   
   Si cuenta con WSL, 'NodeJS', '. Net' y 'Powershell Core'y lo podra instalar usando la opcion el menu mostrado al ejecutar el script '~/.files/shell/bash/setup/linux/01_setup_commands.bash'
   
   - Usando la opcion '1048576' del menu para instalar la ultima version de 'NodeJS' en 'D:\CLI\Programs\NodeJS'.
     En las variables de entorno del sistema debe registrar la la ruta 'D:\CLI\Programs\NodeJS'.
   - Usando la opcion '32768' del menu para instalar las 3 ultimas versiones del SDK de .NET en 'D:\CLI\Programs\DotNet'.
     En las variables de entorno del sistema debe registrar la la ruta 'D:\CLI\Programs\NodeJS'.
   - Usando la opcion '128' del menu para instalar la ultima version de Powershell Core en 'D:\CLI\Programs\PowerShell'.
     En las variables de entorno del sistema debe registrar la la ruta 'D:\CLI\Programs\PowerShell'.
     Si usa Windows Terminal, debera configurar adicionar un nuevo perfil para la terminal 'Powershell':
     - Nombre: Powershell
     - Linea de comandos: D:\CLI\Programs\PowerShell\pwsh.exe
     - Directorio de Inicio: %USERPROFILE%
     - Icono: D:\CLI\Programs\PowerShell\assets\StoreLogo.png
   
   Se recomienda tener estos programas instalados y configurados antes de continuar

2. En una terminal de Powershell, clone el repositorio
   
   ```shell
   #Descargar el repositorio en ~/.files
   git clone https://github.com/lestebanpc/dotfiles.git ${env:USERPROFILE}/.files
   ```

3. Para un usuario especifico, configure los archivos del profile y VIM/NeoVIM: 
   
   Ingrese sesion al usuario que desea configurar el profile y ejecute el script siguiente.
   
   Si desea usar configurar el modo desarrollo (VIM/NeoVIM como IDE) use la opcion 'a'.
   
   ```bash
   #Mostrar el menu para configurar el profile y VIM/NeoVIM
   ${env:USERPROFILE}\.files\powershell\setup\windows\02_setup_profile_win.ps1
   ```

4. Cierre terminal y vuelve a iniciar la configuración.

5. Configure el Windows Terminal.
   Debera configurar la fuente 'Nerd-Fonts'. La fuente recomendada es 'JetBrainsMono Nerd Font Mono'.

6. Problemas y desafios encontrados por usar Windows.
   Algunos comandos como FZF deberan adaptarse para usarse en VIM/NoeVIM.

7. Si desea actualizar los plugins de VIM/NeoVIM, ejecute el script:
   
   ```bash
   #Mostrar el menu para actualizar los plugins de VIM/NeoVIM
   ${env:USERPROFILE}\.files\powershell\setup\windows\03_update_all_win.ps1
   ```

# Configuracion en una 'proot-distro' de Termux (Android)

Es el mismo procedemiento que la configuración en Linux pero con algunas consideraciones previas:
