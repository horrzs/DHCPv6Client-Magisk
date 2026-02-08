#!/system/bin/sh

# DHCPv6 Stop Script

scripts=$(realpath "$0")
scripts_dir=$(dirname "$scripts")

source "$scripts_dir/dhcpv6.config"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [Info] $1" >> "$log_file"
}

# Stop dhcp6c
stop_dhcp6c() {
  if [ -f "$pid_file" ]; then
    local pid=$(cat "$pid_file")
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      log "Stopping dhcp6c (PID: $pid)"
      kill "$pid" 2>/dev/null
      sleep 1
      # Force kill if still running
      kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
    fi
    rm -f "$pid_file"
  fi
  
  # Also kill any orphan dhcp6c processes
  pkill -f "dhcp6c.*$wifi_interface" 2>/dev/null
  
  # Kill the sleep process from the start.sh workaround (if present)
  # Sleep duration 999999 is unique enough to target safely
  pkill -f "sleep 999999" 2>/dev/null
  
  log "dhcp6c stopped"
}

stop_dhcp6c
