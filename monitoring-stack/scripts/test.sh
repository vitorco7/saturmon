#!/bin/bash

timestamp() {
    date +"[%Y-%m-%d %H:%M:%S]"
}

while true; do
    echo "$(timestamp) [INFO] === Starting Serial Stress Tests (Block 1) ==="

    # Serial block stress and sleep durations
    stress_time=$((RANDOM % 11 + 15))s    # 15–25 seconds
    sleep_time=$((RANDOM % 20 + 10))      # 10–30 seconds

    #### Block 1: Serial Stress Tests ####

    # 1. CPU Test
    cpu_workers=$((RANDOM % 2 + 1))
    echo "$(timestamp) [INFO] [CPU] Workers: $cpu_workers, Duration: $stress_time"
    stress-ng --cpu "$cpu_workers" --timeout "$stress_time"

    # 2. Memory Test
    vm_workers=$((RANDOM % 2 + 1))
    vm_bytes=$((RANDOM % 128 + 64))M
    echo "$(timestamp) [INFO] [Memory] Workers: $vm_workers, Bytes per worker: $vm_bytes, Duration: $stress_time"
    stress-ng --vm "$vm_workers" --vm-bytes "$vm_bytes" --timeout "$stress_time"

    # 3. Disk I/O Test
    hdd_workers=1
    hdd_bytes=$((RANDOM % 100 + 50))M
    echo "$(timestamp) [INFO] [Disk I/O] Workers: $hdd_workers, Bytes: $hdd_bytes, Duration: $stress_time"
    stress-ng --hdd "$hdd_workers" --hdd-bytes "$hdd_bytes" --timeout "$stress_time"

    # 4. Network Test
    net_workers=1
    echo "$(timestamp) [INFO] [Network] Workers: $net_workers, Duration: $stress_time"
    stress-ng --sock "$net_workers" --timeout "$stress_time"

    # 5. System Test (e.g., fork)
    system_workers=1
    echo "$(timestamp) [INFO] [System] 'Fork' workers: $system_workers, Duration: $stress_time"
    stress-ng --fork "$system_workers" --timeout "$stress_time"

    echo "$(timestamp) [INFO] === Completed Serial Tests, sleeping for $sleep_time seconds ==="
    sleep "$sleep_time"

    #### Block 2: Parallel Stress Tests ####
    echo "$(timestamp) [INFO] === Starting Parallel Multi-Resource Stress Tests (Block 2) ==="

    # Parallel block stress and sleep durations
    stress_time=$((RANDOM % 6 + 25))s     # 25–30 seconds
    sleep_time=$((RANDOM % 20 + 10))      # 10–30 seconds

    # Regenerate parameters
    cpu_workers=$((RANDOM % 2 + 1))
    vm_workers=$((RANDOM % 2 + 1))
    vm_bytes=$((RANDOM % 128 + 64))M
    hdd_bytes=$((RANDOM % 100 + 50))M
    net_workers=1
    system_workers=1

    echo "$(timestamp) [INFO] CPU: $cpu_workers, VM: $vm_workers x $vm_bytes, HDD: $hdd_bytes, Network: $net_workers, System: $system_workers"
    echo "$(timestamp) [INFO] Running all in parallel for $stress_time"

    stress-ng --cpu "$cpu_workers" --timeout "$stress_time" &
    stress-ng --vm "$vm_workers" --vm-bytes "$vm_bytes" --timeout "$stress_time" &
    stress-ng --hdd 1 --hdd-bytes "$hdd_bytes" --timeout "$stress_time" &
    stress-ng --sock "$net_workers" --timeout "$stress_time" &
    stress-ng --fork "$system_workers" --timeout "$stress_time" &

    wait
    echo "$(timestamp) [INFO] === Completed Parallel Tests, sleeping for $sleep_time seconds ==="
    sleep "$sleep_time"
done
