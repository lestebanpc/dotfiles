
Para VIM/NeoVIM se tiene 2 modos de funcionamiento:

- Modo Editor
    - No ofrece el autocompletado, pero si ofrece el resaltado sintactico.
- Modo IDE
    - VIM como IDE usa como cliente LSP a CoC.
    - NeoVIM como IDE usa el cliente LSP nativo (por defecto), pero pero puede usar CoC: `USE_COC=1 nvim`
    - Tanto VIM/NeoVIM configurado en modo IDE puede omitir la cargar los plugins del IDE usando: `USE_EDITOR=1 vim` o `USE_EDITOR=1 nvim`
         - La limitación del ultimo caso es que los no plugins `filetypes` de modo editor no se cargaran.


Para configurar estos 2 modos se debe ejecutar los scripts:

- Instalar en Linux   : `~/.files/shell/bash/bin/linuxsetup/04_install_profile.bash`
- Instalar en Windows : `~/.files/shell/powershell/bin/windowssetup/02_install_profile.ps1`

Estos script, en resumen, realizan los siguientes configuraciones:

- Crear enlaces simbólico a  archivos y carpetas en uno los `runtimepath` por defecto:
    - VIM en Linux        : `~/.vim/`
    - VIM en Windows      : `${env:USERPROFILE}\vimfiles\`
    - NeoVIM en Linux     : `~/.config/nvim/`
    - NeoVIM en Windows   : `${env:LOCALAPPDATA}\nvim\`

- Adicionalmente descarga plugin en uno de los subdirectorios del runtimepath por defecto:
    - VIM en Linux        : `~/.vim/pack/`
    - VIM en Windows      : `${env:USERPROFILE}\vimfiles\pack\`
    - NeoVIM en Linux     : `~/.local/share/nvim/site/pack/`
    - NeoVIM en Windows   : `${env:LOCALAPPDATA}\nvim-data\site\pack`




# Estructura de carpetas


Para NeoVIM, el script de instalacion crea link de archivos/carpetas en su runtimepath por defecto:

- `~/vimrc` (VIM)
     - Archivo de inicialización de VIM
     - En modo IDE, es un enlace simbolico a `~/.files/vim/vimrc_ide.vim`
     - En modo editor, es un enlace simbolico a `~/.files/vim/vim_editor.vim`
- `./init.vim` (NeoVIM)
     - Archivo de inicialización de NeoVIM
     - En modo IDE, es un enlace simbolico a `~/.files/nvim/init_ide.vim`
     - En modo editor, es un enlace simbolico a `~/.files/nvim/init_editor.vim`
- `./coc-settings.json`  (VIM/NeoVIM)
     - Archivo de configurarion de CoC
     - Solo es usado cuando en modo IDE y usando 'USE_COC=1').
     - Es un enlace a `~/.files/nvim/coc-settings_linux.json`
- `./setting/` (VIM/NeoVIM)
     - Carpeta de script VimScript invocados desde el archivo de inicialización de VIM/NeoVIM.
     - Es un enlace simbolico a `~/.files/vim/setting/`.
- `./lua/`
     - Carpeta de script LUA de configuracion de NeoVIM invocados por los script.
     - Es un enlace a `~/files/nvim/lua/`
- `./ftplugin/` (VIM/NeoVIM)
     - En la carpeta predetermina de plugin de filetypes usado por VIM/NeoVIM.
     - En VIM modo Editor son los plugins de filetypes usados solo para el modo editor y es un link a  `~/.files/vim/ftplugin/editor/`
     - En VIM modo IDE son los plugins de filetypes usados solo para modo IDE y es un link a `~/.files/vim/ftplugin/cocide/`.
     - En NeoVIM modo Editor son los plugins de filetypes usados solo para el modo editor y es un link a `~/.files/nvim/ftplugin/editor`.
     - En NeoVIM en modo IDE son los plugins de filetypes usados solo para IDE ya esa usando LSP nativo o CoC y es un link a `~/.files/nvim/ftplugin/commonide`.
- `./rte_nativeide/ftplugin/` (NeoVIM)
     - Carpeta de plugin de filetypes usado por NeoVIM en modo IDE usando el cliente LSP nativo.
     - En es un enlace simbolico a `~/.files/nvim/ftplugin/nativeide/`.
- .`/rte_cocide/ftplugin/` (NeoVIM)
     - Carpeta de plugin de filetypes usado por NeoVIM en modo IDE usando el cliente LSP de CoC.
     - En es un enlace simbolico a `~/.files/nvim/ftplugin/cocide/`.
- `./custom_config.vim`
     - Archivo que permite modificar las variables globales de este script.
     - Por defecto no existe pero la plantilla se puede obtener de  `~/.files/nvim/config_template.vim` o  `~/.files/vim/config_template.vim`:




# Archivo para la personalización


```bash
# En VIM
cp ~/.files/vim/templates/custom_config.vim ~/.vim/custom_config.vim
cp ${env:USERPROFILE}/.files/vim/config_template.vim ${env:USERPROFILE}/vimfiles/custom_config.vim

# En NeoVIM
cp ~/.files/nvim/templates/custom_config.vim ~/.config/nvim/custom_config.vim
cp ${env:USERPROFILE}/.files/nvim/config_template.vim ${env:LOCALAPPDATA}/nvim/custom_config.vim
```


Prioridad:
- Las variables de entorno definidias.
- Las variables globales de vim definidas.
- Valor por defecto usado



# Integración con el Clipboard


## De VIM al Clipboard

Se usa los siguientes keymappings para escribir en el clipboard:

| Opción | Key          | Descripción                                                   |
| ------ | ------------ | ------------------------------------------------------------- |
| `n`    | `<Leader>cc` | Copiar a el registro `"` (ultimo yank o delete) al clipboard  |
| `n`    | `<Leader>c0` | Copiar a el registro `0` (ultimo yank) al clipboard           |
| `n`    | `<Leader>c1` | Copiar a el registro `1` (ultimo delete) al clipboard         |
| `n`    | `<Leader>c2` | Copiar a el registro `2` (antepen-ultimo delete) al clipboard |
| `n`    | `<Leader>c3` | Copiar a el registro `3` (3er-ulitmo delete) al clipboard     |
| `n`    | `<Leader>c4` | Copiar a el registro `4` (4to-ulitmo delete) al clipboard     |
| `v`    | `<Leader>cy` | Yank del texto seleccionado y copiarlo al clipboard.          |
| `v`    | `<Leader>cd` | Delete del texto seleccionado y copiarlo al clipboard.        |

VIM define las siguientes variables de entorno y variables globales VIM:

- `CLIPBOARD`
    - El mecanismo usado para escribir en el clipboard.
    - Variable global VIM equivalente: `g:clipboard_writer_mode`
    - Sus valores:
        - Si no se define, se calcula el método mas adecuado.
        - `1`: si se usa OSC-52.
            - El formato a usar lo define `OSC52_FORMAT` o la variable VIM `g:clipboard_osc52_format`.
        - `2`: si se usa comando como backend de clipboard.
            - La variable `g:clipboard_writer_cmd` indica el comando usado para escribir el clipboard (debe incluir las opciones para usar el STDIN).
    - Para evaluar si vim usara OSC-52 para escribir en el clipboard, se usa las siguientes reglas:
        - Si VIM están dentro de TMUX
            - Se determinar si se usa OSC-52 en base al valor usado por `$TERM_PROGRAM` y `$TERM`.
            - Si `$TERM_PROGRAM` tiene uno de los siguientes valores, VIM usara OSC-52:
                - `foot`
                - `WezTerm`
                - `kitty`
                - `alacritty`
                - `contour`
                - `iTerm.app`
        - Si VIM esta dentro de TMUX (tmux sobrescribe `TERM_PROGRAM` a `tmux` y `TERM` suele ser `tmux-256color`).
            - TMUX cuando inicia su servidor auto-calcula la variable de entorno `TMUX_SET_CLIPBOARD`, el cual define como TMUX escribe en el clipboard del SO.
                - Este valor puede ser modificado manualmente usando la variable de entorno `SET_CLIPBOARD` antes de ejecutar tmux.
            - Si `TMUX_SET_CLIPBOARD` es `1`, VIM usara OSC-52.
    - Si no sorporta OSC-52, se buscara un backend del clipboard instalado.


```vim
:echo g:clipboard_writer_mode
:echo g:clipboard_writer_cmd

"Si es g:clipboard_writer_mode es 2
:let g:clipboard_writer_mode = 2

:let g:clipboard_writer_cmd = 'wl-copy'
:let g:clipboard_writer_cmd = 'xclip -i -selection clipboard'
:let g:clipboard_writer_cmd = 'xsel -i -b'
:let g:clipboard_writer_cmd = '/mnt/c/windows/system32/clip.exe'
:let g:clipboard_writer_cmd = 'clip.exe'
:let g:clipboard_writer_cmd = 'pbcopy'
:let g:clipboard_writer_cmd = v:null
```

```bash
# Forzar el uso de un comando externo para escribir en el clipboard
CLIPBOARD=2 vim

# Una forma de hacerlo es colocando en el profile (afectando a todo el usuario)
vim ~/.custom_profile.bash
```

```bash
#1. Forzar el uso de OSC-52 en vim para escribir en el clipboard
CLIPBOARD=2 vim

#2. Forzar el uso de OSC-52 en tmux/vim definiendo las variables de entorno antes de iniciar tmux/vim
TERM_PROGRAM='foot'
SET_CLIPBOARD=1

# Una forma de hacerlo es colocando en el profile (afectando a todo el usuario)
#cp ~/.files/shell/bash/login/profile/profile_config_template_basic_local.bash ~/.custom_profile.bash
#cp ~/.files/shell/bash/login/profile/profile_config_template_basic_remote.bash ~/.custom_profile.bash
#cp ~/.files/shell/bash/login/profile/profile_config_template_distrobox.bash ~/.custom_profile.bash
#cp ~/.files/shell/bash/login/profile/profile_config_template_wsl.bash ~/.custom_profile.bash
vim ~/.custom_profile.bash

```

- `OSC52_FORMAT`
    - Si se usa OSC-52 para escribir en clipboard, indica el formato que se usara.
    - Variable global VIM equivalente:`g:clipboard_osc52_format`.
    - Sus valores:
        - `0`: Usar en formato OSC-52 nativo, sin enmascarlo.
            - No use este valor, si usa multiplexores como TMUX o GNU screen.
        - `1`: Enmascara el formato para GNU screen.
        - `2`: Enmascara el formato para TMUX.
    - Esto se intenta calcular automáticamente:
        - Si existe una variable de entorno `TMUX` se considera que este dentro de un tmux y se usara el formato `2`.
        - Si la variable de entorno `TERM` esta definido e inicia con `screen` se considera el formato `1`.
        - Caso contrario se considera `0`.
    - Se recomienda establecer el valor en escenarios especiales donde VIM no puede determinar si esta dentro de tmux:
        - Si usa tmux y se conecta por ssh a un servidor remoto y dentro de ello usa vim/neovim.
        - Si usa tmux y accede en forma interctiva a un contenedor y dentro de ello usa vim/neovim.

```vim
:echo g:clipboard_writer_mode
:echo g:clipboard_osc52_format

"Si es g:clipboard_writer_mode es 1
:let g:clipboard_writer_mode = 1

" No enmascarar
:let g:clipboard_osc52_format = 0

" Enmascarar para TMUX
:let g:clipboard_osc52_format = 2

```

```bash
#1. NO enmascarar
CLIPBOARD=1 OSC52_FORMAT=0 vim

#2. Enmascarar para TMUX
CLIPBOARD=1 OSC52_FORMAT=1 vim
OSC52_FORMAT=1 vim
```


- `YANK_TO_CB`
    - Permitir que cuando se realize un 'yank' se copie automaticamente al clipboard.
    - Variable global VIM equivalente:`g:yank_to_clipboard`.
    - Sus valores:
        - `0` o `v:false`: si se cuando realiza un yank este se copiara automaticamente al clipboard.
        - `1` o `v:true`: si realiza un yank este NO se copiara al clipboard.


```vim
:echo g:yank_to_clipboard

" Por defecto
:let g:yank_to_clipboard = v:false

" Cada yank se copiara al clipboard
:let g:yank_to_clipboard = v:true
```

```bash
# Cada yank se copiara al clipboard
YANK_TO_CB=0 vim

# Una forma de hacerlo es colocando en el profile (afectando a todo el usuario)
vim ~/.custom_profile.bash
```


## Del clipboard al buffer VIM

Se usa los siguientes keymappings para escribir en buffer de VIM:

| Opción   | Key          | Descripción                                                 |
| -------- | ------------ | ----------------------------------------------------------- |
| `n`, `i` | `Ctrl + F11` | Pegar el clipboard despues del cursor actual usando bloques |
| `n`, `i` | `Ctrl + F12` | Pegar el clipboard despues de la linea actual usando lineas |

- La variable vim `g:clipboard_reader_cmd`.
    - Define el comando a usar para leer del clipboard


```vim
:echo g:clipboard_reader_cmd

:let g:clipboard_reader_cmd = 'wl-paste'
:let g:clipboard_reader_cmd = 'xclip -o -selection clipboard'
:let g:clipboard_reader_cmd = 'xsel --clipboard --output'
:let g:clipboard_reader_cmd = 'pwsh.exe -NoProfile -Command "Get-Clipboard"'
:let g:clipboard_reader_cmd = 'pbpaste'
:let g:clipboard_reader_cmd = v:null
```



# Integración con TMUX


Consideraciones:

- Cada vez se se crea un buffer este se almacena en un cola/pila de buffer (el ultimo insertado es el 1ero en la cola/pila).
    - Si no se especifica un nombre, se crea uno automaticamente.

```bash
tmux list-buffers
tmux list-buffers -F '#{buffer_name}'
```

## De VIM a un buffer de TMUX

Consideraciones:

- El buffer creado por los keymappings de VIM tiene siempre  tiene un nombre con estructura `vim<correlative>` donde `<correlative>` es un correlativo entero que inicia en `0`

Se usa los siguientes keymappings para escribir en buffer de tmux:

| Opción | Key          | Descripción                                                                 |
| ------ | ------------ | --------------------------------------------------------------------------- |
| `n`    | `<Leader>tt` | Copiar a el registro `"` (ultimo yank o delete) a un nuevo buffer tmux.     |
| `n`    | `<Leader>t0` | Copiar a el registro `0` (ultimo yank) al clipboard a un nuevo buffer tmux. |
| `n`    | `<Leader>t1` | Copiar a el registro `1` (ultimo delete) a un nuevo buffer tmux.            |
| `n`    | `<Leader>t2` | Copiar a el registro `2` (antepen-ultimo delete) a un nuevo buffer tmux.    |
| `n`    | `<Leader>t3` | Copiar a el registro `3` (3er-ulitmo delete) a un nuevo buffer tmux.        |
| `v`    | `<Leader>ty` | Yank del texto seleccionado y copiarlo a nuevo buffer tmux.                 |
| `v`    | `<Leader>td` | Delete del texto seleccionado y copiarlo a nuevo buffer tmux.               |



## Del buffer de TMUX a buffer de VIM

Consideraciones:

- No importa que el buffer tmux sea creado en VIM o fuera de VIM.
- Importa el orden del buffer tmux en la pila de buffer tmux.

Se usa los siguientes keymappings para escribir/pegado en buffer de VIM:

| Opción   | Key         | Descripción                                                                       |
| -------- | ----------- | --------------------------------------------------------------------------------- |
| `n`, `i` | `Ctrl + F1` | Pega el 1ro de pila de buffer tmux al buffer vim actual despues de cursor actual. |
| `n`, `i` | `Ctrl + F2` | Pega el 2do de pila de buffer tmux al buffer vim actual despues de cursor actual. |
| `n`, `i` | `Ctrl + F3` | Pega el 3ro de pila de buffer tmux al buffer vim actual despues de cursor actual. |
| `n`, `i` | `Ctrl + F4` | Pega el 4to de pila de buffer tmux al buffer vim actual despues de cursor actual. |
| `n`, `i` | `Ctrl + F5` | Pega el 5to de pila de buffer tmux al buffer vim actual despues de cursor actual. |

Las acciones que permiten un pegado en bloques de un buffer tmux a un buffer vim:

| Opción   | Key          | Descripción                                                                                                |
| -------- | ------------ | ---------------------------------------------------------------------------------------------------------- |
| `n`, `i` | `Ctrl + F6`  | Pega el 1ro de pila de buffer tmux al buffer vim actual despues de cursor actual usando pegado en bloques. |
| `n`, `i` | `Ctrl + F7`  | Pega el 2do de pila de buffer tmux al buffer vim actual despues de cursor actual usando pegado en bloques. |
| `n`, `i` | `Ctrl + F8`  | Pega el 3ro de pila de buffer tmux al buffer vim actual despues de cursor actual usando pegado en bloques. |
| `n`, `i` | `Ctrl + F9`  | Pega el 4to de pila de buffer tmux al buffer vim actual despues de cursor actual usando pegado en bloques. |
| `n`, `i` | `Ctrl + F10` | Pega el 5to de pila de buffer tmux al buffer vim actual despues de cursor actual usando pegado en bloques. |


# Personalización como IDE


## Generales


- `ONLY_BASIC`
    - Si es `0`, permite convertir un vim/neovim configurado como IDE en modo editor.
    - Solo usado en modo developer, que permite usar el modo editor.
    - Variable global VIM equivalente:`g:use_ide`.


- `USE_COC` (solo neovim y en modo IDE)
    - Si es `0`, permite usar CoC en vez del LSP integrado de NeoVIM.
    - Si no se define o es diferente de `0`, por defecto, se usa LSP integrado de NeoVIM.


## Rutas de binarios externos

La variable de entorno `MY_TOOLS_PATH` es la carpeta donde se encuentra:
- Ruta base donde están los LSP Server: `./lsp_servers/`
- Ruta base donde están los DAP Server:  `./dap_servers/`
- Ruta base donde están las extensiones de vscode : `./vsc_extensions/`

Esta variable se define el `~/.bashrc`, cuyo valor es:
- El valor definido en la variable `g_tools_path` del script `~/.custom_profile.bash`.
- Si no se define un valor, se usara `/var/opt/tools`

```bash
bat -p ~/.bashrc
vim ~/.custom_profile.bash
```

VIM permite cambiar cambiar esta variable usando la variable de entorno y/o lka variable global VIM:

- `MY_TOOLS_PATH`
    - La carpeta donde se encuentra el programas de usuario `tools`
    - Variable global VIM equivalente:`g:tools_path`.


## Configurar el fixing

- `FIX_ON_SAVE`
    - La carpeta donde se encuentra el programas de usuario `tools`
    - Variable global VIM equivalente: `g:ale_fix_on_save`.




# Uso comunes

Uso de CoC y Neovim


# Keymappings


Consideraciones:

- Se usara la notación:
    - `key` (split-mode) (ámbito)
        - El keymappings no se modifica, se usa la definición existente el por defecto.
    - ~~`key`~~ (split-mode) (ámbito) (eliminado)
    - ~~`key`~~ (split-mode) (ámbito)
        - El keymappings por defecto se elimina.
    - `key` (split-mode) (ámbito) (modificado)
        - El keymappings no se modifica el existente.
    - Donde:
        - El *ámbito* puede ser:
            - Si el ámbito es global, aplicando a todo a un grupo de `filetypes`.
            - Si aplica a un grupo de `filetypes`.
            - Si no se especifica se considera que es global.

- Representaremos:
    - `key1 + key2`
        - Para representar teclas que requieren que ambas las teclas se apretar ambos en forma conjunta para activar una acción.
             - Usualmente, se presiona la 1ra tecla y manteniendo apretado esta, se presiona la segundo, este genera el evento que dispara la acción.
	- `key1, key2`
	    -
	    - Un caso especial son cuando ambos letras representan caracteres imprimibles donde se puede omitir el  separador `,`.
             - Por ejemplo `a, b` se puede representar como `ab`.
    - Si la tecla es un letra imprimible y representa una letra del alfabeto se usara:
        - `Shift, a` se representara como `A`


- Los split-mode considerados:
    - `x` (`visual`)
    - `v` (`visual and select`)
    - `s` (`select`)
    - `o` (`operator-pending`)
        - Sub-modo del normal iniciado por `d` (delete), `c` (change), `y` (yank), etc.

- Si se usa un *prefix key* (*leader*) se usara:
    - El leader por defecto `<Leader>, ` es `,` y es usado para tareas básicas del core.
    - El leader `<space>` para muchas funciones de IDE.
    - Si no se usa leader, se deberá evaluar si se sobrescribe un *keymappings* estándar y su impacto.

## Core


### Generales


- `<Leader>, ee` (normal)
    - Abrir/cerrar el explorador de archivos.

- `<Leader>, hh` (normal)
    - Habilitar/Desabiliar la linea de resaltado horizonal.

- `<Leader>, vv` (normal)
    - Habilitar/Desabiliar la linea de resaltado vertical.

- `<Leader>, th` (normal)
    - Terminal horizonal.

- `<Leader>, tv` (normal)
    - Terminal vertical.



### Buscador

Se usa `fzf` que implementa las siguientes opciones:

- `<Leader>, ff` (normal)
    - Se usa `fd` usando `.gitignore`.
    - Busqueda de archivos del proyecto usando `rg`.

- `<Leader>, fw` (normal)
    - Busqueda de archivos del proyecto usando `rg` filtrando el word actual.

- `<Leader>, fW` (normal)
    - Busqueda de archivos del proyecto usando `rg` filtrando el WORD actual.

- `<Leader>, bb` (normal)
    - Listar, Selexionar/Examinar e Ir al buffer.

- `<Leader>, ll` (normal)
    - Se usa `fd` usando `.gitignore`.
    - Listar archivos del proyecto, Seleccionar/Examinar e Ir

- `<Leader>, lg` (normal)
    - Listar archivos del 'Git Files', Seleccionar/Examinar e Ir

- `<Leader>, ls` (normal)
    - Listar archivos del 'Git Status Files', Seleccionar/Examinar e Ir

- `<Leader>, lc` (normal)
    - Listar comandos VIM, seleccionar y ejecutar.

- `<Leader>, lm` (normal)
    - Marcas (marks)

- `<Leader>, lj`
    - Saltos (Jumps)

- `<Leader>, lT`
    - Listar los tags para el proyecto (si no existe lo debe crear usando "ctags -R")

- `<Leader>, lt`
    - Los tags (generados por CTags) del buffer

- `<Leader>, lh`
    - Los tags de VIM (help de vim)


### TMUX

Usados por `vimux`:

- `<Leader>, tz` (normal)
    - Para restaurar/maximizar nuevamente el panel use la acción tmux `<tmux-prefix>, z`	Ir al panel tmux, maximizando el panel.

- `<Leader>, tp` (normal)
    - Muestra un input prompt para que escriba el comando.
    - Ingresa un comando y lo ejecutar el comando (sin salir de VIM)

- `<Leader>, tr` (normal)
    - Ejecutar el comando especial: Ejecutar el ultimo comando.

- `<Leader>, tx` (normal)
    - Ejecutar el comando especial: Cancelar el comando en ejecución (`CTRL + C`).

- `<Leader>, tl` (normal)
    - Ejecutar el comando especial: Limpiar la terminal (similar a usar `CTRL + l`).

Usados por *tmux navigator* (`vim-tmux-navigator`)

- `Ctrl + h/j/k/l`
- `Ctrl + w, h/j/k/l`
- `Ctrl + w, ←/↓/↑/→`
- `<tmux-prefix>, h/j/k/l`
- `<tmux-prefix>, ←`
    - `Ctrl + h/j/k/l` esta definido por el plugin `vim-tmux-navigator`.
    - `Ctrl + w, ...` es el tecla de acceso por defecto definido por  VIM.
    - `<tmux-prefix>, ...` es el tecla de acceso por defecto definido por TMUX.
    - Ir al split/panel izquierdo, inferior, inferior y superior.


Acciones desde vim al buffer de tmux

- `<Leader>, ty` (visual)
    - Realizar un yank de la seleccion y escribir al clipboard

- `<Leader>, td` (visual)
    - Realizar un delete de la seleccion y escribir al clipboard

- `<Leader>, tt` (normal)
    - Copiar el registro por defecto (ultimo yank/delete) al clipboard

- `<Leader>, t0` (normal)
    - Copiar el ultimo yank al clipboard

- `<Leader>, t1` (normal)
    - Copiar el 1er ultimo delete al clipboard

- `<Leader>, t2` (normal)
    - Copiar el 2do ultimo delete al clipboard

- `<Leader>, t3` (normal)
    - Copiar el 3er ultimo delete al clipboard

- `<Leader>, t4` (normal)
    - Copiar el 3er ultimo delete al clipboard


Acciones para leer el buffer de tmux y luego pegar al buffer vim:

- `Ctrl + F1`  (normal, insert)
    - Leer el buffer de indice 0 y pegar despues de cursor

- `Ctrl + F2`  (normal, insert)
    - Leer el buffer de indice 1 y pegar despues de cursor

- `Ctrl + F3`  (normal, insert)
    - Leer el buffer de indice 2 y pegar despues de cursor

- `Ctrl + F4`  (normal, insert)
    - Leer el buffer de indice 3 y pegar despues de cursor

- `Ctrl + F5`  (normal, insert)
    - Leer el buffer de indice 4 y pegar despues de cursor

Acciones para leer el buffer de tmux y luego pegar al buffer vim como *bloque de texto en columnas*:

- `Ctrl + F6`  (normal, insert)
    - Leer el buffer de indice 0 y pegar en bloque despues de cursor

- `Ctrl + F7`  (normal, insert)
    - Leer el buffer de indice 1 y pegar en bloque despues de cursor

- `Ctrl + F8`  (normal, insert)
    - Leer el buffer de indice 2 y pegar en bloque despues de cursor

- `Ctrl + F9`  (normal, insert)
    - Leer el buffer de indice 3 y pegar en bloque despues de cursor

- `Ctrl + F10`  (normal, insert)
    - Leer el buffer de indice 4 y pegar en bloque despues de cursor


### Clipboard

Leer el clipboard y escribir en el buffer vim:

- `Ctrl + F11` (normal, insert)
    - Leer del clipboard y pegar en bloque despues de cursor

- `Ctrl + F12`  (normal, insert)
    - Leer del clipboard y pegar en linea inferior


Leer el registro vim y copiar al buffer clipboard:

- `<Leader>, cy` (visual)
    - Realizar un yank de la seleccion y escribir al clipboard

- `<Leader>, cd` (visual)
    - Realizar un delete de la seleccion y escribir al clipboard

- `<Leader>, cc` (normal)
    - Copiar el registro por defecto (ultimo yank/delete) al clipboard


- `<Leader>, c0` (normal)
    - Copiar el ultimo yank al clipboard

- `<Leader>, c1` (normal)
    - Copiar el 1er ultimo delete al clipboard

- `<Leader>, c2` (normal)
    - Copiar el 2do ultimo delete al clipboard

- `<Leader>, c3` (normal)
    - Copiar el 3er ultimo delete al clipboard

- `<Leader>, c4` (normal)
    - Copiar el 3er ultimo delete al clipboard



## Tools


### Rest Client



#### General


- `<Leader>, rb` (normal)
    - Open scratchpad (similar a `.http` pero temporal, no se guarda)

- `<Leader>, ro`	(normal)
    - Open 'kulala UI' (buffer donde se muestra el resultado)

- `<Leader>, rs` (normal visual)
    - Send request

- `<Leader>, ra` (normal visual)
    - Send all requests

- `<Leader>, rr` (normal)
    - Replay the last request


#### Para `filetype` que son `http` y `rest`

- `<Leader>, rq`  (normal) (ft `http`, `rest`)
    - Cierra el buffer acutal y 'kulala UI', solo si es 'http' o 'rest'.

- `<Leader>, rc`   (normal) (ft `http`, `rest`)
    - Copy as cURL al clipboard

- `<Leader>, rC`   (normal) (ft `http`, `rest`)
    - Paste from curl (desde clipboard al buffer)

- `<Leader>, ri`   (normal) (ft `http`, `rest`)
    - Muestra un popup donde muestra el request a enviar (sin variables)

- `<Leader>, re`   (normal) (ft `http`, `rest`)
    - Select environment

- `<Leader>, ru`   (normal) (ft `http`, `rest`)
    - Manage Auth Config

- `<CR>`   (normal) (ft `http`, `rest`)
    - Send request actual

- `<Leader>, rg`   (normal) (ft `http`, `rest`)
    - Download GraphQL schema

- `<Leader>, rn`   (normal) (ft `http`, `rest`)
    - Jump to next request

- `<Leader>, rp`   (normal) (ft `http`, `rest`)
    - Jump to previous request

- `<Leader>, rf`   (normal) (ft `http`, `rest`)
    - Find request

- `<Leader>, rt`   (normal) (ft `http`, `rest`)
    - Toggle la vista headers o body de 'kulala UI'

- `<Leader>, rS`   (normal) (ft `http`, `rest`)
    - Show stats

- `<Leader>, rx`   (normal) (ft `http`, `rest`)
    - Clear globals

- `<Leader>, rX`    (normal) (ft `http`, `rest`)
    - Clear cached files



#### Para buffer *UI Kulala*

- `H`   (normal) (ft del buffer de *UI kulala*)
    - Show headers

- `B`   (normal) (ft del buffer de *UI kulala*)
    - Show body

- `A`   (normal) (ft del buffer de *UI kulala*)
    - Show headers and body

- `V`   (normal) (ft del buffer de *UI kulala*)
    - Show verbose

- `O`   (normal) (ft del buffer de *UI kulala*)
    - Show script output

- `S`   (normal) (ft del buffer de *UI kulala*)
    - Show stats

- `R`   (normal) (ft del buffer de *UI kulala*)
    - Show report

- `F`   (normal) (ft del buffer de *UI kulala*)
    - Show filter

- `]`   (normal) (ft del buffer de *UI kulala*)
    - Next response

- `[`   (normal) (ft del buffer de *UI kulala*)
    - Previous response

- `<CR>`   (normal) (ft del buffer de *UI kulala*)
    - Jump to response

- `X`   (normal) (ft del buffer de *UI kulala*)
    - Clear responses history

- `<S-CR>`   (normal) (ft del buffer de *UI kulala*)
    - Send WS message

- `<C-c>`   (normal) (ft del buffer de *UI kulala*)
    - Interrupt requests

- `?`   (normal) (ft del buffer de *UI kulala*)
    - Show help

- `g?`  (normal) (ft del buffer de *UI kulala*)
    - Show news

- `q`   (normal) (ft del buffer de *UI kulala*)
    - Close



### *Git diff* entre workspace y staging area

- `]c` (normal) (buffer en git)
    - Ir al siguiente "staged hunk" (cambio)

- `[c`  (normal) (buffer en git)
    - Ir al anterior  "staged hunk" (cambio)

- `<Leader>, hs`  (normal, visual) (buffer en git)
    - ¿Aceptar? el "staged hunk" (¿promover a ..?) actual/selecionado

- `<Leader>, hs`    (normal, visual) (buffer en git)
    - Reset el "staged hunk" (¿ ..?) actual/selecionado

- `<Leader>, hS`    (normal) (buffer en git)
    - ¿Aceptar? los "staged hunk" (¿promover a ..?) del buffer

- `<Leader>, hR`    (normal) (buffer en git)
    - Reset el "staged hunk" (¿ ..?) del buffer

- `<Leader>, hb`    (normal) (buffer en git)
    - Blame (mostrar info del ultimo commit de) la linea actual

- `<Leader>, hd`    (normal) (buffer en git)
    - Diiff la linea actual

- `<Leader>, hD`    (normal) (buffer en git)
    - Diiff todo el buffer

- `<Leader>, hq`    (normal) (buffer en git)
    - Set the quickfix/location list with changes

- `<Leader>, hQ`    (normal) (buffer en git)
    - Set the quickfix/location list with changes

- `<Leader>, tb`    (normal) (buffer en git)
    - Toogle el blame info de la linea actual

- `<Leader>, tw`   (normal)
    - Toogle el word diff de ...

- `<Leader>, ac`  (normal)
    - Habilitar/Desabilitar AI Completion de Copilot

- `ix`	(O,X)
    - Operar sobre el bloque "staged hunk" actual


### AI tools


### AI Complition

- `<Leader>, ac`
    - Habilitar/Desabilitar AI Completion de Copilot


### AI Agent (Avante)


- `<Leader>, aa`
    - show sidebar

- `<Leader>, at`
    - toggle sidebar visibility

- `<Leader>, ar`
    - refresh sidebar

- `<Leader>, af`
    - switch sidebar focus

- `<Leader>, a?`
    - select model

- `<Leader>, ae`
    - edit selected blocks


- `co`
    - choose ours

- `ct`
    - choose theirs

- `ca`
    - choose all theirs

- `c0`
    - choose none

- `cb`
    - choose both

- `cc`
    - choose cursor

- `]x`
    - move to previous conflict

- `[x`
    - move to next conflict

- `[[`
    - jump to previous codeblocks (results window)

- `]]`
    - jump to next codeblocks (results windows)



## IDE


### Completion

Consideraciones:

- <sup>1</sup> Modo insert pero solo cuando el completado es visible (`pumvisible()`)

El *Built-in Completion*, se da:

- `Ctrl + Space`  (insert)
     - Abrir el popup manualmente. Si esta abierto, actualiza la data	Abrir el popup manualmente. Si esta abierto, actualiza la data
- `automatic` (insert)
    - En CoC, si por lo menos se escribe un carácter visible en el modo edición.
    - Abrir el popup automaticamente.
- `automatic` (insert<sup>1</sup>)
    - Cierra el  popup y si la palabra cambio por alguna acción de navegación este se anula.
    - Cancelar y continuar al modo edición.
- `Escape` (insert<sup>1</sup>)
    - Cierra el  popup y si la palabra cambio por alguna acción de navegación este se anula volviendo a su valor original.
    - Cerrar el popup sin aceptar el elemento e ir al modo normal. (salir del modo).
- `Ctrl + e`
    - Cerrar el popup sin aceptar elemento, continuando el modo insert.
- `Enter` (insert<sup>1</sup>)
    - El elemento selecionado se completa, cierra el tab. CoC si es función, muestra el popup de 'Signature-help Popup Window'.
    - Cerrar el popup aceptando el elemento seleccionado (si no elemento sera el 1er elemento), continuando el modo  insert.

- `Ctrl + y`   (insert<sup>1</sup>)
    - Cerrar el popup continuando el modo  insert. Si hay un elemento seleccionado lo acepta, si no se comparta como `<C-e>` (solo cierra el popup)

- `Tab`  (insert<sup>1</sup>)
- `Ctrl + n`  (insert<sup>1</sup>)
- ~~`Up`~~
    - En CoC, si se usa `<TAB>`, el popup no esta abierto, este popup se muestra.
    - Navegación: Ir al siguiente elemento.

- `Shift + Tab`  (insert<sup>1</sup>)
- `Ctrl + p`     (insert<sup>1</sup>)
- ~~`Down`~~
     - Navegación: Ir al anterior elemento.

- `Ctrl + x, Ctrl + ...`  (insert<sup>1</sup>)
    - Mostrar el popup con una fuente de completado especifico


Omnisharp Completition (el inicio siempre es manual):


- `gq`  (insert<sup>1</sup>)
    - Solo en Omnisharp, en CoC depende del tipo de popup.
    - Cerrar el popup

- `Ctrl + e`  (insert<sup>1</sup>)
    - En Omisharp el ID de la acciones es 'lineDown'.
    - Mover 1 linea hacia abajo.

- `Ctrl + y`  (insert<sup>1</sup>)
    - En Omisharp el ID de la acciones es 'lineUp'.
    - Mover 1 linea hacia arriba.

- `Ctrl +d`  (insert<sup>1</sup>)
    - En Omisharp el ID de la acciones es 'halfPageDown'.
    - Mover 1/2 pagina hacia abajo.

- `Ctrl + u`  (insert<sup>1</sup>)
    - En Omisharp el ID de la acciones es 'halfPageUp'.
    - Mover 1/2 pagina hacia arriba.

- `Ctrl + f`     (insert1)
- `PageDown`     (insert<sup>1</sup>)
    - En Omisharp el ID de la acciones es 'pageDown'
    - Mover 1 pagina hacia abajo ('f' de  'follow').

- `Ctrl + b`    (insert<sup>1</sup>)
- `PageUp`        (insert<sup>1</sup>)
    - En Omisharp el ID de la acciones es 'pageUp'
    - Mover 1 pagina hacia arriba ('b' de 'before').


### Popup windows

*Signature-help Popup* general:

- `Ctrl + \` (insert, normal)
    - En CoC, se inicia cuando se escribir `(` despues del nombre de una funcion, escribir `,` dentro de `()`.

- `automatic` (insert, normal)
    - En CoC, cuando se acepta el completado de una funcion, es escribe automaticamente `(`.

- `automatic`  (insert, normal) (popup)
    - En CoC, Si se mueva fuera de `()` o usa `↑`, `↓`.

*Signature-help Popup* de Omisharp:

- `Ctrl + j`  (insert, normal) (popup)
    - En Omisharp el ID de la accones es `sigNext`.

- `Ctrl + k`  (insert, normal) (popup)
    - En Omisharp el ID de la acciones es `sigPrev`.

- `Ctrl + l`  (insert, normal) (popup)
    - En CoC, es automatico si se escribe `,`.
    - En Omisharp el ID de la acciones es 'sigParamNext'.

- `Ctrl + h`  (insert, normal) (popup)
    - En CoC, es automatico.
    - En Omisharp el ID de la acciones es `sigParamPrev`.

*Preview Popup* de Omisharp:

- `<space>pd`   (normal)
    - No existe un CoC, pero existe en Omnisharp.

- `<space>pi`   (normal)
    - No existe un CoC, pero existe en Omnisharp.

*Documentation Popup*:

- `K`   (normal)
    - Si no se ha definido documentación para este simbolo (variable, metodo, funcion, clase, ..) se muestra solo la declaracion donde se define dicho simbolo.
    - En omnisharp, solo muestra el tipo del simbolo en la barra de estado


### Code Information

- `<space>ty`    (normal)
    - Show en la 'status line'

- `<Space>, hi`    (normal)
    - ¿semantic highlighting?



### Code navegation


#### Navegación básica

Definido a que no se usa el *leader*, se esta anulando algunas *keymappings* predeterminados ¿cuales?

- `gd`   (normal)
    - Location 'definition'
    - Si es variable donde se muestra donde se declara, si es una clase va a definición de la clase.

- `gc`   (normal)
    - Location 'declaration'
    - Una variable donde se muestra donde se declara

- `gi`    (normal)
    - Location 'implementations'
    - En pocos lenguales (como C/C+) se diferencia entre difinicion o implementación, el los demas son iguales.
    - Si es variable donde se muestra donde se declara, si es una clase va a definición de la clase.
    - ¿vim defaults of `gt` (tabnext) and `gT` (tabprev)?

- gy`   (normal)
    - Location 'type definition'
    - Si es una variable, va a da definicion de la clase de la variable.

- `gr`   (normal)
    - Location 'references'
    - Listar el uso del simbolo, seleccionar e ir a dicho referencias (incluyendo las declaraciones de dicho simbolo).

- `gu`   (normal)
    - Location 'used references'
    - Listar el uso del simbolo, seleccionar e ir a dicho referencias pero sin incluir las declaraciones de dicho simbolo.

- `]]`   (normal)
    - Location inicio del 'method'

- `[[`   (normal)
    - Location inicio del 'method'

- `<Space>, ss`    (normal)
    - Listar, Seleccionar e Ir a un 'symbol' en el buffer actual.
    - Permite listar 'symbol' existentes en el proyecto, la busqueda y seleccionar para luego e ir alli. En CoC, lista solo del buffer

- `<Space>, sw`    (normal)
    - Listar, Seleccionar e Ir a un 'symbol' en el workspace.
    - En Omnisharp, busca los clases y sus miembros (variables y metodos) de todo el proyecto. En Coc, lista 'symbols' en wokspace

- `<Space>, s2`   (normal)
    - Listar, Seleccionar e Ir a un 'symbol' en el buffer actual.
    - Usa el plugin Aerial de NeoVIM

- `<Space>, lt`   (normal)
    - Listar, Seleccionar e Ir a un 'type' en el proyecto.
    - Permite listar 'type' existentes en el proyecto, la busqueda y seleccionar para luego e ir alli.
    - En Omnisharp, busca las clases del proyecto.

- `<Space>, lm`   (normal)
    - Listar, Seleccionar e Ir a un 'member' del buffer actual.
    - Permite listar las clases y sus 'member' de una clase (indicando si es privado, publico, …) existentes en el archivos actual.


#### Code Outline

Code Outline del buffer:

- `<Space>, co`   (normal)
    - Mostrar/ocultar el panel esquema de codigo (arbol de lista de simbolos) del buffer actual.
    - Usa el plugin Aerial de NeoVIM


#### Treesitter Navigator


Los objetos validos depende de lenguaje y puede verlo en: https://github.com/nvim-treesitter/nvim-treesitter-textobjects#built-in-textobjects



- `]m` y  `[m`   (normal)
- `]M` y `[M`   (normal)
    - Ir al inicio de **next**/**previous**/**end**/**start**  del objeto `@function`.

- `]c` y  `[c`   (normal)
- `]C` y `[C`   (normal)
    - Ir al inicio de **next**/**previous**/**end**/**start**  del objeto `@class`.

- `]i` y `[i`   (normal)
- `]I` y `[I`   (normal)
    - Ir al inicio de **next**/**previous**/**end**/**start**  del objeto `@conditional`.

- `]m` y `[m`   (normal)
- `]M`  y `[M`   (normal)
    - Ir al inicio de **next**/**previous**/**end**/**start**  del objeto `@loop`.

- `]f` y `[f`   (normal)
- `]F` y `[F`   (normal)
    - Ir al inicio de **next**/**previous**/**end**/**start**  a la llamada de una funcion `@call`.

- `;`   (normal)
    - Repetir el ultimo movimiento Next realizado.

- `\`   (normal)
    - Repetir el ultimo movimiento Previous realizado.



### Swap objects

- `<Space>, na`   (normal)
- `<Space>, pa`   (normal)
    - Intercambiar la posicion del objeto `@parameter` actual con el objeto similar **next**/**previous** (mover hacia abajo/arriba)

- `<Space>, nm`   (normal)
- `<Space>, pm`   (normal)
    - Intercambiar la posicion del objeto `@function` actual con el objeto similar **next**/**previous** (mover hacia abajo/arriba)

### **Text objects** operations

- `am` y `im`	 (visual,o)
    - Operar (`select`, `delete`, `change`, ..) la parte **arround**/**inner** del objeto `@function`.

- `ac` y `ic`	 (visual,o)
    - Operar (`select`, `delete`, `change`, ..)  la parte **arround**/**inner** del objeto `@class`.

- `ai` y `ii`	 (visual,o)
    - Operar (`select`, `delete`, `change`, ..)  la parte **arround**/**inner** del objeto `@conditional`.

- `al` y `il`	 (visual,o)
    - Operar (`select`, `delete`, `change`, ..)  la parte **arround**/**inner** del objeto `@loop`.

- `af` y `if`	 (visual,o)
    - Operar (`select`, `delete`, `change`, ..)  la parte **arround**/**inner** del objeto `@call`.

- `a=` y `i=`	 (visual,o)
    - Operar (`select`, `delete`, `change`, ..)  la parte **arround**/**inner** del objeto `@assigment`.

- `l=` y `r=`	 (visual,o)
    - Operar (`select`, `delete`, `change`, ..)  la parte **left**/**right** del objeto `@assigment`.

### Smart selections


- `Ctrl + Space` (normal)
    - Iniciar el smart selection, esto pasara el modo visual.

- `Ctrl + Space` (visual)
    - Incrementar la selecion (en modo visual) incluyendo el nodo superior que lo contiene ("Expand Selection")

- `Backspace` (visual)
    - Incrementar la selecion (en modo visual) incluyendo el nodo superior que lo contiene ("Shrink Selection")


### Diagnostic

- `<Space>, dd` (normal)
    - Listar, Seleccionar e Ir a un error y/o warning del buffer.
    - Realizar el 'Global Code Check', listar lo errores/warning encontrados, e ir a dicho error.
    - En Omnisharp, lanza un panel llamado 'QuickFix' (no basado en fzf), la cual se puede cerrar selecionado el panel y usando el comando `:close`.
    - En CoC, se inica su popup 'Fuzzy' (no es un panel vim), la cual se cierra usando `[ESC]`.

- `<Space>, dw` (normal)
    - Listar, Seleccionar e Ir a un error y/o warning del proyecto.
    - Realizar el 'Global Code Check', listar lo errores/warning encontrados, e ir a dicho error.
    - En Omnisharp, lanza un panel llamado 'QuickFix' (no basado en fzf), la cual se puede cerrar selecionado el panel y usando el comando `:close`.
    - En CoC, se inica su popup 'Fuzzy' (no es un panel vim), la cual se cierra usando `[ESC]`.

La navegación en ALE:

- `]d` (normal)
    - Ir al siguiente diagnostico desde la posicion actual y dentro del buffer
    - Si se usa lo definido por CoC puede navedar en todo el proyecto

- `[d` (normal)
    - Ir a la anterior diagnostico desde la posicion actual y dentro del buffer

La navegación de Neovim LSP:

- `]2` (normal)
    - Ir al siguiente diagnostico desde la posicion actual y dentro  ...
- `[2` (normal)
    - Ir a la anterior diagnostico desde la posicion actual y dentro del buffer


### Snippets

En la navegacion por cada fragmento del snippet expandido.
 - Algunos fragmentos pasan desde el modo 'Insert' al modo 'Select' selecionando el fragmento (similar al modo visual, pero la seleccion es remplazada automaticamente cuando se escribre).
- Algunos fragmentos se mantiene en el modo 'Insert'.

Generales:

- `<Space>, sn`   (normal)
    - Listar los snippets existentes para el 'filetype' (ver sus definiciones)
- `<Space>, sc`   (insert)
    - Crear un snippet cuyo nombre es el texto selecionado.

- `Ctrl + s`   (insert)
    - Mostrar el completado con los snippets asociado al prompt actual, si existe uno solo el snippet  se expande automaticamente.

Navegar entre fragmentos:

- `Ctrl + f`   (insert, select)
    - Ir al siguiente nodo del snippets activo ('f' de 'follow').

- `Ctrl + b`   (insert, select)
    - Ir al nodo anterior del snippets activo ('b' de 'before').

Navegar entre nodos:

- `Ctrl + E`   (insert)
    - Ir al siguiente valor de un nodo (nodo choice o dynamic)



### Fixing


#### Code formatting

- `<Space>, cf`  (normal, visual)
    - Formato de codigo del buffer actual o la selección actual.


- `<Space>, fx`  (normal, visual)
    - Realiza tareas como formateo y otros usando herramientas externas (no LSP)

#### Code Actions

##### Generales

- `<Space>, aa`   (normal)
    - Listar, seleccionar y ejecutar 'Code Actions' asociados a la cursor actual (si usas CoC, no muestra los de tipo source).

- `<Space>, aa`   (visual)
    - Listar, buscar y ejecutar un 'Code Actions' que se encuentra habilitados en la linea de codigo actual. En Omnisharp, lanza un popup basado en fzf (no es un panel vim), la cual se puede cerrar usando `[ESC]`.
    - En CoC, se inica su popup 'Fuzzy', la cual se cierra usando `[ESC]`.
    - Listar, seleccionar y ejecutar 'Code Actions' existente en el seleccion actual (si usas CoC, no muestra los de tipo source).

- `<Space>, al`   (normal)
    - Listar, seleccionar y ejecutar un 'Code Actions' existente en el la linea actual (si usas CoC, no muestra los de tipo source).

- `<Space>, ar`    (normal, visual)
    - Listar, seleccionar y ejecutar un 'Code Actions' de tipo refactor del cursor actual o seleccion actual.

- `<Space>, as`   (normal)
    - Listar, seleccionar y ejecutar un 'Code Actions' de tipo source (siempre estan asociados al buffer)


##### Source

- `<Space>, oi`   (normal)
    - Acción de reparación:  Organización y/o reparar las refencias de importaciones usadas por el archivo
    - Ejecutar el "Organize Import".

##### Quick fix

- `<Space>, qf`   (normal)
    - Acción de reparación: Accion de repacion rapida
    - Ejecutar el "Quick Fix" de la linea actual

- `<Space>, q.`   (normal)
    - Repetir el ultima "Quick Fix" ejecutado

##### Refactoring

 Véase ejemplo de refactoring en:
 - https://www.jetbrains.com/guide/java/tips/extract-variable/

Los keymappings usado son:


- `<Space>, rn`   (normal)
    - Renombrar

- `<Space>, ev`    (normal, visual)
    - Extract variable

- `<Space>, ec`    (normal, visual)
    - Extract Constant

- `<Space>, em`    (normal, visual)
    - Extract method


### Code Lens

- `<Space>, cl`   (normal)
    - Listas, seleccionar y ejecutar los "code lens" asociadas a una linea actual.

###  LSP Server management


- `<Space>, sa`   (normal)
    - Start server (Omnisharp/Roslyn)

- `<Space>, rs`   (normal)
    - Restart server (Omnisharp/Roslyn)

- `<Space>, so`   (normal)
    - Stop/Down server (Omnisharp/Roslyn)


### Utilidades

Gestion del workspace del LSP:

- `<Space>, wa`  (normal)
    - Adicionar folder actual al workspace

- `<Space>, wr`  (normal)
    - Remover folder actual al workspace

Usados en CoC:

- `<Space>, ee`  (normal)
    - Gestion de extensiones de CoC habilitados.

- `<Space>, cc`  (normal)
    - Mostrar de comandos CoC permitidos.

Otros:

- `<Space>, ol`  (normal)
    - Abrir el anlace del prompt actual


### Unit  Test

- `<Space>, tm`	N
    - Test Nearest method
    - En un archivo de prueba, se ejecuta la prueba más cercana al cursor; de lo contrario, se ejecuta la última prueba más cercana.
    - En entornos de prueba que no admiten números de línea, esta funcionalidad se rellenará con expresiones regulares .
    - Test Nearest method with profiler (solo Java/.Net)

- `<Space>, tc`	N
    - Test Class
    - En un archivo de prueba, se ejecuta la primera clase de prueba que se encuentre en la misma línea que el cursor o por encima de ella. (Actualmente solo compatible con Pytest).

- `<Space>, tf`	N
    - Test File
    - En un archivo de prueba se ejecutan todas las pruebas del archivo actual, de lo contrario, se ejecutan las últimas pruebas del archivo.

- `<Space>, ts`	N
    - Test Suite
    - Ejecuta todo el conjunto de pruebas (si el archivo actual es un archivo de prueba, ejecuta el conjunto de pruebas de ese marco; de lo contrario, determina el marco de prueba de la última prueba ejecutada).

- `<Space>, tl`	N
    - Test Last
    - Test	Ejecuta la última prueba.

- `<Space>, tv`	N
    - Test Visit
    - Visita el archivo de prueba desde el cual ejecutaste por última vez tus pruebas (es útil cuando intentas hacer que una prueba pase y te sumerges profundamente en el código de la aplicación y cierras tu búfer de prueba para hacer más espacio, y una vez que lo has hecho pasar, quieres volver al archivo de prueba para escribir más pruebas).


### Debugging


#### Start debugging


##### Debug project


- `F5`               (normal)
    - Start/Continue debugging (permite escoger el config a usar)	When debugging, continue. Otherwise start debugging.

- `<Space>, F5`  (normal)
    - Start debugging creando una configuracion (no considera la config existente)

- `F4`               (normal)
    - Start debugging usando la ultima configuracion realizada	Restart debugging with the same configuration.

- `<Space>, F4`  (normal)
    - Stop & Exit debugging (elimina los paneles UI).	Stop & Exit debugging.


##### Debug test

Start debugging test:

- `<Space>, dtm`  (normal)
    - Start debugging Test Nearest method

- `<Space>, dtc`  (normal)
    - Start debugging Test Class

- `<Space>, dtf`  (normal)
    - Start debugging Test File

- `<Space>, dts`	(normal)
    - Start debugging Test Suite

Start debugging test with profile:

- `<Space>, dtm`	(normal)
    - Start profile with Test Nearest method

- `<Space>, dtc`	(normal)
    - Start profile with Test Class


##### Debug otros

Start debugging selected code

- `<Space>, dsc`	(visual, select)
    - Start debugging selected code



#### Generales

- `<Space>, db`   (normal)
    - Listar los breakpoints

- `<Space>, df`   (normal)
    - Listar los debug frames (reequite un sesion DAP activa)

- `<Space>, dc`   (normal)
    - Abrir/Cerrar el panel de la consola integrada (REPL Console)

- `F3`   (normal)
    - Stop debugging (deja los paneles UI)	Stop debugging.

- `F6`   (normal)
    - Pause debugger.	Pause debuggee.



#### Breakpoints


- `F9`              (normal)
    - Toggle line breakpoint on the current line.
    - Toggle line breakpoint on the current line.

- `<Space>, F9` (normal)
    - Toggle conditional line breakpoint or logpoint on the current line.
    - Toggle conditional line breakpoint or logpoint on the current line.

- `F8`             (normal)
    - Add a function breakpoint for the expression under cursor
    - Add a function breakpoint for the expression under cursor



#### Navegation


- `<Space>, F8` (normal)
    - Run to Cursor

- `F10` (normal)
    - Step Over

- `F11` (normal)
    - Step Into	Step Into

- `F12` (normal)
    - Step out of current function scope


#### Evaluate expression

- `<Space>, dh`  (normal)
    - Evalua la expresion ingresada.

- `<Space>, de`  (normal, visual)
    - Evalua la expresion: lo seleccionado o la palabra del cursor actual (hover)
