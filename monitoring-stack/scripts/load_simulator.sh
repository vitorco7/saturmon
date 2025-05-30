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

    # 1. CPU Tests
    echo "$(timestamp) [INFO] === Starting CPU Tests ==="
    
    # CPU Test
    cpu_workers=$((RANDOM % 3 + 2))   # 2 or 3 workers for moderate load
    echo "$(timestamp) [INFO] [CPU] Workers: $cpu_workers, Duration: $stress_time"
    stress-ng --cpu "$cpu_workers" --timeout "$stress_time"
    
    # CPU Cache Stress
    cpu_cache_workers=$((RANDOM % 3 + 2))
    echo "$(timestamp) [INFO] [CPU Cache] Workers: $cpu_cache_workers, Duration: $stress_time"
    stress-ng --cache "$cpu_cache_workers" --timeout "$stress_time"
    
    # CPU Floating Point Stress
    cpu_float_workers=$((RANDOM % 3 + 2))
    echo "$(timestamp) [INFO] [CPU Float] Workers: $cpu_float_workers, Duration: $stress_time"
    stress-ng --matrix "$cpu_float_workers" --timeout "$stress_time"
    
    # CPU Pipe Stress
    cpu_pipe_workers=$((RANDOM % 3 + 2))
    echo "$(timestamp) [INFO] [CPU Pipe] Workers: $cpu_pipe_workers, Duration: $stress_time"
    stress-ng --pipe "$cpu_pipe_workers" --timeout "$stress_time"
    
    echo "$(timestamp) [INFO] === Completed CPU Tests ==="

    # 2. Memory Tests
    echo "$(timestamp) [INFO] === Starting Memory Tests ==="
    
    # Memory Test
    vm_workers=$((RANDOM % 2 + 1))   # 1 or 2 workers for moderate load
    vm_bytes=$((RANDOM % 128 + 480))M  # Memory load between 480MB to 608MB per worker (25% increase)
    echo "$(timestamp) [INFO] [Memory] Workers: $vm_workers, Bytes per worker: $vm_bytes, Duration: $stress_time"
    stress-ng --vm "$vm_workers" --vm-bytes "$vm_bytes" --timeout "$stress_time"

    echo "$(timestamp) [INFO] === Completed Memory Tests ==="

    # 3. Disk I/O Tests
    echo "$(timestamp) [INFO] === Starting Disk I/O Tests ==="
    
    # Disk I/O Test
    hdd_workers=1
    hdd_bytes=$((RANDOM % 50 + 100))M  # Disk I/O size between 100MB to 150MB
    echo "$(timestamp) [INFO] [Disk I/O] Workers: $hdd_workers, Bytes: $hdd_bytes, Duration: $stress_time"
    stress-ng --hdd "$hdd_workers" --hdd-bytes "$hdd_bytes" --timeout "$stress_time"

    # Random Write Stress
    echo "$(timestamp) [INFO] [Disk I/O Random Write] Duration: $stress_time"
    stress-ng --hdd 1 --hdd-opts wr-rnd --timeout "$stress_time"

    # Disk Bandwidth Stress
    echo "$(timestamp) [INFO] [Disk Bandwidth] Duration: $stress_time"
    stress-ng --hdd 1 --hdd-opts wr-seq --timeout "$stress_time"

    echo "$(timestamp) [INFO] === Completed Disk I/O Tests ==="

    # 4. Network Tests
    echo "$(timestamp) [INFO] === Starting Network Tests ==="
    
    # Network Test
    net_workers=2   # Increase network load by using 2 workers
    echo "$(timestamp) [INFO] [Network] Workers: $net_workers, Duration: $stress_time"
    # stress-ng --sock "$net_workers" --timeout "$stress_time"

    # Run iperf3 client test to iperf3 server
    iperf3 -c iperf3 -t 5 || echo "iperf3 test failed"

    echo "$(timestamp) [INFO] === Completed Network Tests ==="

    # 5. System Tests
    echo "$(timestamp) [INFO] === Starting System Tests ==="
    
    # System Test (e.g., fork)
    system_workers=2   # Increase system load by using 2 workers
    echo "$(timestamp) [INFO] [System] 'Fork' workers: $system_workers, Duration: $stress_time"
    stress-ng --fork "$system_workers" --timeout "$stress_time"

    echo "$(timestamp) [INFO] === Completed System Tests ==="

    echo "$(timestamp) [INFO] === Completed Serial Tests, sleeping for $sleep_time seconds ==="
    sleep "$sleep_time"

    #### Block 2: Parallel Stress Tests ####
    echo "$(timestamp) [INFO] === Starting Parallel Multi-Resource Stress Tests (Block 2) ==="

    # Parallel block stress and sleep durations
    stress_time=$((RANDOM % 6 + 25))s     # 25–30 seconds
    sleep_time=$((RANDOM % 20 + 10))      # 10–30 seconds

    # Regenerate parameters
    cpu_workers=$((RANDOM % 3 + 2))   # 2 or 3 workers for CPU stress
    vm_workers=$((RANDOM % 2 + 1))   # 1 or 2 workers for memory stress
    vm_bytes=$((RANDOM % 128 + 480))M  # Memory load between 480MB to 608MB per worker (25% increase)
    hdd_bytes=$((RANDOM % 50 + 100))M  # Disk I/O size between 100MB to 150MB
    net_workers=2   # 2 workers for network stress
    system_workers=2  # 2 workers for system stress

    echo "$(timestamp) [INFO] CPU: $cpu_workers, VM: $vm_workers x $vm_bytes, HDD: $hdd_bytes, Network: $net_workers, System: $system_workers"
    echo "$(timestamp) [INFO] Running all in parallel for $stress_time"

    stress-ng --cpu "$cpu_workers" --timeout "$stress_time" &
    stress-ng --vm "$vm_workers" --vm-bytes "$vm_bytes" --timeout "$stress_time" &
    stress-ng --hdd 1 --hdd-bytes "$hdd_bytes" --timeout "$stress_time" &
    stress-ng --sock "$net_workers" --timeout "$stress_time" &
    stress-ng --fork "$system_workers" --timeout "$stress_time" &

    # Parallel block with additional tests
    stress-ng --cache "$cpu_cache_workers" --timeout "$stress_time" &
    stress-ng --matrix "$cpu_float_workers" --timeout "$stress_time" &
    stress-ng --pipe "$cpu_pipe_workers" --timeout "$stress_time" &
    stress-ng --hdd 1 --hdd-opts wr-rnd --timeout "$stress_time" &
    stress-ng --hdd 1 --hdd-opts wr-seq --timeout "$stress_time" &

    # Run iperf3 client test to iperf3 server (parallel)
    iperf3 -c iperf3 -t 5 || echo "iperf3 test failed (parallel)" &

    wait
    echo "$(timestamp) [INFO] === Completed Parallel Tests, sleeping for $sleep_time seconds ==="
    sleep "$sleep_time"
done
