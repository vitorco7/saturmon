#!/bin/bash

# Coordination directory
COORD_DIR="/var/run/load_coordinator"
ACTIVE_FILE="${COORD_DIR}/active_device"

# Get the hostname of this device
HOSTNAME=$(hostname)

# Global flag to control the main loop
RUNNING=true

# Signal handler function
cleanup() {
    echo "$(timestamp) [INFO] Received termination signal, shutting down gracefully..."
    RUNNING=false
    
    # Kill any background stress-ng processes
    pkill -f "stress-ng" 2>/dev/null
    pkill -f "iperf3" 2>/dev/null
    
    echo "$(timestamp) [INFO] Cleanup completed, exiting..."
    exit 0
}

# Set up signal handlers for SIGTERM (docker stop) and SIGINT (Ctrl+C)
trap cleanup SIGTERM SIGINT

timestamp() {
    date +"[%Y-%m-%d %H:%M:%S]"
}

# Function to check if this device is the active one
is_active_device() {
  if [ ! -f "${ACTIVE_FILE}" ]; then
    return 1  # False if file doesn't exist
  fi
  
  active=$(cat ${ACTIVE_FILE})
  if [ "${active}" = "${HOSTNAME}" ]; then
    return 0  # True
  else
    return 1  # False
  fi
}

# Make directory exists (just in case)
mkdir -p ${COORD_DIR}

# Wait for coordinator to be ready 
echo "$(timestamp) [INFO] Waiting for coordinator to initialize..."
while [ ! -f "${ACTIVE_FILE}" ] && $RUNNING; do
  sleep 2
done

echo "$(timestamp) [INFO] Load simulator started"

# Main loop
while $RUNNING; do
    # Check if this device should be active
    if ! is_active_device; then
        echo "$(timestamp) [INFO] This device is not active, waiting..."
        for i in $(seq 1 5); do
            if ! $RUNNING; then break 2; fi
            sleep 1
        done
        continue
    fi
    
    echo "$(timestamp) [INFO] This device is active, starting load simulation"
        
    echo "$(timestamp) [INFO] === Starting Serial Stress Tests (Block 1) ==="
    
    if ! $RUNNING; then break; fi
    
    # Serial block stress and sleep durations
    # OPTIMIZED: reduced stress time to 8-12 seconds
    stress_time=$((RANDOM % 5 + 8))s # 8-12 seconds
    # OPTIMIZED: reduced sleep time to 5-10 seconds
    sleep_time=$((RANDOM % 6 + 5)) # 5-10 seconds
    
    cpu_workers=$((RANDOM % 3 + 2))
    cpu_cache_workers=$((RANDOM % 3 + 2))
    cpu_float_workers=$((RANDOM % 3 + 2))
    cpu_pipe_workers=$((RANDOM % 3 + 2))
    vm_workers=$((RANDOM % 2 + 1))
    
    if [ "$vm_workers" -eq 1 ]; then
        vm_bytes=$((RANDOM % 101 + 500))M # 500–600MB/worker
    else
        vm_bytes=$((RANDOM % 163 + 350))M # 350–512MB/worker
    fi
    
    hdd_workers=1
    hdd_bytes=$((RANDOM % 31 + 30))M # Disk I/O size between 30MB to 60MB
    
    #### Block 1: Serial Stress Tests ####
    
    # 1. CPU Tests
    if ! $RUNNING; then break; fi
    echo "$(timestamp) [INFO] === Starting CPU Tests ==="
    
    # CPU Test
    echo "$(timestamp) [INFO] [CPU] Workers: $cpu_workers, Duration: $stress_time"
    stress-ng --cpu "$cpu_workers" --timeout "$stress_time" &
    wait $! || true
    
    if ! $RUNNING; then break; fi
    
    # CPU Cache Stress
    echo "$(timestamp) [INFO] [CPU Cache] Workers: $cpu_cache_workers, Duration: $stress_time"
    stress-ng --cache "$cpu_cache_workers" --timeout "$stress_time" &
    wait $! || true
    
    if ! $RUNNING; then break; fi
    
    # CPU Floating Point Stress
    echo "$(timestamp) [INFO] [CPU Float] Workers: $cpu_float_workers, Duration: $stress_time"
    stress-ng --matrix "$cpu_float_workers" --timeout "$stress_time" &
    wait $! || true
    
    if ! $RUNNING; then break; fi
    
    # CPU Pipe Stress
    echo "$(timestamp) [INFO] [CPU Pipe] Workers: $cpu_pipe_workers, Duration: $stress_time"
    stress-ng --pipe "$cpu_pipe_workers" --timeout "$stress_time" &
    wait $! || true
    
    echo "$(timestamp) [INFO] === Completed CPU Tests ==="

    # 2. Memory Tests
    if ! $RUNNING; then break; fi
    echo "$(timestamp) [INFO] === Starting Memory Tests ==="
    
    # Memory Test
    echo "$(timestamp) [INFO] [Memory] Workers: $vm_workers, Bytes per worker: $vm_bytes, Duration: $stress_time"
    stress-ng --vm "$vm_workers" --vm-bytes "$vm_bytes" --timeout "$stress_time" &
    wait $! || true
    
    echo "$(timestamp) [INFO] === Completed Memory Tests ==="

    # 3. Disk I/O Tests
    if ! $RUNNING; then break; fi
    echo "$(timestamp) [INFO] === Starting Disk I/O Tests ==="
    
    # Disk I/O Test
    echo "$(timestamp) [INFO] [Disk I/O] Workers: $hdd_workers, Bytes: $hdd_bytes, Duration: $stress_time"
    stress-ng --hdd "$hdd_workers" --hdd-bytes "$hdd_bytes" --timeout "$stress_time" &
    wait $! || true
    
    if ! $RUNNING; then break; fi
    
    # Random Write Stress
    echo "$(timestamp) [INFO] [Disk I/O Random Write] Duration: $stress_time"
    stress-ng --hdd 1 --hdd-opts wr-rnd --timeout "$stress_time" &
    wait $! || true
    
    if ! $RUNNING; then break; fi
    
    # Disk Bandwidth Stress
    echo "$(timestamp) [INFO] [Disk Bandwidth] Duration: $stress_time"
    stress-ng --hdd 1 --hdd-opts wr-seq --timeout "$stress_time" &
    wait $! || true
    
    # Random Read Stress
    echo "$(timestamp) [INFO] [Disk I/O Random Read] Duration: $stress_time"
    stress-ng --hdd 1 --hdd-opts rd-rnd --timeout "$stress_time" &
    wait $! || true
    
    if ! $RUNNING; then break; fi
    
    # Sequential Read Stress
    echo "$(timestamp) [INFO] [Disk I/O Sequential Read] Duration: $stress_time"
    stress-ng --hdd 1 --hdd-opts rd-seq --timeout "$stress_time" &
    wait $! || true
    
    echo "$(timestamp) [INFO] === Completed Disk I/O Tests ==="

    # 4. Network Tests
    if ! $RUNNING; then break; fi
    echo "$(timestamp) [INFO] === Starting Network Tests ==="
    
    # Network Test
    echo "$(timestamp) [INFO] [Network] Duration: $stress_time"
    # Run iperf3 client test to iperf3 server
    iperf3 -c iperf3 -t "$stress_time" || echo "iperf3 test failed" &
    wait $! || true
    
    echo "$(timestamp) [INFO] === Completed Network Tests ==="

    # 5. System Tests
    if ! $RUNNING; then break; fi
    echo "$(timestamp) [INFO] === Starting System Tests ==="
    
    # System Test (e.g., fork)
    system_workers=2
    echo "$(timestamp) [INFO] [System] 'Fork' workers: $system_workers, Duration: $stress_time"
    stress-ng --fork "$system_workers" --timeout "$stress_time" &
    wait $! || true
    
    echo "$(timestamp) [INFO] === Completed System Tests ==="
    
    echo "$(timestamp) [INFO] === Completed Serial Tests, sleeping for $sleep_time seconds ==="
    
    # Interruptible sleep
    for i in $(seq 1 $sleep_time); do
        if ! $RUNNING; then break 2; fi
        sleep 1
    done

    #### Block 2: Parallel Stress Tests ####
    if ! $RUNNING; then break; fi
    echo "$(timestamp) [INFO] === Starting Parallel Multi-Resource Stress Tests (Block 2) ==="
    
    # Parallel block stress and sleep durations
    # OPTIMIZED: reduced parallel stress time to 10-15 seconds
    stress_time=$((RANDOM % 6 + 10))s # 10-15 seconds
    # OPTIMIZED: reduced sleep time to 3-8 seconds
    sleep_time=$((RANDOM % 6 + 3)) # 3-8 seconds
    
    # Regenerate parameters
    cpu_workers=$((RANDOM % 3 + 2))
    vm_workers=$((RANDOM % 2 + 1))
    if [ "$vm_workers" -eq 1 ]; then
        vm_bytes=$((RANDOM % 101 + 500))M # 500–600MB/worker
    else
        vm_bytes=$((RANDOM % 163 + 350))M # 350–512MB/worker
    fi
    hdd_bytes=$((RANDOM % 11 + 15))M # Disk I/O size between 15-25MB
    system_workers=2
    
    echo "$(timestamp) [INFO] CPU: $cpu_workers, VM: $vm_workers x $vm_bytes, HDD: $hdd_bytes, System: $system_workers"
    echo "$(timestamp) [INFO] Running all in parallel for $stress_time"
    
    # Store background process PIDs for cleanup
    PIDS=()
    
    stress-ng --cpu "$cpu_workers" --timeout "$stress_time" & PIDS+=($!)
    stress-ng --vm "$vm_workers" --vm-bytes "$vm_bytes" --timeout "$stress_time" & PIDS+=($!)
    stress-ng --hdd 1 --hdd-bytes "$hdd_bytes" --timeout "$stress_time" & PIDS+=($!)
    stress-ng --fork "$system_workers" --timeout "$stress_time" & PIDS+=($!)
    
    # Parallel block with additional tests
    stress-ng --cache "$cpu_cache_workers" --timeout "$stress_time" & PIDS+=($!)
    stress-ng --matrix "$cpu_float_workers" --timeout "$stress_time" & PIDS+=($!)
    stress-ng --pipe "$cpu_pipe_workers" --timeout "$stress_time" & PIDS+=($!)

    if [ $((RANDOM % 2)) -eq 0 ]; then
        echo "$(timestamp) [INFO] [Parallel] Running random write disk test"
        stress-ng --hdd 1 --hdd-opts wr-rnd --timeout "$stress_time" & PIDS+=($!)
    else
        echo "$(timestamp) [INFO] [Parallel] Running sequential write disk test"
        stress-ng --hdd 1 --hdd-opts wr-seq --timeout "$stress_time" & PIDS+=($!)
    fi

    # stress-ng --hdd 1 --hdd-opts wr-rnd --timeout "$stress_time" & PIDS+=($!)
    # stress-ng --hdd 1 --hdd-opts wr-seq --timeout "$stress_time" & PIDS+=($!)
    stress-ng --hdd 1 --hdd-opts rd-rnd --timeout "$stress_time" & PIDS+=($!)
    stress-ng --hdd 1 --hdd-opts rd-seq --timeout "$stress_time" & PIDS+=($!)
    
    # Run iperf3 client test to iperf3 server (parallel)
    (iperf3 -c iperf3 -t "$stress_time" || echo "iperf3 test failed (parallel)") & PIDS+=($!)
    
    # Wait for all background processes or until we need to stop
    for pid in "${PIDS[@]}"; do
        if ! $RUNNING; then
            # Kill remaining background processes
            for remaining_pid in "${PIDS[@]}"; do
                kill "$remaining_pid" 2>/dev/null || true
            done
            break 2
        fi
        wait "$pid" 2>/dev/null || true
    done
    
    echo "$(timestamp) [INFO] === Completed Parallel Tests ==="
    
    # Check if we should continue running
    if ! $RUNNING; then break; fi
    
    # Set next active device after completing all tests
    echo "$(timestamp) [INFO] Setting next active device"
    /usr/local/bin/load_coordinator.sh set_next
    
    # Replace the sleep section with a simple message
    echo "$(timestamp) [INFO] Handed off to next device, returning to inactive state"
    
    # Maintain a check for shutdown signal before looping back
    if ! $RUNNING; then break; fi
    
    # The loop will now continue immediately, checking active status again
done

echo "$(timestamp) [INFO] Load simulator stopped."