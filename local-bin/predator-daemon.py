#!/usr/bin/python3 -u
"""Predator brain: smart fan curve + thermal governor + automatic performance profile.

Acer Predator Helios 16 PH16-71 · i7-13700HX (throttles ~91-92 °C) · RTX 4060 Laptop · linuwu_sense.
Runs as a user systemd service (predator.service). It replaces the old Noctalia-plugin service, which Noctalia
killed ("exceeded its CPU budget") exactly when the machine was under heavy load, leaving the fans stuck.

Measured fan response (manual %, both fans):
  <=20 % ~1700 rpm (floor) · 30 % 2160 · 40 % 2850 · 50 % 3460 · 60 % 4070 · 70 % 4600 · 80 % 5100 · 100 % 6050
Firmware Auto ("0,0") is the only way to reach 0 rpm, so when the machine is calm control goes back to it.

Files
  ~/.cache/predator-fan-mode   "smart" (default) | "manual"      (written by the Noctalia widgets)
  ~/.cache/predator-auto-off   exists -> profile auto is off
  /tmp/predator-state          live state read by the bar widgets
  ~/.cache/predator-log        one line / 10 s while gaming, heavy or hot (for tuning)
"""
import glob
import os
import pwd
import signal
import socket
import subprocess
import threading
import time

FAN = "/sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi/predator_sense/fan_speed"
PROFILE = "/sys/firmware/acpi/platform_profile"
RAPL = "/sys/class/powercap/intel-rapl:0/"
# Runs as root (system service) in production: user files and the OSD then belong to PREDATOR_USER.
USER = os.environ.get("PREDATOR_USER", "sloppy")
try:
    PW = pwd.getpwnam(USER)
except KeyError:
    PW = pwd.getpwuid(os.getuid())
HOME = PW.pw_dir
FANMODE = HOME + "/.cache/predator-fan-mode"
AUTO_OFF = HOME + "/.cache/predator-auto-off"
STATE = "/tmp/predator-state"
LOG = HOME + "/.cache/predator-log"

LEVELS = [30, 40, 50, 60, 70, 85, 100]        # fan %
CPU_UP = [52, 60, 68, 75, 80, 85, 89]         # °C at which each level is entered
GPU_UP = [48, 55, 61, 66, 70, 74, 79]
HYST, DOWN_HOLD, PREDICT, BAT_SHIFT, COUPLE = 4, 8, 5, 3, 20
HOT_CPU, HOT_GPU = 92, 82
CALM_CPU, CALM_GPU, CALM_HOLD = 58, 55, 20

CPU_PL = 80_000_000          # µW, normal / heavy CPU work
CPU_PL_GAME = 65_000_000     # µW, while the GPU is busy (the cooler tops out at ~125-135 W combined)

# Thermal governor: hardware throttling at 91-92 °C is jerky, so slow the cores down smoothly first.
GOV_HI, GOV_LO = 88, 83      # °C: cap clocks above GOV_HI, release below GOV_LO
CAP_MAX, CAP_MIN, CAP_DOWN, CAP_UP = 5_000_000, 2_800_000, 200_000, 100_000   # kHz


def rd(path, default=None):
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return default


def wr(path, value):
    try:
        with open(path, "w") as f:
            f.write(str(value))
        return True
    except OSError:
        return False


def num(path):
    try:
        return float(rd(path))
    except (TypeError, ValueError):
        return None


def notify(msg):
    """systemd sd_notify: READY=1 once, then WATCHDOG=1 every loop (systemd restarts us if the loop ever hangs)."""
    path = os.environ.get("NOTIFY_SOCKET")
    if not path:
        return
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        s.connect("\0" + path[1:] if path[0] == "@" else path)
        s.send(msg.encode())
        s.close()
    except OSError:
        pass


def osd(icon, text):
    """Noctalia OSD, from root too (talks to the user's session)."""
    env = {"PATH": "/usr/bin", "HOME": HOME, "XDG_RUNTIME_DIR": f"/run/user/{PW.pw_uid}",
           "WAYLAND_DISPLAY": "wayland-1", "DBUS_SESSION_BUS_ADDRESS": f"unix:path=/run/user/{PW.pw_uid}/bus"}
    cmd = ["noctalia", "msg", "osd-show", icon, text]
    if os.geteuid() == 0:
        cmd = ["runuser", "-u", USER, "--"] + cmd
    try:
        subprocess.Popen(cmd, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except OSError:
        pass


def ema(prev, v, a):
    return v if prev is None else prev + a * (v - prev)


class Brain:
    def __init__(self):
        self.acer = self.coretemp = None
        self.prev_total = self.prev_idle = None
        self.cpu_load = 0.0
        self.gpu_util = self.gpu_power = 0.0
        self.gpu_temp = None
        self.gpu_seen = 0.0
        self.tcpu = self.tgpu = self.tchassis = None
        self.hist_c, self.hist_g = [], []
        self.tick = 0
        self.calm = 0
        self.lvl = [0, 0]
        self.changed = [0, 0]
        self.written = None
        self.busy_hold = 0
        self.activity = "idle"
        self.last_target = None
        self.last_try = 0
        self.last_ac = None
        self.cap = CAP_MAX
        self.cap_changed = 0
        self.cpus = sorted(glob.glob("/sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_max_freq"))
        self.find_hwmon()
        threading.Thread(target=self.gpu_stream, daemon=True).start()

    # ---- sensors -------------------------------------------------------
    def find_hwmon(self):
        for base in glob.glob("/sys/class/hwmon/hwmon*"):
            n = rd(base + "/name")
            if n == "acer":
                self.acer = base
            elif n == "coretemp":
                self.coretemp = base

    def gpu_stream(self):
        cmd = ["nvidia-smi", "--query-gpu=temperature.gpu,utilization.gpu,power.draw",
               "--format=csv,noheader,nounits", "-l", "2"]
        while True:
            try:
                p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
                for line in p.stdout:
                    try:
                        t, u, w = [x.strip() for x in line.split(",")]
                        self.gpu_temp = float(t)
                        self.gpu_util = ema(self.gpu_util, float(u), 0.3)
                        self.gpu_power = ema(self.gpu_power, float(w), 0.3)
                        self.gpu_seen = time.time()
                    except ValueError:
                        pass
                p.wait()
            except Exception:
                pass
            time.sleep(5)

    def read_cpu_load(self):
        line = rd("/proc/stat", "").split("\n", 1)[0].split()[1:]
        vals = [int(x) for x in line[:8]]
        total, idle = sum(vals), vals[3] + vals[4]
        if self.prev_total is not None and total > self.prev_total:
            load = 100 * (1 - (idle - self.prev_idle) / (total - self.prev_total))
            self.cpu_load = ema(self.cpu_load, load, 0.25)
        self.prev_total, self.prev_idle = total, idle

    @staticmethod
    def on_ac():
        for n in ("ACAD", "AC", "AC0", "ADP0", "ADP1"):
            v = rd(f"/sys/class/power_supply/{n}/online")
            if v is not None:
                return v == "1"
        return True

    # ---- helpers -------------------------------------------------------
    def write_fan(self, v):
        # re-assert every 10 s: the firmware may reset the fan after suspend/resume
        if v != self.written or self.tick % 10 == 0:
            self.written = v
            wr(FAN, v)

    @staticmethod
    def slope(hist, v):
        hist.append(v)
        if len(hist) > 5:
            hist.pop(0)
        return (hist[-1] - hist[0]) / 4 if len(hist) == 5 else 0

    def classify(self):
        if self.tcpu >= HOT_CPU or self.tgpu >= HOT_GPU:
            return "hot"
        if self.gpu_power >= 35 or self.gpu_util >= 40:
            return "gaming"
        if self.cpu_load >= 55:
            return "heavy"
        if self.cpu_load < 8 and self.gpu_util < 10:
            return "idle"
        return "browsing"

    @staticmethod
    def level_for(pct):
        if pct <= 0:
            return 0
        for i, p in enumerate(LEVELS, 1):
            if p >= pct:
                return i
        return len(LEVELS)

    def floor_pct(self):
        f = 0
        if self.activity == "gaming":
            f = 60 if self.gpu_power >= 80 else 50
        elif self.activity == "heavy":
            f = 40
        # board / VRM area (EC temp3, idles ~50-57 °C): heat-soak hint, only while under load
        if f > 0 and self.tchassis:
            if self.tchassis >= 68:
                f = max(f, 60)
            elif self.tchassis >= 63:
                f = max(f, 50)
        return f

    def step_fan(self, i, temp, rising, up, shift, floor_idx):
        t_eff = temp + (PREDICT if rising else 0)
        want = 0
        for k, thr in enumerate(up, 1):
            if t_eff >= thr + shift:
                want = k
        want = max(want, floor_idx, 1)
        cur = self.lvl[i]
        if want > cur:
            self.lvl[i], self.changed[i] = want, self.tick
        elif want < cur:
            entry = up[cur - 1] + shift
            if temp < entry - HYST and floor_idx < cur and self.tick - self.changed[i] >= DOWN_HOLD:
                self.lvl[i], self.changed[i] = cur - 1, self.tick

    # ---- fan -----------------------------------------------------------
    def smart_fan(self):
        calm_now = self.activity in ("idle", "browsing") and self.tcpu < CALM_CPU and self.tgpu < CALM_GPU
        self.calm = self.calm + 1 if calm_now else 0
        if self.calm >= CALM_HOLD or (self.lvl == [0, 0] and calm_now):
            self.lvl = [0, 0]
            self.write_fan("0,0")                # firmware Auto: silent / 0 rpm when cool
            return
        if self.activity == "hot":
            self.lvl, self.changed = [len(LEVELS)] * 2, [self.tick] * 2
            self.write_fan("100,100")
            return
        shift = 0 if self.on_ac() else BAT_SHIFT
        f_idx = self.level_for(self.floor_pct())
        self.step_fan(0, self.tcpu, self.slope(self.hist_c, self.tcpu) >= 1, CPU_UP, shift, f_idx)
        self.step_fan(1, self.tgpu, self.slope(self.hist_g, self.tgpu) >= 1, GPU_UP, shift, f_idx)
        c, g = LEVELS[self.lvl[0] - 1], LEVELS[self.lvl[1] - 1]
        # shared heatpipes: when either chip is near its limit, run both fans almost together
        couple = 10 if (self.tcpu >= 85 or self.tgpu >= 75) else COUPLE
        c, g = max(c, g - couple), max(g, c - couple)
        self.write_fan(f"{c},{g}")

    # ---- CPU: power limit + thermal governor ---------------------------
    def enforce_power_limit(self):
        pl = CPU_PL_GAME if self.activity == "gaming" else CPU_PL
        for f in ("constraint_0_power_limit_uw", "constraint_1_power_limit_uw"):
            if num(RAPL + f) != pl:
                wr(RAPL + f, pl)

    def thermal_governor(self):
        new = self.cap
        if self.tcpu >= GOV_HI and self.tick - self.cap_changed >= 2:
            new = max(CAP_MIN, self.cap - CAP_DOWN)
        elif self.tcpu <= GOV_LO and self.cap < CAP_MAX and self.tick - self.cap_changed >= 3:
            new = min(CAP_MAX, self.cap + CAP_UP)
        if new != self.cap:
            self.cap, self.cap_changed = new, self.tick
            self.apply_cap()
        elif self.cap < CAP_MAX and self.tick % 30 == 0:
            self.apply_cap()                      # auto-cpufreq / turbo toggles may reset it

    def apply_cap(self):
        for p in self.cpus:
            if rd(p) != str(self.cap):
                wr(p, self.cap)

    # ---- profile -------------------------------------------------------
    def auto_profile(self):
        if os.path.exists(AUTO_OFF):
            return
        busy = self.activity in ("gaming", "heavy", "hot")
        self.busy_hold = 20 if busy else max(0, self.busy_hold - 1)
        ac = self.on_ac()
        # the firmware only accepts low-power / balanced on battery
        if self.busy_hold > 0:
            target = "performance" if ac else "balanced"
        else:
            target = "balanced" if ac else "low-power"
        cur = rd(PROFILE)
        # retry if something else changed the profile (the driver restores a saved one on every plug/unplug),
        # but only every 30 s per target so a profile the firmware refuses doesn't spam
        if cur and cur != target and (target != self.last_target or self.tick - self.last_try >= 30):
            self.last_target = target
            self.last_try = self.tick
            wr(PROFILE, target)
            names = {"performance": "Performance", "balanced": "Balanced", "low-power": "Eco"}
            why = self.activity if busy else ("on power" if ac else "on battery")
            osd("gauge", f"Profile: {names[target]} ({why})")
        elif cur == target:
            self.last_target = target

    # ---- output --------------------------------------------------------
    def publish(self, mode):
        fan = "manual" if mode == "manual" else ("auto" if self.lvl == [0, 0] else (self.written or "auto"))
        s = (f"mode={mode}\nactivity={self.activity}\nfan={fan}\ntcpu={self.tcpu:.0f}\ntgpu={self.tgpu:.0f}\n"
             f"chassis={(self.tchassis or 0):.0f}\ncpu={self.cpu_load:.0f}\ngpu={self.gpu_util:.0f}\n"
             f"gpuw={self.gpu_power:.0f}\ncap={self.cap // 1000}\n")
        tmp = STATE + ".tmp"
        try:
            with open(tmp, "w") as f:
                f.write(s)
            os.chmod(tmp, 0o644)
            os.replace(tmp, STATE)
        except OSError:
            pass

    def log_line(self, mode):
        if self.tick % 10 or self.activity not in ("gaming", "heavy", "hot"):
            return
        mhz = []
        for line in rd("/proc/cpuinfo", "").split("\n"):
            if line.startswith("cpu MHz"):
                mhz.append(float(line.split(":")[1]))
        line = (f"{time.strftime('%T')} act={self.activity} fan={'manual' if mode == 'manual' else self.written} "
                f"cpu={self.tcpu:.0f}C/{self.cpu_load:.0f}%/{sum(mhz) / max(1, len(mhz)):.0f}MHz cap={self.cap // 1000} "
                f"gpu={self.tgpu:.0f}C/{self.gpu_util:.0f}%/{self.gpu_power:.0f}W board={(self.tchassis or 0):.0f}C "
                f"pl={int(num(RAPL + 'constraint_0_power_limit_uw') or 0) // 1_000_000}W prof={rd(PROFILE)} "
                f"thr={rd('/sys/devices/system/cpu/cpu0/thermal_throttle/package_throttle_count')}\n")
        try:
            with open(LOG, "a") as f:
                f.write(line)
            if os.geteuid() == 0:
                os.chown(LOG, PW.pw_uid, PW.pw_gid)
            if self.tick % 600 == 0 and os.path.getsize(LOG) > 400_000:
                lines = open(LOG).readlines()[-2000:]
                open(LOG, "w").writelines(lines)
        except OSError:
            pass

    # ---- main step -----------------------------------------------------
    def step(self):
        self.tick += 1
        if self.tick % 30 == 1:
            if not os.path.exists(FAN):           # linuwu_sense gone (kernel update?): try to load it, keep running
                subprocess.run(["modprobe", "linuwu_sense"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if not (self.acer and self.coretemp and os.path.exists(self.acer)):
                self.find_hwmon()                 # hwmon numbers change when modules reload
        self.read_cpu_load()
        pkg = num(self.coretemp + "/temp1_input") if self.coretemp else None
        ec1 = num(self.acer + "/temp1_input") if self.acer else None
        ec2 = num(self.acer + "/temp2_input") if self.acer else None
        ec3 = num(self.acer + "/temp3_input") if self.acer else None
        raw_c = max(pkg or 0, ec1 or 0) / 1000
        raw_g = max((ec2 or 0) / 1000, self.gpu_temp if time.time() - self.gpu_seen <= 6 and self.gpu_temp else 0)
        if raw_c <= 0:                            # no sensors: let the firmware handle it
            self.write_fan("0,0")
            return
        self.tcpu = ema(self.tcpu, raw_c, 0.4)
        self.tgpu = ema(self.tgpu, raw_g if raw_g > 0 else raw_c, 0.4)
        if ec3:
            self.tchassis = ema(self.tchassis, ec3 / 1000, 0.2)
        self.activity = self.classify()

        ac = self.on_ac()
        if self.last_ac is not None and ac != self.last_ac:
            self.written = None                   # plug/unplug: the driver just reset the fans/profile, reassert now
            self.last_target = None
            self.cap_changed = self.tick
        self.last_ac = ac
        mode = "manual" if rd(FANMODE) == "manual" else "smart"
        if mode == "smart":
            self.smart_fan()
        else:
            self.lvl, self.written, self.calm = [0, 0], None, 0
        if self.tick % 3 == 1:
            self.enforce_power_limit()
        self.thermal_governor()
        self.auto_profile()
        self.publish(mode)
        self.log_line(mode)

    def shutdown(self, *_):
        wr(FAN, "0,0")                            # hand the fans back to the firmware
        self.cap = CAP_MAX
        self.apply_cap()
        raise SystemExit(0)


def main():
    brain = Brain()
    signal.signal(signal.SIGTERM, brain.shutdown)
    signal.signal(signal.SIGINT, brain.shutdown)
    notify("READY=1")
    nxt = time.monotonic()
    while True:
        try:
            brain.step()
        except Exception as e:                    # never die: a stuck fan under load is the worst outcome
            print("step failed:", repr(e), flush=True)
            if brain.tcpu is None or brain.tcpu >= 80:
                wr(FAN, "100,100")                # can't think -> cool hard, never leave the fans low
        notify("WATCHDOG=1")
        nxt += 1
        now = time.monotonic()
        if nxt < now - 5:                         # woke from suspend / long stall: resync and redo caches
            nxt = now
            brain.written = None
            brain.cap_changed = brain.tick
        time.sleep(max(0.0, nxt - now))


if __name__ == "__main__":
    main()
