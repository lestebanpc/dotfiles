@echo off
setlocal enabledelayedexpansion

:: Configurar colores
set "color_reset=[0m"
set "color_gray=[90m"
set "color_red=[31m"

:: Función de ayuda
if "%1"=="-h" (
    call :show_usage
    exit /b 0
)

:: 0. Validaciones previas
where wezterm >nul 2>&1
if %errorlevel% neq 0 (
    echo [%color_red%ERROR%color_reset%] WezTerm no está instalado o no está en el PATH.
    exit /b 1
)

:: 1. Buscar file.exe usando YAZI_FILE_ONE primero
set "git_file_exe="
if defined YAZI_FILE_ONE (
    if exist "%YAZI_FILE_ONE%" (
        set "git_file_exe=%YAZI_FILE_ONE%"
        goto :found_file
    ) else (
        echo [%color_red%ADVERTENCIA%color_reset%] La variable YAZI_FILE_ONE está definida pero el archivo no existe: "%YAZI_FILE_ONE%"
    )
)

:found_file
if not defined git_file_exe (
    echo [%color_red%ERROR%color_reset%] No se encontró file.exe.
    echo Este comando es requerido para determinar el tipo de archivo.
    echo Soluciones:
    echo   1. Configure la variable YAZI_FILE_ONE con la ruta correcta a file.exe
    echo      Ejemplo: set YAZI_FILE_ONE=C:\Program Files\Git\usr\bin\file.exe
    echo   2. O instale Git for Windows que incluye file.exe
    echo   3. O agregue la ubicación de file.exe al PATH del sistema
    exit /b 1
)

:: 2. Procesar opciones
set "open_in_editor=0"
set "arg_path="

:arg_loop
if "%1"=="" goto :process_args
if "%1"=="-e" (
    set "open_in_editor=1"
    shift
    goto :arg_loop
)
if "%1"=="-h" (
    call :show_usage
    exit /b 0
)
if "%1"=="-*" (
    echo [%color_red%ERROR%color_reset%] Opción "%color_gray%%1%color_reset%" no es válida.
    call :show_usage
    exit /b 1
)
set "arg_path=%1"
shift
goto :arg_loop

:process_args
:: 3. Leer argumentos
if "%arg_path%"=="" (
    echo [%color_red%ERROR%color_reset%] Debe especificar como argumento la ruta de un folder o archivo.
    call :show_usage
    exit /b 1
)

:: 4. Obtener ruta absoluta
set "full_path="
if exist "%arg_path%\" (
    :: Es un directorio
    set "full_path=%arg_path%"
) else (
    :: Es un archivo o ruta relativa
    if exist "%arg_path%" (
        set "full_path=%arg_path%"
    ) else (
        :: Intentar resolver ruta relativa
        set "full_path=%cd%\%arg_path%"
    )
)

if not exist "%full_path%" (
    echo [%color_red%ERROR%color_reset%] El argumento "%color_gray%%arg_path%%color_reset%" no es una ruta válida.
    exit /b 1
)

:: 5. Determinar si es folder o archivo
set "is_folder=0"
set "working_dir="
set "filename="

if exist "%full_path%\" (
    set "is_folder=1"
    set "working_dir=%full_path%"
    set "filename="
) else (
    set "is_folder=0"
    for %%F in ("%full_path%") do (
        set "working_dir=%%~dpF"
        set "filename=%%~nxF"
    )
)

:: 6. Si es archivo y se quiere abrir en editor, verificar si es texto
set "is_text_file=0"
if %is_folder%==0 if %open_in_editor%==1 (
    :: Usar file.exe para determinar el tipo MIME
    for /f "tokens=2 delims=:" %%T in ('"%git_file_exe%" -i "%full_path%" 2^>nul') do (
        set "mime_type=%%T"
        if "%%T"==" text/plain" set "is_text_file=1"
        if "%%T"==" inode/x-empty" set "is_text_file=1"
    )
)

:: 7. Verificar si es WezTerm
if not defined WEZTERM_UNIX_SOCKET (
    echo [%color_red%ERROR%color_reset%] Este script solo funciona dentro de WezTerm.
    exit /b 1
)

:: 8. Crear nuevo tab en WezTerm - SIEMPRE usar spawn --cwd para ambos casos
set "pane_id="
if %is_folder%==1 (
    :: Es un directorio - abrir terminal normal
    wezterm cli spawn --cwd "%working_dir%"
) else (
    :: Es un archivo - abrir terminal normal primero
    for /f "delims=" %%P in ('wezterm cli spawn --cwd "%working_dir%"') do set "pane_id=%%P"

    :: Si es un archivo de texto y se quiere abrir en editor, enviar comando
    if %open_in_editor%==1 if %is_text_file%==1 (
        set "editor=%EDITOR%"
        if not defined editor set "editor=vim"

        :: Enviar comando para abrir el editor en el pane creado
        wezterm cli send-text --pane-id "%pane_id%" --no-paste "%editor% \"%filename%\""$
        wezterm cli send-text --pane-id "%pane_id%" --no-paste $
    )
)

exit /b 0

:: Función de ayuda
:show_usage
echo Usage: open_new_termtab [options] folder_or_file
echo.
echo Crea una nueva ventana/pestaña en la terminal actual donde el directorio de trabajo
echo es el folder enviado como argumento (si el argumento es un archivo se considera el folder donde está el archivo).
echo.
echo Actualmente solo está soportado para el emulador de terminal: WezTerm
echo.
echo Ejemplos:
echo   open_new_termtab ../
echo   open_new_termtab C:\Users\usuario\code
echo   open_new_termtab C:\Users\usuario\code\mynote.txt
echo   open_new_termtab -e C:\Users\usuario\code\mynote.txt
echo.
echo Options:
echo   -e     Si es un archivo abre el archivo con el editor %%EDITOR%%.
echo   -h     Mostrar esta ayuda.
echo.
echo Arguments:
echo   ^<file_or_folder^> Ruta del folder o archivo.
exit /b 0
