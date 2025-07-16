# Descripción

Mi archivos de configuración
Las estructura folderes es:

- './etc/' contiene archivos de configuracion de programas que no sea codigo interpretado (como bash, lua, vimscript, tmux script, etc).
- './shell/' incluye todo codigo que ejecutado por el interprete shell de su SO (incluye archivos usados por programas de terceros, archivos de instalacion, funciones de utilidad, etc).
  Estan organizados por carpetas que representan la implementacion de un determinado interpre shell 'sh' (no es un implementacion de un interpre shell, pero obliga a usar el estandar POSIX), 'bash', 'zsh', ...
  Por cada implementacion de interprete shell, generalmente, se tiene las siguientes carpetas:
  - 'login/' script usado en su login
    - 'autocomplete/' script usados por para el autocomplete en su profile
    - 'keybindings/' script de keybindings usado en su profile
    - 'profile/' script de su profile.
  - 'lib/' script tratados como modulos que contiene funciones y variables, las cuales son importados en cualquier script usando 'source'.
  - 'bin/' script tratados como ejecutables.
    - 'linuxsetup/' script usados para configurar el entorno del usuario.
    - 'tmux/' script que expone funciones que son usados en la configuracion de tmux.
    - 'fzf/' script que expone funciones que son usados para mostrar popup fzf.
- './keys/tls/' mis archivos de claves publicas (generalmente almacenados en formados certificados x509).
- Archivos de configuración que a su vez es codigo interpretado pero no es ejecutado por un interprete shell.
  - './vim/' archivos de configuracion de VIM (en VimScript)
  - './nvim/' archivos de configuracion de NeoVIM (en LUA y VimScript).
  - './tmux/' archivos de configuracion usando script TMUX.
  - './wezterm/' archivos de configuracion de terminal Wezterm (en LUA).


 - Archivos para personalizar la configuracion por defecto en Linux:

```bash
# Archivos para personalizar la configuracion del profile de bash
~/.profile_config.bash

# Archivos para personalizar la configuracion del profile de powershell
~/.config/powershell/profile_config.ps1

# Archivos para personalizar la configuracion de VIM
~/.vim/custom_config.vim

# Archivos para personalizar la configuracion de NeoVIM
~/.config/nvim/custom_config.vim

# Archivos para personalizar los script de configuración
shell/bash/bin/linuxsetup/.setup_config.bash
shell/bash/bin/termuxsetup/.setup_config.bash
shell/powershell/bin/linuxsetup/.setup_config.ps1
```

 - Archivos para personalizar la configuracion por defecto en Windows:

```powershell
# Archivos para personalizar la configuracion del profile de powershell
~/.profile_config.ps1

# Archivos para personalizar los script de configuración
shell/powershell/bin/windowssetup/.setup_config.ps1

# Archivos para personalizar la configuracion de VIM
~/.vimfiles/custom_config.vim

# Archivos para personalizar la configuracion de NeoVIM
./nvim/custom_config.vim
```


# Configuración en Linux

Para la configuracion se puede usar una de las siguientes script de configuración.

- Script `./shell/bash/bin/linuxsetup/01_setup_binaries.bash` descarga y configura comandos (un binario) y programas (conjunto de binarios) de repositorio que no sean del SO (usualmente GitHub).
  Se recomienda si ejecute con un usuario que no sea root para que los binarios/programas sean compartidos para todos los usuario, pero podria usarlo.
  Por defecto, aunque puede moficarse usando los archivos de configuración, se usaran la siguientes rutas de configuración:

  - Los programas se instalaran:
    - Si tiene la opcion 'sudo' como root habilitada, creara `/var/opt/tools` (lo instara crear la primeraz vez que ejecuta el script), si no puede intentara en '/opt/tools'.
    - Si no lo tiene, lo instalará en `~/tools`.
  - Los comandos lo instalar en:
    - Si tiene la opcion 'sudo' habilitada, creara `/usr/local/bin`.
    - Si no lo tiene, lo instalará en `~/.local/bin`.
  - Las fuentes Nerd-Fonts lo instalar en:
    - Si tiene la opcion 'sudo' habilitada, creara `/usr/share/fonts`.
    - Si no lo tiene, lo instalará en `~/.local/share/fonts`.
  - Si usa WSL, este descarga los binarios/programas para Windows en las sigueente rutas:
    - Los programas los descargará en `C:\cli\prgs`.
    - Los comandos los descargará en `C:\cli\cmds\bin`.

- Script `./shell/bash/bin/linuxsetup/04_install_profile.bash` permite configurar los archivos mas usados del profile del usuario y configurar VIM/NeoVIM.

- Script `./shell/bash/bin/linuxsetup/05_update_profile.bash` permite actualizar los comandos/programas descargados de los repositorios que no son del SO, actualizar los plugin de VIM/NoeVIM.

No uso un gestor de plugin para VIM/NeoVIM, uso paquetes nativo de VIM/NeoVIM. Para actualizar los paquetes de VIM/NeoVIM use la opción `./shell/bash/bin/linuxsetup/05_update_profile.bash`.

Los pasos recomandos para configurar su SO son:

1. Instalar comandos basicos 'git', 'curl', 'tmux' y 'rsync'

```shell
#1. Instalar comandos basicos 'git', 'curl', 'tmux' y 'rsync'

#En Linux de la familia Fedora
sudo dnf install git
sudo dnf install curl
sudo dnf install tmux
sudo dnf install rsync

#En Linux de la familia Debian

#2. Si desea instalar VIM como IDE de desarrollo debera tener instalado Python3.

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

3. Opcional. Configuración de los script de instalación/actualización.
   Los script de instalación usan variable globales con valores por defecto, las cuales puede ser modificados, segun orden de prioridad:
- Los argumentos enviados a ejecutar el script,
- Las variables especificadas en el archivos de configuración ".setup_config.bash" (por defecto este archivo no existe, tiene que crearlo).

Puede copiar el archivo basando en la plantilla existente en su repositorio:

```shell
cp ~/.files/shell/bash/bin/linuxsetup/lib/setup_config_template.bash ~/.files/shell/bash/bin/linuxsetup/.setup_config.bash
```

Descomente las variables que desea modificar y establecer el valor deseado.

4. Descarga y configurar comandos/programas basicos de los repositorios (usualmente Github).

   - Se puede ejecutar con root, pero no se recomienda si desea que los comandos sean para todos los usuarios.

   - Se debera escoger por lo menos la opcion 'b' que instala 'binarios basicos', las fuentes 'Nerd-Fonts' y NeoVIM (instalar 'Nerd-Fonts' es opcional si desea usar solo terminal, en cuyo caso la fuente 'Nerd-Fonts' siempre debe estar instalado en el SO donde ejecuta la terminal).

   - Si desea trabajar VIM con IDE desarrollo ejecute tambien la opcion '1048576' que descargara y configurar la ultima version de NodeJS.

```shell
#Mostrar el menu para instalar/actualizar comandos/programas:
~/.files/shell/bash/bin/linuxsetup/01_setup_binaries.bash

#Para mostrar los parametros del script, ingrese un parametro invalido como:
~/.files/shell/bash/bin/linuxsetup/01_setup_binaries.bash x
```

5. Configure la terminal.
   Debera configurar la fuente 'Nerd-Fonts'. La fuente que uso es `JetBrainsMono Nerd Font Mono`.

6. Para un usuario especifico, configure los plugins VIM/NeoVIM:
   Ingrese sesion al usuario que desea configurar el profile y ejecute el script siguiente.

   - Si desea usar configurar el modo desarrollo (VIM/NeoVIM como IDE) use la opcion 'd' o 'f'.
   - Si desea usar configurar el modo editor (VIM/NeoVIM basico) use la opcion 'c' o 'e'.

```bash
#Mostrar el menu para configurar el profile y VIM/NeoVIM
~/.files/shell/bash/bin/linuxsetup/04_install_profile.bash

#Para mostrar los parametros del script, ingrese un parametro invalido como:
~/.files/shell/bash/bin/linuxsetup/04_install_profile.bash
```

7. Opcional. Configuración de su profile del shell del SO:
   El script de profile `~/.bashrc` define algunas variable globales con valores por defecto, las cuales puede ser modificados, defiendo el archivo de configuración `.custom_profile.bash`.
   El archivo de configuración por defecto no existe y debe ser creado en `~/.custom_profile.bash`.

   Tambien puede copiar el archivo basando en la plantilla existente en su repositorio:
   Descomente las variables que desea modificar y establecer el valor deseado.

```shell
cp ~/.files/shell/bash/login/profile/profile_config_template_nonwsl.bash ~/.custom_profile.bash
cp ~/.files/shell/bash/login/profile/profile_config_template_wsl.bash ~/.custom_profile.bash
```

8. Vuelva a cargar su profile para registrar la variables de entorno de su profile del usuario.

9. Opcional. Configuración de VIM/NeoVIM:
   El script de inicio de VIM define algunas variable globales con valores por defecto, las cuales puede ser modificados, defiendo el archivo de configuración 'config.vim':

   - Para VIM, se requiere el archivo `~/.vim/config.vim` o en cualquier ruta del runtimepath.
     `cp ~/.files/vim/config_template.vim ~/.vim/`
   - Para NoeVIM, se requiere el archivo "~/.config/nvim/config.vim" o en cualquier ruta del runtimepath.
     `cp ~/.files/nvim/config_template.vim ~/.config/nvim/config.vim`

   Puede copiar el archivo basando en la plantilla existente en su repositorio:
   Descomente las variables que desea modificar y establecer el valor deseado.

```shell
cp ~/.files/vim/template_config.vim ~/.vim/config.vim
cp ~/.files/nvim/template_config.vim ~/.config/nvim/config.vim
```

10. Si desea actualizar los plugins de VIM/NeoVIM, ejecute el script:

```bash
#Mostrar el menu para actualizar los plugins de VIM/NeoVIM
~/.files/shell/bash/bin/linuxsetup/04_update_all.bash

#Para mostrar los parametros del script, ingrese un parametro invalido como:
~/.files/shell/bash/bin/linuxsetup/04_update_all.bash
```

11. Otras configuraciones> Configuración de GIT

12. Otras configuraciones> Configuración del cliente SSH

13. Uso de VIM/NeoVIM/Tmux

En NeoVIM se puede usar las siguientes variables de entorno:

 - La variable de entorno `ONLY_BASIC` desactiva el plugins usado para modo IDE

 - La variable de entorno `USE_COC` es 1 usa CoC en vez del LSP nativo (como lo hace VIM)

 - La variable de entorno `CLIPBOARD` pueden tener los siguientes valores:

   - `0` Usar el mecanismo nativo de escritura al clipboard de NeoVIM
   - `1` Implementar el mecanismo de uso OSC 52
   - `2` Implementar el mecanismo de uso comandos externo del gestion de clipboard
   - Otro valor, determina automaticamente el mecanismo correcto segun order de prioridad:
     - Usar mecanismo nativo (SOC y comandos externos) si esta habilitado.
     - Implementar el mecanismo OSC 52.

 - La variable de entorno `OSC52_FORMAT`. Esta variable solo sera usado cuando `g:set_clipboard_type` es `1` y puede tener
   los siguientes posibles valores:

   - `0` Formato OSC 52 estandar que es enviado directmente una terminal que NO use como '$TERM' a GNU screen.
   - `1` Formato DSC chunking que es enviado directmente a una terminal que use como '$TERM' a GNU screen. La data es enviada por varias trozos pequeños en formato DSC.
   - `2` Formato DSC enmascarado para TMUX (tmux requiere un formato determinado, y si esta configurado, este se encargara de traducir al formato OSC 52 estandar y reenviarlo a la terminal donde corre tmux). Enmascara el OSC52 como un parametro de una secuancia de escape DSC.
     Si no define o tiene otro valor, se calucara automaticamente su valor. Solo use esta opcion cuando VIM/NeoVIM se ejecuta de manera local la terminal, si lo ejecuta de manera remota, por ejemplo esta dentro programa ssh o dentro de un contenedor, se recomianda establecer el valor si esta dentro de tmux o de una terminal GNU '$TERM' a screen.

   Ejemplo de uso:

   - `CLIPBOARD=1 nvim`
   - `CLIPBOARD=1 OSC52_FORMAT=2 nvim`
   - `CLIPBOARD=1 OSC52_FORMAT=2 USE_COC=1 nvim`
   - `CLIPBOARD=1 USE_COC=1 nvim`
   - `ONLY_BASIC=1 nvim`

 En VIM se puede usar las siguientes variable de entorno:

 - La variable de entorno `ONLY_BASIC` desactiva el plugins usado para modo IDE

 - La variable de entorno `CLIPBOARD` pueden tener los siguientes valores:

   - `0` Usar el mecanismo nativo de escritura al clipboard de VIM
   - `1` Implementar el mecanismo de uso OSC 52
   - `2` Implementar el mecanismo de uso comandos externo del gestion de clipboard
   - Otro valor, Determinar automaticamente el mecanismo correcto segun order de prioridad:
     - Implementar el mecanismo OSC 52, si la terminal lo permite.
     - Usar mecanismo nativo (API del SO) si esta habilitado.
     - Implementar el mecanismo de uso comandos externo del gestion de clipboard
     - Si no existe comando externo, se Implementara el mecanismo OSC 52

 - La variable de entorno `OSC52_FORMAT`. Esta variable solo sera usado cuando `g:set_clipboard_type` es `1` y puede tener
   los siguientes posibles valores:

   - `0` Formato OSC 52 estandar que es enviado directmente una terminal que NO use como `$TERM` a GNU screen.
   - `1` Formato DSC chunking que es enviado directmente a una terminal que use como `$TERM` a GNU screen. La data es enviada por varias trozos pequeños en formato DSC.
   - `2` Formato DSC enmascarado para TMUX (tmux requiere un formato determinado, y si esta configurado, este se encargara de traducir al formato OSC 52 estandar y reenviarlo a la terminal donde corre tmux). Enmascara el OSC52 como un parametro de una secuancia de escape DSC.
     Si no define o tiene otro valor, se calucara automaticamente su valor. Solo use esta opcion cuando VIM/NeoVIM se ejecuta de manera local la terminal, si lo ejecuta de manera remota, por ejemplo esta dentro programa ssh o dentro de un contenedor, se recomianda establecer el valor si esta dentro de tmux o de una terminal GNU '$TERM' a screen.

   Ejemplo de uso:

   - `CLIPBOARD=1 nvim`
   - `CLIPBOARD=1 OSC52_FORMAT=2 nvim`
   - `ONLY_BASIC=1 vim`

 En TMUX, autogenera los siguiente variables de entorno:

 - La variable de entorno `TMUX_SET_CLIPBOARD` cuyos posibles valores son:
   - Otro valor, No se ha podido establecer un mecanismo del clipboard (se indica que usa comando externo, pero no se ubica.
   - `0` Usar comandos externo de clipboard y la opcion 'set-clipboard' en 'off'
   - `1` Usar OSC 52 con la opcion 'set-clipboard' en 'on'
   - `2` Usar OSC 52 con la opcion 'set-clipboard' en 'external'

# Configuración en Windows

Para la configuracion se puede usar una de las siguientes script de configuración.

- Script `.\powershell\bin\windowssetup\02_install_profile.ps1` permite configurar los archivos mas usados del profile del usuario y configurar VIM/NeoVIM.
- Script `.\powershell\bin\windowssetup\03_update_profile.ps1` permite actualizar los comandos/programas descargados de los repositorios que no son del SO, actualizar los plugin de VIM/NoeVIM.

No se usa un gestor de plugin para VIM/NeoVIM (esto me trajo algunos problemas al ser usado en contenedores), por lo que se uso paquetes nativo de VIM/NeoVIM. Para actualizar los paquetes de VIM/NeoVIM use la opción `./shell/powershell/bin/windowssetup/03_update_profile.ps1`.

Los pasos recomandos para configurar su SO son:

1. Instalar comandos basicos 'git', 'Powershell Core' (requiere .NET SDK o RTE instalado) y 'VIM' para Windows.

```shell
#
```

Si desea instalar VIM como IDE de desarrollo debera tener instalado NodeJS y Python3.

```shell
#
```

Si cuenta con WSL, 'NodeJS', '. Net' y 'Powershell Core'y lo podra instalar usando la opcion el menu mostrado al ejecutar el script `~/.files/shell/bash/bin/linuxsetup/01_setup_binaries.bash`

- Usando la opcion '1048576' del menu para instalar la ultima version de 'NodeJS' en 'D:\CLI\Programs\NodeJS'.
  En las variables de entorno del sistema debe registrar la la ruta 'D:\CLI\Programs\NodeJS'.
- Usando la opcion '32768' del menu para instalar las 3 ultimas versiones del SDK de .NET en 'D:\CLI\Programs\DotNet'.
  En las variables de entorno del sistema debe registrar la la ruta 'D:\CLI\Programs\NodeJS'.
- Usando la opcion '128' del menu para instalar la ultima version de Powershell Core en 'D:\CLI\Programs\PowerShell'.
  En las variables de entorno del sistema debe registrar la la ruta 'D:\CLI\Programs\PowerShell'.
  Si usa Windows Terminal, debera configurar adicionar un nuevo perfil para la terminal 'Powershell':
  - Nombre: Powershell
  - Linea de comandos: `D:\CLI\Programs\PowerShell\pwsh.exe`
  - Directorio de Inicio: `%USERPROFILE%`
  - Icono: `D:\CLI\Programs\PowerShell\assets\StoreLogo.png`

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
${env:USERPROFILE}\.files\powershell\bin\windowssetup\02_install_profile.ps1
```

4. Cierre terminal y vuelve a iniciar la configuración.

5. Configure el Windows Terminal.
   Debera configurar la fuente 'Nerd-Fonts'. La fuente recomendada es `JetBrainsMono Nerd Font Mono`.

6. Problemas y desafios encontrados por usar Windows.
   Algunos comandos como FZF deberan adaptarse para usarse en VIM/NoeVIM.

7. Si desea actualizar los plugins de VIM/NeoVIM, ejecute el script:

```bash
#Mostrar el menu para actualizar los plugins de VIM/NeoVIM
${env:USERPROFILE}\.files\powershell\bin\windowssetup\03_update_profile.ps1
```

# Configuracion en una 'proot-distro' de Termux (Android)

Es el mismo procedemiento que la configuración en Linux pero con algunas consideraciones previas:
