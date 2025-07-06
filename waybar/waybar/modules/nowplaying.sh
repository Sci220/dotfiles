#!/bin/bash

track=$(mpc current)

if [[ -n "$track" ]]; then
  echo "{\"text\": \"🎵 $track\", \"class\": \"nowplaying\"}"
else
  echo "{\"text\": \"🎵 Nothing Playing\", \"class\": \"nowplaying-muted\"}"
fi
