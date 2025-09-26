# Estructura de repositorio

Las estructura folderes es:

- `./etc/` contiene archivos de configuracion de programas que no sea codigo interpretado (como bash, lua, vimscript, tmux script, etc).
- `./shell/` incluye todo codigo que ejecutado por el interprete shell de su SO (incluye archivos usados por programas de terceros, archivos de instalacion, funciones de utilidad, etc).
  Estan organizados por carpetas que representan la implementacion de un determinado interpre shell 'sh' (no es un implementacion de un interpre shell, pero obliga a usar el estandar POSIX), 'bash', 'zsh', ...
  Por cada implementacion de interprete shell, generalmente, se tiene las siguientes carpetas:
  - `login/` script usado en su login
    - `autocomplete/` script usados por para el autocomplete en su profile
    - `keybindings/` script de keybindings usado en su profile
    - `profile/` script de su profile.
  - `lib/` script tratados como modulos que contiene funciones y variables, las cuales son importados en cualquier script usando 'source'.
  - `bin/` script tratados como ejecutables.
    - `linuxsetup/` script usados para configurar el entorno del usuario.
    - `tmux/` script que expone funciones que son usados en la configuracion de tmux.
    - `fzf/` script que expone funciones que son usados para mostrar popup fzf.
- `./keys/tls/` mis archivos de claves publicas (generalmente almacenados en formados certificados x509).
- Archivos de configuración que a su vez es codigo interpretado pero no es ejecutado por un interprete shell.
  - `./vim/` archivos de configuracion de VIM (en VimScript)
  - `./nvim/` archivos de configuracion de NeoVIM (en LUA y VimScript).
  - `./tmux/` archivos de configuracion usando script TMUX.
  - `./wezterm/` archivos de configuracion de terminal Wezterm (en LUA).



Los script para instalacion y configuración en Linux son:

- Script `./shell/bash/bin/linuxsetup/01_setup_binaries.bash` descarga y configura comandos (un binario) y programas (conjunto de binarios) de repositorio que no sean del SO (usualmente GitHub).
  - Se recomienda si ejecute con un usuario que no sea root para que los binarios/programas sean compartidos para todos los usuario, pero podria usarlo.
  - Por defecto, aunque puede moficarse usando los archivos de configuración, se usaran la siguientes rutas de configuración:
    - Los programas se instalaran:
      - Si tiene la opcion 'sudo' como root habilitada, creara `/var/opt/tools` (lo instara crear la primeraz vez que ejecuta el script), si no puede intentara en '/opt/tools'.
      - Si no lo tiene, lo instalará en `~/tools`.
    - Los comandos lo instalar en:
      - Si tiene la opcion 'sudo' habilitada, creara `/usr/local/bin`.
      - Si no lo tiene, lo instalará en `~/.local/bin`.
    - Las fuentes Nerd-Fonts lo instalar en:
      - Si tiene la opcion 'sudo' habilitada, creara `/usr/local/share/fonts`.
      - Si no lo tiene, lo instalará en `~/.local/share/fonts`.
    - Si usa WSL, este descarga los binarios/programas para Windows en las sigueente rutas:
      - Los programas los descargará en `C:\apps\tools`.
      - Los comandos los descargará en `C:\apps\cmds\bin`.

- Script `./shell/bash/bin/linuxsetup/04_install_profile.bash` permite configurar los archivos mas usados del profile del usuario y configurar VIM/NeoVIM.
- Script `./shell/bash/bin/linuxsetup/05_update_profile.bash` permite actualizar los comandos/programas descargados de los repositorios que no son del SO, actualizar los plugin de VIM/NoeVIM.
  - No uso un gestor de plugin para VIM/NeoVIM, uso paquetes nativo de VIM/NeoVIM. Para actualizar los paquetes de VIM/NeoVIM use la opción `./shell/bash/bin/linuxsetup/05_update_profile.bash`.



Los script para instalacion y configuración en Windows son:

- Script `.\powershell\bin\windowssetup\02_install_profile.ps1` permite configurar los archivos mas usados del profile del usuario y configurar VIM/NeoVIM.
- Script `.\powershell\bin\windowssetup\03_update_profile.ps1` permite actualizar los comandos/programas descargados de los repositorios que no son del SO, actualizar los plugin de VIM/NoeVIM.
  - No se usa un gestor de plugin para VIM/NeoVIM (esto me trajo algunos problemas al ser usado en contenedores), por lo que se uso paquetes nativo de VIM/NeoVIM. Para actualizar los paquetes de VIM/NeoVIM use la opción `./shell/powershell/bin/windowssetup/03_update_profile.ps1`.



# Carpetas creadas o requeridas

Las carpetas usadas para instalar programas desde repositorios GitHub y otros, son:

- Para binarios y archivos de Windows (solo para Linux WSL):
    - Por defecto se usa la ruta `C:\apps`.
        - Para cambiar la ruta, deberá modificar el archivo de configuración del *profile setup* de los setup para los usuarios `lucianoepc` (opcionalmente del usuario `root`).
        - Por ejemplo puede cambiar la ruta en `D:\apps`.
    - Este folder debe existir. No es necesario crear las sub-carpetas (estos se crean automáticamente si no se han creado)

```
C:\apps\
   .\cmds\
       .\bin\
       .\man\
       .\doc\
       .\etc\
   .\fonts\
   .\tools\
       .\lsp_servers\
       .\dap_servers\
       .\vsc_extensions\
       .\shell\
           .\autocomplete\
           .\keybinding\
       .\sharedkeys\
   .\myprograms\
```

```powershell
mkdir C:\apps
mkdir D:\apps
```

- Para binarios y archivos de Linux:
    - Por commandos y archivos del sistema se usa:
        - Si tiene permisos para usar root, se usara `/usr/local`.
            - Para binarios: `/usr/local/bin`.
            - Para archivos fuentes: `/usr/local/fonts`.
            - Para archivos de ayuda: `/usr/local/man`
            - Para imágenes e iconos: `/usr/local/icons`
        - Si NO se tiene permisos para usar root, se usara `~/.local`.
            - Para binarios: `~/.local/bin`.
            - Para archivos fuentes: `~/.local/fonts`.
            - Para archivos de ayuda: `~/.local/man`
            - Para imágenes e iconos: `~/.local/icons`
    - Para *tools* (programas generales) se usara:
        - Si tiene permisos para usar root, se usara `/var/opt/tools`.
        - Si NO tiene permisos para usar root, se usara `~/tools`.

En muchos casos se requiere que la carpeta usados para *tools* (programas generales) no se creado automáticamente por el instalador (este intentara crear la carpeta `/var/opt/tools` con owner `root`).

- Cree la carpeta de *tools* (programas generales) con el owner sea el usuario `lucianoepc`

```bash
sudo mkdir -m 755 /var/opt/tools/
sudo chown lucianoepc:lucianoepc /var/opt/tools/
```

```
/var/opt/
    ./tools/
       ./lsp_servers/
       ./dap_servers/
       ./vsc_extensions/
       ./shell/
           ./autocomplete/
           ./keybinding/
       ./sharedkeys/
   ./myprograms/
```



# Personalizacion

Se permite personalizar la configuración del profile del usario, de VIM o NeoVIM y el script de instalación:

 - Archivos para personalizar la configuracion por defecto en Linux:

```bash
# Archivos para personalizar la configuracion del profile de bash
cp ~/.files/shell/bash/login/profile/profile_config_template_basic_local.bash ~/.custom_profile.bash
cp ~/.files/shell/bash/login/profile/profile_config_template_nonwsl.bash ~/.custom_profile.bash
vim ~/.custom_profile.bash

# Archivos para personalizar la configuracion del profile de powershell
cp ~/.files/shell/powershell/login/linuxprofile/custom_profile_template.ps1 ~/.config/powershell/custom_profile.ps1
vim ~/.config/powershell/custom_profile.ps1

# Archivos para personalizar la configuracion de VIM
cp ~/.files/vim/templates/custom_config.vim ~/.vim/custom_config.vim
vim ~/.vim/custom_config.vim

# Archivos para personalizar la configuracion de NeoVIM
cp ~/.files/nvim/templates/custom_config.vim ~/.config/nvim/custom_config.vim
vim ~/.config/nvim/custom_config.vim

# Archivos para personalizar los script de configuración
cp ~/.files/shell/bash/bin/linuxsetup/lib/setup_config_template.bash ~/.files/shell/bash/bin/linuxsetup/.setup_config.bash
vim ~/.files/shell/bash/bin/linuxsetup/.setup_config.bash

vim ~/.files/shell/bash/bin/termuxsetup/.setup_config.bash
vim ~/.files/shell/powershell/bin/linuxsetup/.setup_config.ps1
```

 - Archivos para personalizar la configuracion por defecto en Windows:

```powershell
# Archivos para personalizar la configuracion del profile de powershell
cp ~/.files/shell/powershell/login/windowsprofile/custom_profile_template.ps1 "${env:USERPROFILE}/custom_profile.ps1"
vim "${env:USERPROFILE}/custom_profile.ps1"

# Archivos para personalizar los script de configuración
vim ~/.files/shell/powershell/bin/windowssetup/.setup_config.ps1

# Archivos para personalizar la configuracion de VIM
vim ~/.vimfiles/custom_config.vim

# Archivos para personalizar la configuracion de NeoVIM
vim ${env:LOCALAPPDATA}/nvim/custom_config.vim


# Archivos para personalizar los script de configuración
cp ~/.files/shell/powershell/bin/windowssetup/lib/setup_config_template.ps1 "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/.setup_config.ps1"
vim "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/.setup_config.ps1"
```

# Setup

Para ver como configurar el profile y entorno del usuario vease:

- [Configuración en Linux](docs/setup_on_linux.md)
- [Configuración en Windows](docs/setup_on_windows.md)
- [Configuración en Tmux](docs/use_tmux.md)


# Uso de programas

Los programas configurados en el paso anterior, puede personalizarse y establecer algunos criterios de uso:

- [Uso de VIM/NeoVIM](docs/use_vim.md)
- [Uso de TMUX](docs/use_tmux.md)
- [Uso de WezTerm](docs/use_wezterm.md)
