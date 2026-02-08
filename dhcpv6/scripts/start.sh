#!/system/bin/sh

# DHCPv6 Start Script

scripts=$(realpath "$0")
scripts_dir=$(dirname "$scripts")

source "$scripts_dir/dhcpv6.config"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [Info] $1" >> "$log_file"
}

log_error() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [Error] $1" >> "$log_file"
}

# Rotate log if too large
rotate_log() {
  if [ -f "$log_file" ]; then
    local size=$(stat -c%s "$log_file" 2>/dev/null || echo 0)
    if [ "$size" -gt "$max_log_size" ]; then
      mv "$log_file" "${log_file}.old"
      log "Log rotated"
    fi
  fi
}

# Check if WiFi is connected
is_wifi_connected() {
  # Check if interface exists and has carrier
  if [ -f "/sys/class/net/$wifi_interface/carrier" ]; then
    local carrier=$(cat "/sys/class/net/$wifi_interface/carrier" 2>/dev/null)
    [ "$carrier" = "1" ] && return 0
  fi
  
  # Alternative: check operstate
  if [ -f "/sys/class/net/$wifi_interface/operstate" ]; then
    local state=$(cat "/sys/class/net/$wifi_interface/operstate" 2>/dev/null)
    [ "$state" = "up" ] && return 0
  fi
  
  return 1
}

# Stop existing dhcp6c process
stop_dhcp6c() {
  if [ -f "$pid_file" ]; then
    local pid=$(cat "$pid_file")
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      log "Stopping existing dhcp6c (PID: $pid)"
      kill "$pid" 2>/dev/null
      sleep 1
      # Force kill if still running
      kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
    fi
    rm -f "$pid_file"
  fi
  
  # Also kill any orphan dhcp6c processes
  pkill -f "dhcp6c.*$wifi_interface" 2>/dev/null
}

# Start dhcp6c
start_dhcp6c() {
  rotate_log
  
  # Check if WiFi is connected
  if ! is_wifi_connected; then
    log "WiFi not connected, skipping DHCPv6"
    return 0
  fi
  
  # Stop existing process
  stop_dhcp6c
  
  # Create run directory
  mkdir -p "$run_dir"
  
  # Diagnostic checks
  if [ ! -f "$dhcp6c_bin" ]; then
    log_error "dhcp6c binary not found at: $dhcp6c_bin"
    return 1
  fi
  
  if [ ! -x "$dhcp6c_bin" ]; then
    log "Setting execute permission on dhcp6c"
    chmod +x "$dhcp6c_bin"
  fi
  
  if [ ! -f "$dhcp6c_conf" ]; then
    log_error "Config file not found at: $dhcp6c_conf"
    return 1
  fi
  
  # Build command arguments - use absolute paths
  local args="-c $dhcp6c_conf -p $pid_file"
  
  if [ "$debug_mode" = "1" ]; then
    args="-D $args"
  fi

  # Check for root and elevate if needed
  if [ "$(id -u)" != "0" ]; then
    log "Not running as root, elevating..."
    if command -v su >/dev/null 2>&1; then
      exec su -c "sh $0 $@"
    else
      log_error "Root required but su not found"
      exit 1
    fi
  fi
  
  # Change to data directory
  cd "$dhcpv6_data" || { log_error "Failed to cd to $dhcpv6_data"; exit 1; }
  
  # SElinux / Permission fixes
  if command -v chcon >/dev/null 2>&1; then
      chcon -R u:object_r:system_file:s0 "$dhcpv6_data" 2>/dev/null || true
  fi
  chmod 755 "$dhcpv6_data" 2>/dev/null
  if [ -f "$duid_file" ]; then
      chmod 644 "$duid_file" 2>/dev/null
  fi

  log "Starting dhcp6c on $wifi_interface"
  log "Working directory: $(pwd)"
  log "User: $(id)"
  
  log "Starting dhcp6c on $wifi_interface"
  log "Working directory: $(pwd)"
  log "User: $(id)"
  
  # WORKAROUND: Use a pipe to keep STDIN open!
  # The Android version of dhcp6c checks for STDIN EOF and exits if found.
  # By piping from sleep, we keep STDIN open (but valid), preventing auto-exit.
  # This avoids the need for immediate recompilation.
  
  # Background the entire pipeline
  # We use a subshell to ensure the PID file gets the dhcp6c PID, not sleep's PID
  # Note: Shell job control handling of pipelines can be tricky for PID tracking.
  # Reliable method: Use setsid if available, or just launch.
  
  # Simplest robust way:
  # sleep outputs nothing, so dhcp6c reads nothing but select() blocks -> no exit.
  
  (sleep 999999 | $dhcp6c_bin -f -c "$dhcp6c_conf" -p "$pid_file" "$wifi_interface" >> "$log_file" 2>&1) &
  
  # Wait a bit for PID file creation by dhcp6c
  sleep 3
  
  # Check if pid file was created
  if [ -f "$pid_file" ]; then
    local pid=$(cat "$pid_file")
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        log "dhcp6c started successfully (PID: $pid)"
        return 0
    fi
  fi
  
  # Fallback: check pgrep
  if pgrep -f "dhcp6c.*$wifi_interface" > /dev/null 2>&1; then
    local running_pid=$(pgrep -f "dhcp6c.*$wifi_interface" | head -1)
    log "dhcp6c started successfully (process found, PID: $running_pid)"
    echo "$running_pid" > "$pid_file"
    return 0
  fi
  
  # Diagnose failure
  log_error "dhcp6c failed to start"
  log_error "Logcat:"
  logcat -d -s dhcp6c | tail -n 20 >> "$log_file"
  
  return 1
}

main() {
  mkdir -p "$run_dir"
  start_dhcp6c
}

main "$@"
