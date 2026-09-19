<div align="center">
  <img src="assets/logo.png" alt="nemo-turbo logo" width="160" height="160" style="border-radius: 28px;" />
  <h1>nemo-turbo ⚡</h1>
  <p><strong>Instant launch daemon & CLI for the Nemo file manager on Linux Mint & Cinnamon.</strong></p>
  <p>Cuts window launch latency from <strong>~1.2s – 1.7s cold start</strong> down to <strong>instant warm response</strong> at <strong>0.00% idle CPU</strong> with zero battery churn.</p>

  <p>
    <a href="https://linuxmint.com/"><img src="https://img.shields.io/badge/Linux_Mint-22.x_|_21.x-87cf3e?logo=linuxmint&logoColor=white" alt="Linux Mint" /></a>
    <a href="https://github.com/linuxmint/cinnamon"><img src="https://img.shields.io/badge/Desktop-Cinnamon-orange" alt="Cinnamon" /></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License" /></a>
    <a href="#how-it-works"><img src="https://img.shields.io/badge/Idle_CPU-0.00%25-success" alt="CPU" /></a>
    <a href="#how-it-works"><img src="https://img.shields.io/badge/Idle_RAM-~48_MB-success" alt="RAM" /></a>
  </p>
</div>

---

## ⚡ The Problem

On Linux Mint and Cinnamon desktops, the **Nemo** file manager can feel sluggish to launch, frequently taking **1.2 to 1.7+ seconds** to open.

### Why does this happen?
1. **No Resident Window Daemon:** In older versions of Cinnamon, Nemo managed both the desktop icons and window browsing in a single process, keeping it warm in RAM. When desktop icon management was split into `nemo-desktop`, the main file manager lost its background daemon.
2. **The 10-Second Idle Shutdown:** Nemo is built on `GtkApplication`. Whenever all file manager windows are closed, GTK starts an internal 10-second timer. If no new windows open, **Nemo unloads its caches and terminates completely**.
3. **Cold Start Penalty:** Every subsequent click on "Files" or `Super+E` is forced to do a full cold start: loading shared libraries, initializing GTK3 widget trees, parsing fontconfig XMLs, and querying storage devices.

---

## 🚀 How It Works (Native `NEMO_PERSIST` Engine)

Rather than relying on fragile process respawn loops or invasive `LD_PRELOAD` hooks (which leak into child applications like `xed`), `nemo-turbo` activates Nemo's own built-in persistence flag:

```c
/* src/nemo-main.c:98-100 in Cinnamon Nemo source */
if (g_getenv ("NEMO_PERSIST") != NULL) {
    g_application_hold (G_APPLICATION (application));
}
```

When `NEMO_PERSIST=1` is set, Nemo natively holds the `GApplication` singleton open in the background:

```
[ Desktop Login ]
        │
        ▼
[ nemo-turbo systemd user service ]
        │
        ├── Environment="NEMO_PERSIST=1"
        │
        ▼
[ /usr/bin/nemo --no-default-window ]
        │
        ├── Natively calls g_application_hold()
        │   Increments GApplication use count (prevents 10s idle exit)
        │
        ▼
[ Sits quietly in Linux epoll_wait (0.00% CPU, ~48 MB RAM) ]
        │
   User clicks "Files" or hits Super+E
        │
        ▼
[ Window appears instantly via D-Bus activation ]
```

### Key Advantages:
* 🛡️ **Zero Child Process Leakage:** Does not use `LD_PRELOAD`. Applications launched from Files (`xed`, `eog`, calculators, LibreOffice) behave completely normally.
* 📦 **Zero Compiler Dependencies:** No `gcc` or `make` required to install or run.
* ⚡ **0.00% Idle CPU:** Nemo sleeps in Linux `epoll_wait`. Zero CPU wakeups or battery churn.
* 🔄 **Restart Resilience:** Configured with `Restart=always` so running `nemo -q` doesn't permanently kill your launch daemon.

---

## 📊 Objective Benchmarks

Tested on **Linux Mint 22.3 (Zena)**, Intel Core i7-7600U, NVMe SSD:

| Metric | Stock Cold Start (No Daemon) | `nemo-turbo` Active | Speedup |
| :--- | :---: | :---: | :---: |
| **D-Bus IPC Response** | N/A (Process cold boots) | **~75 ms** | **Instant handoff** |
| **Visible X11 Window Map** | **1,200 ms – 1,712 ms** | **~380 ms – 500 ms** | **3x – 4x faster** |
| **Idle CPU Utilization** | 0.0% | **0.00%** (0 ticks) | **Zero churn** |
| **Idle RAM Footprint** | 0 MB (when dead) | ~48 MB fresh (~70 MB active) | Minimal |
| **Process Restarts** | Constant cold boots | **0 restarts** | **Zero battery penalty** |

---

## 🛠️ Quickstart

### Installation (No root/sudo required)

```bash
git clone https://github.com/mailinglistenator/nemo-turbo.git
cd nemo-turbo
./install.sh
```

---

## 💻 CLI Usage

`nemo-turbo` includes a companion CLI for management and live latency benchmarking:

```bash
# Check daemon status, PID, live memory, and measured CPU
nemo-turbo status

# Measure actual D-Bus and visible window launch latency on your hardware
nemo-turbo bench

# Apply safe Nemo engine optimizations (disables unused Samba probe)
nemo-turbo optimize

# Revert optimizations back to previous user settings
nemo-turbo restore

# View daemon journal logs
nemo-turbo logs

# Service lifecycle
nemo-turbo restart
nemo-turbo stop
nemo-turbo start
```

### Live CLI Status Output:
```text
$ nemo-turbo status
=== nemo-turbo status ===
  Service Status:   ACTIVE (running via systemd)
  Daemon PID:       1668
  Memory Footprint: 48.2 MB
  CPU Utilization:  0.0% (0 ticks/150ms sample)
  Active Windows:   0
=========================
```

---

## ⚙️ Safe Engine Optimizations (`nemo-turbo optimize`)

Running `nemo-turbo optimize` safely applies non-destructive `gsettings` tweaks:
1. **Disables Unused Samba Probing:** Prevents Nemo from querying network shares when Samba sharing is unconfigured. Preserves other plugins in `disabled-extensions`.
2. **Eliminates Cloud-Mount Stalling:** Disables recursive item counting and deep content detection so opening Home (`~`) with virtual cloud mounts never hangs.

*All original settings are automatically backed up to `~/.config/nemo-turbo/previous_settings.json` and can be restored anytime with `nemo-turbo restore`.*

---

## 🗑️ Uninstallation

To restore stock Nemo behavior completely:

```bash
cd nemo-turbo
./uninstall.sh
```

---

## 📄 License

MIT License. Copyright (c) 2026 [Kyle Choi](https://github.com/mailinglistenator).
