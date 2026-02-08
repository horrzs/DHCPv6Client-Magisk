#!/system/bin/sh

# Create DUID script (pure shell, no Python required)
# Generates DUID Type 1: Link-layer address plus time

dhcpv6_data="/data/adb/dhcpv6"
duid_file="$dhcpv6_data/dhcp6c-duid"

# Get WiFi interface MAC address
get_mac() {
  local interface="wlan0"
  if [ -f "/sys/class/net/$interface/address" ]; then
    cat "/sys/class/net/$interface/address" | tr -d ':'
  else
    # Fallback: try to get any available interface
    for iface in /sys/class/net/wlan*; do
      if [ -f "$iface/address" ]; then
        cat "$iface/address" | tr -d ':'
        return
      fi
    done
    # Last resort: generate random MAC
    od -An -tx1 -N6 /dev/urandom | tr -d ' \n'
  fi
}

# Convert decimal to big-endian hex bytes
to_be16() {
  printf '%04x' "$1"
}

to_be32() {
  printf '%08x' "$1"
}

# Convert little-endian 16-bit
to_le16() {
  local val=$1
  local high=$((val >> 8))
  local low=$((val & 0xFF))
  printf '%02x%02x' "$low" "$high"
}

# Main
main() {
  # DUID Type 1 parameters
  local duid_type=1
  local hw_type=1  # Ethernet
  
  # Time: seconds since 2000-01-01 00:00:00 UTC
  local epoch_2000=946684800
  local now=$(date +%s)
  local time_val=$((now - epoch_2000))
  
  # Ensure time_val fits in 32 bits
  time_val=$((time_val & 0xFFFFFFFF))
  
  # Get MAC address
  local mac=$(get_mac)
  
  # Build DUID: type(2) + hw_type(2) + time(4) + mac(6) = 14 bytes
  local duid_hex=$(to_be16 $duid_type)$(to_be16 $hw_type)$(to_be32 $time_val)${mac}
  
  # Length prefix (little-endian 16-bit)
  local length=14
  local length_hex=$(to_le16 $length)
  
  # Write binary file
  mkdir -p "$(dirname "$duid_file")"
  
  # Convert hex to binary and write
  echo "${length_hex}${duid_hex}" | xxd -r -p > "$duid_file"
  
  if [ $? -eq 0 ] && [ -f "$duid_file" ]; then
    echo "DUID created successfully: $duid_file"
    echo "DUID hex: ${duid_hex}"
  else
    echo "Failed to create DUID file"
    return 1
  fi
}

main "$@"
