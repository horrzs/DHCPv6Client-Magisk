#!/system/bin/sh

# DHCPv6 Service Script
# Runs at boot to start WiFi monitoring

module_dir="/data/adb/modules/dhcpv6"
dhcpv6_data="/data/adb/dhcpv6"
scripts_dir="$dhcpv6_data/scripts"
run_dir="$dhcpv6_data/run"

# Check for Magisk Lite
[ -n "$(magisk -v 2>/dev/null | grep lite)" ] && module_dir=/data/adb/lite_modules/dhcpv6

# Wait for boot completion
(
until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 3
done

# Additional wait for network stack
sleep 5

mkdir -p "$run_dir"

# Start DHCPv6 service if module is enabled
if [ ! -f "$dhcpv6_data/manual" ] && [ ! -f "$module_dir/disable" ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') [Info] DHCPv6 service starting" >> "$run_dir/dhcpv6.log"
  
  # Start WiFi monitoring
  ${scripts_dir}/start.sh >> "$run_dir/dhcpv6.log" 2>&1
fi
)&

# Start inotifyd to monitor module disable/enable
inotifyd ${scripts_dir}/module.inotify ${module_dir} > /dev/null 2>&1 &

# Monitor network changes for WiFi switching
# /data/misc/net/rt_tables changes when network routing changes
while [ ! -f /data/misc/net/rt_tables ]; do
  sleep 3
done

inotifyd ${scripts_dir}/wifi.inotify /data/misc/net > /dev/null 2>&1 &
