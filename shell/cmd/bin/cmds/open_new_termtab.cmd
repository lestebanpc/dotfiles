@echo off
setlocal enabledelayedexpansion

:: Configurar colores para mejor legibilidad
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set "DEL=%%a"
  set "ESC=%%b"
)

:: Definir colores ANSI
set "color_reset=%ESC%[0m"
set "color_gray=%ESC%[90m"
set "color_red=%ESC%[31m"

:: Función de ayuda
if "%1"=="-h" (
    call :show_usage
    exit /b 0
)

:: 0. Validaciones previas

:: Verificar si estamos en WezTerm usando TERM_PROGRAM
if not "%TERM_PROGRAM%"=="WezTerm" (
    echo [%color_red%ERROR%color_reset%] Este script solo funciona dentro de WezTerm.
    echo Variable TERM_PROGRAM actual: "%TERM_PROGRAM%"
    exit /b 1
)

:: Verificar que wezterm CLI esté disponible
where wezterm >nul 2>&1
if %errorlevel% neq 0 (
    echo [%color_red%ERROR%color_reset%] WezTerm CLI no está instalado o no está en el PATH.
    exit /b 1
)

:: Buscar file.exe en varios lugares posibles
set "git_file_exe="

:: 1. Intentar usar la variable YAZI_FILE_ONE si está definida
if defined YAZI_FILE_ONE (
    if exist "%YAZI_FILE_ONE%" (
        set "git_file_exe=%YAZI_FILE_ONE%"
        goto :file_found
    ) else (
        echo [%color_gray%INFO%color_reset%] La variable YAZI_FILE_ONE está definida pero el archivo no existe.
    )
)

:: 2. Buscar file.exe en el PATH usando where
where file.exe >nul 2>&1
if %errorlevel%==0 (
    for /f "delims=" %%F in ('where file.exe') do (
        set "git_file_exe=%%F"
        goto :file_found
    )
)

:: 3. Buscar en ubicaciones comunes de Git for Windows
set "common_paths=C:\Program Files\Git\usr\bin\file.exe;C:\Program Files (x86)\Git\usr\bin\file.exe"
for %%P in (%common_paths%) do (
    if exist "%%P" (
        set "git_file_exe=%%P"
        goto :file_found
    )
)

:: Si no se encontró file.exe
echo [%color_red%ERROR%color_reset%] No se encontró file.exe.
echo Este comando es requerido para determinar el tipo de archivo.
echo Soluciones:
echo   1. Configure la variable YAZI_FILE_ONE con la ruta correcta a file.exe
echo      Ejemplo: set YAZI_FILE_ONE=C:\Program Files\Git\usr\bin\file.exe
echo   2. O instale Git for Windows que incluye file.exe
echo   3. O agregue la ubicación de file.exe al PATH del sistema
exit /b 1

:file_found

:: 1. Procesar opciones
set "show_info_file=0"
set "use_default_work_dir=0"
set "arg_path="


:arg_loop
if "%1"=="" goto :process_args

if "%1"=="-e" (
    set "show_info_file=1"
    shift
    goto :arg_loop
)

if "%1"=="-w" (
    set "use_default_work_dir=1"
    shift
    goto :arg_loop
)

if "%1"=="-h" (
    call :show_usage
    exit /b 0
)

if "%1:~0,1%"=="-" (
    echo [%color_red%ERROR%color_reset%] Opción "%color_gray%%1%color_reset%" no es válida.
    call :show_usage
    exit /b 1
)

set "arg_path=%1"
shift
goto :arg_loop


:process_args
:: 2. Validar que se haya proporcionado una ruta
if "%arg_path%"=="" (
    echo [%color_red%ERROR%color_reset%] Debe especificar como argumento la ruta de un folder o archivo.
    call :show_usage
    exit /b 1
)

:: 3. Obtener ruta absoluta
set "full_path="
if exist "%arg_path%" (
    :: La ruta existe (archivo o directorio)
    for %%F in ("%arg_path%") do (
        set "full_path=%%~fF"
    )
) else (
    echo [%color_red%ERROR%color_reset%] El argumento "%color_gray%%arg_path%%color_reset%" no es una ruta válida.
    exit /b 1
)

:: 4. Determinar si es folder o archivo
set "is_folder=0"

:: Asegurar que full_path no tenga barra final
if "!full_path:~-1!"=="\" set "full_path=!full_path:~0,-1!"

if exist "%full_path%\" (
    set "is_folder=1"

) else (
    set "is_folder=0"
)

:: 5. Si es archivo
set "file_path="
set "is_text_file=0"
set "working_dir="
set "working_dir=%full_path%"

if !is_folder!==0 (

	:: Determinar si el archvio es texto o binario
    if !show_info_file!==1 (

        :: Usando un archivo temporal para capturar la salida
        set "temp_file=%temp%\file_output_%random%.txt"

        :: Ejecutar file.exe y guardar la salida en un archivo temporal
        "!git_file_exe!" -i "%full_path%" > "!temp_file!" 2>&1

        :: Leer la primera línea del archivo temporal
        set "mime_output="
        < "!temp_file!" set /p mime_output=

        :: Limpiar el archivo temporal
        del "!temp_file!" >nul 2>&1

        :: Depuración: mostrar lo que se capturó
        echo [%color_gray%DEBUG%color_reset%] Salida de file.exe: "!mime_output!"

        if "!mime_output!"=="" (
            echo [%color_gray%INFO%color_reset%] No se pudo determinar el tipo MIME del archivo.
        ) else (
            :: Método más robusto para verificar si es texto
            echo !mime_output! | findstr /i "text/plain" >nul && set "is_text_file=1"
            echo !mime_output! | findstr /i "inode/x-empty" >nul && set "is_text_file=1"
            echo !mime_output! | findstr /i "text/x-shellscript" >nul && set "is_text_file=1"
            echo !mime_output! | findstr /i "application/x-empty" >nul && set "is_text_file=1"

            :: También verificar extensiones comunes de archivos de texto
            if !is_text_file!==0 (
                echo !file_path! | findstr /i "\.\(txt\|bat\|cmd\|bash\|sh\|ps1\|py\|js\|html\|css\|xml\|json\|md\|yml\|yaml\|ini\|cfg\|conf\|log\)$" >nul && set "is_text_file=1"
            )
        )

        :: Depuración: mostrar resultado
        echo [%color_gray%DEBUG%color_reset%] is_text_file: !is_text_file!
    )

    if !use_default_work_dir!==0 (

        :: Obtener la ruta dse trabajo del panel y la ruta/nombre del archivo
        for %%F in ("%full_path%") do (
            set "working_dir=%%~dpF"
            set "file_path=%%~nxF"
        )

        :: Asegurar que working_dir no tenga barra final
        if "!working_dir:~-1!"=="\" set "working_dir=!working_dir:~0,-1!"

    ) else (
        set "file_path=%full_path%"
    )

)

:: 6. Crear nuevo tab en WezTerm
if !is_folder!==1 (

    :: Es un directorio - abrir terminal normal
    echo [%color_gray%INFO%color_reset%] Abriendo nuevo tab en: !working_dir!
    wezterm cli spawn --cwd "!working_dir!"

) else (

    :: Es un archivo
    echo [%color_gray%INFO%color_reset%] Archivo            : !file_path!
    echo [%color_gray%INFO%color_reset%] Directorio         : !working_dir!
    echo [%color_gray%INFO%color_reset%] Current panel ID   : !WEZTERM_PANE!

    if !use_default_work_dir!==1 (

        set "working_dir="
        set "l_data="

        :: Obtener el directorio de trabajo del panel actual de Wezterm
        for /f "delims=" %%a in ('wezterm cli list --format json ^| jq -r --arg pid "!WEZTERM_PANE!" ".[] | select(.pane_id == ($pid | tonumber)) | .cwd"') do (
            set "l_data=%%a"
        )

        :: Verificar si l_data está vacío
        if "!l_data!"=="" (
            exit /b 2
        )
        echo [%color_gray%INFO%color_reset%] Current WorkingDir : !l_data!

        :: Extraer la parte del directorio de la URL (similar a sed)
        if "!l_data:~0,7!"=="file://" (

            set "str=!l_data:file://=!"
            if "!str:~0,1!"=="/" (
                set "working_dir=!str:~1!"
            ) else (
                for /f "delims=/ tokens=1*" %%a in ("!str!") do (
                    set "working_dir=%%b"
                )
            )

        )

        :: Verificar si l_data está vacío
        if "!working_dir!"=="" (
            exit /b 2
        )
        echo [%color_gray%INFO%color_reset%] Current WorkingDir : !working_dir!

    )

    :: Crear nuevo tab en el directorio del archivo
    set "pane_id="
    for /f "tokens=*" %%P in ('wezterm cli spawn --cwd "!working_dir!" 2^>nul') do set "pane_id=%%P"

    if not defined pane_id (
        echo [%color_red%ERROR%color_reset%] No se pudo obtener el ID del panel de WezTerm.
        exit /b 2
    )

    echo [%color_gray%INFO%color_reset%] New panel ID       : !pane_id!

    :: Si se debe mostrar informacion del archivo
    if !show_info_file!==1 (

        if !is_text_file!==1 (

            set "editor=!EDITOR!"
            if not defined editor set "editor=vim"

            echo [%color_gray%INFO%color_reset%] Abriendo archivo con: !editor!

            :: Enviar comando a la pseudo-terminal del nuevo tab creado
            wezterm cli send-text --pane-id "!pane_id!" --no-paste "!editor! '!file_path!'"

        ) else (

            echo [%color_gray%INFO%color_reset%] Mostrando informacion del archivo

            :: Enviar comando a la pseudo-terminal del nuevo tab creado
            wezterm cli send-text --pane-id "!pane_id!" --no-paste "dir '!file_path!'"

        )


    )

)

exit /b 0

:: Función de ayuda
:show_usage
echo Usage: open_new_termtab.cmd [options] folder_or_file
echo.
echo Crea una nueva ventana/tab en la terminal actual
echo - El directorio de trabajo usado por la nueva ventana/panel es:
echo   - Si el argumento es un folder, el directorio de trabajo siempre es este folder.
echo   - Si el argumento es un archivo:
echo     - Si se especifica la opcion '-w', se usara el directorio de trabajo del panel actual.
echo     - Si no se especifica la opcion '-w', se usara el directorio donde se encuentra el archivo.
echo Los emuladores de terminal soportados son:
echo - WezTerm
echo.
echo Ejemplos usando shell CMD:
echo   open_new_termtab.cmd ../
echo   open_new_termtab.cmd C:\Users\usuario\code
echo   open_new_termtab.cmd C:\Users\usuario\code\mynote.txt
echo   open_new_termtab.cmd -e C:\Users\usuario\code\mynote.txt
echo   open_new_termtab.cmd -w C:\Users\usuario\code\mynote.txt
echo   open_new_termtab.cmd -e -w C:\Users\usuario\code\mynote.txt
echo.
echo Ejemplos usando cualquier shell:
echo   cmd /c "%USERPROFILE%\.files\shell\cmd\bin\cmds\open_new_termtab.cmd" -e D:\Users\lucpea\.files\shell\bash\bin\cmds\open_new_termtab.bash
echo.
echo Options:
echo   -e     Si es un archivo, si es un archivo de texto lo abre con el editor %EDITOR%, si es binario muestra la informacion del archivo.
echo   -w     Si es un archivo, el nuevo tab usara como directorio de trabajo el del panel actual.
echo          Si no se especifica y es un archivo, se usara como directorio de trabajo el folder donde se ubica el archivo.
echo.
echo Arguments:
echo   ^<file_or_folder^> Ruta del folder o archivo.
exit /b 0
