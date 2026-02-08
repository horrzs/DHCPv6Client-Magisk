#!/sbin/sh

SKIPUNZIP=1
ASH_STANDALONE=1

if [ "$BOOTMODE" != true ]; then
  abort "Error: Please install in Magisk Manager, KernelSU Manager or APatch"
fi

if [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 10670 ]; then
  abort "Error: Please update your KernelSU"
fi

# Determine service.d directory
if [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 10683 ]; then
  service_dir="/data/adb/ksu/service.d"
else 
  service_dir="/data/adb/service.d"
fi

[ ! -d "$service_dir" ] && mkdir -p "$service_dir"

# Extract module files
ui_print "- Extracting module files"
unzip -qo "${ZIPFILE}" -x 'META-INF/*' -d "$MODPATH"

# Setup data directory
dhcpv6_data="/data/adb/dhcpv6"

if [ -d "$dhcpv6_data" ]; then
  # Preserve existing DUID if it exists
  if [ -f "$dhcpv6_data/dhcp6c-duid" ]; then
    cp "$dhcpv6_data/dhcp6c-duid" /tmp/dhcp6c-duid.bak
    ui_print "- Preserving existing DUID"
  fi
  # Preserve existing config if it exists
  if [ -f "$dhcpv6_data/dhcp6c.conf" ]; then
    cp "$dhcpv6_data/dhcp6c.conf" /tmp/dhcp6c.conf.bak
    ui_print "- Preserving existing configuration"
  fi
fi

# Move dhcpv6 directory to data
mv "$MODPATH/dhcpv6" "$dhcpv6_data"

# Restore preserved files
if [ -f /tmp/dhcp6c-duid.bak ]; then
  mv /tmp/dhcp6c-duid.bak "$dhcpv6_data/dhcp6c-duid"
fi
if [ -f /tmp/dhcp6c.conf.bak ]; then
  mv /tmp/dhcp6c.conf.bak "$dhcpv6_data/dhcp6c.conf"
fi

# Generate DUID if not exists
if [ ! -f "$dhcpv6_data/dhcp6c-duid" ]; then
  ui_print "- Generating DUID"
  sh "$dhcpv6_data/scripts/create_duid.sh"
fi

# Update module name based on manager
if [ "$KSU" = true ]; then
  sed -i 's/name=DHCPv6 Client/name=DHCPv6 Client (KernelSU)/g' "$MODPATH/module.prop"
fi

if [ "$APATCH" = true ]; then
  sed -i 's/name=DHCPv6 Client/name=DHCPv6 Client (APatch)/g' "$MODPATH/module.prop"
fi

# Create necessary directories
mkdir -p "$dhcpv6_data/run"

# Move service script
mv -f "$MODPATH/dhcpv6_service.sh" "$service_dir/"

# Cleanup
rm -f "$MODPATH/customize.sh"

# Set permissions
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm_recursive "$dhcpv6_data" 0 0 0755 0644
set_perm_recursive "$dhcpv6_data/scripts" 0 0 0755 0700
set_perm_recursive "$dhcpv6_data/bin" 0 0 0755 0700
set_perm "$service_dir/dhcpv6_service.sh" 0 0 0700
set_perm "$dhcpv6_data/bin/dhcp6c" 0 0 0755

# Fix permissions on scripts
chmod ugo+x "$dhcpv6_data/scripts/"*
chmod ugo+x "$dhcpv6_data/bin/"*

ui_print "- DHCPv6 module installed successfully"
ui_print "- Data directory: $dhcpv6_data"
