#!/usr/bin/env bash

PAGE_SIZE=$(vm_stat | awk '/page size of/ {print $8}')

vm_stat | awk -v ps=$PAGE_SIZE '
/Pages active/ {a=$NF}
/Pages wired down/ {w=$NF}
/Pages occupied by compressor/ {c=$NF}
END {
  gsub("\\.", "", a)
  gsub("\\.", "", w)
  gsub("\\.", "", c)

  used=(a+w+c)*ps
  total='"$(sysctl -n hw.memsize)"'

  printf "%d%%\n", (used/total)*100
}'
