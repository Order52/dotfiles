#!/bin/bash
# Run with:  sudo bash ~/fix-profile.sh
# Lets the group `linuwu_sense` (you) change the Predator performance profile without root.
cat > /etc/tmpfiles.d/acer-platform-profile.conf <<'T'
z /sys/firmware/acpi/platform_profile 0664 root linuwu_sense -
z /sys/class/platform-profile/platform-profile-0/profile 0664 root linuwu_sense -
T
systemd-tmpfiles --create /etc/tmpfiles.d/acer-platform-profile.conf
ls -l /sys/firmware/acpi/platform_profile
