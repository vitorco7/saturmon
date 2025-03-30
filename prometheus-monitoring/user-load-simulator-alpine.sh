#!/bin/sh

while true; do
    echo "[INFO] Starting multi-resource stress test..."

    # Generate random parameters
    cpu_workers=$((RANDOM % 2 + 1))       # 1–2 CPU workers
    vm_workers=$((RANDOM % 2 + 1))        # 1–2 RAM workers
    vm_bytes=$((RANDOM % 128 + 64))M      # 64M–191M per VM worker
    hdd_workers=1                         # 1 HDD worker (can be randomized too)
    hdd_bytes=$((RANDOM % 100 + 50))M     # 50M–149M disk I/O
    net_workers=1                         # 1 network stressor
    stress_time=$((RANDOM % 16 + 10))s    # 10–25 seconds
    sleep_time=$((RANDOM % 20 + 10))      # 10–30 seconds

    echo "[INFO] CPU: $cpu_workers workers"
    echo "[INFO] RAM: $vm_workers workers, $vm_bytes per worker"
    echo "[INFO] Disk: $hdd_workers workers, $hdd_bytes total"
    echo "[INFO] Network: $net_workers worker"
    echo "[INFO] Stress duration: $stress_time"
    echo "[INFO] Sleeping after stress for $sleep_time seconds"

    # Run all stressors in the background
    stress-ng --cpu "$cpu_workers" --timeout "$stress_time" &
    stress-ng --vm "$vm_workers" --vm-bytes "$vm_bytes" --timeout "$stress_time" &
    stress-ng --hdd "$hdd_workers" --hdd-bytes "$hdd_bytes" --timeout "$stress_time" &
    stress-ng --sock "$net_workers" --timeout "$stress_time" &

    # Wait for all to finish
    wait

    # Sleep before next run
    sleep "$sleep_time"
done
