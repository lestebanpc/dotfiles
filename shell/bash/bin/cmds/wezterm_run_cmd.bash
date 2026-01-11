#!/bin/bash

# Constantes de colores
g_color_reset="\x1b[0m"
g_color_green1="\x1b[32m"
g_color_gray1="\x1b[90m"
g_color_cian1="\x1b[36m"
g_color_yellow1="\x1b[33m"
g_color_red1="\x1b[31m"
g_color_blue1="\x1b[34m"


# Un tab_id es similar a una ventana tmux
# Una ventaan wezterm, es simular a una instancia ventaan dentro de un misma ventana fisica del emulador de terminal

# ID del tab y el workspace del panel actual
# workspace
#wezterm cli list --format json | jq -r --arg pane_id "$WEZTERM_PANE" '.[] | select(.pane_id == ($pane_id|tonumber)) | .tab_id'

# Arrrglo de paneles disponibles en el mismo workspace y solo representan a fs local  (dominio local o socket unix o exec domian)
# "cwd": "file://fenix/home/lucianoepc/.ssh/"i (local domain),
# "cwd": "file:///home/lucianoepc/.ssh/" (exec domain pwsh)
# ssh domain no genera un tty_name (uno local)
# un workspace diferente tiene su ventana id diferentes por mas que fisicamente sean un emulador de terminal
#wezterm cli list --format json | jq '[ .[] | select((.title | contains("bash")) and (.tty_name != null)) | { window_id, tab_id, pane_id } ]'

# Verifica si un panel está disponible (no ejecutando programas como btop, htop, etc.)
is_pane_available() {
    local pane_id="$1"

    # Obtener información del panel en formato JSON
    local pane_info
    pane_info=$(wezterm cli list --format json 2>/dev/null | jq -r --arg pane_id "$pane_id" '.[] | select(.pane_id == ($pane_id|tonumber)) | .foreground_processes[].name')

    # Si no hay procesos en primer plano, el panel está disponible
    if [ -z "$pane_info" ]; then
        return 0
    fi

    # Lista de programas que consideramos "ocupados"
    local busy_programs=("btop" "htop" "nvim" "vim" "tmux" "ssh" "docker" "python" "node" "less" "more" "man" "top")

    # Verificar si el panel está ejecutando algún programa ocupado
    for busy_program in "${busy_programs[@]}"; do
        if echo "$pane_info" | grep -q "\<$busy_program\>"; then
            return 1
        fi
    done

    return 0
}

# Obtiene un panel disponible en la ventana actual
get_available_pane_id() {
    local current_pane_id
    current_pane_id=$(wezterm cli get-active-pane-id 2>/dev/null)

    if [ -z "$current_pane_id" ]; then
        return 1
    fi

    # Obtener todos los paneles de la ventana actual en formato JSON
    local window_id
    window_id=$(wezterm cli list --format json 2>/dev/null | jq -r '.active_window_id')

    if [ -z "$window_id" ] || [ "$window_id" = "null" ]; then
        return 1
    fi

    # Listar paneles de la ventana actual
    local pane_ids
    pane_ids=$(wezterm cli list --format json 2>/dev/null | jq -r --arg window_id "$window_id" '.[] | select(.window_id == ($window_id|tonumber)) | .pane_id')

    # Buscar un panel disponible que no sea el actual
    for pane_id in $pane_ids; do
        if [ "$pane_id" != "$current_pane_id" ]; then
            if is_pane_available "$pane_id"; then
                echo "$pane_id"
                return 0
            fi
        fi
    done

    return 1
}

# Crea un panel horizontal de 20% de altura
create_horizontal_pane() {
    local percent=${1:-20}

    # Crear panel horizontal (arriba) con el porcentaje especificado
    wezterm cli split-pane --top --percent "$percent" 2>/dev/null

    # Obtener el ID del nuevo panel creado (el último en la lista)
    local new_pane_id
    new_pane_id=$(wezterm cli list --format json 2>/dev/null | jq -r '.panes[-1].pane_id')

    if [ -z "$new_pane_id" ] || [ "$new_pane_id" = "null" ]; then
        return 1
    fi

    echo "$new_pane_id"
    return 0
}

# Ejecuta un comando en un panel específico
execute_command_in_pane() {
    local pane_id="$1"
    local command="$2"

    # Enviar el comando al panel
    wezterm cli send-text --pane-id "$pane_id" "$command" 2>/dev/null
    wezterm cli send-text --pane-id "$pane_id" $'\n' 2>/dev/null
}

_usage() {
cat <<EOF
Usage: wezterm_run_cmd [options] -- [command]
> Busca un panel disponible en la ventana actual de Wezterm (que no esté ejecutando programas como btop, htop, etc.).
> Si no encuentra un panel disponible, crea un panel horizontal de 20% de altura.
> Ejecuta el comando especificado en el panel encontrado/creado.
> Siempre mantiene enfocado el panel actual.

Ejemplos:
$ wezterm_run_cmd -- 'echo "Hola mundo"'
$ wezterm_run_cmd -h 30 -- 'ls -la'
$ wezterm_run_cmd -- echo Hola mundo

Options:
-h <percent>  Porcentaje de altura para el nuevo panel horizontal (por defecto: 20)
--help        Muestra esta ayuda
EOF
}

# -------------------------------------------------------------------------------------
# Main code
# -------------------------------------------------------------------------------------

# Validar si tenemos jq instalado
if ! command -v jq &> /dev/null; then
    printf '[%bERROR%b] El comando "jq" no está instalado. Por favor, instálalo primero.\n' "$g_color_red1" "$g_color_reset"
    exit 1
fi

# Variables por defecto
g_height=20
g_command_args=()

# Procesar opciones
while [ $# -gt 0 ]; do
    case "$1" in
        -h)
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                printf '[%bERROR%b] Valor de la opción "%b%s%b" es inválido: %b%s%b\n' "$g_color_red1" "$g_color_reset" \
                    "$g_color_gray1" "-h" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                _usage
                exit 1
            fi
            if [ "$2" -lt 10 ] || [ "$2" -gt 90 ]; then
                printf '[%bERROR%b] Valor de la opción "%b%s%b" debe estar entre [10, 90]: %b%s%b\n' "$g_color_red1" "$g_color_reset" \
                    "$g_color_gray1" "-h" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                _usage
                exit 1
            fi
            g_height="$2"
            shift 2
            ;;
        --help)
            _usage
            exit 0
            ;;
        --)
            shift
            # Solo continuar si se encuentra la opción '--'
            break
            ;;
        -*)
            printf '[%bERROR%b] Opción "%b%s%b" no es válida.\n' "$g_color_red1" "$g_color_reset" \
                "$g_color_gray1" "$1" "$g_color_reset"
            _usage
            exit 1
            ;;
        *)
            # Si no es una opción reconocida y no hemos visto '--', es un error
            if [ ${#g_command_args[@]} -eq 0 ] && [ "$1" != "--" ]; then
                printf '[%bERROR%b] Argumento "%b%s%b" no es esperado antes de la opción --.\n' "$g_color_red1" "$g_color_reset" \
                    "$g_color_gray1" "$1" "$g_color_reset"
                _usage
                exit 1
            fi
            break
            ;;
    esac
done

# Argumentos restantes después de "--" (comando a ejecutar)
g_command_args=("$@")
if [ ${#g_command_args[@]} -le 0 ]; then
    printf '[%bERROR%b] Debe especificar un comando a ejecutar.\n' "$g_color_red1" "$g_color_reset"
    _usage
    exit 1
fi

# Obtener el comando a ejecutar
g_command=''
if [ ${#g_command_args[@]} -eq 1 ]; then
    g_command="${g_command_args[0]}"
else
    # Si hay múltiples argumentos, unirlos con espacios
    g_command="${g_command_args[*]}"
fi

# Guardar el panel actual para mantener el foco
current_pane_id=$(wezterm cli list --format json | jq -r '.[] | select(.is_active == true) | .pane_id')
#current_pane_id=$WEZTERM_PANE
if [ -z "$current_pane_id" ]; then
    printf '[%bERROR%b] No se pudo obtener el ID del panel actual. ¿Estás ejecutando esto dentro de Wezterm?\n' "$g_color_red1" "$g_color_reset"
    exit 1
fi

# Intentar obtener un panel disponible
target_pane_id=$(get_available_pane_id)

# Si no hay panel disponible, crear uno nuevo
if [ -z "$target_pane_id" ]; then
    printf '[%bINFO%b] No se encontró panel disponible. Creando nuevo panel horizontal con %d%% de altura...\n' "$g_color_blue1" "$g_color_reset" "$g_height"
    target_pane_id=$(create_horizontal_pane "$g_height")
    if [ -z "$target_pane_id" ]; then
        printf '[%bERROR%b] No se pudo crear el nuevo panel.\n' "$g_color_red1" "$g_color_reset"
        exit 1
    fi
else
    printf '[%bINFO%b] Usando panel disponible: %s\n' "$g_color_green1" "$g_color_reset" "$target_pane_id"
fi

# Ejecutar el comando en el panel objetivo
execute_command_in_pane "$target_pane_id" "$g_command"

# Siempre mantener enfocado el panel actual
wezterm cli activate-pane --pane-id "$current_pane_id" 2>/dev/null

printf '[%bSUCCESS%b] Comando ejecutado en el panel %s\n' "$g_color_green1" "$g_color_reset" "$target_pane_id"
exit 0
