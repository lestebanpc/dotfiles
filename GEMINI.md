# 1. Resumen del proyecto

El proyecto incluye archivos *dotfiles* usados para configurar un profile del usuario para un desarrollador de software en Linux, Windows y Termux (Android).
Gemini CLI debera ofrecer apoyo en la codificacion de los script usados en el proyecto, ubicados principalmente en la carpetas del proyecto:
- `./shell/bash/bin/linuxsetup` script en bash de configuracion del sistema y del profile para un desarrollador de software en Linux. Los scripts mas importante son:
  - `./01_setup_binaries.bash` script usado para instalar y actualizar binarios usualmente descargados de repositorios externos al SO (por ejemplo descargado de 'Releases' de GitHub)
  - `./04_install_profile.bash` script para configuar el profile bash del usuario actual de la distribucion Linux.
  - `./05_update_profile.bash` script para actualizar el profile del usuario (usualmente para actualizar los plugin de VIM o NeoVIM instalados).
- `./shell/powershell/bin/windowssetup` script powershell usados para configurar el profile para un desarrollador de software en Windows >= 11. Los scripts mas importantes son:
  - `./01_setup_binaries.ps1` script usado para instalar y actualizar binarios usualmente descargados de repositorios externos al SO (por ejemplo descargado de 'Releases' de GitHub)
  - `./02_install_profile.ps1` script para configuar el profile powershekk del usuario actual de Windows.
  - `./03_update_profile.ps1` script para actualizar el profile del usuario (usualmente para actualizar los plugin de VIM o NeoVIM instalados).
- `./nvim` archivos usados para configrar Neovim usando LUA. Estos archivos extienden la configuracion existente en la carpeta `./vim`
- `./vim` archivos usados para configurar vim usando CoC y VimScript.
- `./wezterm/local` script en LUA usados para configurar el emulador de terminal wezterm.
- `./wezterm/remote` script en LUA usados para configurar un servidor de multiplexion en un servidor remoto (en dicho servidor no se instala el emulador de terminal, solo  se requiere los binario `wezterm-mux-server` y opcionalmente `wezterm`)



# 2. Tono y Estilo de Comunicación
- Responde siempre en español.
- Sé directo y técnico, pero explica conceptos complejos de forma sencilla.
- Proporciona ejemplos de código para ilustrar tus puntos.


# 3. Uso de los scripts


## Linux

- Instalar comandos basicos usando los paquetes del sistema: `git`, `curl`, `tmux`, `rsync`.
- Debera clonar los archivos del repositorio git: `git clone https://github.com/lestebanpc/dotfiles.git ~/.files`.
- Descargar comandos basicos de repositorios externos al SO:
```bash
~/.files/shell/bash/bin/linuxsetup/01_setup_binaries.bash 1 4
~/.files/shell/bash/bin/linuxsetup/01_setup_binaries.bash 2 'tmux-thumbs,tmux-fingers,sesh,tree-sitter'
```
- Configurar el profile de usuario en modo developer o basico segun sea el caso usando el script `~/.files/shell/bash/bin/linuxsetup/04_install_profile.bash`
- opcionalmente puede configurar en modo basico el usuario root.
- Si desea actualizar los plugin VIM/NeoVIM del usuario puede usar `~/.files/shell/bash/bin/linuxsetup/05_update_profile.bash`.


## Windows

- Instalar comandos basicos usando los paquetes del sistema: `git`, `curl`, `tmux`, `rsync`.
- Debera clonar los archivos del repositorio git: `git clone https://github.com/lestebanpc/dotfiles.git ~/.files`.
- Configurar el profile de usuario en modo developer o basico segun sea el caso usando el script `~\.files\shell\powershell\bin\windowssetup\02_install_profile.ps1`
- Si desea actualizar los plugin VIM/NeoVIM del usuario puede usar `~\.files\shell\powershell\bin\windowssetup\03_update_profile.ps1`.
