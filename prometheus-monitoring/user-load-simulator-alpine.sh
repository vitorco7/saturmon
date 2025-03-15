#!/bin/sh

while true; do
    num=$(od -An -N1 -i /dev/random | awk '{print $1 % 3}')
    case $num in
        0) echo "[INFO] Running light CPU stress..."; stress-ng --cpu 1 --timeout 15s ;;
        1) echo "[INFO] Running light RAM stress..."; stress-ng --vm 1 --vm-bytes 64M --timeout 15s ;;
        2) echo "[INFO] Running light Disk I/O stress..."; stress-ng --hdd 1 --hdd-bytes 50M --timeout 15s ;;
    esac
    sleep $(expr $(od -An -N1 -i /dev/random | awk '{print $1 % 20 + 10}'))  # Sleep 10-30s
done
