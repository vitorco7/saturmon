#!/bin/bash

# Coordination directory
COORD_DIR="/var/run/load_coordinator"
ACTIVE_FILE="${COORD_DIR}/active_device"
SEQUENCE_FILE="${COORD_DIR}/sequence"
PRESENCE_DIR="${COORD_DIR}/devices"
LOCK_FILE="${COORD_DIR}/lock"
RESTART_MARKER="${COORD_DIR}/.restart_timestamp"

# Get the hostname of this device
HOSTNAME=$(hostname)

# Log function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${HOSTNAME}] $1"
}

# Make sure the coordination directory exists
mkdir -p ${COORD_DIR}
mkdir -p ${PRESENCE_DIR}

# Use a simple file-based lock for initialization
lock_acquire() {
  while ! mkdir "${LOCK_FILE}" 2>/dev/null; do
    log "Waiting for lock to be released"
    sleep 1
  done
}

lock_release() {
  rmdir "${LOCK_FILE}" 2>/dev/null || true
}

# Check if we need to reset coordination (new deploy/restart)
check_for_restart() {
  lock_acquire
  
  # Get current timestamp
  current_time=$(date +%s)
  
  # If restart marker doesn't exist or is too old, consider this a fresh start
  if [ ! -f "${RESTART_MARKER}" ] || [ $((current_time - $(cat "${RESTART_MARKER}"))) -gt 5 ]; then
    log "Detected new deployment or restart - resetting coordination"
    
    # Clean up old presence files
    find "${PRESENCE_DIR}" -type f -delete
    
    # Reset sequence and active device files
    rm -f "${SEQUENCE_FILE}" "${ACTIVE_FILE}"
    
    # Update restart timestamp
    echo "${current_time}" > "${RESTART_MARKER}"
  fi
  
  lock_release
}

# Register this device as present
register_device() {
  touch "${PRESENCE_DIR}/${HOSTNAME}"
  log "Registered device: ${HOSTNAME}"
}

# Get a list of currently active devices
get_active_devices() {
  find "${PRESENCE_DIR}" -type f -exec basename {} \; | sort
}

# Initialize sequence file with available devices
initialize_files() {
  lock_acquire
  
  # Check if files already exist
  if [ ! -f "${SEQUENCE_FILE}" ] || [ ! -f "${ACTIVE_FILE}" ]; then
    log "Initializing coordination files"
    
    # Wait a moment for other containers to register
    sleep 3
    
    # Get list of registered devices
    devices=$(get_active_devices)
    
    if [ -z "${devices}" ]; then
      # No devices registered yet, use this device
      log "No devices registered, using this device as default"
      echo "${HOSTNAME}" > "${SEQUENCE_FILE}"
      echo "${HOSTNAME}" > "${ACTIVE_FILE}"
    else
      # Build comma-separated list of devices
      device_list=$(echo "${devices}" | tr '\n' ',' | sed 's/,$//')
      log "Creating sequence with devices: ${device_list}"
      echo "${device_list}" > "${SEQUENCE_FILE}"
      
      # Set first device as active
      first_device=$(echo "${devices}" | head -n 1)
      echo "${first_device}" > "${ACTIVE_FILE}"
      log "Set initial active device: ${first_device}"
    fi
  else
    log "Coordination files already exist"
    
    # Update sequence with any new devices
    devices=$(get_active_devices)
    device_list=$(echo "${devices}" | tr '\n' ',' | sed 's/,$//')
    
    # Only update if we have a list of devices
    if [ -n "${device_list}" ]; then
      log "Updating sequence with devices: ${device_list}"
      echo "${device_list}" > "${SEQUENCE_FILE}"
    fi
  fi
  
  lock_release
}

# Function to check if this device is the active one
is_active_device() {
  if [ ! -f "${ACTIVE_FILE}" ]; then
    echo "${HOSTNAME}" > "${ACTIVE_FILE}"
    return 0
  fi
  
  active=$(cat ${ACTIVE_FILE})
  if [ "${active}" = "${HOSTNAME}" ]; then
    return 0  # True
  else
    return 1  # False
  fi
}

# Function to set the next active device
set_next_device() {
  lock_acquire
  
  local sequence_content=""
  if [ -f "${SEQUENCE_FILE}" ]; then
    sequence_content=$(cat ${SEQUENCE_FILE})
  fi
  
  local current=""
  if [ -f "${ACTIVE_FILE}" ]; then
    current=$(cat ${ACTIVE_FILE})
  fi
  
  # Get updated list of devices
  local devices=$(get_active_devices)
  local device_list=$(echo "${devices}" | tr '\n' ',' | sed 's/,$//')
  
  # Update sequence if needed
  if [ "${device_list}" != "${sequence_content}" ] && [ -n "${device_list}" ]; then
    log "Updating sequence with current devices: ${device_list}"
    echo "${device_list}" > "${SEQUENCE_FILE}"
    sequence_content="${device_list}"
  fi
  
  # Convert sequence to array
  IFS=',' read -ra DEVICES <<< "${sequence_content}"
  
  if [ ${#DEVICES[@]} -eq 0 ]; then
    # No devices in sequence, use this one
    log "No devices in sequence, setting self as active"
    echo "${HOSTNAME}" > "${ACTIVE_FILE}"
  else
    # Find current in sequence
    local found=false
    for i in "${!DEVICES[@]}"; do
      if [ "${DEVICES[$i]}" = "${current}" ]; then
        # Calculate next index with wrap-around
        next_index=$(( (i + 1) % ${#DEVICES[@]} ))
        echo "${DEVICES[$next_index]}" > ${ACTIVE_FILE}
        log "Set next active device: ${DEVICES[$next_index]}"
        found=true
        break
      fi
    done
    
    # If current not found in sequence, use first device
    if ! $found && [ ${#DEVICES[@]} -gt 0 ]; then
      echo "${DEVICES[0]}" > ${ACTIVE_FILE}
      log "Current device not in sequence, setting first device as active: ${DEVICES[0]}"
    fi
  fi
  
  lock_release
}

# Check for command-line arguments
if [ "$1" = "set_next" ]; then
  set_next_device
  exit 0
fi

# Check for restart and reset coordination if needed
check_for_restart

# Register this device as present
register_device

# Initialize files if needed
initialize_files

# Main coordination loop
log "Starting load coordinator"
while true; do
  # Periodically check and update device sequence
  initialize_files
  
  # Wait for a short period before checking again
  sleep 5
done