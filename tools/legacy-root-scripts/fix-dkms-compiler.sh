#!/bin/bash
# Run with:  sudo bash ~/fix-dkms-compiler.sh
# Makes the linuwu_sense DKMS build use the same compiler family the kernel was built with (clang or gcc),
# so it builds for the main (clang) kernel AND the LTS (gcc) kernel, and keeps working if CachyOS ever switches.
set -e
CONF=/usr/src/linuwu_sense-1.0/dkms.conf
cp -n "$CONF" "$CONF.orig"
python3 - <<'E'
p="/usr/src/linuwu_sense-1.0/dkms.conf"
lines=[l for l in open(p).read().splitlines() if not l.startswith("MAKE[0]")]
lines.append('MAKE[0]="if grep -q \'^CONFIG_CC_IS_CLANG=y\' /lib/modules/${kernelver}/build/.config; then make CC=clang LD=ld.lld KVER=${kernelver} all; else make KVER=${kernelver} all; fi"')
open(p,"w").write("\n".join(lines)+"\n")
E
cat "$CONF"
echo "--- building for every installed CachyOS kernel"
for k in /usr/lib/modules/*/build; do
  kv=$(basename "$(dirname "$k")")
  [ -d "$k/include" ] || continue
  case "$kv" in *cachyos*) ;; *) continue ;; esac
  if dkms status linuwu_sense/1.0 -k "$kv" 2>/dev/null | grep -q installed; then echo "$kv: already installed"; continue; fi
  dkms install linuwu_sense/1.0 -k "$kv" && echo "$kv: built OK" || echo "$kv: BUILD FAILED"
done
dkms status
echo "running kernel module still loaded: $(lsmod | grep -c linuwu_sense)"
