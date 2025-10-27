
La configuración en Linux ...


# Instalar comandos basicos

Los pasos recomandos para configurar su SO son:

1. Instalar comandos basicos

```bash

#1. Para distribuciones de la familia Debian
sudo apt-get update
sudo apt-get install tmux git curl openssl vim rsync wl-clipboard

# Solo usado en modo developer, para compilar un AST de `tree-sitter`
sudo apt-get install gcc

#2. En Linux de la familia Fedora
sudo dnf install tmux git curl openssl vim rsync wl-clipboard

# Solo usado en modo developer, para compilar un AST de `tree-sitter`
sudo dnf install gcc
```


2. Clonar el repositorio

```shell
#1. Clonacion del repositorio

# Opc1: Clonacion completa de la rama por defecto repositorio
git clone https://github.com/lestebanpc/dotfiles.git ~/.files

# Opc2: Clonacion superficial de la rama por defecto del repositorio (solo el ultimo commit)
git clone --depth=1 https://github.com/lestebanpc/dotfiles.git ~/.files


#2. Si ya existe el repositorio y desea actualizarlo
cd ~/.files

# Opc1: Actualizacion completa
git pull main origin

# Opc2: Actualizacion completa
git fetch origin main
git merge FETCH_HEAD

# Opc3: Actualizacion superficial (solo el ultimo commit)
git fetch --depth=1 origin main
git reset --hard FETCH_HEAD
```

3. Opcional. Configuración de los script de instalación/actualización.
   - Los script de instalación usan variable globales con valores por defecto, las cuales puede ser modificados, segun orden de prioridad:
     - Los argumentos enviados a ejecutar el script,
     - Las variables especificadas en el archivos de configuración ".setup_config.bash" (por defecto este archivo no existe, tiene que crearlo).
   - Puede copiar el archivo basando en la plantilla existente en su repositorio.
   - Descomente las variables que desea modificar y establecer el valor deseado.

```shell
# Parametros del instalador del profile y otros
cp ~/.files/shell/bash/bin/linuxsetup/lib/setup_config_template.bash ~/.files/shell/bash/bin/linuxsetup/.setup_config.bash

vim ~/.files/shell/bash/bin/linuxsetup/.setup_config.bash
```

4. Descarga y configurar comandos/programas basicos de los repositorios (usualmente Github).
   - Se puede ejecutar con root, pero no se recomienda si desea que los comandos sean para todos los usuarios.

```shell
#Escager la opcion 4
~/.files/shell/bash/bin/linuxsetup/01_setup_binaries.bash 1 4
# > Escoger la opcion 4

# Instalar
# El CLI 'tree-sitter' solo es requerido por NeoVIM para procesar algunos AST de algunos lenguajes que usan archivos de configuracion.
~/.files/shell/bash/bin/linuxsetup/01_setup_binaries.bash 2 'tmux-thumbs,tmux-fingers,sesh,tree-sitter'
```



# Configuracion de la fuente del terminal

1. Descargar 'Nerd Font'

2. Configure la terminal.
   - Debera configurar la fuente 'Nerd-Fonts'. La fuente que uso es `JetBrainsMono Nerd Font Mono`.



# Configurar el profile del usuario

1. Para un usuario especifico, configure los plugins VIM/NeoVIM:
   - Ingrese sesion al usuario que desea configurar el profile y ejecute el script siguiente.
   - Si desea usar configurar el modo desarrollo (VIM/NeoVIM como IDE) use la opcion 'd' o 'f'.
   - Si desea usar configurar el modo editor (VIM/NeoVIM basico) use la opcion 'c' o 'e'.

```bash
#Mostrar el menu para configurar el profile y VIM/NeoVIM
~/.files/shell/bash/bin/linuxsetup/04_install_profile.bash

#Para mostrar los parametros del script, ingrese un parametro invalido como:
~/.files/shell/bash/bin/linuxsetup/04_install_profile.bash
```

2. Opcional. Configuración de su profile del shell del SO:
   El script de profile `~/.bashrc` define algunas variable globales con valores por defecto, las cuales puede ser modificados, defiendo el archivo de configuración `.custom_profile.bash`.
   El archivo de configuración por defecto no existe y debe ser creado en `~/.custom_profile.bash`.

   Tambien puede copiar el archivo basando en la plantilla existente en su repositorio:
   Descomente las variables que desea modificar y establecer el valor deseado.

```shell
cp ~/.files/shell/bash/login/profile/profile_config_template_nonwsl.bash ~/.custom_profile.bash
cp ~/.files/shell/bash/login/profile/profile_config_template_wsl.bash ~/.custom_profile.bash
```

3. Configurar/actualizar el perfil modo developer, usa la opción el cual permitirá configurar VIM/NeoVIM:
    - Instalar los plugins
    - Indexar la documentación.
        - Esto inicia VIM pero debido a que los archivos de configuración son los ultimo que se instala, si es la primera vez que instala:
            - No se auto-instale las extension `CoC`.
            - Iniciar NeoVIM para se compile e instale los AST `tree-sitter`.
    - Crear los archivos y carpetas requeridas por VIM/NeoVIM

```shell
#1. Iniciar el instalador
~/.files/shell/bash/bin/linuxsetup/04_install_profile.bash

#Escoga la opcion 's'
```


4. Personalizar configuración del *profile* (opcional):
    - Si se instala en *WSL* o *Distrobox*, el instalador copia un archivo `~/.custom_profile.bash` con parámetros iniciales el cual puede modificar si lo desea.
    - Si el equipo es para uso personal y tiene acceso a la red local, establezca:

```bash
cp ~/.files/shell/bash/login/profile/profile_config_template_basic_local.bash ~/.custom_profile.bash
#cp ~/.files/shell/bash/login/profile/profile_config_template_basic_remote.bash ~/.custom_profile.bash
#cp ~/.files/shell/bash/login/profile/profile_config_template_distrobox.bash ~/.custom_profile.bash
#cp ~/.files/shell/bash/login/profile/profile_config_template_wsl.bash ~/.custom_profile.bash

vim ~/.custom_profile.bash
```



# Configurar el profile del root (opcional)

1. Descargar el repositorio para el usuario `root`
   - Se recomienda que solo use clonación o actualización superficial.
     - Excepción cuando usa a root para actualizar el repositorio.
   - Para ver como actualizar una rama local con su respectiva rama remota de un repositorio véase  [[05. Actualizar rama remota]].

```bash
#1. Ingrese como root
su -

#2. Clonacion del repositorio

# Opc1: Clonacion completa de la rama por defecto repositorio
git clone https://github.com/lestebanpc/dotfiles.git ~/.files

# Opc2: Clonacion superficial de la rama por defecto del repositorio (solo el ultimo commit)
git clone --depth=1 https://github.com/lestebanpc/dotfiles.git ~/.files


#3. Si ya existe el repositorio y desea actualizarlo
cd ~/.files

# Opc1: Actualizacion completa
git pull main origin

# Opc2: Actualizacion completa
git fetch origin main
git merge FETCH_HEAD

# Opc3: Actualizacion superficial (solo el ultimo commit)
git fetch --depth=1 origin main
git reset --hard FETCH_HEAD
```


2. Modifique el *profile setup* del usuario `root` (opcional)
   - Usualmente no se instala con el usuario root, pero puede cambiarlo con fines de homologar la rutas entre el usuario `lucianoepc` y `root`.
   - Si cambio la ruta de los folders donde se almacenara los programas, deberá modificar el archivo de configuración

```bash
# Parametros del instalador del profile y otros
cp ~/.files/shell/bash/bin/linuxsetup/lib/setup_config_template.bash ~/.files/shell/bash/bin/linuxsetup/.setup_config.bash

vim ~/.files/shell/bash/bin/linuxsetup/.setup_config.bash
```

```bash
#Folder base donde se almacena el comando y sus archivos afines.
# . . . . . . . . .
#g_lnx_base_path=''

# . . . . . . . . .
# . . . . . . . . .

#Folder base, generados solo para Linux WSL, donde se almacena el programas, comando y afines usados por Windows.
# . . . . . . . . .
g_win_base_path='/mnt/d/apps'
```


3. Configurar el profile del usuario `root` como editor.

```bash
# Iniciar el instalador
~/.files/shell/bash/bin/linuxsetup/04_install_profile.bash

#Escoger la opcion 'g'
```



4. Personalizar configuración del *profile* (opcional):
   - Si se instala en *WSL* o *Distrobox*, el instalador copia un archivo `~/.custom_profile.bash` con parámetros iniciales el cual puede modificar si lo desea.
   - Si el equipo es para uso personal y tiene acceso a la red local, establezca:

```bash
cp ~/.files/shell/bash/login/profile/profile_config_template_basic_local.bash ~/.custom_profile.bash
#cp ~/.files/shell/bash/login/profile/profile_config_template_basic_remote.bash ~/.custom_profile.bash
#cp ~/.files/shell/bash/login/profile/profile_config_template_distrobox.bash ~/.custom_profile.bash
#cp ~/.files/shell/bash/login/profile/profile_config_template_wsl.bash ~/.custom_profile.bash

vim ~/.custom_profile.bash
```



# Otras configuraciones


## Configuración de GIT


1. Las opciones por defecto del usuario para git está definido en el archivo `~/.gitconfig`.
   - Esta es un enlace simbólico de `~/.files/etc/git/root_gitconfig_linux.toml`

2. Validar y/o verificar los archivos generados

```powershell
bat ~/.gitconfig
bat ~/.config/git/user_main.toml
bat ~/.config/git/user_mywork.toml
```

3. Configurar parámetros usuario, cambiando

```bash
vim ~/.config/git/user_main
```

```toml
#Usuario personal
[user]
    email = lestebanpc@gmail.com
    name  = Mi name

#. . . . . . . . . . . . . . . .
#. . . . . . . . . . . . . . . .

#Usuario de work "mywork"
#[includeIf "gitdir:~/code/mywork/"]
#    path = work_mywork.toml
```

```bash
mv ~/.config/git/user_mywork.toml ~/.config/git/user_progrez.toml
vim ~/.config/git/user_prograz.toml
```

4. Valida los parámetros globales/usuario están correctamente configurados

```bash
git config --global -l
git config -l
```

```bash
user.email=lestebanpc@gmail.com
user.name=Esteban Peña
core.editor=vim
core.autocrlf=input
init.defaultBranch=main
#. . . . . . . . . . . . . . . .
#. . . . . . . . . . . . . . . .
#. . . . . . . . . . . . . . . .
```




## Configuración del cliente SSH

Se debe ...
