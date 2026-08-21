#!/usr/bin/env bash

stats=$(vm_stat) || exit 0
page_size=$(awk '/page size of/ {print $8; exit}' <<< "$stats")
active=$(awk '/Pages active:/ {gsub("\\.", "", $NF); print $NF; exit}' <<< "$stats")
wired=$(awk '/Pages wired down:/ {gsub("\\.", "", $NF); print $NF; exit}' <<< "$stats")
total=$(sysctl -n hw.memsize 2>/dev/null || true)

if [[ -z "$page_size" || -z "$active" || -z "$wired" || -z "$total" ]]; then
  exit 0
fi

used=$(( (active + wired) * page_size ))
percentage=$(awk -v used="$used" -v total="$total" 'BEGIN { printf "%.0f", 100 * used / total }')

if (( percentage >= 80 )); then
  color="#[fg=#FF0000]"
  icon="󰁹"
elif (( percentage >= 50 )); then
  color="#[fg=#FFA500]"
  icon="󰁾"
else
  color="#[fg=WHITE]"
  icon="󰁺"
fi

printf '%s%s %s%%#[fg=default]\n' "$color" "$icon" "$percentage"
