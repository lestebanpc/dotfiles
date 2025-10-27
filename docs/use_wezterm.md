
Wezterm usa el archivo de configuración `~/.config/wezterm/wezterm.lua` el cual es un enlace simbólico a `~/.files/wezterm/local/wezterm.lua`.

- El directorio `~/.config/wezterm/` esta en el **runtimepath** de LuaJIT integrado con WezTerm.
- Este archivo invoca al archivo `~/.config/wezterm/custom_config.lua`, el cual no es un enlace simbólico, por lo que se recomienda realizar personalizaciones desde ese archivo.
- Las carpeta `~/.config/wezterm/lua/` contiene archivos módulos (script lua) requeridos por el archivo de configuración `wezterm.lua`


```bash
vim ~/.config/wezterm/wezterm.lua
vim ~/.config/wezterm/custom_config.lua
ls -la ~/.config/wezterm/
ls -la ~/.config/wezterm/lua/
```



# Personalización

Se recomienda modificar el archivo `~/.config/wezterm/custom_config.lua` (invocado por  `~/.config/wezterm/wezterm.lua`):

```bash
# Si es Linux
cp ~/.files/wezterm/local/custom_config_template_lnx.lua ~/.config/wezterm/custom_config.lua

# Si es Windows
cp ${env:USERPROFILE}/.files/wezterm/local/custom_config_template_win.lua ${env:USERPROFILE}/.config/wezterm/custom_config.lua
```



# Keymapping

Consideraciones:

- Se usara la notación:
    - `key`
        - El keymappings no se modifica, se usa la definición existente el por defecto.
    - ~~`key`~~ (eliminado)
    - ~~`key`~~
        - El keymappings por defecto se elimina.
    - `key` (modificado)
        - El keymappings no se modifica el existente.
    - `key` (new)
    - `key` (custom)
        - Nuevo keymappings no se modifica el existente.

- Representaremos:
    - `key1 + key2`
        - Para representar teclas que requieren que ambas las teclas se apretar ambos en forma conjunta para activar una acción.
             - Usualmente, se presiona la 1ra tecla y manteniendo apretado esta, se presiona la segundo, este genera el evento que dispara la acción.
	- `key1, key2`
	    - Un caso especial son cuando ambos letras representan caracteres imprimibles donde se puede omitir el  separador `,`.
             - Por ejemplo `a, b` se puede representar como `ab`.
    - Si la tecla es un letra imprimible y representa una letra del alfabeto se usara:
        - `Shift, a` se representara como `A`


## Modo normal (Scroll mode)

Vease:
- <https://wezfurlong.org/wezterm/config/default-keys.html>
- <https://gist.github.com/tuxfight3r/0dca25825d9f2608714b>
- <https://wezfurlong.org/wezterm/config/key-tables.html>

Modificara el keybinding por defecto para tener un keybinding compatiable con *GNome Terminal*, *Tilix* y *TMUX* y *VIM*.

Para diferencias usando:

- El keybinding por defecto que no se usa estara ~~tachado~~.
- El keybinding personalizada que se indicara con *cursiva*.
- Se usara como **key leader** a `ATL + a`
    - No usar `CTRL + a` entrar en conflicto con el prefijo alterno/remoto de tmux
    - Evitar de usar `CTRL` para dejarlo a ciertos keymapping para VIM



### Capacidades basicas


#### Scrollback del panel actual

La teclas up/down se usan para navegar del promtp actual
Las demás teclas como pagUp, PageDonwn, left, rigth, ... No sé recomienda usar directamente en modo normal y reservarlas para el prompt (esto depende del shell usado), es por ello que la mayoría de las terminales como no usan estás teclas si usar un modificador como SHIFT.
Vease: <https://wezfurlong.org/wezterm/scrollback.html>

- `Shift  + PageUp`
    - Acción: `ScrollByPage=-1`
- `Shift  + PageDown`
    - Acción: `ScrollByPage=1`
- *`Ctrl + Shift + UpArrow`*
    - Acción: `ScrollByLine(-1)`
- *`Ctrl + Shift + DownArrow`*
    - Acción: `ScrollByLine(1)`
- *`Shift + Home`*
    - Acción: `ScrollToTop`
- *`Shift + End`*
    - Acción: `ScrollToBottom`
- `Ctrl + Z`
    - Acción: `ScrollToPrompt(-1)`
- `Ctrl + X`
    - Acción: `ScrollToPrompt(1)`



#### Gestión de la fuente

- ~~`Super + -`~~
- `Ctrl + -`
    - Acción: `DecreaseFontSize`

- ~~`Super + +`~~
- `CTRL + +`
- *`CTRL + =`*
- *`Ctrl + Shift + +`*
    - Acción: `IncreaseFontSize`

- ~~`Super + 0`~~
- `CTRL + 0`
    - Acción: `ResetFontSize`


#### Gestión clipboard

- ~~`Super + c`~~
- `Ctrl + C`
    - Acción: `CopyTo="Clipboard"`

- ~~`Super + v`~~
- `Ctrl + V`
- `Leader, [`
    - Acción: `PasteFrom="Clipboard"`

- ~~`Ctrl + Insert`~~
    - Acción: `CopyTo="PrimarySelection"-`

- ~~`Shift + Insert`~~
    - Acción: `PasteFrom="PrimarySelection"`



### Generales


#### Ingresar a un modo

- ~~`Ctrl + F`~~
- ~~`Super + f`~~
    - Modo de busqueda 
    - En la version *nightly* se cambio el modo busqueda como un modo *overlay* al modo copia, similar a *tmux*.
    - Acción: `Search={CaseSensitiveString}`

- ~~`Ctrl + X`~~
- `Leader, [`
- `Leader, (Shift) [`
    - Modo copia 
    - Acción: `ActivateCopyMode`

- ~~`Ctrl + Shift + Space`~~
- `Leader, Space`
    - Modo selección rapida 
    - Acción: `QuickSelect`

- ~~`Ctrl + U`~~
- `Leader, U`
    - Unicode Character selection mode 
    - Acción: `CharSelect`


#### Otros

- ~~`Super + r`~~
- ~~`Ctrl + R`~~
- `Leader, r`
    - Acción:  `ReloadConfiguration`

- ~~`Super + k`~~
- ~~`Ctrl + K`~~
- ~~`Ctrl + L`~~ (eliminado)
    - Limpiar el historial.
    - No se usara a nivel terminal, pues anula la navegación entre paneles.
    - Use a nivel del shell, por ejemplo:
        - Si usa el modo **emacs**, tiene configurando la opción `Ctrl + l` en el `GNU ReadLine` usando por bash
    - Acción: `ClearScrollback="ScrollbackOnly"`. 

- ~~`Ctrl + L`~~
- *`Leader + l`*
    - Acción: `ShowDebugOverlay`

- `Ctrl + P`
    - Muestra el menu, similar a apreta el boton `+`. 
    - Acción: `ActivateCommandPalette`



#### No considerados

Se desestabilizara (solo se usara el "keyboard global shurcut" del SO):

- ~~`Super + m`~~
- ~~`Ctrl + M`~~
    - Ocultar la ventana
    - Acción: `Hide` 

- ~~`Super + n`~~
- ~~`Ctrl + N`~~
    - Crear la ventana
    - Acción: `SpawnWindow`

- ~~`Alt + Enter`~~
    -  Maximizar
    - Acción: `ToggleFullScreen`

- ~~`Super + h`~~
    - Solo aplica para macOS.
    -  Acción: `HideApplication`



### Gestión de tab (window)

#### Variados

- ~~`Super + w`~~ (eliminado)
- ~~`Ctrl + W`~~ (eliminado)
    - Cerrar un tab actual
    - Acción: `CloseCurrentTab{confirm=true}`

- `Prefix, (Shift) &` (custom)
    - Cerrar la ventana actual.


#### Tab Creation

- ~~`Super + t`~~ (eliminado)
- `Prefix, c` (custom)
    - Crear un tab usando el dominio usado por el panel actual
    - Acción: `SpawnTab="CurrentPaneDomain"`

- `Prefix, (Shift) C` (custom)
    - Crear un tab usando el default dominio de panels
    - Acción: `SpawnTab="DefaultDomain"`


##### Interactive (Usando el Launcher)

- `Prefix, (Shift) W`
    - Mostrar el menu de item
    - Acción: `ShowLauncherArgs{ flags =  'LAUNCH_MENU_ITEMS' }`

- `Prefix, w`
    - Mostrar la busqueda de dominios
    - Usado en Windows para abrir el WSL de la distro por defecto.
    - Acción: `ShowLauncherArgs{ flags =  'FUZZY|DOMAINS' }`


#### Tab navigation

- ~~`Super + n`~~
- ~~`Ctrl + Shift + n`~~
- *`Prefix, <n>`* (custom)
    - Ir al tab al indice n=1  (para indice m=0),  hasta n=0 (para el índice m=9) 
    - Acción: `ActivateTab(m)`
        - `m = -1`es para ir al último tab. 
        - `m` es negativo se cuenta desde el último para la izquierda.

- *`Prefix, (Shift) L`* (custom)
    - Ir al ultimo tab
    - Acción: `ActivateTab(-1)`


- ~~`Super + Shift + [`~~
- ~~`Ctrl + Shift + Tab`~~
- ~~`Ctrl + PageUp`~~
- *`Prefix, l`* (custom)
    - Ir al Tab de la izquierda del actual tab (*previous*)
    - Acción: `ActivateTabRelative(-1)`

- ~~`Super + Shift + ]`~~
- ~~`Ctrl + Tab`~~
- ~~`Ctrl + PageDown`~~
- *`Prefix, p`* (custom)
    - Ir al Tab de la derecha del actual tab (*next*)
    - Acción: `ActivateTabRelative(1)`


#### Swap tab

- ~~`Ctrl + Shift + PageUp`~~
- *`Prefix, <`* (custom, latin keybord layout)
- *`Prefix, (Shift) <`* (custom)
	- Mover el Tab actual a la izquierda, cambiando el índice del tab 
    - Acción: `MoveTabRelative(-1)`

- ~~`Ctrl + Shift + PageDown`~~
- *`Prefix, (Shift) >`* (custom)
    - Mover el Tab actual a la derecha, cambiando el índice del tab 
    - Acción: `MoveTabRelative(1)`



### Gestión del panel

Se ha cambiado usando la teclas tecla LEADER para le gestiona de paneles.


#### Variados

- ~~`Ctrl+ (Shift) Z`~~
- *`Leader, z`*  (custom)
    - Fullscreen/Restaurar el tamaño del panel actual 
    - Acción: `TogglePaneZoomState`

- *`Leader, x`* (custom)
    - Cerrar el panel actual
    - Accion: `CloseCurrentPane { confirm = true }`

- `Leader, (Shift) !` (custom)
    - Convertir el panel actual en una nueva Windows.

- `Leader, q` (custom)
    - Mostrar el indice de todos los paneles de la ventana


#### Pane Split

- ~~`Ctrl + Alt + (Shift) "`~~
- *`Leader, (Shift) "`* (custom)
- *`Leader, =`* (custom)
- *`Leader, (Shift) =`* (custom, latin keyboard layout)
- *`Leader, |`* (custom, latin keyboard layout)
- *`Leader, (Shift) |`* (custom)
    - Dividir panel actual en forma vertical.
    - Acción: `SplitVertical={domain="CurrentPaneDomain"}`
    - Notas:
        - En un teclado de layout ingles, la posición de la tecla `%` es el `Shift + 5` y está en la línea vertical del teclado. 

- ~~`Ctrl + Alt + (Shift) %`~~
- *`Leader, (Shift) %`* (custom)
- *`Leader, -`* (custom)
    - Dividir panel actual en forma horizontal.
    - Acción: `SplitHorizontal={domain="CurrentPaneDomain"}`
    - Notas:
        - La posición de la tecla `"` es el `Shift + '` y está esta línea horizontal medio del teclado. 


#### Pane Navegation

- ~~`Ctrl + Shift + ←/↓/↑/→`~~
- `<Leader>, ←/↓/↑/→`
- `<Leader>, h/j/k/l`
- `Ctrl + h/j/k/l` (personalizado, solo para cierto proceso que se ejecuta en el panel))
    - Acción: `ActivatePaneDirection="Left"`
    - Acción: `ActivatePaneDirection="Right"`
    - Acción: `ActivatePaneDirection="Up"`
    - Acción: `ActivatePaneDirection="Down"`


#### Pane Resizing

No se usara el keybinding por defecto: ~~`Ctrl + Alt + Shift + ←/↓/↑/→`~~
Se crea un modo especial usando un *Key Table* personalizado llamado`resize_pane`.

- `<Leader>, r` (custom).
    - Inicia esta nuevo modo (*Key Table* personalizado llamdo`resize_pane`)
- `Esc`
    - Por inactividad (timeout por defecto es `xxx`).
    - Se salir del modo y volver al modo normal.

Una vez estado en este modo puede ejecutar una sola vez o en forma repetitiva:


- `←/↓/↑/→` (custom)
- `h/j/k/l` (custom)
    - Repetible ...
	- Acción: `AdjustPaneSize={"Left", 1}`
    - Acción: `AdjustPaneSize={"Right", 1}`
    - Acción: `AdjustPaneSize={"Up", 1}`
    - Acción: `AdjustPaneSize={"Down", 1}`


- `Shift + ←/↓/↑/→` (custom)
- `Shift + h/j/k/l` (custom)
    - Repetible ...
	- Acción: `AdjustPaneSize={"Left", 5}`
    - Acción: `AdjustPaneSize={"Right", 5}`
    - Acción: `AdjustPaneSize={"Up", 5}`
    - Acción: `AdjustPaneSize={"Down", 5}`




#### Rotating panel

No existe un swap como en tmux.
- Permite  intercambiar el índice (con ello el orden de cómo se muestra el panel) el tamaño entre 2 paneles.

No existe algo similar a tmux.
Vease: https://wezterm.org/config/lua/keyassignment/RotatePanes.html?h=pane


- `<Leader>, {`  (custom, latin keyboard layout)
- `<Leader>, (Shift) {`  (custom)
	- Intercambiar paneles moviendo a la izquierda del panel actual.
	- Sentido contrario a las agujar del reloj
    - Acción: `RotatePanes('CounterClockwise')`

- `<Leader>, }`  (custom, latin keyboard layout)
- `<Leader>, (Shift) }`  (custom)
    - Intercambiar paneles moviendo a la derecha del panel actual.
    - Sentido de las agujar del reloj

	- Acción: `RotatePanes('Clockwise')`


## Modo copia

Vease: https://wezterm.org/copymode.html#configurable-key-assignments

Este modo permite:
- Navegar en todo el contenido del panel (incluyendo los programas interactivos hijos que estén ejecutándose).
- Establecer criterios de búsqueda y la orientación de búsqueda.
- Navegar entre la coincidencia de los criterios de búsqueda.
- Realizar una selección de texto y permite copiar de texto seleccionado del panel actual (de *manera interactiva*) como el ultimo buffer tmux.

Cuando se inicia al modo copia  (usando `Leader, [`) este permite la **navegación** y permite ingresar a 2 sub-modos especiales **Prompt de búsqueda** y **Creación de la Selección**

- `?` o `/` para ingresar al modo *prompt de búsqueda*.
- `Espace` (selección no lineal) o `V` (selección lineal) para ingresar al modo *creación de selección*
- Para salir:
    - `q`
    - `Enter` (si no hay una selección, se comporta igual que `q`)

Los sub-modos especiales son:

- Prompt de búsqueda
    - Muestra un *prompt* que permite establecer el criterio de búsqueda.
    - Para salir y volver al modo navegación:
        - `Enter` puede aceptar el criterio de búsqueda.
        - `Esc` puede rechazar el criterio de búsqueda
    - Tiene su propio *key table*.

- Creación de la Selección:
    - Permite establecer la selección usando la teclas de navegación.
    - Siempre se oculta los marcadores de criterios de búsqueda.
    - NO Tiene su propio *key table*.
    - Para salir de este modo puede:
        - Rechazar la selección (no copia al clipboard)
            - `Esc` para volver la modo navegación normal
            - `q` para salir del modo copia
        - Aceptar la selección (copiar al clipboard)
            - `y` para volver la modo navegación normal
            - `Enter` para salir del modo copia



### Inicial


#### Navegación básica

Se **elimina** las siguientes key de navegacion:

- ~~`Enter`~~
    - Moverse al inicio de la siguiente linea
    - Accion: `MoveToStartOfNextLine`

- Navegacion basica
    - `LeftArrow` o `h`
        - Move Left
    - `DownArrow` o `j`
        - Move Down
    - `UpArrow` o `k`
        - Move Up
    - `RightArrow`, `l`
        - Move Right

- Moverse en una misma linea
    - `Alt + m`
    - `^`
         - Accion: Move to start of indented line

	- `$`
    - `End`
        - Move to end of this line
    - `0`
    - `Home`
        - Move to start of this line

- Moverse al inicio de la siguiente linea a la actual
    - `Enter`
        - Move to start of next line


- Moverse entre word anterior y siguiente
    - `w`
    - `Alt + RightArrow`
    - `Alt + f`
    - `Tab`
         - Move forward one word
	- `b`
	- `Alt + LeftArrow`
	- `Alt + B`
	- `Shift + Tab`
        - Move backward one word
	- `e`
        - Move forward one word end


- Moverse verticalmente dentro buffer del scrollback
     - `G`
         - Move to bottom of scrollback
	- `g`
        - Move to top of scrollback
	- `PageUp`
	- `Ctrl + B`
        - Move up one screen
	- `Ctrl + u`
        - Move up half a screen
	- `PageDown`
	- `Ctrl + f`
        - Move down one screen
	- `Ctrl + d`
        - Move down half a screen

- Mover el viewport dentro buffer del scrollback
    - `H`
         - Move to top of viewport
	- `M`
         - Move to middle of viewport
	 - `L`
        - Move to bottom of viewport



#### Ir a una coincidencia de búsqueda

Si se estableció el **criterio de búsqueda**, puede navegar entre la coincidencias.

A diferencia de **tmux**:

- El criterio de búsqueda se puede **limpiar**.
    - Elimina los marcadores del la coincidencia de los criterios de búsqueda
    - Establecer a vació el *criterio de búsqueda*.
    - Oculta el **search bar**.
- No se puede *ocultar* los marcadores de búsqueda y el *search bar*. Solo **limpiarlo**.
- No se permite definir (por defecto) la *dirección de búsqueda* de la coincidencia cuando se crea la *criterio de búsqueda*.

Navegar entre la **conciencia** del *criterio de búsqueda* (solo si se estableció un *expresión de búsqueda*):

- `n` (custom)
    - Ir hacia búsqueda hacia adelante

- `N` (custom)
- `p` (custom)
    - Ir hacia el anterior coincidencia.


Para limpiar el *criterio de búsqueda* seleccionado, se usa:

- `Ctrl + u` (custom)
    - El criterio de búsqueda se puede **limpiar**.
        - Elimina los marcadores del la coincidencia de los criterios de búsqueda
        - Establecer a vació el *criterio de búsqueda*.
        - Oculta el **search bar**.

Se **elimina** las siguientes key de busqueda:

- ~~`,`~~
    - Moverse al anterior criterio de busquefa
    - Accion `JumpReverse`

- ~~`;`~~
    - Moverse al siguiente criterio de busqueda
    - Accion: `JumpAgain`

- ~~`f`~~
    - Accion `CopyMode { JumpForward = { prev_char = true } }`
- ~~`F`~~
    - Accion `CopyMode { JumpBackward = { prev_char = false } }`

- ~~`t`~~
    - Accion `CopyMode { JumpForward = { prev_char = true } }`

- ~~`T`~~
    - Accion: `CopyMode { JumpBackward = { prev_char = true } }`




#### Ir al prompt de búsqueda

Permite ingresar al submodo *prompt de búsqueda* donde se muestra un *prompt* donde se establece el criterio de búsqueda.

A diferencia de **tmux**:

- El criterio de búsqueda se puede **limpiar**.
    - Elimina los marcadores del la coincidencia de los criterios de búsqueda
    - Establecer a vació el *criterio de búsqueda*.
    - Oculta el **search bar**.
- No se puede *ocultar* los marcadores de búsqueda y el *search bar*. Solo **limpiarlo**.
- No se permite definir (por defecto) la *dirección de búsqueda* de la coincidencia cuando se crea la *criterio de búsqueda*.


Se crea nuevos keymappings aso

- `\` (custom)
    - Define el sentido de navegación de criterios de búsqueda **hacia adelante**.

- `?` (custom)
    - Define el sentido de navegación de criterios de búsqueda **hacia atras**.

- Tanto el *criterio de búsqueda* como la *dirección de búsqueda* no puede eliminar hasta que termina la sesión (esto se almacen a nivel sesion), pero se puede:
    - `Esc`.
        - Ocultar los marcadores de coincidencias de búsqueda.
	- Si los marcadores están ocultos y navegar entre la coincidencias usando `n` o `N`, se volverá a mostrar las marcadores de la coincidencias.
    - Cuando inicia una selección, los marcadores se dejan de mostrar (se oculta automáticamente).



#### Ir a crear una selección

Para iniciar una *selection*, muevese en el lugar que deseado para iniciar una selección:
- `v`
    - Para seleccionar caracteres continuo.
- `V`
    - Para seleccionar lineas completa.
- `Ctrl + v`
- `Ctrl + q` (custom)
    - Para seleccionar rectangular

Si desea cambiar de modo, apreté nuevamente lo deseas.

Adicionalemente se puede

- Modificar la selección actual horizontalmente (usado frecuentemente en ua selección rectangular)
    - `o`
        - Move to other end of the selection
    - `O`
        - Move to other end of the selection horizontally



#### Salir

Para salir del *copy-mode* (ingresar la modo normal):

- `q` (custom)
    - Salir del modo (e ingresar al modo normal).


- `Enter` (modificado)
    - Si no una hay selección, se comporta igual que `q`.



### Prompt de búsqueda


Se muestra un *prompt* donde se establece el criterio de busqueda.
- Se muestran marcadores del la coincidencia de los criterios de búsqueda
- Se muestra la **search bar** donde esta el prompt para ingresar el criterio de busqueda.

En la version *nightly* se cambio el modo búsqueda como un modo *overlay* al modo copia, similar a *tmux*.

- El modo búsqueda en una sola superposición del modo copia. Ambos modos siguen estando conceptualmente separados porque las combinaciones de teclas deben comportarse de forma diferente, pero ahora comparten estado.
- El modo busqueda pasa a ser un submodo del modo copia:
    - https://github.com/wezterm/wezterm/issues/1592#issuecomment-1118722289
    - <https://wezfurlong.org/wezterm/scrollback.html>
    - Aun se mantiene el modo de navegacion sin  ingresar al modo copia. Solo se unifica el modo busqueda dentro del modo copia.
        - https://github.com/wezterm/wezterm/issues/1592
        - https://github.com/wezterm/wezterm/issues/5952
        - https://github.com/wezterm/wezterm/issues/2170
- A diferencia de **tmux**:
    - El criterio de búsqueda se puede **limpiar**.
        - Elimina los marcadores del la coincidencia de los criterios de búsqueda
        - Establecer a vació el *criterio de búsqueda*.
        - Oculta el **search bar**.
    - No se puede *ocultar* los marcadores de búsqueda y el *search bar*. Solo **limpiarlo**.
    - No se permite definir (por defecto) la *dirección de búsqueda* de la coincidencia cuando se crea la *criterio de búsqueda*.


Dentro de este prompt, también se permite:

- `Ctrl + u` (custom)
    - Para limpiar el criterio de busqueda escrito
    - El criterio de búsqueda ingresado se **limpiar**.
    - No sale del modo.

- `Ctrl + r`
    - Cambia el modo de búsqueda, reiniciando la búsqueda. Los modos de busqueda: 
        - "case-sensitive"  
        - "case-inssensitive"  
        - "expresiones regulares"



Para salir y volver al modo navegación puede usar las teclas:
- `Enter` (custom)
    - Aceptar el criterio de busqueda
    - Establecer el criterio de búsqueda
- `Esc` (custom)
    - Rechazar el criterio de busqueda


En el modo copia siempre se mostrara el *search bar* y los marcadores de coincidencia a menos que lo limpie.

Se elimina los siguientes keymappingd:

- Navegar a las coincidencias dentro del *prompt de busqueda*.
    - ~~`↑` ~~
    - ~~`Ctrl + p`~~
    - ~~`Enter`~~
        - Buscar la anterior ("previous") coincidencia
    - ~~`↓`~~
    - ~~`Ctrl + n`~~
        - Buscar la siguiente ("next") coincidencia.
    - ~~`PageUp`~~
        - Búsqueda de la primera coincidencia en la siguiente página
    - ~~`PageDown`~~
        - Búsqueda de la primera coincidencia en la  página anterior



### Creación de la Selección

Usando la teclas de navegación puede establecer la forma de la selección.


En cualquier momento se permite cambiar el **modo de selección** usando:

- `v`
    - Para seleccionar caracteres continuo.
- `V`
    - Para seleccionar lineas completa.
- `Ctrl + v`
- `Ctrl + q` (custom)
    - Para seleccionar rectangular



Para salir de este modo puede:

- Rechazar la selección (no copia al clipboard)
    - `Esc` (redefinido)
        - para volver la modo navegación normal
    - `q` (custom)
        - para salir del modo copia

- Aceptar la selección (copiar al clipboard)
    - `y` (redefinido)
        - para volver la modo navegación normal
    - `Enter` (redefinido)
        - para salir del modo copia



#### Aceptar la selección


##### Aceptar la selección

Para **aceptar** una selección sin salir del modo:

- `y` (redefine, el por defecto sale del modo)
    - No sale del modo copia
    - **Acepta** sin salir: realiza la copia al clipboard pero no sale del modo copia




##### Salir del modo copia

Para **aceptar** una selección y **salir del modo**:

- `Enter` (redefine)
    - **Acepta** la copia, saliendo del modo copia




#### Rechazar la selección


##### Cancelar la selección

Para cancelar la seleccion (nunca sale del modo copia):

- `Esc` (redefine)
    - Cancelar la seleccion (nunca sale del modo):




##### Salir del modo copia


Para **salir del modo** (*sin aceptar* la selección):

- `q` (new)
- ~~`Ctrl + c`~~
- ~~`Ctrl + g`~~
- ~~`Esc`~~
    - Salir del modo sin aceptar la selección.
    - Acción: `Multiple { { CopyMode = 'ScrollToBottom' }, { CopyMode = 'Close' }, }`






## Modo de selecion de caracteres

Vease: <https://wezfurlong.org/wezterm/config/lua/keyassignment/CharSelect.html>


## Modo de selección rápida

Permite copiar al clipboard una palabra especial usando un selector (generado automáticamente y que consiste de 1 o 2 caracteres).
Solo realiza una búsqueda en la pagina actual (las demás página, no reliza una búsqueda y desabilita las opciones de ir a esas páginas, por ejemplo desabilita el scroll).
Vease: <https://wezfurlong.org/wezterm/quickselect.html>

Por defecto para iniciar este modo use `Leader, Space` ya no ~~`Ctrl + Shift + Space`~~).
El modo marcara ciertas palabras con 1 o 2 caracteres usando caracteres minúsculas de amarillo. mostrado al inicio de la palabra, el cual se llamara el selector de la palabra.

Para salir de modo:

- Escribir el selector de la palabra (en minúscula).
    - Copiara al portapapeles y saldra de modo
- Escribir el selector de la palabra en `Shift`.
    - Copiara al portapapeles y pegara el prompt actual y luego saldra del modo.
- `Esc` para salir de modo de búsqueda sin hacer nada.
