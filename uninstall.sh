#!/system/bin/sh

# DHCPv6 Uninstall Script
# Removes all data created by the module

dhcpv6_data="/data/adb/dhcpv6"
service_dir="/data/adb/service.d"
ksu_service_dir="/data/adb/ksu/service.d"

# Stop dhcp6c if running
if [ -f "$dhcpv6_data/run/dhcp6c.pid" ]; then
  pid=$(cat "$dhcpv6_data/run/dhcp6c.pid")
  [ -n "$pid" ] && kill "$pid" 2>/dev/null
fi

# Stop inotifyd monitors
for pid in $(pidof inotifyd); do
  if grep -q "dhcpv6" /proc/${pid}/cmdline 2>/dev/null; then
    kill ${pid} 2>/dev/null
  fi
done

# Remove service script
rm -f "$service_dir/dhcpv6_service.sh"
rm -f "$ksu_service_dir/dhcpv6_service.sh"

# Remove data directory
rm -rf "$dhcpv6_data"

echo "DHCPv6 module uninstalled and data cleaned up"
