
Configuración en Windows


# Configuración basica del SO


1. Hibernación
   - Si una VM, desabilitar la hibernacion.
     - En "Sistema \> Inicio/Apagado \> Pantalla y Suspension" y desabilitar la hibernacion si el equipo esta conectado


2. Idioma y Region
   - Adicionar la configuración para el teclado en ingles
     - Setting\> Hora e idoma\>


3. Teclado
   - Escoja el teclado deseado:


4. Soporte a *remote apps*
   - Habilitar el escritorio remoto:
     - En "Sistema \> Escritorio remoto"
     - Si usa Linux y una VM como windows, debe habilitar la capacidad de `remote apps` en el `terminal server` de Windows.
   - Ir al grupo `Equipo\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList`.
   - Cree o modifique el registro `DWORD` de 32 bits, `fDisabledAllowList` con el valor `1`.
   - Consideraciones:
     - Cuando se cierra visualmente la ventana del `remote app`, el proceso `xfreerdp` que lo invoca no termina hasta que inicia otra sesión remota (por defecto se tiene una licencia de 1 sesión concurrente por servidor, por lo que iniciar una nueva sesión siempre terminara el otra conexión).
     - Si requiere iniciar la sesión de un `remote app` el servidor, debe cerrar todas las conexiones activas al servidor RDP. Ello evitara que el comando `xfreerdp` maneje la conexión sin que gestiona la ventana de advertencia (que no puede gestionar) que si desea que el otro usuario esta conectado.

   - Para que una conexión desconectada se cierre después de un determinado tiempo.
     - Edita **gpedit.msc**
     - Ir a: Computer Configuration \> Administrative Templates \> Windows Components \> Terminal Services ("Servicio de Escritorio Remoto") \> Terminal Server ("Host de Sesion de Escritorio Remoto") \> Session Time Limits ("Limites de tiempo de session").
     - Activar el valor "**RemoteApp session logoff delay**" ("Establecer el limite de tiempo para las sesiones desconectadas") y establecer el valor a 10 minutos.
     - Actualize las políticas/directivas para el usuario: `gpupdate`.


5. Otros
   - Mostrar el iconos en el desktop
       - Personalización \> Temas
       - Configuración relacionada \> Configuración de iconos de escritorio.

   - Configuraciones del explorar de Windows:
       - Opciones \> Ocultar extensiones de archivos comunes

   - Mover carpetas especiales:
       - Carpeta Descargas: `C:\Download`

   - Deshabilitar el tamaño máximo permitido para el valor de la variable `PATH`.
       - En el regedit …
       - Cuando se instala python te ofrece a deshabilitar ello.



6. Mover carpetas fuera de onedrive
   - Las carpetas ... no permite moverse a otro directorio debido a que estas carpetas esta configuradas para sincronizacion ....
   - Este bloqueo es una característica de protección de Windows cuando las carpetas están vinculadas a OneDrive para evitar pérdidas de datos.
     - Desvincular la copia de seguridad de OneDrive
         - Ir a "Ajustes y configuración" de OneDrive del usuario.
         - Ve a la pestaña "Copia de seguridad" y busca la opción "Administrar copia de seguridad" o "Elegir carpetas".
         - Desmarca la opción para Documentos e Imágenes.


     - Mover la ruta predeterminada
         - Navega a la carpeta `Documents`, `Desktop` y `Images`, haz clic derecho y selecciona "Propiedades".
         - Ve a la pestaña "Ubicación".
             - Haz clic en "Restaurar predeterminado" o
             - Establecer la ruta deseada.
         - Aplica y Acepta los cambios.

     - Reiniciar
         - Verifica acceso y permisos


7. Crear una segunda particion
   - Botón derecho en **Inicio → Administración de discos (Disk Management)**.
   - Botón derecho sobre **C:** → **Reducir volumen (Shrink Volume)**.

       - En “Tamaño del espacio a reducir (MB)” escribe cuánto **quieres liberar para D:**.
       - Si quieres crear **D: ≈ 1 TB**, escribe por ejemplo **1 024 000** (para ~1 000 GB) o **1 048 576** (para 1 TiB).
       - Haz clic en **Reducir**.

   - Verás ahora **espacio no asignado** (Unallocated). Botón derecho → **Nuevo volumen simple (New Simple Volume)** → seguir el asistente → asigna letra **D:** → formato NTFS (quick format) → terminar.
   - Vuelve a activar archivo de paginación, hibernación y Restaurar sistema si los desactivaste.

```lua
diskpart
list volume
select volume <número de la C:>      <-- asegúrate de seleccionar el volumen correcto
shrink desired=1024000               <-- libera 1,024,000 MB (ajusta si quieres otro tamaño)
exit
```




# Setup WSL

Si es una VM Windows, debe habilitar `nested virtualization`.

1. Instalación de WSL Ubuntu
   - Para instalar WSL Ubuntu, no requiere realizar configuraciones previas, el comando `wsl --install` realizara las configuraciones.

```powershell
wsl --install
```

2. Configuración inicial
   - Pedirá reiniciar el equipo una vez concluido.
   - Inicie WSL Ubuntu y la primera vez solicitara el usuario (establecer `lucianoepc`) y passwrod.
   - Establecer el password de root: `sudo passwd root`
   - Instalar paquetes básicos

```bash
sudo apt-get install git
sudo apt-get install unzip
```


3. Mejoras de WSL
   - Modificar `/etc/wsl.conf` para configurar:
     - Establecer como sistema de inicio del SO: `systemd`
     - No adicionar el PATH de Windows en WSL.
     - …
     - …

```bash
sudo vim /etc/wsl.conf
```

```toml
[boot] 
#Usar SystemD como 'System Service' (por defecto usa 'Init System/SysV') 
systemd=true 

[network] 
#No autogenerar '/etc/resolv.conf' (servidores DNSs) 
#generateResolvConf = false 
hostname = wsl-ubuntu 
#No autogenerar '/etc/hosts' (DNS locales) 
#generateHosts = false 

[interop] 
#Permitir la interoperabilidad con Windows (especialmente ejecutar .exe desde WSL) 
enabled = true 
#No adicionar la variable 'PATH' de Windows a 'PATH' del WSL 
appendWindowsPath = false 

[automount] 
#No permitir el automontaje de 'fixed drives' de Windows, en Linux. 
#enabled = false 
#Usar el montaje manual usando '/etc/fstab' 
#mountFsTab = true
```


4. Reiniciar WSL y analizar el estado de los servicios:
   - Desde Windows (Powershell o CMD) detenga la instancia (o cierre todas las sesiones y espera 8 segundos para que automáticamente se cierre WSL2).
   - Inicialmente existía un unidades con error, actualmente ya no aparecen ellos (muchos de estos que generaban el error están deshabilitados por defecto).

```bash
wsl --shutdown 

#1. Inicie la instancia y validar: 

#Carge la configuracion
sudo systemctl daemon-reload

#Ver el estado general 
systemctl status

#Ver el estado de los servicios 
systemctl list-unit-files --type=service

#Listar las unidades fallados 
systemctl --failed
```

5. Desabilitar `CGroup v2` y solo permitir `CGroup v1`
   - Desde Linux v5.0, la opción de arranque del núcleo `cgroup_no_v1=<list_of_controllers_to_disable>` se puede utilizar para desactivar `cgroup v1`las jerarquías.
   - Desde Powershell, Crear/modificar ....

```powershell
vim ${env:USERPROFILE}/.wslconfig
```

```toml
[wsl2]
#Solo permitir que se habilite CGroup v2 (desabilitando la version 1)
kernelCommandLine = cgroup_no_v1=all
```

6. Reiniciar WSL

7. Configurar el profile
   - Vease la configuracion de Linux



## Upgrade la distribución Linux

1. Actualizar el SO

```bash
sudo apt-get update
sudo apt-get upgrade
sudo apt-get dist-upgrade
sudo apt-get full-upgrade
```

2. Cambiar la versión LTS a normal (software más actualizado) y actualizarlo

```bash
sudo vi /etc/update-manager/release-upgrades

#Validar si hay actulizaciones 
sudo do-release-upgrade -c

#Realizar la actualización (sin sudo) 
do-release-upgrade

#validar la version 
lsb_release -a
```

# Setup Programas GUI basicos


1. Instalar programas básicos


```powershell
winget install -e --id Google.Chrome
winget install -e --id Mozilla.Firefox


winget install --id Microsoft.PowerShell --source winget
#winget list | findstr /i Powershell


winget install -e --id Microsoft.PowerToys --source winget

#mkdir flameshot
#winget install -e --id Flameshot.Flameshot --location 'C:\apps\flameshot'
winget install -e --id Flameshot.Flameshot

# Crear la carpeta "C:\apps"
New-Item -ItemType Directory -Path "C:\apps" -Force

mkdir 7zip
winget install -e --id 7zip.7zip --location 'C:\apps\7zip'


mkdir vim
winget install -e --id vim.vim --location 'C:\apps\vim'
#winget install -e --id Neovim.Neovim


mkdir notepadpp
winget install -e --id Notepad++.Notepad++ --location 'C:\apps\notepadpp'

mkdir keepassxc
winget install -e --id KeePassXCTeam.KeePassXC --location 'C:\apps\keepassxc'

#Solo en Windows ARM no se ofrece el comando curl (solo un alias powershell)
#Para evitar usar el alias use 'curl.exe' y no 'curl'
winget install -e --id cURL.cURL --location 'C:\apps\curl'

```

2. Variable `PATH` del sistema
   - Adicionar la variables ...
   - Settings \> Sistema \> Información \> Configuración avanzada \> Variables de entorno
    - Adicionar la variables:
      - VIM: `C:\apps\vim\vim91`
      - 7zip: `C:\apps\7zip`

3. Configurar los browsers
   - Configurar Micosroft Egde
     - Crear los perfiles para los correos de outlook
   - Instalar y configurar "Google Chrome"
     - Crear los perfiles para los correos de gmail
   - Habilitar el dark mode de todos lo browser:
     - Instalar extension 'Dark Reader' y habilitarlo
     - Actualmente, el modo 'dark' por defecto de browser Google Chrome, esta limitado (solo algunas páginas como el motor de búsqueda estan en este modo).
       - Para habilitarlo, use `edge://flags/#enable-force-dark` (no use esto).
   - Eliminar las aplicaciones subcripciones a las notificaciones que esta en google chrome: `chrome://settings/content/notifications`


4. Configurar *Microsoft PowerToys*
   - Solo mantener habilitado los siguientes módulos:


5. Configurar `flameshot`
   - Instalar
     - Decargar el binario desde el repo de github o usar `winget install flameshot`
     - Este descargara el instalador de github y luego lo instalara
   - Opcional: Validar que esta hbilitado el shorcut
     - Windows Settings -\> Ease of Access -\> Keyboard -\> Scroll down to "Print Screen Shortcut" and turn off the "Use the Prtscn button to open screen snipping":
   - Opcional\> establecer un nuevo shrocut (no funciona bien)
     - Si no existe un enlace (usualmente en sau scritorio) creado del porograma 'flameshot.exe', creelo.
     - Modifica el enlace y establece el shutcut al programa. Usaremos\> Ctrl + Alt + p


6. Configurar `KeePassXC`
   - Descargar de `https://keepassxc.org/download/#windows`
   - Ruta de instalación `C:\apps\keepassxc\`


7. Instalación de `MS Office`
   - Configurar Office:
     - Por cada una de la cuentas configurar el modo oscuro: Archivo \> Cuenta
   - OneNote ir a mi cuenta "esteban_fiis@hotmail.com" y abrir todos los block de notas.



# Setup Programas CLI basicos


1. Instalar programas básicos
   - Instalar programas generales

```powershell
# Instalar Perl
winget install -e --id StrawberryPerl.StrawberryPerl


# Crear la carpeta "C:\apps"
#New-Item -ItemType Directory -Path "C:\apps" -Force
cd C:\apps



# Instalar GIT
mkdir git
winget install -e --id Git.Git --source winget --location 'C:\apps\git'
#winget list | findstr /i Git.Git

# Tiene que buscar la version a instalar
winget search --id Python.Python
mkdir python3.13
winget install -e --id Python.Python.3.13 --location 'C:\apps\python3.13'
```


2. Registrar en el `PATH` del sistema
   - Ir a Settings \> Sistema \> Información \> Configuración avanzada \> Variables de entorno
   - Validar las variables:
     - Git: `C:\apps\git\cmd`
     - Git: `C:\apps\vim\vim91`
   - Adicionar los programas instalados usando *profile setup* de WSL:
     - Node JS: `C:\apps\tools\nodejs`
     - NeoVIM: `C:\apps\tools\neovim\bin`
     - Comandos de windows:  `C:\apps\cmds\bin`


3. Exclusiones del antivirus
   - Adicionar a la variable de entorno 'Path' del sistema con la ruta de los comandos: `C:\apps\cmds\bin`.
     - Settings \> Sistema \> Información \> Configuración avanzada \>  Variables de entorno
   - Deberá adicionar a ala exclusiones del antivirus del SO (Windows lo detecta algunos comandos como `fzf.exe` como virus).
     - Settings \> Privacidad y seguridad \> Seguridad en Windows \>
     - Protección contra virus y amenazas \> Configuración de antivirus y protección contra amenazas
     - Administración la configuración \> Exclusiones


3. Instalar programas adicionales
   - Windows por defecto viene con net runtime, pero puede instalar el SDK.

```powershell
# .NET SDK
winget search --id Microsoft.DotNet.SDK
winget install -e --id Microsoft.DotNet.SDK.8
```


# Setup built-in Terminal


1. Instalar *fonts* mono para CLI
   - Ingresar a WSL para descargar las fuentes (tambien instalara las fuentes en WSL, pero esto solo sera usado si usa programas GUI usando WSLg).
   - Instalar las fuentes descargas en `c:\apps\fonts` en Windows
     - Los emuladores de terminales corren en windows, por lo que lo requieren.
     - Para instalar debera copiar en la carpeta `fonts` de Windows.
     - Copie la fuentes de cada una de las sub-carpetas de `C:\apps\fonts\` a `C:\Windows\Fonts`

```bash
~/.files/shell/bash/bin/linuxsetup/01_setup_binaries.bash 2 'xxx'
```



2. Soporte a *Read Command Line* de `cmd`
   - Documentacion:
     - Github: https://github.com/chrisant996/clink
     - Documentacion: https://chrisant996.github.io/clink/clink.html
   - Instalar y validar
   - Configuración de manera permanente:
     - Crear un archivo o copiarlo de
   - Inicie nuevamente ...

```bash
cd C:\apps

# Buscar
winget search clink

# Instalar
mkdir clink

winget install clink --source winget --location 'C:\apps\clink'

# Ingresar a `cmd` y ejecutar:
clink info
```


```powershell
# Copiar un archivo de configuracion CLink
cp ~/.files/etc/clink/default.lua C:\apps\clink\oh-my-posh.lua

# Crear un archivo de configuracion CLink
cd C:\apps\clink
vim oh-my-posh.lua
```


```lua
load(io.popen('oh-my-posh --init --shell cmd --config C:\\Users\\lucianoepc\\.files\\etc\\oh-my-posh\\default_settings.json'):read("*a"))()
```


3. Setup *Powershell*
   - Se recomienda usar **Powershell Core** y no **Windows Powershell**.

4. Configurar Windows Powershell
   - El instalador del profile, acualmente no instala los prerequisitos de *Windows Powershell*, por lo que lo tiene que realizar manualmente.
   - Abra una termina de la Windows terminal como administrador y luego inicie `Windows Powershell`
   - En windows poweshell, permite ejecutar script
   - Instalar el modulo `PFS`

```powershell
#Ejeuctar script locales, ejecutar srcipt remots solo si estan firmados
Set-ExecutionPolicy RemoteSigned
```

```powershell
Install-Module -Name PSFzf -Scope AllUsers
```




5. Configuración de *Windows Terminal*
   - Por defecto ya viene instalado en las version modernas de Windows 11.
     - Si no esta instalado, use:
   - Configuración por defecto
     - Establecer la fuente por defecto de "Windows Terminal":
       - Copie la fuentes de cada una de las sub-carpetas de `C:\apps\fonts\` a `C:\Windows\Fonts`
       - Abrir "Windows Terminal" y configurar:
           - "Perfiles \> Valores predeterminados"
            El tamaño de la fuente, dependiente del monitor/resolución dependerá será 10 o 11.
            Espesor de la fuente: "semi clara"

     - Establezca el color `background` por defecto y de todas la terminales existentes:
   - Configuración de *Powershell Core*
     - Validar que Powershell este en el `PATH` del sistema o usuario:
       - Settings \> Sistema \> Información \> Configuración avanzada \> Variables de entorno
       - Powershell: `xxxx`
     - Configuración de la profile 'Powershell'
       - Configuración \> Adicionar un nuevo perfil \> clonar desde "Windows Powershell"
       - Luego modificar los atributos:
           - Linea de comandos: `pwsh.exe`
           - Directorio de inicio: `%USERPROFILE%`
           - Icono: `C:\cli\prgs\PowerShell\assets\Square44x44Logo.png`
       - Establecer el perfil predeterminado.
           - Configuración\> Inicio\> Perfil predeterminado\> Powershell.
   - Configurar el orden de las terminales:
       - Configuración\> Inicio\> Abrir archivo JSON
       - Mover el orden de los elementos en `.profiles.list[]`

```powershell
# Windows Terminal
winget install -e --id Microsoft.WindowsTerminal
```

## Setup Wezterm


1. Instalar un emulador OpenGL
   - Si usa una VM Window en Linux y requieres usar Wezterm.
   - Instalar un emulador de OpenGL >= 3.0 (dentro de la VM de Windows),
     - Cuando visualizas una VM  windows con QEMU usando el driver `virtIO` la emulacion de la GPU ofrece un soporte limitado a librerias graficas como `OpenGL`.
     - Ello imposibilita el uso aplicación como la terminal que usa GPU `wezterm` que requiere acceso a una version superior de la librería.
   - Pasos para la instalación dentro de la VM:
     - Desactivar el análisis en tiempo real del antivirus
       - https://github.com/pal1000/mesa-dist-win/releases
   - Descargar la version release `mesa3d-24.3.2-release-msvc`
     - Descomprimir
   - tiene 2 formas de instalación:
     - A system-wide deployment tool.
     - A per-application deployment tool
     - https://github.com/pal1000/mesa-dist-win?tab=readme-ov-file#installation-and-usage
   - Usando la instalacion a nivel sistema, ejecutar como administrador el bat `systemwidedeploy.bat`
     - Se escoge la opcion 1 y 5, y se sale.
     - El mismo archivo bat también permite la desintalacion


```powershell
cd C:\Installers\drivers

# Eliminar la carpeta
if (Test-Path '.\mesa') { Remove-Item -Recurse -Force '.\mesa' }

# Descargar
curl -LO 'https://github.com/pal1000/mesa-dist-win/releases/download/25.1.8/mesa3d-25.1.8-release-msvc.7z'

# Descomprimir el archivo
7z x 'mesa3d-25.1.8-release-msvc.7z' -oC:\Installers\drivers\mesa -y

# Cambiar el nombre de la carpeta creada al descomprimir
#$folder = Get-ChildItem -Directory | Where-Object { $_.Name -like "Wezterm-windows*" } | Select-Object -First 1
#if ($folder) { Rename-Item -Path $folder.FullName -NewName 'wezterm' }

# Eliminar el zip
rm 'mesa3d-25.1.8-release-msvc.7z'

```

```cmd
# Iniciar un `cmd` como un usuario comun e instalar/actualizar:
cd C:\Installers\drivers\mesa

systemwidedeploy.cmd
```

2. Instalar de terminal *Wezterm*
   - Wezterm (no esta la version ngightly. Instalar manualmente)
   - Instalar la terminal Wezterm usando la version *Nigihky*
     - URL: https://wezterm.org/install/windows.html#installing-on-windows
     - Validar la version actual con la version existente
   - Establecer el PATH los programas:
     - Ir a Settings \> Sistema \> Información \> Configuración avanzada \> Variables de entorno.
     - Wezterm: `C:\apps\wezTerm`


   - Crear un acceso directo usando el ejecutable
     - Ejecutar  `wezterm-gui.exe`
     - Click secundario en el programa en ejecucion y anclar el programa en la barra de tareas.

```powershell
# Wezterm (no esta la version ngightly. Instalar manualmente)
#mkdir wezterm
#winget search --id wez.wezterm  --location 'C:\apps\wezterm'

~\.files\shell\powershell\bin\windowssetup\01_setup_binaries.ps1
```

```powershell
# Validar la version actual con la nigtly
wezterm --version
```

3. Configurar el server multiplexer en WSL
   - Actualmento no funciona en WSL2 debido a que no soporta `AF_UNIX`.
   - Instalar el mulitplexer server
     - Por defecto su API es TLS/HTTPS usando socket IPC.
     - El `wezterm` es usado como `wezterm cli` para iniciar el servidor remotamente y/o crear un proxy cuando se conecta usando SSH.

```bash
curl -LO 'https://github.com/wezterm/wezterm/releases/download/nightly/wezterm-nightly.Ubuntu24.04.tar.xz'

mkdir borrar
tar -xJvf wezterm-nightly.Ubuntu24.04.tar.xz -C ./borrar


sudo cp borrar/wezterm/usr/bin/wezterm /usr/local/bin/
sudo cp borrar/wezterm/usr/bin/wezterm-mux-server /usr/local/bin/

rm -rf ./borrar
rm wezterm-nightly.Ubuntu24.04.tar.xz
```

```bash
# Modificar el nombre de la distribucion y el usuario del servidor
vim ~/.config/wezterm/wezterm.lua
```


# Setting Profile en Windows


Para Configurar del profile `lucianoepc` de Windows

Se realizara los siguientes pasos:

- Instalar el profile de `lucianoepc`
- Configurar `vim` de Windows para soporte `FZF`
- Configuración de `git`


1. Profile de `lucianoepc`
   - Para el usuario `lucianoepc`, se debe configurar el profile como *developer*:
     - Descargue el repositorio de git en sus archivos
   - Configurar el *profile setup* del usuario `lucianoepc` (opcional)
     - Si cambio la ruta de los folders donde se almacenara los programas, deberá modificar el archivo de configuración
   - Existe 2 tipos de instalación:
     - Si es la primera vez:
       - Instalar todo sin indexar la documentación.
       - Iniciar VIM para que se auto-instale las extension `CoC`.
       - Iniciar NeoVIM para se compile e instale los AST `tree-sitter`.
       - Indexar la documentación existente
     - Si es una actualización:
       - ....


```powershell
cd ${env:USERPROFILE}
git clone https://github.com/lestebanpc/dotfiles.git .files
```

```powershell
cp ~/.files/shell/powershell/bin/windowssetup/lib/setup_config_template.ps1 "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/.setup_config.ps1"

vim "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/.setup_config.ps1"
```

```powershell
# . . . . . . . . .
# . . . . . . . . .

#Folder base, generados solo para Linux WSL, donde se almacena el programas, comando y afines usados por Windows.
# . . . . . . . . .
g_win_base_path='/mnt/d/apps'
```


2. Setup el profile sin sudo
   - Inicia el shell con el usuario y cree las carpetas basicas:
     - Esto creara
   - Inicie el shell como administrador y cree los enlaces simbólicos y instale el modulo `PSFzf`:
     - Abra una termina de la Windows terminal como administrador (es necesario para crear los enlaces simbólicos).
     - Este script instalar el módulo `PSFzf` para todos los usuarios en Powershell.
       - `Install-Module -Name PSFzf -Scope AllUsers`
   - Configure  el profile del usuario
     - Si se instala por primera vez y en modo developer no indexe la documentación (intentara ejecutar la lógica de inicializacion de CoC, el tree-sitter)
       - Escoger la opción `i` (si es su primera vez), luego inicio vim y neovim, luego indexe la documentación existente.
     - Si solo desea actualizar ejecute la opción.
   - Inicie VIM y NeoVIM
   - Indexe la documentación existente en VIM y NeoVIM

```powershell
~\.files\shell\powershell\bin\windowssetup\02_install_profile.ps1
#Escoger la opción a
```


```powershell
~\.files\shell\powershell\bin\windowssetup\02_install_profile.ps1
#Escoger la opción b o c

#Validar si el módulo 'PSFzf' está instalado:
Get-InstalledModule

```


```powershell
~\.files\shell\powershell\bin\windowssetup\02_install_profile.ps1
```



3. Setup el profile con sudo
   - Si su windows si soporta `sudo`:

```powershell
~\.files\shell\powershell\bin\windowssetup\02_install_profile.ps1
#Escoger la opción x
```


4. Personalizar el profile instalado
   - Configurar el *profile* del usuario `lucianoepc` (opcional)
     - Si ....

```powershell
cp ~/.files/shell/powershell/login/windowsprofile/custom_profile_template.ps1 "${env:USERPROFILE}/custom_profile.ps1"

vim "${env:USERPROFILE}/custom_profile.ps1"
```

```powershell
# . . . . . . . . .
# . . . . . . . . .
# . . . . . . . . .
```


5. Modificar `~/.ssh/config`
   - La implementacion de OpenSSH de Windows no expande el `~`, por lo que deberá modificar el `~/.ssh/config` para incluir la ruta del home del usuario.

```powershell
cd ${env:USERPROFILE}
vim ~/.ssh/config
```


```
:%s#${HOME}#C:/Users/lucianoepc#gce
```



6. Profile de `administrador`
   - Ninguno


# Setting VIM en Windows


1. Configurar `vim` para soporte `FZF`
   - Los archivos corregidos de FZF puede ser archivos muy antiguos para la version actual.
   - En ese escenario se usa lo corregido.

2. Modificar los archivos corregidos (opcional)
   - Rollback de las modificaciones del plugins `fzf` y `fzf.vim` (restuara la version del repositorio y obtiene la ultima version).
   - Buscar hay cambios que obligen a corregir las fuentes.
     - No cambie la líneas comentado con el comentario "CHANGE" …
     - Debe Comparando la última versión (plugin de VIM) vs la fuente (`C:\Users\lpena\files\vim\templates\fixes\`)
     - Opciones usadas en la comparacion:
       - Use `diffput` para subir cambios a la fuente.
       - Use `[c` y `]c` para navegar en las diferencias de un split.
       - Use `windo diffoff` para ingresar al modo normal.
       - Use `Ctrl + w, l` y  `Ctrl + w, h` para navegar en entre los split (si lo requiere)
       - Guarde los cambios con `:w`.
       - Para salir completamente use `qall!`.
   - Inicie la comparación de `.\fzf\plugin\fzf.vim`:
   - La fuente tiene cambios (fue corregido), copie y remplace los archivos desde la fuente (corregido) a los plugins

```powershell
cd ${env:USERPROFILE} 
.files\shell\powershell\bin\windowssetup\03_update_profile.ps1
#Opcion (b) 'Rollback las modificaciones realizadas de los plugins ..'
```


```powershell
vim -d ${env:USERPROFILE}\vimfiles\pack\basic_core\opt\fzf.vim\autoload\fzf\vim.vim ${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\autoload\fzf\vim.vim
```


3. Copiar los archivos corregidos
   - Puede copiar los archivos modificados y requeridos, el cual se puede ser usados por 2 formas:

Usando el script

```powershell
cd ${env:USERPROFILE} 
.files\shell\powershell\bin\windowssetup\03_update_profile.ps1

#Opción (c) 'Cambiar los plugins 'fzf.vim' usando la fuente corregida'
```

Manualmente:

```powershell
#VIM> Copiando los archivos de la fuente corregida al plugin 'fzf.vim':
cp ${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\autoload\fzf\vim.vim ${env:USERPROFILE}\vimfiles\pack\basic_core\opt\fzf.vim\autoload\fzf\

cp ${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\bin\preview.ps1 ${env:USERPROFILE}\vimfiles\pack\basic_core\opt\fzf.vim\bin\

#NeoVIM> Copiando los archivos de la fuente corregida al plugin 'fzf.vim':
cp ${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\autoload\fzf\vim.vim ${env:LOCALAPPDATA}\nvim-data\site\pack\basic_core\opt\fzf.vim\autoload\fzf\

cp ${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\bin\preview.ps1 ${env:LOCALAPPDATA}\nvim-data\site\pack\basic_core\opt\fzf.vim\bin\

#3. Validar
cd ${env:USERPROFILE}\vimfiles\pack\basic_core\opt\fzf.vim\
git status

cd ${env:LOCALAPPDATA}\nvim-data\site\pack\basic_core\opt\fzf.vim\
git status

```

Luego, validar si FZF de vim funciona correctamente.


# Setting GIT

Para la configuracion en WSL vease la configuracion e Linux.
Para la configuración en Windows, se debe usar la implementacion de SSH de  *OpenSSH for Windows*.

- A diferencia de git en Linux y MacOS, en Windows Git usa la implementacion SSH integrada en Git.
- *OpenSSH for Windows* por defecto se instala en `C:\Program Files\OpenSSH\`

Realizar las siguiente configuraciones:

1. Las opciones por defecto del usuario para git está definido en el archivo `~/.gitconfig`.
  - Esta es un enlace simbólico de `~/.files/etc/git/root_gitconfig_windows.toml`


2. Validar y/o verificar los archivos generados

```powershell
cd ${env:USERPROFILE}
bat .gitconfig
bat .config/git/user_main.toml
bat .config/git/user_mywork.toml
```


3. Configurar parámetros del usuario

```bash
vim ~/.config/git/user_main.toml
```

```toml
# Usuario personal
[user]
	email = esteban_fiis@hotmail.com
	name  = Mi name


# Opciones generales
[core]
    # Editor (colocar la ruta completa si este no esta en el 'PATH'.
	editor = C:/apps/vim/vim91/vim.exe
	# Usar la implementacion SSH de 'Open SSH for Windows'
	sshCommand = "\"C:/Program Files/OpenSSH/ssh.exe\""


#. . . . . . . . . . . . . . . .
#. . . . . . . . . . . . . . . .

#Usuario de work "mywork"
#[includeIf "gitdir:~/code/mywork/"]
#    path = work_mywork.toml
```

```powershell
cd ${env:USERPROFILE}
mv ~/.config/git/user_mywork.toml ~/.config/git/user_progrez.toml
vim ~/.config/git/user_prograz.toml
```

4. Valida los parámetros globales/usuario están correctamente configurados

```bash
git config --global -l
git config -l
```

```bash
user.email=esteban_fiis@hotmail.com
user.name=Luciano Peña
core.editor=C:/apps/vim/vim91/vim.exe
core.autocrlf=true
init.defaultBranch=main
core.sshcommand="C:/Program Files/OpenSSH/ssh.exe"
#. . . . . . . . . . . . . . . .
#. . . . . . . . . . . . . . . .
#. . . . . . . . . . . . . . . .
```


# Setting SSH Client


Se debe usar la versión beta *OpenSSH for Windows*, debido a ella usualmente tiene uan versión mas desactualizada que la mayoría de las distribuciones linux.

Los binarios versión realese solo puden ser instalados como una caracteristica de Windows.

1. Instalar el cliente OpenSSH de Microsoft
   - El agente SSH de Microsoft se implementa como un proceso "ssh-agent.exe" que se ejecuta en background usando un servicio Windows con la descripción "OpenSSH Authentication Agent" el cual por defecto este se encuentra deshabilitado.
   - Desintalar la caracteristica `OpenSSH Client` (se usara la version beta que es la mas actual).
     - Validar si esta instalado
     - System > Optional Features > Buscar "Open SSH Client"
     - Si existe eliminarlo
   - Instalar la version preview

```powershell
# Instalar la implementacion de OpenSSH de Microsoft (Preview)
winget install -e Microsoft.OpenSSH.Preview
#winget list | findstr /i OpenSSH
```

2. Configuración del Agente `OpenSSH`
   - Valide que los servicios windows están instalados:
     - Ingrese a la terminal de powershell como administrador
   - Opcional: Algunas version del instalador no configuran el SSH Agent de windows como servicio.
     - Puede realizar la configuración manual con un terminal ejecutado como administrador
   - Establecer el agente SSH como inicio automatico e iniciarlo

```powershell
Get-Service -Name ssh*

#Cambio de estado el servidor SSH
Set-Service -StartupType 'Manual' sshd
Stop-Service sshd

```

```powershell
New-Service -Name ssh-agent -BinaryPathName "C:\Program Files\OpenSSH\ssh-agent.exe" -DisplayName "OpenSSH Authentication Agent" -StartupType Automatic
```

```powershell
#1. Como Administrador, cambie el estado a "Manual" o "Automático":

#Cambio de estado a "Automatic"
Set-Service -StartupType 'Automatic' ssh-agent

#2. Como usuario, iniciar el servicio:
Start-Service ssh-agent

#3. Como usuario, detener el servicio:
Stop-Service ssh-agent

#4. Validar el estado del servicio
Get-Service ssh-agent | select -property name, status, displayname, starttype
```

3. Habilitar mis claves publicas SSH
   - Solo se copiaran las claves publicas SSH.
   - Las claves privadas SSH se almacenaran en el agente SSH usando `KeePassXC`.
   - Copiar mis claves
     - Obtener el archivo zip de las claves publicas SSH desde algunos de los lugares.
     - Copiar el archivo dentro de la maquina windows:
       - Dentro de Windows: `~/.files/keys/shared/`
       - Dentro de WSL: `~/.files/keys/shared/`
   - Tenga en cuenta que las claves privadas deben tener acceso solo el usuario:
     - Ir a la carpeta `~/.shh/` \> Propiedades \> Tab 'Seguridad' \> Opciones Avanzadas \>
       - Opcion 'Desabilitar herencia' (indicar copiar las propiedades heredadas a este objeto).
       - Quitar todos los usuario, solo quedarse con el usuario.
       - Check 'Remplazar todas la entradas … a los objetos secundarios'

```powershell
vim ~/.ssh/config
```

```bash
cd ~/.files/keys/shared/
unzip ssh_public_key-20241201.zip -d ./
```



## Usar el agente SSH desde WSL

1. Instalar socat en WSL
   - En WSL, instalar paquetes básicos

```bash
#Usado para emular un SSH Agente en WSL que este conectado al SSH Agent de windows
sudo apt-get install socat
```

2. Descarga del `npiperelay`  en Windows
   - En Windows, descargar el binario `npiperelay.exe` (Esto puede realizarse desde WSL).

```bash
curl -LO https://github.com/jstarks/npiperelay/releases/latest/download/npiperelay_windows_amd64.zip

unzip npiperelay_windows_amd64.zip -d /mnt/c/cli/cmds/bin
rm npiperelay_windows_amd64.zip
```



3. Redireccion del agente SSH
   - Usarlo manualmente:
     - NPipeRelay path   : `/mnt/c/apps/cmds/bin/npiperelay.exe`
     - Socket IPC a usar : `/home/lucianoepc/.ssh/agent.sock`
   - Usarlo usando un script:

```bash
(setsid socat UNIX-LISTEN:/home/lucianoepc/.ssh/agent.sock,fork EXEC:"/mnt/c/apps/cmds/bin/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &)
```

```bash
connect_win_sshagent
```

4. Acceso SSH a mis repositorios git
   - Algunos repositorios basicos, cambiarlo para que tenga acceso para push por SSH y no por HTTPS:
   - Repostorio `.files`
   - Validacion de la credencial por ssh

```powershell
git remote -v

git remote set-url --push origin 'gh-writer-dotfiles:lestebanpc/dotfiles.git'

git remote -v
```

```bash
ssh -vT gh-writer-dotfiles
```

5. Posibles problemas:
   - Usar el `ssh.exe` integrado de `git` y no el `ssh.exe` compatible con el agente SSH
     - El `ssh.exe` integrado de git NO puede soportar lo enviado por el agente SSH, no pudiendo encriptar ni desencriptar claves.
     - Este problema esta ocurriendo en Windows con las versiones:
       - `OpenSSH_for_Windows_9.8p2 Win32-OpenSSH-GitHub, LibreSSL 4.0.0`
       - `git version 2.50.1.windows.1`




# Tareas comunes

1. Si usa QEMU y usando *VirtIO FS* para compartir informacion entre el host y el guest. Iniciar el servicio **VirtioFSSvc** para compartir.

   - Iniciar Powershell como administrador e iniciar el servicio

```bash
#1. Ver el estado actual
Get-Service -Name *virtio* | select -property name, status, displayname, starttype

#2. Como administrador, establecer e iniciarlo
Start-Service VirtioFSSvc

#3. Ver el estado actual
Get-Service -Name *virtio* | select -property name, status, displayname, starttype
```
