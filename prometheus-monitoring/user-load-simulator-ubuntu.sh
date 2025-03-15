#!/bin/bash

while true; do
    case $((RANDOM % 3)) in
        0) echo "[INFO] Running light CPU stress..."; stress-ng --cpu 1 --timeout 15s ;;
        1) echo "[INFO] Running light RAM stress..."; stress-ng --vm 1 --vm-bytes 64M --timeout 15s ;;
        2) echo "[INFO] Running light Disk I/O stress..."; stress-ng --hdd 1 --hdd-bytes 50M --timeout 15s ;;
    esac
    sleep $((RANDOM % 20 + 10))  # Sleep between 10-30 seconds
done