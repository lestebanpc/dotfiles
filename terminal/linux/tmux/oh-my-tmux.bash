#!/bin/bash
# Modificacion de 'oh-my-tmux' de 'Gregory Pakosz' (obtenido de https://github.com/gpakosz/.tmux)

# exit the script if any statement returns a non-true return value
set -e

unset GREP_OPTIONS
export LC_NUMERIC=C
(set +H 2>/dev/null) && set +H || true

if ! printf '' | sed -E 's///' 2>/dev/null; then
  if printf '' | sed -r 's///' 2>/dev/null; then
    sed () {
      n=$#; while [ "$n" -gt 0 ]; do arg=$1; shift; case $arg in -E*) arg=-r${arg#-E};; esac; set -- "$@" "$arg"; n=$(( n - 1 )); done
      command sed "$@"
    }
  fi
fi

_uname_s=$(uname -s)

_tmux_version=$(tmux -V | awk '{gsub(/[^0-9.]/, "", $2); print ($2+0) * 100}')

_is_true() {
  [ x"$1" = x"true" ] || [ x"$1" = x"yes" ] || [ x"$1" = x"1" ]
}

_is_enabled() {
  [ x"$1" = x"enabled" ]
}

_is_disabled() {
  [ x"$1" = x"disabled" ]
}

_circled() {
  circled_digits='⓪ ① ② ③ ④ ⑤ ⑥ ⑦ ⑧ ⑨ ⑩ ⑪ ⑫ ⑬ ⑭ ⑮ ⑯ ⑰ ⑱ ⑲ ⑳'
  if [ "$1" -le 20 ] 2>/dev/null; then
    i=$(( $1 + 1 ))
    eval set -- "$circled_digits"
    eval echo "\${$i}"
  else
    echo "$1"
  fi
}

_decode_unicode_escapes() {
  printf '%s' "$*" | perl -CS -pe 's/(\\u([0-9A-Fa-f]{1,4})|\\U([0-9A-Fa-f]{1,8}))/chr(hex($2.$3))/eg' 2>/dev/null
}

if command -v pkill > /dev/null 2>&1; then
  _pkillf() {
    pkill -f "$@" || true
  }
else
  case "$_uname_s" in
    *CYGWIN*)
      _pkillf() {
        while IFS= read -r pid; do
          kill "$pid" || true
        done  << EOF
$(grep -Eao "$@" /proc/*/cmdline | xargs -0 | sed -E -n 's,/proc/([0-9]+)/.+$,\1,pg')
EOF
      }
      ;;
    *)
      _pkillf() {
        while IFS= read -r pid; do
          kill "$pid" || true
        done  << EOF
$(ps -x -o pid= -o command= | grep -E "$@" | cut -d' ' -f1)
EOF
      }
      ;;
  esac
fi

_maximize_pane() {
  current_session=${1:-$(tmux display -p '#{session_name}')}
  current_pane=${2:-$(tmux display -p '#{pane_id}')}

  dead_panes=$(tmux list-panes -s -t "$current_session" -F '#{pane_dead} #{pane_id} #{pane_start_command}' | grep -E -o '^1 %.+maximized.+$' || true)
  restore=$(printf "%s" "$dead_panes" | sed -n -E -e "s/^1 $current_pane .+maximized.+'(%[0-9]+)'\"?$/tmux swap-pane -s \1 -t $current_pane \; kill-pane -t $current_pane/p"\
                                           -e "s/^1 (%[0-9]+) .+maximized.+'$current_pane'\"?$/tmux swap-pane -s \1 -t $current_pane \; kill-pane -t \1/p")

  if [ -z "$restore" ]; then
    [ "$(tmux list-panes -t "$current_session:" | wc -l | sed 's/^ *//g')" -eq 1 ] && tmux display "Can't maximize with only one pane" && return
    current_pane_height=$(tmux display -t "$current_pane" -p "#{pane_height}")
    info=$(tmux new-window -t "$current_session:" -F "#{session_name}:#{window_index}.#{pane_id}" -P "maximized... 2>/dev/null & tmux setw -t \"$current_session:\" remain-on-exit on; printf \"\\033[\$(tput lines);0fPane has been maximized, press <prefix>+ to restore\n\" '$current_pane'")
    session_window=${info%.*}
    new_pane=${info#*.}

    retry=1000
    while [ x"$(tmux list-panes -t "$session_window" -F '#{session_name}:#{window_index}.#{pane_id} #{pane_dead}' 2>/dev/null)" != x"$info 1" ] && [ "$retry" -ne 0 ]; do
      sleep 0.1
      retry=$((retry - 1))
    done
    if [ "$retry" -eq 0 ]; then
      tmux display 'Unable to maximize pane'
    fi

    tmux setw -t "$session_window" remain-on-exit off \; swap-pane -s "$current_pane" -t "$new_pane"
  else
    $restore || tmux kill-pane
  fi
}

_toggle_mouse() {
  old=$(tmux show -gv mouse)
  new=""

  if [ "$old" = "on" ]; then
    new="off"
  else
    new="on"
  fi

  tmux set -g mouse $new
}

_battery_info() {
  count=0
  charge=0
  case "$_uname_s" in
    *Darwin*)
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        discharging=$(printf '%s' "$line" | grep -qi "discharging" && echo "true" || echo "false")
        percentage=$(printf '%s' "$line" | grep -E -o '[0-9]+%' || echo "0%")
        charge=$(awk -v charge="$charge" -v percentage="${percentage%%%}" 'BEGIN { print charge + percentage / 100 }')
        count=$((count + 1))
      done  << EOF
$(pmset -g batt | grep 'InternalBattery')
EOF
      ;;
    *Linux*)
      while IFS= read -r batpath; do
        [ -z "$batpath" ] && continue
        grep -i -q device "$batpath/scope" 2> /dev/null && continue

        discharging=$(grep -qi "discharging" "$batpath/status" && echo "true" || echo "false")
        bat_capacity="$batpath/capacity"
        if [ -r "$bat_capacity" ]; then
          charge=$(awk -v charge="$charge" -v capacity="$(cat "$bat_capacity")" 'BEGIN { print charge + (capacity > 100 ? 100 : capacity) / 100 }')
        else
          bat_energy_full="$batpath/energy_full"
          bat_energy_now="$batpath/energy_now"
          if [ -r "$bat_energy_full" ] && [ -r "$bat_energy_now" ]; then
            charge=$(awk -v charge="$charge" -v energy_now="$(cat "$bat_energy_now")" -v energy_full="$(cat "$bat_energy_full")" 'BEGIN { print charge + energy_now / energy_full }')
          fi
        fi
        count=$((count + 1))
      done  << EOF
$(find /sys/class/power_supply -maxdepth 1 -iname '*bat*')
EOF
      ;;
    *CYGWIN*|*MSYS*|*MINGW*)
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        discharging=$(printf '%s' "$line" | awk '{ s = ($1 == 1) ? "true" : "false"; print s }')
        charge=$(printf '%s' "$line" | awk -v charge="$charge" '{ print charge + $2 / 100 }')
        count=$((count + 1))
      done  << EOF
$(wmic path Win32_Battery get BatteryStatus, EstimatedChargeRemaining 2> /dev/null | tr -d '\r' | tail -n +2 || true)
EOF
      ;;
    *OpenBSD*)
      for batid in 0 1 2; do
        sysctl -n "hw.sensors.acpibat$batid.raw0" 2>&1 | grep -q 'not found' && continue
        discharging=$(sysctl -n "hw.sensors.acpibat$batid.raw0" | grep -q 1 && echo "true" || echo "false")
        if sysctl -n "hw.sensors.acpibat$batid" | grep -q amphour; then
          charge=$(awk -v charge="$charge" -v remaining="$(sysctl -n hw.sensors.acpibat$batid.amphour3 | cut -d' ' -f1)" -v full="$(sysctl -n hw.sensors.acpibat$batid.amphour0 | cut -d' ' -f1)" 'BEGIN { print charge + remaining / full }')
        else
          charge=$(awk -v charge="$charge" -v remaining="$(sysctl -n hw.sensors.acpibat$batid.watthour3 | cut -d' ' -f1)" -v full="$(sysctl -n hw.sensors.acpibat$batid.watthour0 | cut -d' ' -f1)" 'BEGIN { print charge + remaining / full }')
        fi
        count=$((count + 1))
      done
      ;;
  esac
  [ "$count" -ne 0 ] && charge=$(awk -v charge="$charge" -v count="$count" 'BEGIN { print charge / count }') || true
}

_battery_status() {
  _battery_info
  if [ "$charge" = 0 ]; then
    tmux set -ug '@battery_status'
    return
  fi

  battery_status_charging=$1
  battery_status_discharging=$2
  if [ x"$discharging" = x"true" ]; then
    battery_status="$battery_status_discharging"
  else
    battery_status="$battery_status_charging"
  fi

  tmux set -g '@battery_status' "$battery_status"
}

_battery_bar() {
  _battery_info
  if [ "$charge" = 0 ]; then
    tmux  set -ug '@battery_bar'     \;\
          set -ug '@battery_hbar'    \;\
          set -ug '@battery_vbar'    \;\
          set -ug '@battery_percentage'
    return
  fi

  battery_bar_symbol_full=$1
  battery_bar_symbol_empty=$2
  battery_bar_length=$3
  battery_bar_palette=$4
  battery_hbar_palette=$5
  battery_vbar_palette=$6

  if [ x"$battery_bar_length" = x"auto" ]; then
    columns=$(tmux -q display -p '#{client_width}' 2> /dev/null || echo 80)
    if [ "$columns" -ge 80 ]; then
      battery_bar_length=10
    else
      battery_bar_length=5
    fi
  fi

  if echo "$battery_bar_palette" | grep -q -E '^heat|gradient(,[#a-z0-9]{7,9})?$'; then
    # shellcheck disable=SC2086
    { set -f; IFS=,; set -- $battery_bar_palette; unset IFS; set +f; }
    palette_style=$1
    battery_bg=${2:-none}
    [ x"$palette_style" = x"gradient" ] && \
      palette="196 202 208 214 220 226 190 154 118 82 46"
    [ x"$palette_style" = x"heat" ] && \
      palette="243 245 247 144 143 142 184 214 208 202 196"

    palette=$(echo "$palette" | awk -v n="$battery_bar_length" '{ for (i = 0; i < n; ++i) printf $(1 + (i * NF / n))" " }')
    eval set -- "$palette"

    full=$(awk "BEGIN { printf \"%.0f\", ($charge) * $battery_bar_length }")
    battery_bar="#[bg=$battery_bg]"
    # shellcheck disable=SC2046
    [ "$full" -gt 0 ] && \
      battery_bar="$battery_bar$(printf "#[fg=colour%s]$battery_bar_symbol_full" $(echo "$palette" | cut -d' ' -f1-"$full"))"
    # shellcheck disable=SC2046
    empty=$((battery_bar_length - full))
    # shellcheck disable=SC2046
    [ "$empty" -gt 0 ] && \
      battery_bar="$battery_bar$(printf "#[fg=colour%s]$battery_bar_symbol_empty" $(echo "$palette" | cut -d' ' -f$((full + 1))-$((full + empty))))"
      eval battery_bar="$battery_bar#[fg=colour\${$((full == 0 ? 1 : full))}]"
  elif echo "$battery_bar_palette" | grep -q -E '^(([#a-z0-9]{7,9}|none),?){3}$'; then
    # shellcheck disable=SC2086
    { set -f; IFS=,; set -- $battery_bar_palette; unset IFS; set +f; }
    battery_full_fg=$1
    battery_empty_fg=$2
    battery_bg=$3

    full=$(awk "BEGIN { printf \"%.0f\", ($charge) * $battery_bar_length }")
    [ x"$battery_bg" != x"none" ] && \
      battery_bar="#[bg=$battery_bg]"
    #shellcheck disable=SC2046
    [ "$full" -gt 0 ] && \
      battery_bar="$battery_bar#[fg=$battery_full_fg]$(printf "%0.s$battery_bar_symbol_full" $(seq 1 "$full"))"
    empty=$((battery_bar_length - full))
    #shellcheck disable=SC2046
    [ "$empty" -gt 0 ] && \
      battery_bar="$battery_bar#[fg=$battery_empty_fg]$(printf "%0.s$battery_bar_symbol_empty" $(seq 1 "$empty"))" && \
      battery_bar="$battery_bar#[fg=$battery_empty_fg]"
  fi

  if echo "$battery_hbar_palette" | grep -q -E '^heat|gradient(,[#a-z0-9]{7,9})?$'; then
    # shellcheck disable=SC2086
    { set -f; IFS=,; set -- $battery_hbar_palette; unset IFS; set +f; }
    palette_style=$1
    [ x"$palette_style" = x"gradient" ] && \
      palette="196 202 208 214 220 226 190 154 118 82 46"
    [ x"$palette_style" = x"heat" ] && \
      palette="233 234 235 237 239 241 243 245 247 144 143 142 184 214 208 202 196"

    palette=$(echo "$palette" | awk -v n="$battery_bar_length" '{ for (i = 0; i < n; ++i) printf $(1 + (i * NF / n))" " }')
    eval set -- "$palette"

    full=$(awk "BEGIN { printf \"%.0f\", ($charge) * $battery_bar_length }")
    eval battery_hbar_fg="colour\${$((full == 0 ? 1 : full))}"
  elif echo "$battery_hbar_palette" | grep -q -E '^([#a-z0-9]{7,9},?){3}$'; then
    # shellcheck disable=SC2086
    { set -f; IFS=,; set -- $battery_hbar_palette; unset IFS; set +f; }

    # shellcheck disable=SC2046
    eval $(awk "BEGIN { printf \"battery_hbar_fg=$%d\", (($charge) - 0.001) * $# + 1 }")
  fi

  eval set -- "▏ ▎ ▍ ▌ ▋ ▊ ▉ █"
  # shellcheck disable=SC2046
  eval $(awk "BEGIN { printf \"battery_hbar_symbol=$%d\", ($charge) * ($# - 1) + 1 }")
  battery_hbar="#[fg=${battery_hbar_fg?}]${battery_hbar_symbol?}"

  if echo "$battery_vbar_palette" | grep -q -E '^heat|gradient(,[#a-z0-9]{7,9})?$'; then
    # shellcheck disable=SC2086
    { set -f; IFS=,; set -- $battery_vbar_palette; unset IFS; set +f; }
    palette_style=$1
    [ x"$palette_style" = x"gradient" ] && \
      palette="196 202 208 214 220 226 190 154 118 82 46"
    [ x"$palette_style" = x"heat" ] && \
      palette="233 234 235 237 239 241 243 245 247 144 143 142 184 214 208 202 196"

    palette=$(echo "$palette" | awk -v n="$battery_bar_length" '{ for (i = 0; i < n; ++i) printf $(1 + (i * NF / n))" " }')
    eval set -- "$palette"

    full=$(awk "BEGIN { printf \"%.0f\", ($charge) * $battery_bar_length }")
    eval battery_vbar_fg="colour\${$((full == 0 ? 1 : full))}"
  elif echo "$battery_vbar_palette" | grep -q -E '^([#a-z0-9]{7,9},?){3}$'; then
    # shellcheck disable=SC2086
    { set -f; IFS=,; set -- $battery_vbar_palette; unset IFS; set +f; }

    # shellcheck disable=SC2046
    eval $(awk "BEGIN { printf \"battery_vbar_fg=$%d\", (($charge) - 0.001) * $# + 1 }")
  fi

  eval set -- "▁ ▂ ▃ ▄ ▅ ▆ ▇ █"
  # shellcheck disable=SC2046
  eval $(awk "BEGIN { printf \"battery_vbar_symbol=$%d\", ($charge) * ($# - 1) + 1 }")
  battery_vbar="#[fg=${battery_vbar_fg?}]${battery_vbar_symbol?}"

  battery_percentage="$(awk "BEGIN { printf \"%.0f%%\", ($charge) * 100 }")"

  tmux set -g '@battery_bar' "$battery_bar" \;\
        set -g '@battery_hbar' "$battery_hbar" \;\
        set -g '@battery_vbar' "$battery_vbar" \;\
        set -g '@battery_percentage' "$battery_percentage"
}

_pane_info() {
  pane_pid="$1"
  pane_tty="${2##/dev/}"
  case "$_uname_s" in
    *CYGWIN*)
      ps -al | tail -n +2 | awk -v pane_pid="$pane_pid" -v tty="$pane_tty" '
        ((/ssh/ && !/-W/) || !/ssh/) && !/tee/ && $5 == tty {
          user[$1] = $6; if (!child[$2]) child[$2] = $1
        }
        END {
          pid = pane_pid
          while (child[pid])
            pid = child[pid]

          file = "/proc/" pid "/cmdline"; getline command < file; close(file)
          gsub(/\0/, " ", command)
          "id -un " user[pid] | getline username
          print pid":"username":"command
        }
      '
      ;;
    *Linux*)
      ps -t "$pane_tty" --sort=lstart -o user=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -o pid= -o ppid= -o command= | awk -v pane_pid="$pane_pid" '
        ((/ssh/ && !/-W/) || !/ssh/) && !/tee/ {
          user[$2] = $1; if (!child[$3]) child[$3] = $2; pid=$2; $1 = $2 = $3 = ""; command[pid] = substr($0,4)
        }
        END {
          pid = pane_pid
          while (child[pid])
            pid = child[pid]

          print pid":"user[pid]":"command[pid]
        }
      '
      ;;
    *)
      ps -t "$pane_tty" -o user=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -o pid= -o ppid= -o command= | awk -v pane_pid="$pane_pid" '
        ((/ssh/ && !/-W/) || !/ssh/) && !/tee/ {
          user[$2] = $1; if (!child[$3]) child[$3] = $2; pid=$2; $1 = $2 = $3 = ""; command[pid] = substr($0,4)
        }
        END {
          pid = pane_pid
          while (child[pid])
            pid = child[pid]

          print pid":"user[pid]":"command[pid]
        }
      '
      ;;
  esac
}

_ssh_or_mosh_args() {
  case "$1" in
    *ssh*)
      args=$(printf '%s' "$1" | perl -n -e 'print if s/.*?\bssh[\w]*\s*((?:\s+-\w+)*)(\s+\w+)(\s\w+)?/\1\2/')
      ;;
    *mosh-client*)
      args=$(printf '%s' "$1" | sed -E -e 's/.*mosh-client -# (.*)\|.*$/\1/' -e 's/-[^ ]*//g' -e 's/\d:\d//g')
      ;;
  esac

 printf '%s' "$args"
}

_username() {
  pane_pid=${1:-$(tmux display -p '#{pane_pid}')}
  pane_tty=${2:-$(tmux display -p '#{b:pane_tty}')}
  ssh_only=$3

  pane_info=$(_pane_info "$pane_pid" "$pane_tty")
  command=${pane_info#*:}
  command=${command#*:}

  ssh_or_mosh_args=$(_ssh_or_mosh_args "$command")
  if [ -n "$ssh_or_mosh_args" ]; then
    # shellcheck disable=SC2086
    username=$(ssh -G $ssh_or_mosh_args 2>/dev/null | awk '/^user / { print $2; exit }')
    # shellcheck disable=SC2086
    [ -z "$username" ] && username=$(ssh $ssh_or_mosh_args -T -o ControlPath=none -o ProxyCommand="sh -c 'echo %%username%% %r >&2'" 2>&1 | awk '/^%username% / { print $2; exit }')
    [ -z "$username" ] && username=$(ssh $ssh_or_mosh_args -v -T -o ControlPath=none -o ProxyCommand=false -o IdentityFile='%%username%%/%r' 2>&1 | awk '/%username%/ { print substr($4,12); exit }')
  else
    if ! _is_true "$ssh_only"; then
      username=${pane_info#*:}
      username=${username%%:*}
    fi
  fi

  printf '%s\n' "$username"
}

_hostname() {
  pane_pid=${1:-$(tmux display -p '#{pane_pid}')}
  pane_tty=${2:-$(tmux display -p '#{b:pane_tty}')}
  ssh_only=$3
  full=$4
  h_or_H=$5

  pane_info=$(_pane_info "$pane_pid" "$pane_tty")
  command=${pane_info#*:}
  command=${command#*:}

  ssh_or_mosh_args=$(_ssh_or_mosh_args "$command")
  if [ -n "$ssh_or_mosh_args" ]; then
    # shellcheck disable=SC2086
    hostname=$(ssh -G $ssh_or_mosh_args 2>/dev/null | awk '/^hostname / { print $2; exit }')
    # shellcheck disable=SC2086
    [ -z "$hostname" ] && hostname=$(ssh -T -o ControlPath=none -o ProxyCommand="sh -c 'echo %%hostname%% %h >&2'" $ssh_or_mosh_args 2>&1 | awk '/^%hostname% / { print $2; exit }')

    if ! _is_true "$full"; then
      case "$hostname" in
          *[a-z-].*)
              hostname=${hostname%%.*}
              ;;
          127.0.0.1)
              hostname="localhost"
              ;;
      esac
    fi
  else
    if ! _is_true "$ssh_only"; then
      hostname="$h_or_H"
    fi
  fi

  printf '%s\n' "$hostname"
}

_root() {
  pane_pid=${1:-$(tmux display -p '#{pane_pid}')}
  pane_tty=${2:-$(tmux display -p '#{b:pane_tty}')}
  root=$3

  username=$(_username "$pane_id" "$pane_tty" false)

  [ x"$username" = x"root" ] && echo "$root"
}

_uptime() {
  case "$_uname_s" in
    *Darwin*|*FreeBSD*)
      boot=$(sysctl -q -n kern.boottime | awk -F'[ ,:]+' '{ print $4 }')
      now=$(date +%s)
      ;;
    *Linux*|*CYGWIN*|*MSYS*|*MINGW*)
      boot=0
      now=$(cut -d' ' -f1 < /proc/uptime)
      ;;
    *OpenBSD*)
      boot=$(sysctl -n kern.boottime)
      now=$(date +%s)
  esac
  # shellcheck disable=SC1004
  awk -v boot="$boot" -v now="$now" '
    BEGIN {
      uptime = now - boot
      y = int(uptime / 31536000)
      dy = int(uptime / 86400) % 365
      d = int(uptime / 86400)
      h = int(uptime / 3600) % 24
      m = int(uptime / 60) % 60
      s = int(uptime) % 60

      system("tmux  set -g @uptime_y " y + 0 " \\; " \
                   "set -g @uptime_dy " dy + 0 " \\; " \
                   "set -g @uptime_d " d + 0 " \\; " \
                   "set -g @uptime_h " h + 0 " \\; " \
                   "set -g @uptime_m " m + 0 " \\; " \
                   "set -g @uptime_s " s + 0)
    }'
}

_loadavg() {
  case "$_uname_s" in
    *Darwin*|*FreeBSD*)
      tmux set -g @loadavg "$(sysctl -q -n vm.loadavg | cut -d' ' -f2)"
      ;;
    *Linux*|*CYGWIN*)
      tmux set -g @loadavg "$(cut -d' ' -f1 < /proc/loadavg)"
      ;;
    *OpenBSD*)
      tmux set -g @loadavg "$(sysctl -q -n vm.loadavg | cut -d' ' -f1)"
      ;;
  esac
}

_split_window_ssh() {
  pane_pid=${1:-$(tmux display -p '#{pane_pid}')}
  pane_tty=${2:-$(tmux display -p '#{b:pane_tty}')}
  shift 2

  pane_info=$(_pane_info "$pane_pid" "$pane_tty")
  command=${pane_info#*:}
  command=${command#*:}

  case "$command" in
    *mosh-client*)
      # shellcheck disable=SC2046
       tmux split-window "$@" mosh $(echo "$command" | sed -E -e 's/.*mosh-client -# (.*)\|.*$/\1/')
     ;;
    *ssh*)
      # shellcheck disable=SC2046
      tmux split-window "$@" $(echo "$command" | sed -e 's/;/\\;/g')
      ;;
    *)
      tmux split-window "$@"
  esac
}

_split_window() {
  _split_window_ssh "$@"
}

_apply_tmux_256color() {
  # when tmux-256color is available, use it
  # on macOS though, make sure to use /usr/bin/infocmp to probe if it's availalbe system wide
  case "$_uname_s" in
    *Darwin*)
      if /usr/bin/infocmp -x tmux-256color > /dev/null 2>&1; then
        tmux set -g default-terminal 'tmux-256color'
      fi
      ;;
     *)
      if command infocmp -x tmux-256color > /dev/null 2>&1; then
        tmux set -g default-terminal 'tmux-256color'
      fi
      ;;
  esac
}

_apply_24b() {
  tmux_conf_theme_24b_colour=${tmux_conf_theme_24b_colour:-auto}
  tmux_conf_24b_colour=${tmux_conf_24b_colour:-$tmux_conf_theme_24b_colour}
  if [ x"$tmux_conf_24b_colour" = x"auto" ]; then
    case "$COLORTERM" in
      truecolor|24bit)
        apply_24b=true
        ;;
    esac
    if [ x"$apply_24b" = x"" ] && [ x"$(tput colors)" = x"16777216" ]; then
      apply_24b=true
    fi
  elif _is_true "$tmux_conf_24b_colour"; then
    apply_24b=true
  fi
  if [ x"$apply_24b" = x"true" ]; then
    case "$TERM" in
      screen-*|tmux-*)
        ;;
      *)
        tmux set-option -ga terminal-overrides ",*256col*:Tc"
        ;;
    esac
  fi
}

_apply_bindings() {
  cfg=$(mktemp) && trap 'rm -f $cfg*' EXIT

  tmux list-keys | grep -vF 'tmux.conf.local' | grep -E 'new-window|split(-|_)window|new-session|copy-selection|copy-pipe' > "$cfg"

  # tmux 3.0 doesn't include 02254d1e5c881be95fd2fc37b4c4209640b6b266 and the
  # output of list-keys can be truncated
  perl -p -i -e "s/'#\{\?window_zoomed_flag,Unzoom,Zoom\}' 'z' \{resize-pane -$/'#{?window_zoomed_flag,Unzoom,Zoom}' 'z' {resize-pane -Z}\"/g" "$cfg"

  tmux_conf_new_window_retain_current_path=${tmux_conf_new_window_retain_current_path:-false}
  if ! _is_disabled "$tmux_conf_new_window_retain_current_path"; then
    perl -p -i -e "
      s/\bnew-window\b([^;}\n]*?)(?:\s+-c\s+((?:\\\\\")?|\"?|'?)#\{pane_current_path\}\2)/new-window\1/g" \
      "$cfg"
  fi

  tmux_conf_new_pane_retain_current_path=${tmux_conf_new_pane_retain_current_path:-true}
  if ! _is_disabled "$tmux_conf_new_pane_retain_current_path"; then
    perl -p -i -e "
      s/\brun-shell\b\s+(\"|')cut\s+-c3-\s+~\/\.tmux\.conf\s+\|\s+sh\s+-s\s+_split_window\s+#\{b:pane_tty\}([^\n\1]*)(\s+-c\s+((?:\\\\\")?|\"?|'?)#\{pane_current_path\}\4)([^\n\1]*)\1/run-shell \1cut -c3- ~\/.tmux.conf | sh -s _split_window #{pane_pid} #{b:pane_tty}\2\5\1/g
      ;
      s/\brun-shell\b(\s+((?:\\\\\")?|\"?|'?)cut\s+-c3-\s+~\/\.tmux\.conf\s+\|\s+sh\s+-s\s+_split_window\s+((?:\\\\\")?|\"?|'?)#\{b:pane_tty\}\3)(.*?)\2/split-window\4/g
      ;
      s/\bsplit-window\b([^;}\n]*?)(?:\s+-c\s+((?:\\\\\")?|\"?|'?)#\{pane_current_path\}\2)/split-window\1/g" \
      "$cfg"
  fi

  if ! _is_disabled "$tmux_conf_new_window_retain_current_path"; then
    if _is_true "$tmux_conf_new_window_retain_current_path"; then
      perl -p -i -e "
        s/\bnew-window\b(?!\s+(?:-|}))/{$&}/g if /\bdisplay-menu\b/
        ;
        s/\bnew-window\b/new-window -c '#\{pane_current_path\}'/g" \
        "$cfg"
    fi
  fi

  perl -p -i -e "
    s/\bsplit-window\b((?:(?:[ \t]+-[bdfhIvP])|(?:[ \t]+-[celtF][ \t]+(?!\bssh\b)[^\s]+))*)?(?:\s+(\bssh\b))((?:(?:[ \t]+-[bdfhIvP])|(?:[ \t]+-[celtF][ \t]+(?!\bssh\b)[^\s]+))*)?/run-shell 'cut -c3- ~\/\.tmux\.conf | sh -s _split_window_ssh #\{pane_pid\} #\{b:pane_tty\}\1'/g if /\bsplit-window\b((?:(?:[ \t]+-[bdfhIvP])|(?:[ \t]+-[celtF][ \t]+(?!ssh)[^\s]+))*)?(?:\s+(ssh))((?:(?:[ \t]+-[bdfhIvP])|(?:[ \t]+-[celtF][ \t]+(?!ssh)[^\s]+))*)?/"\
  "$cfg"

  tmux_conf_new_pane_reconnect_ssh=${tmux_conf_new_pane_reconnect_ssh:-false}
  if ! _is_disabled "$tmux_conf_new_pane_reconnect_ssh" && _is_true "$tmux_conf_new_pane_reconnect_ssh"; then
    perl -p -i -e "s/\bsplit-window\b([^;}\n\"]*)/run-shell 'cut -c3- ~\/\.tmux\.conf | sh -s _split_window #\{pane_pid\} #\{b:pane_tty\}\1'/g" "$cfg"
  fi

  if ! _is_disabled "$tmux_conf_new_pane_retain_current_path" && _is_true "$tmux_conf_new_pane_retain_current_path"; then
    perl -p -i -e "
      s/\bsplit-window\b(?!\s+(?:-|}))/{$&}/g if /\bdisplay-menu\b/
      ;
      s/\bsplit-window\b/split-window -c '#{pane_current_path}'\1/g
      ;
      s/\brun-shell\b\s+'cut\s+-c3-\s+~\/\.tmux\.conf\s+\|\s+sh\s+-s\s+_split_window(_ssh)?\s+#\{pane_pid\}\s+#\{b:pane_tty\}([^}\n']*)'/run-shell 'cut -c3- ~\/.tmux.conf | sh -s _split_window\1 #\{pane_pid\} #\{b:pane_tty\} -c \\\\\"#\{pane_current_path\}\\\\\"\2'/g if /\bdisplay-menu\b/
      ;
      s/\brun-shell\b\s+'cut\s+-c3-\s+~\/\.tmux\.conf\s+\|\s+sh\s+-s\s+_split_window(_ssh)?\s+#\{pane_pid\}\s+#\{b:pane_tty\}([^}\n']*)'/run-shell 'cut -c3- ~\/.tmux.conf | sh -s _split_window\1 #\{pane_pid\} #\{b:pane_tty\} -c \"#\{pane_current_path\}\"\2'/g" \
      "$cfg"
  fi

  tmux_conf_new_session_prompt=${tmux_conf_new_session_prompt:-false}
  if ! _is_disabled "$tmux_conf_new_session_prompt" && _is_true "$tmux_conf_new_session_prompt"; then
    perl -p -i \
      -e "s/(?<!command-prompt -p )\b(new-session)\b(?!\s+(?:-|}))/{$&}/g if /\bdisplay-menu\b/" \
      -e ';' \
      -e "s/(?<!\bcommand-prompt -p )\bnew-session\b(?! -s)/command-prompt -p new-session 'new-session -s \"%%\"'/g" \
      "$cfg"
  else
    perl -p -i -e "s/\bcommand-prompt\s+-p\s+new-session\s+'new-session\s+-s\s+\"%%\"'/new-session/g" "$cfg"
  fi

  tmux_conf_copy_to_os_clipboard=${tmux_conf_copy_to_os_clipboard:-false}
  command -v xsel > /dev/null 2>&1 && command='xsel -i -b'
  ! command -v xsel > /dev/null 2>&1 && command -v xclip > /dev/null 2>&1 && command='xclip -i -selection clipboard > \/dev\/null 2>\&1'
  command -v wl-copy > /dev/null 2>&1 && command='wl-copy'
  command -v pbcopy > /dev/null 2>&1 && command='pbcopy'
  command -v reattach-to-user-namespace > /dev/null 2>&1 && command='reattach-to-user-namespace pbcopy'
  command -v clip.exe > /dev/null 2>&1 && command='clip\.exe'
  [ -c /dev/clipboard ] && command='cat > \/dev\/clipboard'

  if [ -n "$command" ]; then
    if ! _is_disabled "$tmux_conf_copy_to_os_clipboard" && _is_true "$tmux_conf_copy_to_os_clipboard"; then
      perl -p -i -e "s/(?!.*?$command)\bcopy-(?:selection|pipe)(-and-cancel)?\b/copy-pipe\1 '$command'/g" "$cfg"
    else
      if [ $_tmux_version -ge 320 ]; then
        perl -p -i -e "s/\bcopy-pipe(-and-cancel)?\b\s+(\"|')?$command\2?/copy-pipe\1/g" "$cfg"
      else
        perl -p -i -e "s/\bcopy-pipe(-and-cancel)?\b\s+(\"|')?$command\2?/copy-selection\1/g" "$cfg"
      fi
    fi
  fi

  # until tmux >= 3.0, output of tmux list-keys can't be consumed back by tmux source-file without applying some escapings
  awk < "$cfg" \
    '{i = $2 == "-T" ? 4 : 5; gsub(/^[;]$/, "\\\\&", $i); gsub(/^[$"#~]$/, "'"'"'&'"'"'", $i); gsub(/^['"'"']$/, "\"&\"", $i); print}' > "$cfg.in"

  # ignore bindings with errors
  if ! tmux source-file "$cfg.in"; then
    verbose_flag=$(tmux source-file -v /dev/null 2> /dev/null && printf -- '-v' || true)
    while ! out=$(tmux source-file "$verbose_flag" "$cfg.in"); do
      line=$(printf "%s" "$out" | tail -1 | cut -d':' -f2)
      perl -n -i -e "if ($. != $line) { print }" "$cfg.in"
    done
  fi
}

_apply_theme() {
  tmux_conf_theme=${tmux_conf_theme:-enabled}
  if ! _is_disabled "$tmux_conf_theme"; then

    # -- default theme -------------------------------------------------------

    tmux_conf_theme_colour_1=${tmux_conf_theme_colour_1:-#080808}     # dark gray
    tmux_conf_theme_colour_2=${tmux_conf_theme_colour_2:-#303030}     # gray
    tmux_conf_theme_colour_3=${tmux_conf_theme_colour_3:-#8a8a8a}     # light gray
    tmux_conf_theme_colour_4=${tmux_conf_theme_colour_4:-#00afff}     # light blue
    tmux_conf_theme_colour_5=${tmux_conf_theme_colour_5:-#ffff00}     # yellow
    tmux_conf_theme_colour_6=${tmux_conf_theme_colour_6:-#080808}     # dark gray
    tmux_conf_theme_colour_7=${tmux_conf_theme_colour_7:-#e4e4e4}     # white
    tmux_conf_theme_colour_8=${tmux_conf_theme_colour_8:-#080808}     # dark gray
    tmux_conf_theme_colour_9=${tmux_conf_theme_colour_9:-#ffff00}     # yellow
    tmux_conf_theme_colour_10=${tmux_conf_theme_colour_10:-#ff00af}   # pink
    tmux_conf_theme_colour_11=${tmux_conf_theme_colour_11:-#5fff00}   # green
    tmux_conf_theme_colour_12=${tmux_conf_theme_colour_12:-#8a8a8a}   # light gray
    tmux_conf_theme_colour_13=${tmux_conf_theme_colour_13:-#e4e4e4}   # white
    tmux_conf_theme_colour_14=${tmux_conf_theme_colour_14:-#080808}   # dark gray
    tmux_conf_theme_colour_15=${tmux_conf_theme_colour_15:-#080808}   # dark gray
    tmux_conf_theme_colour_16=${tmux_conf_theme_colour_16:-#d70000}   # red
    tmux_conf_theme_colour_17=${tmux_conf_theme_colour_17:-#e4e4e4}   # white

    # -- panes ---------------------------------------------------------------

    tmux_conf_theme_window_fg=${tmux_conf_theme_window_fg:-default}
    tmux_conf_theme_window_bg=${tmux_conf_theme_window_bg:-default}
    tmux_conf_theme_highlight_focused_pane=${tmux_conf_theme_highlight_focused_pane:-false}
    tmux_conf_theme_focused_pane_fg=${tmux_conf_theme_focused_pane_fg:-default}
    tmux_conf_theme_focused_pane_bg=${tmux_conf_theme_focused_pane_bg:-$tmux_conf_theme_colour_2}

    window_style="fg=$tmux_conf_theme_window_fg,bg=$tmux_conf_theme_window_bg"
    if _is_true "$tmux_conf_theme_highlight_focused_pane"; then
      window_active_style="fg=$tmux_conf_theme_focused_pane_fg,bg=$tmux_conf_theme_focused_pane_bg"
    else
      window_active_style="default"
    fi

    tmux_conf_theme_pane_border_style=${tmux_conf_theme_pane_border_style:-thin}
    tmux_conf_theme_pane_border=${tmux_conf_theme_pane_border:-$tmux_conf_theme_colour_2}
    tmux_conf_theme_pane_active_border=${tmux_conf_theme_pane_active_border:-$tmux_conf_theme_colour_4}
    tmux_conf_theme_pane_border_fg=${tmux_conf_theme_pane_border_fg:-$tmux_conf_theme_pane_border}
    tmux_conf_theme_pane_active_border_fg=${tmux_conf_theme_pane_active_border_fg:-$tmux_conf_theme_pane_active_border}
    case "$tmux_conf_theme_pane_border_style" in
      fat)
        tmux_conf_theme_pane_border_bg=${tmux_conf_theme_pane_border_bg:-$tmux_conf_theme_pane_border_fg}
        tmux_conf_theme_pane_active_border_bg=${tmux_conf_theme_pane_active_border_bg:-$tmux_conf_theme_pane_active_border_fg}
        ;;
      thin|*)
        tmux_conf_theme_pane_border_bg=${tmux_conf_theme_pane_border_bg:-default}
        tmux_conf_theme_pane_active_border_bg=${tmux_conf_theme_pane_active_border_bg:-default}
        ;;
    esac

    tmux_conf_theme_pane_indicator=${tmux_conf_theme_pane_indicator:-$tmux_conf_theme_colour_4}
    tmux_conf_theme_pane_active_indicator=${tmux_conf_theme_pane_active_indicator:-$tmux_conf_theme_colour_4}

    # -- status line ---------------------------------------------------------

    tmux_conf_theme_left_separator_main=$(_decode_unicode_escapes "${tmux_conf_theme_left_separator_main-}")
    tmux_conf_theme_left_separator_sub=$(_decode_unicode_escapes "${tmux_conf_theme_left_separator_sub-|}")
    tmux_conf_theme_right_separator_main=$(_decode_unicode_escapes "${tmux_conf_theme_right_separator_main-}")
    tmux_conf_theme_right_separator_sub=$(_decode_unicode_escapes "${tmux_conf_theme_right_separator_sub-|}")

    tmux_conf_theme_message_fg=${tmux_conf_theme_message_fg:-$tmux_conf_theme_colour_1}
    tmux_conf_theme_message_bg=${tmux_conf_theme_message_bg:-$tmux_conf_theme_colour_5}
    tmux_conf_theme_message_attr=${tmux_conf_theme_message_attr:-bold}

    tmux_conf_theme_message_command_fg=${tmux_conf_theme_message_command_fg:-$tmux_conf_theme_colour_5}
    tmux_conf_theme_message_command_bg=${tmux_conf_theme_message_command_bg:-$tmux_conf_theme_colour_1}
    tmux_conf_theme_message_command_attr=${tmux_conf_theme_message_command_attr:-bold}

    tmux_conf_theme_mode_fg=${tmux_conf_theme_mode_fg:-$tmux_conf_theme_colour_1}
    tmux_conf_theme_mode_bg=${tmux_conf_theme_mode_bg:-$tmux_conf_theme_colour_5}
    tmux_conf_theme_mode_attr=${tmux_conf_theme_mode_attr:-bold}

    tmux_conf_theme_status_fg=${tmux_conf_theme_status_fg:-$tmux_conf_theme_colour_3}
    tmux_conf_theme_status_bg=${tmux_conf_theme_status_bg:-$tmux_conf_theme_colour_1}
    tmux_conf_theme_status_attr=${tmux_conf_theme_status_attr:-none}

    tmux_conf_theme_terminal_title=${tmux_conf_theme_terminal_title:-#h ❐ #S ● #I #W}

    tmux_conf_theme_window_status_fg=${tmux_conf_theme_window_status_fg:-$tmux_conf_theme_colour_3}
    tmux_conf_theme_window_status_bg=${tmux_conf_theme_window_status_bg:-$tmux_conf_theme_colour_1}
    tmux_conf_theme_window_status_attr=${tmux_conf_theme_window_status_attr:-none}
    tmux_conf_theme_window_status_format=${tmux_conf_theme_window_status_format:-#I #W}

    tmux_conf_theme_window_status_current_fg=${tmux_conf_theme_window_status_current_fg:-$tmux_conf_theme_colour_1}
    tmux_conf_theme_window_status_current_bg=${tmux_conf_theme_window_status_current_bg:-$tmux_conf_theme_colour_4}
    tmux_conf_theme_window_status_current_attr=${tmux_conf_theme_window_status_current_attr:-bold}
    tmux_conf_theme_window_status_current_format=${tmux_conf_theme_window_status_current_format:-#I #W}

    tmux_conf_theme_window_status_activity_fg=${tmux_conf_theme_window_status_activity_fg:-default}
    tmux_conf_theme_window_status_activity_bg=${tmux_conf_theme_window_status_activity_bg:-default}
    tmux_conf_theme_window_status_activity_attr=${tmux_conf_theme_window_status_activity_attr:-underscore}

    tmux_conf_theme_window_status_bell_fg=${tmux_conf_theme_window_status_bell_fg:-$tmux_conf_theme_colour_5}
    tmux_conf_theme_window_status_bell_bg=${tmux_conf_theme_window_status_bell_bg:-default}
    tmux_conf_theme_window_status_bell_attr=${tmux_conf_theme_window_status_bell_attr:-blink,bold}

    tmux_conf_theme_window_status_last_fg=${tmux_conf_theme_window_status_last_fg:-$tmux_conf_theme_colour_4}
    tmux_conf_theme_window_status_last_bg=${tmux_conf_theme_window_status_last_bg:-default}
    tmux_conf_theme_window_status_last_attr=${tmux_conf_theme_window_status_last_attr:-none}

    if [ x"$tmux_conf_theme_window_status_bg" = x"$tmux_conf_theme_status_bg" ] || [ x"$tmux_conf_theme_window_status_bg" = x"default" ]; then
      spacer=''
      spacer_current=' '
    else
      spacer=' '
      spacer_current=' '
    fi
    if [ x"$tmux_conf_theme_window_status_last_bg" = x"$tmux_conf_theme_status_bg" ] || [ x"$tmux_conf_theme_window_status_last_bg" = x"default" ] ; then
      spacer_last=''
    else
      spacer_last=' '
    fi
    if [ x"$tmux_conf_theme_window_status_activity_bg" = x"$tmux_conf_theme_status_bg" ] || [ x"$tmux_conf_theme_window_status_activity_bg" = x"default" ] ; then
      spacer_activity=''
      spacer_last_activity="$spacer_last"
    else
      spacer_activity=' '
      spacer_last_activity=' '
    fi
    if [ x"$tmux_conf_theme_window_status_bell_bg" = x"$tmux_conf_theme_status_bg" ] || [ x"$tmux_conf_theme_window_status_bell_bg" = x"default" ] ; then
      spacer_bell=''
      spacer_last_bell="$spacer_last"
      spacer_activity_bell="$spacer_activity"
      spacer_last_activity_bell="$spacer_last_activity"
    else
      spacer_bell=' '
      spacer_last_bell=' '
      spacer_activity_bell=' '
      spacer_last_activity_bell=' '
    fi
    spacer="#{?window_last_flag,#{?window_activity_flag,#{?window_bell_flag,$spacer_last_activity_bell,$spacer_last_activity},#{?window_bell_flag,$spacer_last_bell,$spacer_last}},#{?window_activity_flag,#{?window_bell_flag,$spacer_activity_bell,$spacer_activity},#{?window_bell_flag,$spacer_bell,$spacer}}}"
    if [ x"$(tmux show -g -v status-justify)" = x"right" ]; then
      if [ -z "$tmux_conf_theme_right_separator_main" ]; then
        window_status_separator=' '
      else
        window_status_separator=''
      fi
      window_status_format="#[fg=$tmux_conf_theme_window_status_bg,bg=$tmux_conf_theme_status_bg,none]#{?window_last_flag,$(printf "$tmux_conf_theme_window_status_last_bg" | perl -n -e "s/.+/#[fg=$&]/; print if !/default/"),}#{?window_activity_flag,$(printf "$tmux_conf_theme_window_status_activity_bg" | perl -n -e "s/.+/#[fg=$&]/; print if !/default/"),}#{?window_bell_flag,$(printf "$tmux_conf_theme_window_status_bell_bg" | perl -n -e "s/.+/#[fg=$&]/; print if !/default/"),}$tmux_conf_theme_right_separator_main#[fg=$tmux_conf_theme_window_status_fg,bg=$tmux_conf_theme_window_status_bg,$tmux_conf_theme_window_status_attr]#{?window_last_flag,$(printf "$tmux_conf_theme_window_status_last_fg" | perl -n -e "s/.+/#[fg=$&]/; print if !/default/"),}#{?window_last_flag,$(printf "$tmux_conf_theme_window_status_last_bg" | perl -n -e "s/.+/#[bg=$&]/; print if !/default/"),}#{?window_activity_flag,$(printf "$tmux_conf_theme_window_status_activity_fg" | perl -n -e "s/.+/#[fg=$&]/; print if !/default/"),}#{?window_activity_flag,$(printf "$tmux_conf_theme_window_status_activity_bg" | perl -n -e "s/.+/#[bg=$&]/; print if !/default/"),}#{?window_bell_flag,$(printf "$tmux_conf_theme_window_status_bell_fg" | perl -n -e "s/.+/#[fg=$&]/; print if !/default/"),}#{?window_bell_flag,$(printf "$tmux_conf_theme_window_status_bell_bg" | perl -n -e "s/.+/#[bg=$&]/; print if !/default/"),}$spacer$(printf "$tmux_conf_theme_window_status_last_attr" | perl -n -e 'print "#{?window_last_flag,#[none],}" if !/default/ ; s/([a-z]+),?/#{?window_last_flag,#[\1],}/g; print if !/default/')$(printf "$tmux_conf_theme_window_status_activity_attr" | perl -n -e 'print "#{?window_activity_flag?,#[none],}" if !/default/ ; s/([a-z]+),?/#{?window_activity_flag,#[\1],}/g; print if !/default/')$(printf "$tmux_conf_theme_window_status_bell_attr" | perl -n -e 'print "#{?window_bell_flag,#[none],}" if !/default/ ; s/([a-z]+),?/#{?window_bell_flag,#[\1],}/g; print if !/default/')$tmux_conf_theme_window_status_format#[none]$spacer#[fg=$tmux_conf_theme_status_bg,bg=$tmux_conf_theme_window_status_bg]#{?window_last_flag,$(printf "$tmux_conf_theme_window_status_last_bg" | perl -n -e "s/.+/#[bg=$&]/; print if !/default/"),}#{?window_activity_flag,$(printf "$tmux_conf_theme_window_status_activity_bg" | perl -n -e "s/.+/#[bg=$&]/; print if !/default/"),}#{?window_bell_flag,$(printf "$tmux_conf_theme_window_status_bell_bg" | perl -n -e "s/.+/#[bg=$&]/; print if !/default/"),}#[none]$tmux_conf_theme_right_separator_main"
      window_status_current_format="#[fg=$tmux_conf_theme_window_status_current_bg,bg=$tmux_conf_theme_status_bg,none]$tmux_conf_theme_right_separator_main#[fg=$tmux_conf_theme_window_status_current_fg,bg=$tmux_conf_theme_window_status_current_bg,$tmux_conf_theme_window_status_current_attr]$spacer_current$tmux_conf_theme_window_status_current_format$spacer_current#[fg=$tmux_conf_theme_status_bg,bg=$tmux_conf_theme_window_status_current_bg,none]$tmux_conf_theme_right_separator_main"
    else
      if [ -z "$tmux_conf_theme_left_separator_main" ]; then
        window_status_separator=' '
      else
        window_status_separator=''
      fi
      window_status_format="#[fg=$tmux_conf_theme_status_bg,bg=$tmux_conf_theme_window_status_bg,none]#{?window_last_flag,$(printf "$tmux_conf_theme_window_status_last_bg" | perl -n -e "s/.+/#[bg=$&]/; print if !/default/"),}#{?window_activity_flag,$(printf "$tmux_conf_theme_window_status_activity_bg" | perl -n -e "s/.+/#[bg=$&]/; print if !/default/"),}#{?window_bell_flag,$(printf "$tmux_conf_theme_window_status_bell_bg" | perl -n -e "s/.+/#[bg=$&]/; print if !/default/"),}$tmux_conf_theme_left_separator_main#[fg=$tmux_conf_theme_window_status_fg,bg=$tmux_conf_theme_window_status_bg,$tmux_conf_theme_window_status_attr]#{?window_last_flag,$(printf "$tmux_conf_theme_window_status_last_fg" | perl -n -e "s/.+/#[fg=$&]/; print if !/default/"),}#{?window_last_flag,$(printf "$tmux_conf_theme_window_status_last_bg" | perl -n -e "s/.+/#[bg=$&]/; print if !/default/"),}#{?window_activity_flag,$(printf "$tmux_conf_theme_window_status_activity_fg" | perl -n -e "s/.+/#[fg=$&]/; print if !/default/"),}#{?window_activity_flag,$(printf "$tmux_conf_theme_window_status_activity_bg" | perl -n -e "s/.+/#[bg=$&]/; print if !/default/"),}#{?window_bell_flag,$(printf "$tmux_conf_theme_window_status_bell_fg" | perl -n -e "s/.+/#[fg=$&]/; print if !/default/"),}#{?window_bell_flag,$(printf "$tmux_conf_theme_window_status_bell_bg" | perl -n -e "s/.+/#[bg=$&]/; print if !/default/"),}$spacer$(printf "$tmux_conf_theme_window_status_last_attr" | perl -n -e 'print "#{?window_last_flag,#[none],}" if !/default/ ; s/([a-z]+),?/#{?window_last_flag,#[\1],}/g; print if !/default/')$(printf "$tmux_conf_theme_window_status_activity_attr" | perl -n -e 'print "#{?window_activity_flag,#[none],}" if !/default/ ; s/([a-z]+),?/#{?window_activity_flag,#[\1],}/g; print if !/default/')$(printf "$tmux_conf_theme_window_status_bell_attr" | perl -n -e 'print "#{?window_bell_flag,#[none],}" if /!default/ ; s/([a-z]+),?/#{?window_bell_flag,#[\1],}/g; print if !/default/')$tmux_conf_theme_window_status_format#[none]$spacer#[fg=$tmux_conf_theme_window_status_bg,bg=$tmux_conf_theme_status_bg]#{?window_last_flag,$(printf "$tmux_conf_theme_window_status_last_bg" | perl -n -e "s/.+/#[fg=$&]/; print if !/default/"),}#{?window_activity_flag,$(printf "$tmux_conf_theme_window_status_activity_bg" | perl -n -e "s/.+/#[fg=$&]/; print if !/default/"),}#{?window_bell_flag,$(printf "$tmux_conf_theme_window_status_bell_bg" | perl -n -e "s/.+/#[fg=$&]/; print if !/default/"),}$tmux_conf_theme_left_separator_main"
      window_status_current_format="#[fg=$tmux_conf_theme_status_bg,bg=$tmux_conf_theme_window_status_current_bg,none]$tmux_conf_theme_left_separator_main#[fg=$tmux_conf_theme_window_status_current_fg,bg=$tmux_conf_theme_window_status_current_bg,$tmux_conf_theme_window_status_current_attr]$spacer_current$tmux_conf_theme_window_status_current_format$spacer_current#[fg=$tmux_conf_theme_window_status_current_bg,bg=$tmux_conf_theme_status_bg]$tmux_conf_theme_left_separator_main"
    fi

    # -- indicators

    tmux_conf_theme_pairing=${tmux_conf_theme_pairing:-⚇}                         # U+2687
    tmux_conf_theme_pairing_fg=${tmux_conf_theme_pairing_fg:-none}
    tmux_conf_theme_pairing_bg=${tmux_conf_theme_pairing_bg:-none}
    tmux_conf_theme_pairing_attr=${tmux_conf_theme_pairing_attr:-none}

    tmux_conf_theme_prefix=${tmux_conf_theme_prefix:-⌨}                           # U+2328
    tmux_conf_theme_prefix_fg=${tmux_conf_theme_prefix_fg:-none}
    tmux_conf_theme_prefix_bg=${tmux_conf_theme_prefix_bg:-none}
    tmux_conf_theme_prefix_attr=${tmux_conf_theme_prefix_attr:-none}

    tmux_conf_theme_mouse=${tmux_conf_theme_mouse:-↗}                             # U+2197
    tmux_conf_theme_mouse_fg=${tmux_conf_theme_mouse_fg:-none}
    tmux_conf_theme_mouse_bg=${tmux_conf_theme_mouse_bg:-none}
    tmux_conf_theme_mouse_attr=${tmux_conf_theme_mouse_attr:-none}

    tmux_conf_theme_root=${tmux_conf_theme_root:-!}
    tmux_conf_theme_root_fg=${tmux_conf_theme_root_fg:-none}
    tmux_conf_theme_root_bg=${tmux_conf_theme_root_bg:-none}
    tmux_conf_theme_root_attr=${tmux_conf_theme_root_attr:-bold,blink}

    tmux_conf_theme_synchronized=${tmux_conf_theme_synchronized:-⚏}               # U+268F
    tmux_conf_theme_synchronized_fg=${tmux_conf_theme_synchronized_fg:-none}
    tmux_conf_theme_synchronized_bg=${tmux_conf_theme_synchronized_bg:-none}
    tmux_conf_theme_synchronized_attr=${tmux_conf_theme_synchronized_attr:-none}

    # -- status-left style

    tmux_conf_theme_status_left=${tmux_conf_theme_status_left-' ❐ #S | ↑#{?uptime_y, #{uptime_y}y,}#{?uptime_d, #{uptime_d}d,}#{?uptime_h, #{uptime_h}h,}#{?uptime_m, #{uptime_m}m,} '}
    tmux_conf_theme_status_left_fg=${tmux_conf_theme_status_left_fg:-$tmux_conf_theme_colour_6,$tmux_conf_theme_colour_7,$tmux_conf_theme_colour_8}
    tmux_conf_theme_status_left_bg=${tmux_conf_theme_status_left_bg:-$tmux_conf_theme_colour_9,$tmux_conf_theme_colour_10,$tmux_conf_theme_colour_11}
    tmux_conf_theme_status_left_attr=${tmux_conf_theme_status_left_attr:-bold,none,none}

    if [ -n "$tmux_conf_theme_status_left" ]; then
      status_left=$(echo "$tmux_conf_theme_status_left" | sed \
        -e "s/#{pairing}/#[fg=$tmux_conf_theme_pairing_fg]#[bg=$tmux_conf_theme_pairing_bg]#[$tmux_conf_theme_pairing_attr]#{pairing}/g" \
        -e "s/#{prefix}/#[fg=$tmux_conf_theme_prefix_fg]#[bg=$tmux_conf_theme_prefix_bg]#[$tmux_conf_theme_prefix_attr]#{prefix}/g" \
        -e "s/#{mouse}/#[fg=$tmux_conf_theme_mouse_fg]#[bg=$tmux_conf_theme_mouse_bg]#[$tmux_conf_theme_mouse_attr]#{mouse}/g" \
        -e "s%#{synchronized}%#[fg=$tmux_conf_theme_synchronized_fg]#[bg=$tmux_conf_theme_synchronized_bg]#[$tmux_conf_theme_synchronized_attr]#{synchronized}%g" \
        -e "s%#{root}%#[fg=$tmux_conf_theme_root_fg]#[bg=$tmux_conf_theme_root_bg]#[$tmux_conf_theme_root_attr]#{root}#[inherit]%g")

      status_left=$(printf '%s' "$status_left" | awk \
                        -v status_bg="$tmux_conf_theme_status_bg" \
                        -v fg_="$tmux_conf_theme_status_left_fg" \
                        -v bg_="$tmux_conf_theme_status_left_bg" \
                        -v attr_="$tmux_conf_theme_status_left_attr" \
                        -v mainsep="$tmux_conf_theme_left_separator_main" \
                        -v subsep="$tmux_conf_theme_left_separator_sub" '
        function subsplit(s, l, i, a, r)
        {
          l = split(s, a, ",")
          for (i = 1; i <= l; ++i)
          {
            o = split(a[i], _, "(") - 1
            c = split(a[i], _, ")") - 1
            open += o - c
            o_ = split(a[i], _, "{") - 1
            c_ = split(a[i], _, "}") - 1
            open_ += o_ - c_
            o__ = split(a[i], _, "[") - 1
            c__ = split(a[i], _, "]") - 1
            open__ += o__ - c__

            if (i == l)
              r = sprintf("%s%s", r, a[i])
            else if (open || open_ || open__)
              r = sprintf("%s%s,", r, a[i])
            else
              r = sprintf("%s%s#[fg=%s,bg=%s,%s]%s", r, a[i], fg[j], bg[j], attr[j], subsep)
          }

          gsub(/#\[inherit\]/, sprintf("#[default]#[fg=%s,bg=%s,%s]", fg[j], bg[j], attr[j]), r)
          return r
        }
        BEGIN {
          FS = "|"
          l1 = split(fg_, fg, ",")
          l2 = split(bg_, bg, ",")
          l3 = split(attr_, attr, ",")
          l = l1 < l2 ? (l1 < l3 ? l1 : l3) : (l2 < l3 ? l2 : l3)
        }
        {
          for (i = j = 1; i <= NF; ++i)
          {
            if (open || open_ || open__)
              printf "|%s", subsplit($i)
            else
            {
              if (i > 1)
                printf "#[fg=%s,bg=%s,none]%s#[fg=%s,bg=%s,%s]%s", bg[j_], bg[j], mainsep, fg[j], bg[j], attr[j], subsplit($i)
              else
                printf "#[fg=%s,bg=%s,%s]%s", fg[j], bg[j], attr[j], subsplit($i)
            }

            if (!open && !open_ && !open__)
            {
              j_ = j
              j = j % l + 1
            }
          }
          printf "#[fg=%s,bg=%s,none]%s", bg[j_], status_bg, mainsep
        }')

      status_left="$status_left "
    fi

    # -- status-right style

    tmux_conf_theme_status_right=${tmux_conf_theme_status_right-' #{prefix}#{mouse}#{pairing}#{synchronized}#{?battery_status, #{battery_status},}#{?battery_bar, #{battery_bar},}#{?battery_percentage, #{battery_percentage},} , %R , %d %b | #{username}#{root} | #{hostname} '}
    tmux_conf_theme_status_right_fg=${tmux_conf_theme_status_right_fg:-$tmux_conf_theme_colour_12,$tmux_conf_theme_colour_13,$tmux_conf_theme_colour_14}
    tmux_conf_theme_status_right_bg=${tmux_conf_theme_status_right_bg:-$tmux_conf_theme_colour_15,$tmux_conf_theme_colour_16,$tmux_conf_theme_colour_17}
    tmux_conf_theme_status_right_attr=${tmux_conf_theme_status_right_attr:-none,none,bold}

    if [ -n "$tmux_conf_theme_status_right" ]; then
      status_right=$(echo "$tmux_conf_theme_status_right" | sed \
        -e "s/#{pairing}/#[fg=$tmux_conf_theme_pairing_fg]#[bg=$tmux_conf_theme_pairing_bg]#[$tmux_conf_theme_pairing_attr]#{pairing}/g" \
        -e "s/#{prefix}/#[fg=$tmux_conf_theme_prefix_fg]#[bg=$tmux_conf_theme_prefix_bg]#[$tmux_conf_theme_prefix_attr]#{prefix}/g" \
        -e "s/#{mouse}/#[fg=$tmux_conf_theme_mouse_fg]#[bg=$tmux_conf_theme_mouse_bg]#[$tmux_conf_theme_mouse_attr]#{mouse}/g" \
        -e "s%#{synchronized}%#[fg=$tmux_conf_theme_synchronized_fg]#[bg=$tmux_conf_theme_synchronized_bg]#[$tmux_conf_theme_synchronized_attr]#{synchronized}%g" \
        -e "s%#{root}%#[fg=$tmux_conf_theme_root_fg]#[bg=$tmux_conf_theme_root_bg]#[$tmux_conf_theme_root_attr]#{root}#[inherit]%g")

      status_right=$(printf '%s' "$status_right" | awk \
                        -v status_bg="$tmux_conf_theme_status_bg" \
                        -v fg_="$tmux_conf_theme_status_right_fg" \
                        -v bg_="$tmux_conf_theme_status_right_bg" \
                        -v attr_="$tmux_conf_theme_status_right_attr" \
                        -v mainsep="$tmux_conf_theme_right_separator_main" \
                        -v subsep="$tmux_conf_theme_right_separator_sub" '
        function subsplit(s, l, i, a, r)
        {
          l = split(s, a, ",")
          for (i = 1; i <= l; ++i)
          {
            o = split(a[i], _, "(") - 1
            c = split(a[i], _, ")") - 1
            open += o - c
            o_ = split(a[i], _, "{") - 1
            c_ = split(a[i], _, "}") - 1
            open_ += o_ - c_
            o__ = split(a[i], _, "[") - 1
            c__ = split(a[i], _, "]") - 1
            open__ += o__ - c__

            if (i == l)
              r = sprintf("%s%s", r, a[i])
            else if (open || open_ || open__)
              r = sprintf("%s%s,", r, a[i])
            else
              r = sprintf("%s%s#[fg=%s,bg=%s,%s]%s", r, a[i], fg[j], bg[j], attr[j], subsep)
          }

          gsub(/#\[inherit\]/, sprintf("#[default]#[fg=%s,bg=%s,%s]", fg[j], bg[j], attr[j]), r)
          return r
        }
        BEGIN {
          FS = "|"
          l1 = split(fg_, fg, ",")
          l2 = split(bg_, bg, ",")
          l3 = split(attr_, attr, ",")
          l = l1 < l2 ? (l1 < l3 ? l1 : l3) : (l2 < l3 ? l2 : l3)
        }
        {
          for (i = j = 1; i <= NF; ++i)
          {
            if (open_ || open || open__)
              printf "|%s", subsplit($i)
            else
              printf "#[fg=%s,bg=%s,none]%s#[fg=%s,bg=%s,%s]%s", bg[j], (i == 1) ? status_bg : bg[j_], mainsep, fg[j], bg[j], attr[j], subsplit($i)

            if (!open && !open_ && !open__)
            {
              j_ = j
              j = j % l + 1
            }
          }
        }')
    fi

    # -- clock ---------------------------------------------------------------

    tmux_conf_theme_clock_colour=${tmux_conf_theme_clock_colour:-$tmux_conf_theme_colour_4}
    tmux_conf_theme_clock_style=${tmux_conf_theme_clock_style:-24}

    tmux setw -g window-style "$window_style" \; setw -g window-active-style "$window_active_style" \;\
         setw -g pane-border-style "fg=$tmux_conf_theme_pane_border_fg,bg=$tmux_conf_theme_pane_border_bg" \; set -g pane-active-border-style "fg=$tmux_conf_theme_pane_active_border_fg,bg=$tmux_conf_theme_pane_active_border_bg" \;\
         set -g display-panes-colour "$tmux_conf_theme_pane_indicator" \; set -g display-panes-active-colour "$tmux_conf_theme_pane_active_indicator" \;\
         set -g message-style "fg=$tmux_conf_theme_message_fg,bg=$tmux_conf_theme_message_bg,$tmux_conf_theme_message_attr" \;\
         set -g message-command-style "fg=$tmux_conf_theme_message_command_fg,bg=$tmux_conf_theme_message_command_bg,$tmux_conf_theme_message_command_attr" \;\
         setw -g mode-style "fg=$tmux_conf_theme_mode_fg,bg=$tmux_conf_theme_mode_bg,$tmux_conf_theme_mode_attr" \;\
         set -g status-style "fg=$tmux_conf_theme_status_fg,bg=$tmux_conf_theme_status_bg,$tmux_conf_theme_status_attr" \;\
         set -g status-left-style "fg=$tmux_conf_theme_status_fg,bg=$tmux_conf_theme_status_bg,$tmux_conf_theme_status_attr" \;\
         set -g status-right-style "fg=$tmux_conf_theme_status_fg,bg=$tmux_conf_theme_status_bg,$tmux_conf_theme_status_attr" \;\
         setw -g window-status-style "fg=$tmux_conf_theme_window_status_fg,bg=$tmux_conf_theme_window_status_bg,$tmux_conf_theme_window_status_attr" \;\
         setw -g window-status-current-style "fg=$tmux_conf_theme_window_status_current_fg,bg=$tmux_conf_theme_window_status_current_bg,$tmux_conf_theme_window_status_current_attr" \;\
         setw -g window-status-activity-style "fg=$tmux_conf_theme_window_status_activity_fg,bg=$tmux_conf_theme_window_status_activity_bg,$tmux_conf_theme_window_status_activity_attr" \;\
         setw -g window-status-bell-style "fg=$tmux_conf_theme_window_status_bell_fg,bg=$tmux_conf_theme_window_status_bell_bg,$tmux_conf_theme_window_status_bell_attr" \;\
         setw -g window-status-last-style "fg=$tmux_conf_theme_window_status_last_fg,bg=$tmux_conf_theme_window_status_last_bg,$tmux_conf_theme_window_status_last_attr" \;\
         setw -g window-status-separator "$window_status_separator" \;\
         setw -g clock-mode-colour "$tmux_conf_theme_clock_colour" \;\
         setw -g clock-mode-style "$tmux_conf_theme_clock_style"
  fi

  # -- variables -------------------------------------------------------------

  set_titles_string=$(printf '%s' "${tmux_conf_theme_terminal_title:-$(tmux show -gv set-titles-string)}" | sed \
    -e 's%#{circled_window_index}%#(cut -c3- ~/.tmux.conf | sh -s _circled #I)%g' \
    -e 's%#{circled_session_name}%#(cut -c3- ~/.tmux.conf | sh -s _circled #S)%g' \
    -e 's%#{username}%#(cut -c3- ~/.tmux.conf | sh -s _username #{pane_pid} #{b:pane_tty} false #D)%g' \
    -e 's%#{hostname}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} false false #h #D)%g' \
    -e 's%#{hostname_full}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} false true #H #D)%g' \
    -e 's%#{username_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _username #{pane_pid} #{b:pane_tty} true #D)%g' \
    -e 's%#{hostname_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} true false #h #D)%g' \
    -e 's%#{hostname_full_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} true true #H #D)%g')

  window_status_format=$(printf '%s' "${window_status_format:-$(tmux show -gv window-status-format)}" | sed \
    -e 's%#{circled_window_index}%#(cut -c3- ~/.tmux.conf | sh -s _circled #I)%g' \
    -e 's%#{circled_session_name}%#(cut -c3- ~/.tmux.conf | sh -s _circled #S)%g' \
    -e 's%#{username}%#(cut -c3- ~/.tmux.conf | sh -s _username #{pane_pid} #{b:pane_tty} false #D)%g' \
    -e 's%#{hostname}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} false false #h #D)%g' \
    -e 's%#{hostname_full}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} false true #H #D)%g' \
    -e 's%#{username_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _username #{pane_pid} #{b:pane_tty} true #D)%g' \
    -e 's%#{hostname_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} true false #h #D)%g' \
    -e 's%#{hostname_full_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} true true #H #D)%g')

  window_status_current_format=$(printf '%s' "${window_status_current_format:-$(tmux show -gv window-status-current-format)}" | sed \
    -e 's%#{circled_window_index}%#(cut -c3- ~/.tmux.conf | sh -s _circled #I)%g' \
    -e 's%#{circled_session_name}%#(cut -c3- ~/.tmux.conf | sh -s _circled #S)%g' \
    -e 's%#{username}%#(cut -c3- ~/.tmux.conf | sh -s _username #{pane_pid} #{b:pane_tty} false #D)%g' \
    -e 's%#{hostname}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} false false #h #D)%g' \
    -e 's%#{hostname_full}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} false true #H #D)%g' \
    -e 's%#{username_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _username #{pane_pid} #{b:pane_tty} true #D)%g' \
    -e 's%#{hostname_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} true false #h #D)%g' \
    -e 's%#{hostname_full_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} true true #H #D)%g')

  status_left=$(printf '%s' "${status_left:-$(tmux show -gv status-left)}" | sed \
    -e "s/#{pairing}/#{?session_many_attached,$tmux_conf_theme_pairing ,}/g" \
    -e "s/#{prefix}/#{?client_prefix,$tmux_conf_theme_prefix ,$(printf "$tmux_conf_theme_prefix" | sed -e 's/./ /g') }/g" \
    -e "s/#{mouse}/#{?mouse,$tmux_conf_theme_mouse ,$(printf "$tmux_conf_theme_mouse" | sed -e 's/./ /g') }/g" \
    -e "s%#{synchronized}%#{?pane_synchronized,$tmux_conf_theme_synchronized ,}%g" \
    -e "s%#{circled_session_name}%#(cut -c3- ~/.tmux.conf | sh -s _circled #S)%g" \
    -e "s%#{root}%#{?#{==:#(cut -c3- ~/.tmux.conf | sh -s _username #{pane_pid} #{b:pane_tty} #D),root},$tmux_conf_theme_root,}%g")

  status_right=$(printf '%s' "${status_right:-$(tmux show -gv status-right)}" | sed \
    -e "s/#{pairing}/#{?session_many_attached,$tmux_conf_theme_pairing ,}/g" \
    -e "s/#{prefix}/#{?client_prefix,$tmux_conf_theme_prefix ,$(printf "$tmux_conf_theme_prefix" | sed -e 's/./ /g') }/g" \
    -e "s/#{mouse}/#{?mouse,$tmux_conf_theme_mouse ,$(printf "$tmux_conf_theme_mouse" | sed -e 's/./ /g') }/g" \
    -e "s%#{synchronized}%#{?pane_synchronized,$tmux_conf_theme_synchronized ,}%g" \
    -e "s%#{circled_session_name}%#(cut -c3- ~/.tmux.conf | sh -s _circled #S)%g" \
    -e "s%#{root}%#{?#{==:#(cut -c3- ~/.tmux.conf | sh -s _username #{pane_pid} #{b:pane_tty} #D),root},$tmux_conf_theme_root,}%g")

  tmux_conf_battery_bar_symbol_full=$(_decode_unicode_escapes "${tmux_conf_battery_bar_symbol_full:-◼}")
  tmux_conf_battery_bar_symbol_empty=$(_decode_unicode_escapes "${tmux_conf_battery_bar_symbol_empty:-◻}")
  tmux_conf_battery_bar_length=${tmux_conf_battery_bar_length:-auto}
  tmux_conf_battery_bar_palette=${tmux_conf_battery_bar_palette:-gradient}
  tmux_conf_battery_hbar_palette=${tmux_conf_battery_hbar_palette:-gradient}
  tmux_conf_battery_vbar_palette=${tmux_conf_battery_vbar_palette:-gradient}
  tmux_conf_battery_status_charging=$(_decode_unicode_escapes "${tmux_conf_battery_status_charging:-↑}")        # U+2191
  tmux_conf_battery_status_discharging=$(_decode_unicode_escapes "${tmux_conf_battery_status_discharging:-↓}")  # U+2193

  _pkillf 'cut -c3- ~/\.tmux\.conf \| sh -s _battery_bar'
  _battery_info
  if [ "$charge" != 0 ]; then
    case "$status_left $status_right" in
      *'#{battery_'*|*'#{?battery_'*)
        status_left=$(echo "$status_left" | sed -E \
          -e 's/#\{(\?)?battery_bar/#\{\1@battery_bar/g' \
          -e 's/#\{(\?)?battery_hbar/#\{\1@battery_hbar/g' \
          -e 's/#\{(\?)?battery_vbar/#\{\1@battery_vbar/g' \
          -e 's/#\{(\?)?battery_status/#\{\1@battery_status/g' \
          -e 's/#\{(\?)?battery_percentage/#\{\1@battery_percentage/g')
        status_right=$(echo "$status_right" | sed -E \
          -e 's/#\{(\?)?battery_bar/#\{\1@battery_bar/g' \
          -e 's/#\{(\?)?battery_hbar/#\{\1@battery_hbar/g' \
          -e 's/#\{(\?)?battery_vbar/#\{\1@battery_vbar/g' \
          -e 's/#\{(\?)?battery_status/#\{\1@battery_status/g' \
          -e 's/#\{(\?)?battery_percentage/#\{\1@battery_percentage/g')
        status_right="#(echo; nice cut -c3- ~/.tmux.conf | sh -s _battery_status \"$tmux_conf_battery_status_charging\" \"$tmux_conf_battery_status_discharging\")$status_right"
        interval=60
        if [ $_tmux_version -ge 320 ]; then
          tmux run -b "trap '[ -n \"\$sleep_pid\" ] && kill -9 \$sleep_pid; exit 0' TERM; while [ x\"\$(tmux -S '#{socket_path}' display -p '#{l:#{pid}}')\" = x\"#{pid}\" ]; do nice cut -c3- ~/.tmux.conf | sh -s _battery_bar \"$tmux_conf_battery_bar_symbol_full\" \"$tmux_conf_battery_bar_symbol_empty\" \"$tmux_conf_battery_bar_length\" \"$tmux_conf_battery_bar_palette\" \"$tmux_conf_battery_hbar_palette\" \"$tmux_conf_battery_vbar_palette\"; sleep $interval & sleep_pid=\$!; wait \$sleep_pid; sleep_pid=; done"
        elif [ $_tmux_version -ge 280 ]; then
          status_right="#(echo; while [ x\"\$(tmux -S '#{socket_path}' display -p '#{l:#{pid}}')\" = x\"#{pid}\" ]; do nice cut -c3- ~/.tmux.conf | sh -s _battery_bar \"$tmux_conf_battery_bar_symbol_full\" \"$tmux_conf_battery_bar_symbol_empty\" \"$tmux_conf_battery_bar_length\" \"$tmux_conf_battery_bar_palette\" \"$tmux_conf_battery_hbar_palette\" \"$tmux_conf_battery_vbar_palette\"; sleep $interval; done)$status_right"
        elif [ $_tmux_version -gt 240 ]; then
          status_right="#(echo; while :; do nice cut -c3- ~/.tmux.conf | sh -s _battery_bar \"$tmux_conf_battery_bar_symbol_full\" \"$tmux_conf_battery_bar_symbol_empty\" \"$tmux_conf_battery_bar_length\" \"$tmux_conf_battery_bar_palette\" \"$tmux_conf_battery_hbar_palette\" \"$tmux_conf_battery_vbar_palette\"; sleep $interval; done)$status_right"
        else
          status_right="#(nice cut -c3- ~/.tmux.conf | sh -s _battery_bar \"$tmux_conf_battery_bar_symbol_full\" \"$tmux_conf_battery_bar_symbol_empty\" \"$tmux_conf_battery_bar_length\" \"$tmux_conf_battery_bar_palette\" \"$tmux_conf_battery_hbar_palette\" \"$tmux_conf_battery_vbar_palette\")$status_right"
        fi
        ;;
    esac
  fi

  case "$status_left $status_right" in
    *'#{username}'*|*'#{hostname}'*|*'#{hostname_full}'*|*'#{username_ssh}'*|*'#{hostname_ssh}'*|*'#{hostname_full_ssh}'*)
      status_left=$(echo "$status_left" | sed \
        -e 's%#{username}%#(cut -c3- ~/.tmux.conf | sh -s _username #{pane_pid} #{b:pane_tty} false #D)%g' \
        -e 's%#{hostname}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} false false #h #D)%g' \
        -e 's%#{hostname_full}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} false true #H #D)%g' \
        -e 's%#{username_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _username #{pane_pid} #{b:pane_tty} true #D)%g' \
        -e 's%#{hostname_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} true false #h #D)%g' \
        -e 's%#{hostname_full_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} true true #H #D)%g')
      status_right=$(echo "$status_right" | sed \
        -e 's%#{username}%#(cut -c3- ~/.tmux.conf | sh -s _username #{pane_pid} #{b:pane_tty} false #D)%g' \
        -e 's%#{hostname}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} false false #h #D)%g' \
        -e 's%#{hostname_full}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} false true #H #D)%g' \
        -e 's%#{username_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _username #{pane_pid} #{b:pane_tty} true #D)%g' \
        -e 's%#{hostname_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} true false #h #D)%g' \
        -e 's%#{hostname_full_ssh}%#(cut -c3- ~/.tmux.conf | sh -s _hostname #{pane_pid} #{b:pane_tty} true true #H #D)%g')
      ;;
  esac

  _pkillf 'cut -c3- ~/\.tmux\.conf \| sh -s _uptime'
  case "$status_left $status_right" in
    *'#{uptime_'*|*'#{?uptime_'*)
      status_left=$(echo "$status_left" | perl -p -e '
        ; s/#\{(\?)?uptime_y\b/#\{\1\@uptime_y/g
        ; s/#\{(\?)?uptime_d\b/#\{\1\@uptime_d/g
        ; s/\@uptime_d\b/\@uptime_dy/g if /\@uptime_y\b/
        ; s/#\{(\?)?uptime_h\b/#\{\1\@uptime_h/g
        ; s/#\{(\?)?uptime_m\b/#\{\1\@uptime_m/g
        ; s/#\{(\?)?uptime_s\b/#\{\1\@uptime_s/g')
      status_right=$(echo "$status_right" | perl -p -e '
        ; s/#\{(\?)?uptime_y\b/#\{\1\@uptime_y/g
        ; s/#\{(\?)?uptime_d\b/#\{\1\@uptime_d/g
        ; s/\@uptime_d\b/\@uptime_dy/g if /\@uptime_y\b/
        ; s/#\{(\?)?uptime_h\b/#\{\1\@uptime_h/g
        ; s/#\{(\?)?uptime_m\b/#\{\1\@uptime_m/g
        ; s/#\{(\?)?uptime_s\b/#\{\1\@uptime_s/g')
      interval=60
      case "$status_left $status_right" in
        *'#{@uptime_s}'*)
          interval=$(tmux show -gv status-interval)
          ;;
      esac
      if [ $_tmux_version -ge 320 ]; then
        tmux run -b "trap '[ -n \"\$sleep_pid\" ] && kill -9 \$sleep_pid; exit 0' TERM; while [ x\"\$(tmux -S '#{socket_path}' display -p '#{l:#{pid}}')\" = x\"#{pid}\" ]; do nice cut -c3- ~/.tmux.conf | sh -s _uptime; sleep $interval & sleep_pid=\$!; wait \$sleep_pid; sleep_pid=; done"
      elif [ $_tmux_version -gt 280 ]; then
        status_right="#(echo; while [ x\"\$(tmux -S '#{socket_path}' display -p '#{l:#{pid}}')\" = x\"#{pid}\" ]; do nice cut -c3- ~/.tmux.conf | sh -s _uptime; sleep $interval; done)$status_right"
      elif [ $_tmux_version -gt 240 ]; then
        status_right="#(echo; while :; do nice cut -c3- ~/.tmux.conf | sh -s _uptime; sleep $interval; done)$status_right"
      else
        status_right="#(nice cut -c3- ~/.tmux.conf | sh -s _uptime)$status_right"
      fi
      ;;
  esac

  _pkillf 'cut -c3- ~/\.tmux\.conf \| sh -s _loadavg'
  case "$status_left $status_right" in
    *'#{loadavg'*|*'#{?loadavg'*)
      status_left=$(echo "$status_left" | sed -E \
        -e 's/#\{(\?)?loadavg/#\{\1@loadavg/g')
      status_right=$(echo "$status_right" | sed -E \
        -e 's/#\{(\?)?loadavg/#\{\1@loadavg/g')
      interval=$(tmux show -gv status-interval)
      if [ $_tmux_version -ge 320 ]; then
        tmux run -b "trap '[ -n \"\$sleep_pid\" ] && kill -9 \$sleep_pid; exit 0' TERM; while [ x\"\$(tmux -S '#{socket_path}' display -p '#{l:#{pid}}')\" = x\"#{pid}\" ]; do nice cut -c3- ~/.tmux.conf | sh -s _loadavg; sleep $interval & sleep_pid=\$!; wait \$sleep_pid; sleep_pid=; done"
      elif [ $_tmux_version -gt 280 ]; then
        status_right="#(echo; while [ x\"\$(tmux -S '#{socket_path}' display -p '#{l:#{pid}}')\" = x\"#{pid}\" ]; do nice cut -c3- ~/.tmux.conf | sh -s _loadavg; sleep $interval; done)$status_right"
      elif [ $_tmux_version -gt 240 ]; then
        status_right="#(echo; while :; do nice cut -c3- ~/.tmux.conf | sh -s _loadavg; sleep $interval; done)$status_right"
      else
        status_right="#(nice cut -c3- ~/.tmux.conf | sh -s _loadavg)$status_right"
      fi
      ;;
  esac

  # -- custom variables ------------------------------------------------------

  if [ -f ~/.tmux.conf.local ] && [ x"$(cut -c3- ~/.tmux.conf.local | sh 2>/dev/null -s printf probe)" = x"probe" ]; then
    replacements=$(perl -n -e 'print if s!^#\s+([^_][^()\s]+)\s*\(\)\s*{\s*(?:#.*)?\n!s%#\\\{\1((?:\\s+(?:[^\{\}]+?|#\\{(?:[^\{\}]+?)\}))*)\\\}%#(cut -c3- ~/.tmux.conf.local | sh -s \1\\1)%g; !p' < ~/.tmux.conf.local)
    status_left=$(echo "$status_left" | perl -p -e "$replacements" || echo "$status_left")
    status_right=$(echo "$status_right" | perl -p -e "$replacements" || echo "$status_right")
  fi

  # --------------------------------------------------------------------------

  tmux set -g set-titles-string "$(_decode_unicode_escapes "$set_titles_string")" \;\
       setw -g window-status-format "$(_decode_unicode_escapes "$window_status_format")" \;\
       setw -g window-status-current-format "$(_decode_unicode_escapes "$window_status_current_format")" \;\
       set -g status-left-length 1000 \; set -g status-left "$(_decode_unicode_escapes "$status_left")" \;\
       set -g status-right-length 1000 \; set -g status-right "$(_decode_unicode_escapes "$status_right")"
}

__apply_plugins() {
  window_active="$1"
  tmux_conf_update_plugins_on_launch="$2"
  tmux_conf_update_plugins_on_reload="$3"
  tmux_conf_uninstall_plugins_on_reload="$4"

  TMUX_PLUGIN_MANAGER_PATH=${TMUX_PLUGIN_MANAGER_PATH:-~/.tmux/plugins}
  if [ -z "$(tmux show -gv '@plugin')" ] && [ -z "$(tmux show -gv '@tpm_plugins')" ]; then
    if _is_true "$tmux_conf_uninstall_plugins_on_reload" && [ -d "$TMUX_PLUGIN_MANAGER_PATH/tpm" ]; then
      tmux display 'Uninstalling tpm and plugins...'
      rm -rf "$TMUX_PLUGIN_MANAGER_PATH"
      tmux display 'Done uninstalling tpm and plugins...'
    fi
  else
    if git ls-remote -hq https://github.com/gpakosz/.tmux.git master > /dev/null; then
      if [ ! -d "$TMUX_PLUGIN_MANAGER_PATH/tpm" ]; then
        install_tpm=true
        tmux display 'Installing tpm and plugins...'
        git clone --depth 1 https://github.com/tmux-plugins/tpm "$TMUX_PLUGIN_MANAGER_PATH/tpm"
      elif { [ -z "$window_active" ] && _is_true "$tmux_conf_update_plugins_on_launch"; } || { [ -n "$window_active" ] && _is_true "$tmux_conf_update_plugins_on_reload"; }; then
        update_tpm=true
        tmux display 'Updating tpm and plugins...'
        (cd "$TMUX_PLUGIN_MANAGER_PATH/tpm" && git fetch -q -p && git checkout -q master && git reset -q --hard origin/master)
      fi
      if [ x"$install_tpm" = x"true" ] || [ x"$update_tpm" = x"true" ]; then
        perl -0777 -p -i -e 's/git clone(?!\s+--depth\s+1)/git clone --depth 1/g
                            ;s/(install_plugin(.(?!&))*)\n(\s+)done/\1&\n\3done\n\3wait/g' "$TMUX_PLUGIN_MANAGER_PATH/tpm/scripts/install_plugins.sh"
        perl -p -i -e 's/git submodule update --init --recursive(?!\s+--depth\s+1)/git submodule update --init --recursive --depth 1/g' "$TMUX_PLUGIN_MANAGER_PATH/tpm/scripts/update_plugin.sh"
        perl -p -i -e 's,\$tmux_file\s+>/dev/null\s+2>\&1,$& || { tmux display "Plugin \$(basename \${plugin_path}) failed" && false; },' "$TMUX_PLUGIN_MANAGER_PATH/tpm/scripts/source_plugins.sh"
        tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$TMUX_PLUGIN_MANAGER_PATH"
      fi
      if [ x"$update_tpm" = x"true" ]; then
        {
          echo "Invoking $TMUX_PLUGIN_MANAGER_PATH/tpm/bin/install_plugins ..." > "$TMUX_PLUGIN_MANAGER_PATH/tpm_log.txt" 2>&1 && \
          "$TMUX_PLUGIN_MANAGER_PATH/tpm/bin/install_plugins" >> "$TMUX_PLUGIN_MANAGER_PATH/tpm_log.txt" 2>&1     &&\
          echo "Invoking $TMUX_PLUGIN_MANAGER_PATH/tpm/bin/update_plugins all ..." > "$TMUX_PLUGIN_MANAGER_PATH/tpm_log.txt" 2>&1 && \
          "$TMUX_PLUGIN_MANAGER_PATH/tpm/bin/update_plugins" all >> "$TMUX_PLUGIN_MANAGER_PATH/tpm_log.txt" 2>&1  &&\
          echo "Invoking $TMUX_PLUGIN_MANAGER_PATH/tpm/bin/clean_plugins all ..." > "$TMUX_PLUGIN_MANAGER_PATH/tpm_log.txt" 2>&1 && \
          "$TMUX_PLUGIN_MANAGER_PATH/tpm/bin/clean_plugins" all >> "$TMUX_PLUGIN_MANAGER_PATH/tpm_log.txt" 2>&1   &&\
          tmux display 'Done updating tpm and plugins...'
        } || tmux display 'Failed updating tpm and plugins...'
      elif [ x"$install_tpm" = x"true" ]; then
        {
          echo "Invoking $TMUX_PLUGIN_MANAGER_PATH/tpm/bin/install_plugins ..." > "$TMUX_PLUGIN_MANAGER_PATH/tpm_log.txt" 2>&1 && \
          "$TMUX_PLUGIN_MANAGER_PATH/tpm/bin/install_plugins" >> "$TMUX_PLUGIN_MANAGER_PATH/tpm_log.txt" 2>&1
          tmux display 'Done installing tpm and plugins...'
        } || tmux display 'Failed installing tpm and plugins...'
      fi
    else
      tmux display "GitHub doesn't seem to be reachable, skipping installing and/or updating tpm and plugins..."
    fi

    [ -z "$(tmux show -gqv '@tpm-install')" ] && tmux set -g '@tpm-install' 'I'
    [ -z "$(tmux show -gqv '@tpm-update')" ] && tmux set -g '@tpm-update' 'u'
    [ -z "$(tmux show -gqv '@tpm-clean')" ] && tmux set -g '@tpm-clean' 'M-u'
    [ -f "$TMUX_PLUGIN_MANAGER_PATH/tpm/tpm" ] && "$TMUX_PLUGIN_MANAGER_PATH/tpm/tpm" || tmux display "One or more tpm plugin(s) failed"
    if [ $_tmux_version -gt 260 ]; then
      tmux set -gu '@tpm-install' \; set -gu '@tpm-update' \; set -gu '@tpm-clean' \; set -gu '@plugin'
    fi
  fi
}

_apply_plugins() {
  tmux_conf_update_plugins_on_launch=${tmux_conf_update_plugins_on_launch:-true}
  tmux_conf_update_plugins_on_reload=${tmux_conf_update_plugins_on_reload:-true}
  tmux_conf_uninstall_plugins_on_reload=${tmux_conf_uninstall_plugins_on_reload:-true}
  tmux run -b "cut -c3- ~/.tmux.conf | sh -s __apply_plugins \"$window_active\" \"$tmux_conf_update_plugins_on_launch\" \"$tmux_conf_update_plugins_on_reload\" \"$tmux_conf_uninstall_plugins_on_reload\""
}

_apply_important() {
  cfg=$(mktemp) && trap 'rm -f $cfg*' EXIT

  if perl -n -e 'print if /^\s*(?:set|bind|unbind).+?#!important\s*$/' ~/.tmux.conf.local 2>/dev/null > "$cfg.local"; then
    if ! tmux source-file "$cfg.local"; then
      verbose_flag=$(tmux source-file -v /dev/null 2> /dev/null && printf -- '-v' || true)
      while ! out=$(tmux source-file "$verbose_flag" "$cfg.local"); do
        line=$(printf "%s" "$out" | tail -1 | cut -d':' -f2)
        perl -n -i -e "if ($. != $line) { print }" "$cfg.local"
      done
    fi
  fi
}

_apply_configuration() {
  window_active="$(tmux display -p '#{window_active}' 2>/dev/null || true)"
  if [ -z "$window_active" ]; then
    if ! command -v perl > /dev/null 2>&1; then
      tmux run -b 'tmux set display-time 3000 \; display "This configuration requires perl" \; set -u display-time \; run "sleep 3" \; kill-server'
      return
    fi
    if ! command -v sed > /dev/null 2>&1; then
      tmux run -b 'tmux set display-time 3000 \; display "This configuration requires sed" \; set -u display-time \; run "sleep 3" \; kill-server'
      return
    fi
    if ! command -v awk > /dev/null 2>&1; then
      tmux run -b 'tmux set display-time 3000 \; display "This configuration requires awk" \; set -u display-time \; run "sleep 3" \; kill-server'
      return
    fi
    if [ $_tmux_version -lt 240 ]; then
      tmux run -b 'tmux set display-time 3000 \; display "This configuration requires tmux 2.4+" \; set -u display-time \; run "sleep 3" \; kill-server'
      return
    fi
  fi

  # see https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard
  if command -v reattach-to-user-namespace > /dev/null 2>&1; then
    default_shell="$(tmux show -gv default-shell)"
    case "$default_shell" in
      *fish)
        tmux set -g default-command "reattach-to-user-namespace -l $default_shell"
        ;;
      *sh)
        tmux set -g default-command "exec $default_shell... 2> /dev/null & reattach-to-user-namespace -l $default_shell"
        ;;
    esac
  fi

  case "$_uname_s" in
    *CYGWIN*|*MSYS*)
      # prevent Cygwin and MSYS2 from cd-ing into home directory when evaluating /etc/profile
      tmux setenv -g CHERE_INVOKING 1
      ;;
  esac

  #Se ha comentado porque no esta funcionando la deteccion de color, se establece manualmente en el archivo 'tmux.conf'
  #_apply_tmux_256color
  #_apply_24b&
  _apply_theme&
  _apply_bindings&
  wait

  _apply_plugins
  _apply_important

  # shellcheck disable=SC2046
  tmux setenv -gu tmux_conf_dummy $(printenv | grep -E -o '^tmux_conf_[^=]+' | awk '{printf "; setenv -gu %s", $0}')
}

_urlview() {
  tmux capture-pane -J -S - -E - -b "urlview-$1" -t "$1"
  tmux split-window "tmux show-buffer -b urlview-$1 | urlview || true; tmux delete-buffer -b urlview-$1"
}

_fpp() {
  tmux capture-pane -J -S - -E - -b "fpp-$1" -t "$1"
  tmux split-window -c $2 "tmux show-buffer -b fpp-$1 | fpp || true; tmux delete-buffer -b fpp-$1"
}

"$@"
