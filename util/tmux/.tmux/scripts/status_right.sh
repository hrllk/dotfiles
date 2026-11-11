#!/usr/bin/env bash
# Whole status-right segment in one process.
#
# Replaces tmux-cpu, which spawned three processes per refresh and recomputed
# the CPU figure in each. Its macOS path runs `iostat -c 2`, which blocks for a
# second; at a 2s interval that is most of a core.
#
# CPU is load-per-core, not utilisation: macOS has no kern.cp_time, `top -l 1`
# costs 600ms, and summing `ps -A -o %cpu` reports about half the true figure.
# iostat was printing these same load averages in its last three columns.
set -u

read -r ncpu total <<< "$(sysctl -n hw.ncpu hw.memsize | tr '\n' ' ')"
load=$(sysctl -n vm.loadavg | awk '{print $2}')
cpu=$(awk -v l="$load" -v n="$ncpu" 'BEGIN { printf "%.0f", 100 * l / n }')

stats=$(vm_stat) || exit 0
mem=$(awk -v total="$total" '
  /page size of/      { ps = $8 }
  /Pages active:/     { gsub("\\.", "", $NF); a = $NF }
  /Pages wired down:/ { gsub("\\.", "", $NF); w = $NF }
  END { if (ps && total) printf "%.0f", 100 * (a + w) * ps / total }
' <<< "$stats")

# No orange: that colour means "a window wants you" everywhere else.
paint() {
  if   (( $1 >= 80 )); then printf '#[fg=#FB617E]󰁹'
  elif (( $1 >= 50 )); then printf '#[fg=#EDC763]󰁾'
  else                      printf '#[fg=#E1E3E4]󰁺'
  fi
}

printf 'CU %s %s%%#[fg=default] ▸ MU %s %s%%#[fg=default] \n' \
  "$(paint "$cpu")" "$cpu" "$(paint "${mem:-0}")" "${mem:-0}"
