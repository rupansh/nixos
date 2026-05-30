#!/usr/bin/env bash
# Power diagnostic snapshot. Run as root:
#   sudo bash power-diag.sh > power-diag.log 2>&1
# Then paste power-diag.log back.
set -u

sec()  { echo; echo "=== $* ==="; }
have() { command -v "$1" >/dev/null 2>&1; }
read_or_skip() { [[ -r "$1" ]] && cat "$1" 2>&1 || echo "(unreadable: $1)"; }

sec "uname / uptime / battery snapshot"
uname -a
uptime
upower -i "$(upower -e | grep -i bat | head -1)" 2>&1 | grep -E 'state|energy|percentage|time to'

sec "RAPL package/core/uncore/psys power (sampled over 5s)"
declare -A E1
for d in /sys/class/powercap/intel-rapl:*; do
  [[ -r "$d/energy_uj" ]] || continue
  E1[$d]=$(cat "$d/energy_uj")
done
sleep 5
for d in /sys/class/powercap/intel-rapl:*; do
  [[ -r "$d/energy_uj" ]] || continue
  e1=${E1[$d]:-0}; e2=$(cat "$d/energy_uj")
  # wraparound-safe (max_energy_range_uj)
  if (( e2 < e1 )); then
    max=$(cat "$d/max_energy_range_uj" 2>/dev/null || echo 0)
    delta=$(( max - e1 + e2 ))
  else
    delta=$(( e2 - e1 ))
  fi
  mw=$(( delta / 5000 ))
  name=$(cat "$d/name" 2>/dev/null)
  printf "%-40s %s = %d mW\n" "$d" "$name" "$mw"
done

sec "S0ix readiness (PMC core)"
echo "-- slp_s0_residency_usec --"
read_or_skip /sys/kernel/debug/pmc_core/slp_s0_residency_usec
echo "-- substate_residencies --"
read_or_skip /sys/kernel/debug/pmc_core/substate_residencies
echo "-- package_cstate_residency --"
read_or_skip /sys/kernel/debug/pmc_core/package_cstate_residency
echo "-- ltr_show (low-traffic latency tolerances) --"
read_or_skip /sys/kernel/debug/pmc_core/ltr_show
echo "-- pch_ip_power_gating_status --"
read_or_skip /sys/kernel/debug/pmc_core/pch_ip_power_gating_status

sec "Per-core c-state residency (5s sample)"
if have turbostat; then
  turbostat --quiet --interval 1 --num_iterations 5 --show Package,Core,CPU,Busy%,Bzy_MHz,IRQ,POLL,C1,C1E,C6,C10,CorWatt,PkgWatt,GFXWatt 2>&1 | tail -80
else
  echo "(turbostat not installed — install via environment.systemPackages with pkgs.linuxPackages.turbostat)"
  echo "Falling back to /sys cpuidle counters:"
  for s in /sys/devices/system/cpu/cpu0/cpuidle/state*; do
    n=$(cat "$s/name"); us=$(cat "$s/time"); echo "cpu0 $n total_us=$us"
  done
fi

sec "PCI runtime PM — devices NOT in auto, or stuck active"
for d in /sys/bus/pci/devices/*; do
  ctrl=$(cat "$d/power/control" 2>/dev/null) || continue
  st=$(cat "$d/power/runtime_status" 2>/dev/null)
  act=$(cat "$d/power/runtime_active_time" 2>/dev/null)
  sus=$(cat "$d/power/runtime_suspended_time" 2>/dev/null)
  name=$(basename "$d")
  if [[ "$ctrl" != "auto" ]] || [[ "$st" != "suspended" ]]; then
    desc=$(lspci -s "${name#0000:}" 2>/dev/null | sed 's/^[^ ]* //')
    printf "%-14s ctrl=%-4s status=%-9s act=%-10s sus=%-10s  %s\n" \
      "$name" "$ctrl" "$st" "${act}ms" "${sus}ms" "$desc"
  fi
done

sec "USB runtime PM (devices in 'on')"
for d in /sys/bus/usb/devices/*/power/control; do
  ctrl=$(cat "$d")
  if [[ "$ctrl" != "auto" ]]; then
    dev=$(dirname "$d" | xargs dirname)
    prod=$(cat "$dev/product" 2>/dev/null)
    mfg=$(cat "$dev/manufacturer" 2>/dev/null)
    echo "$(basename "$dev"): ctrl=$ctrl  $mfg / $prod"
  fi
done

sec "WiFi / iwlwifi state"
for f in /sys/module/iwlwifi/parameters/*; do
  echo "iwlwifi.$(basename "$f") = $(cat "$f")"
done
for f in /sys/module/iwlmvm/parameters/*; do
  echo "iwlmvm.$(basename "$f") = $(cat "$f")"
done
echo "-- wlo1 device power/control --"
read_or_skip /sys/class/net/wlo1/device/power/control
echo "-- iw dev link --"
if have iw; then iw dev wlo1 link 2>&1; iw dev wlo1 get power_save 2>&1; else echo "(iw not installed)"; fi
echo "-- nmcli powersave setting --"
nmcli -t -f connection.id,802-11-wireless.powersave c show --active 2>&1 | grep -v '^$'

sec "NVMe state (storage often hides under VMD)"
for n in /sys/class/nvme/nvme*; do
  [[ -e "$n" ]] || continue
  echo "-- $n --"
  echo "  model:   $(cat $n/model 2>/dev/null)"
  echo "  state:   $(cat $n/state 2>/dev/null)"
  echo "  power/control: $(cat $n/device/power/control 2>/dev/null)"
done
echo "-- APST (autonomous power state transition) via nvme-cli if present --"
if have nvme; then
  for d in /dev/nvme[0-9]; do
    [[ -e "$d" ]] || continue
    echo "  $d:"
    nvme get-feature -f 0x0c -H "$d" 2>&1 | head -8
  done
else
  echo "(nvme-cli not installed)"
fi

sec "Top CPU consumers (1s snapshot)"
top -bn1 -o %CPU | head -25

sec "Process wakeups via /proc/PID/wchan and /proc/PID/io (top 10 by CPU)"
for pid in $(ps -eo pid --sort=-pcpu --no-headers | head -10); do
  comm=$(cat /proc/$pid/comm 2>/dev/null) || continue
  printf "pid=%-6s comm=%-20s state=%s\n" "$pid" "$comm" "$(cat /proc/$pid/stat 2>/dev/null | awk '{print $3}')"
done

sec "Interrupts (top wake sources by total count)"
awk 'NR==1 {next} {sum=0; for(i=2;i<=NF-2;i++) sum+=$i; print sum, $0}' /proc/interrupts \
  | sort -rn | head -15 | awk '{$1=""; print}'

sec "Kernel wakeup_sources (top 10 by active count)"
if [[ -r /sys/kernel/debug/wakeup_sources ]]; then
  head -1 /sys/kernel/debug/wakeup_sources
  tail -n +2 /sys/kernel/debug/wakeup_sources | sort -k3 -rn | head -10
else
  echo "(wakeup_sources unreadable)"
fi

sec "Display backlight"
for b in /sys/class/backlight/*; do
  echo "$b: $(cat $b/brightness)/$(cat $b/max_brightness) ($(cat $b/actual_brightness 2>/dev/null))"
done
for l in /sys/class/leds/*kbd*backlight*; do
  echo "$l: $(cat $l/brightness)/$(cat $l/max_brightness)"
done

sec "ASUS platform profile / EPP"
read_or_skip /sys/firmware/acpi/platform_profile
read_or_skip /sys/firmware/acpi/platform_profile_choices
echo "-- per-cpu energy_performance_preference --"
for c in /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference; do
  echo "cpu0 EPP: $(cat $c)"
done

sec "dGPU power state (verify still off)"
echo "supergfxctl -g: $(supergfxctl -g 2>&1)"
echo "supergfxctl -S: $(supergfxctl -S 2>&1)"
echo "PCIe root port 00:01.0 status: $(cat /sys/bus/pci/devices/0000:00:01.0/power/runtime_status)"
echo "01:00.0 present: $(lspci -s 01:00.0 2>&1)"
lsmod | grep -E '^(nvidia|nouveau)' || echo "(no nvidia/nouveau modules — good)"

sec "Recent dmesg (last 60 lines)"
dmesg | tail -60

echo
echo "=== DONE ==="
