#!/usr/bin/env bash
# tune.sh – makes vanilla Arch fast like CachyOS, safe like Debian and secure like Fedora. setup.sh runs it; you can run
# it again on its own (bash ~/dotfiles/arch/tune.sh). Needs the packages setup.sh installs. Made by Claude.
#   fast    – CachyOS's own memory/disk/CPU tweaks, LAVD gaming scheduler, NTSYNC, amd-pstate, kernel options
#   safe    – a btrfs snapshot before and after every update (bootable from the menu), lean snapshot keeping,
#             mirrors / package cache / SSD trim looked after automatically
#   secure  – firewall, AppArmor, kernel + network hardening, encrypted DNS, out-of-memory killer
set -euo pipefail
step() { printf '\n\033[1;37m== %s\033[0m\n' "$*"; }

# ================================================================ FAST (like CachyOS)
step "fast: CachyOS's memory, disk and CPU tweaks"
sudo tee /etc/sysctl.d/70-yu-performance.conf >/dev/null <<'CONF'
# CachyOS's settings (70-cachyos-settings.conf + 99-splitlock.conf), plus BBR networking
vm.swappiness = 150
vm.vfs_cache_pressure = 50
vm.dirty_bytes = 268435456
vm.dirty_background_bytes = 67108864
vm.dirty_writeback_centisecs = 1500
vm.page-cluster = 0
vm.max_map_count = 2147483642
kernel.nmi_watchdog = 0
kernel.split_lock_mitigate = 0
kernel.printk = 3 3 3 3
net.core.netdev_max_backlog = 4096
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
fs.file-max = 2097152
CONF
sudo tee /etc/udev/rules.d/60-yu-ioschedulers.rules >/dev/null <<'CONF'
# disk schedulers like CachyOS: kyber for NVMe, mq-deadline for SSDs, BFQ for hard drives
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
CONF
sudo tee /etc/udev/rules.d/30-yu-zram.rules >/dev/null <<'CONF'
# zram is on, so zswap off (they'd compress twice)
ACTION=="change", KERNEL=="zram0", ATTR{initstate}=="1", RUN+="/bin/sh -c 'echo N > /sys/module/zswap/parameters/enabled'"
CONF
sudo tee /etc/tmpfiles.d/yu-thp.conf >/dev/null <<'CONF'
# transparent huge pages like CachyOS: only where apps ask, compacted in the background
w! /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise
w! /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none - - - - 409
CONF
echo ntsync | sudo tee /etc/modules-load.d/ntsync.conf >/dev/null      # Proton's fast Windows sync
printf 'default_sched = "scx_lavd"\ndefault_mode = "Gaming"\n' | sudo tee /etc/scx_loader.toml >/dev/null
sudo systemctl enable scx_loader

step "fast + secure: kernel options in the boot menu"
# amd_pstate=active: modern Ryzen frequency driver · nowatchdog: less overhead · split_lock_detect=off: no game stutter
# amdgpu.ppfeaturemask: lets LACT set the GPU fan curve / undervolt · lsm=…apparmor: turns AppArmor on
# randomize_kstack_offset=on: cheap hardening
opts="amd_pstate=active nowatchdog split_lock_detect=off amdgpu.ppfeaturemask=0xfff7ffff lsm=landlock,lockdown,yama,integrity,apparmor,bpf randomize_kstack_offset=on"
for f in /boot/limine.conf /boot/limine/limine.conf /boot/EFI/limine/limine.conf /boot/loader/entries/*.conf; do
  [ -f "$f" ] || continue
  sudo grep -q 'amd_pstate=active' "$f" && continue
  sudo sed -i -E "s|^(\s*(kernel_)?cmdline:.*)$|\1 $opts|; s|^(options .*)$|\1 $opts|" "$f"
  echo "   added to $f"
done

# ================================================================ SAFE (like Debian)
step "safe: a snapshot before and after every update, bootable from the menu"
if [ "$(findmnt -no FSTYPE /)" = btrfs ] && [ ! -e /etc/snapper/configs/root ]; then
  had_sub=0; grep -qE '\s/\.snapshots\s' /etc/fstab && had_sub=1
  mountpoint -q /.snapshots && sudo umount /.snapshots
  [ -d /.snapshots ] && sudo rmdir /.snapshots      # only works if empty (fresh install): never deletes anything
  sudo snapper -c root create-config /
  if [ "$had_sub" = 1 ]; then                       # archinstall's own @.snapshots subvolume takes over again
    sudo btrfs subvolume delete /.snapshots; sudo mkdir /.snapshots; sudo mount -a
  fi
  sudo chmod 750 /.snapshots
  # lean: snapshots come from updates (snap-pac), no hourly ones, the last 10 kept
  sudo sed -i 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="no"/; s/^NUMBER_LIMIT=.*/NUMBER_LIMIT="10"/; s/^NUMBER_LIMIT_IMPORTANT=.*/NUMBER_LIMIT_IMPORTANT="5"/' /etc/snapper/configs/root
fi
printf 'LIMIT_USAGE_PERCENT=85\nRESTORE_METHOD=replace\nSNAPSHOT_FORMAT_CHOICE=2\n' | sudo tee /etc/limine-snapper-sync.conf >/dev/null
sudo systemctl enable snapper-cleanup.timer
systemctl list-unit-files limine-snapper-sync.service >/dev/null 2>&1 && sudo systemctl enable limine-snapper-sync.service || true

step "safe: mirrors, package cache and SSD looked after automatically"
sudo tee /etc/xdg/reflector/reflector.conf >/dev/null <<'CONF'
--save /etc/pacman.d/mirrorlist
--protocol https
--country Turkey,Germany,Netherlands
--latest 10
--sort rate
CONF
sudo systemctl enable reflector.timer paccache.timer fstrim.timer

# ================================================================ SECURE (like Fedora)
step "secure: firewall (nothing gets in unless you started it)"
sudo ufw default deny incoming; sudo ufw default allow outgoing
sudo ufw allow from 192.168.1.0/24 to any port 5353 proto udp comment 'local device discovery'
sudo ufw --force enable; sudo systemctl enable ufw

step "secure: AppArmor, kernel + network hardening, out-of-memory killer"
sudo systemctl enable apparmor systemd-oomd
sudo tee /etc/sysctl.d/80-yu-hardening.conf >/dev/null <<'CONF'
# hide kernel addresses/logs from normal programs, safer files in shared folders, no BPF tricks for normal users
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.unprivileged_bpf_disabled = 1
net.core.bpf_jit_harden = 2
kernel.yama.ptrace_scope = 1
fs.protected_fifos = 2
fs.protected_regular = 2
fs.protected_symlinks = 1
fs.protected_hardlinks = 1
# network: no spoofed packets, no ICMP redirects, SYN-flood protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
CONF

step "secure: encrypted DNS (your provider can't see or change what you look up)"
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/yu-dns.conf >/dev/null <<'CONF'
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net 2606:4700:4700::1111#cloudflare-dns.com
FallbackDNS=1.0.0.1#cloudflare-dns.com 149.112.112.112#dns.quad9.net
DNSOverTLS=yes
DNSSEC=allow-downgrade
CONF
sudo systemctl enable systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

echo; echo "tuning done (takes effect after a reboot)"
