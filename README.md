# nemo-turbo ⚡

> **Instant 70ms launch daemon for the Nemo file manager on Linux Mint & Cinnamon.**  
> Cuts window launch latency from **~1.78s down to 0.07s (a 25x speedup)** at **0.00% idle CPU** with zero battery drain.

[![Linux Mint](https://img.shields.io/badge/Linux_Mint-22.x_|_21.x-87cf3e?logo=linuxmint&logoColor=white)](https://linuxmint.com/)
[![Cinnamon](https://img.shields.io/badge/Desktop-Cinnamon-orange)](https://github.com/linuxmint/cinnamon)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![RAM](https://img.shields.io/badge/Idle_RAM-~25_MB-success)](#how-it-works)
[![CPU](https://img.shields.io/badge/Idle_CPU-0.00%25-success)](#how-it-works)

---

## The Problem

On Linux Mint and Cinnamon desktops, the **Nemo** file manager can feel sluggish to launch, frequently taking **1.7 to 4.9 seconds** to open.

### Why does this happen?
1. **No Resident Window Daemon:** In older versions of Cinnamon, Nemo managed both the desktop icons and window browsing in a single process, keeping it warm in RAM. When the Mint team split desktop icon management into a separate binary (`nemo-desktop`), normal Nemo lost its resident daemon.
2. **The 10-Second Idle Shutdown:** Nemo is built on `GtkApplication`. Whenever all file manager windows are closed, GTK starts an internal 10-second timer. If no new windows open, **Nemo unloads its caches and terminates completely**.
3. **Cold Start Penalty:** Every subsequent click on "Files" or `Super+E` is forced to do a cold start: loading shared libraries, initializing GTK3 widget trees, parsing fontconfig XMLs, and checking places.

---

## The Benchmark

Measured on **Linux Mint 22.3 (Zena)**, Intel Core i7-7600U, NVMe SSD:

| State | Cold Start (No Daemon) | `nemo-turbo` Active | **Improvement** |
| :--- | :---: | :---: | :---: |
| **Window Launch Latency** | **1,712 ms** (up to 4,900 ms on cold disk) | **72 ms** | **24x – 25x faster** |
| **CPU Utilization (Idle)** | 0.0% | **0.00%** | **Identical (Asleep)** |
| **Process Restarts** | Constant cold starts | **0 restarts** | **Zero battery wakeups** |
| **Memory Footprint** | 0 MB (when dead) | ~25 MB | Negligible |

---

## How It Works

`nemo-turbo` solves the problem without fragile hacks or continuous restart loops:

```
[ Desktop Login ]
        │
        ▼
[ nemo-turbo systemd user service ]
        │
        ├── Loads ~/.local/lib/libnemo-turbo.so (hooks g_application_run)
        │
        ▼
[ /usr/bin/nemo --no-default-window ]
        │
        ├── Calls g_application_hold(app)
        │   Increments GApplication use count (prevents the 10s idle shutdown)
        │
        ▼
[ Sits quietly in Linux epoll_wait (0.00% CPU, ~25 MB RAM) ]
        │
   User clicks "Files" or hits Super+E
        │
        ▼
[ Window appears in 70 ms via instant D-Bus activation ]
```

When you close all Nemo windows, Nemo stays resident in RAM at 0.00% CPU, ready to spawn the next window in **70 milliseconds**.

---

## Quickstart

### Installation (No root/sudo required)

```bash
git clone https://github.com/mailinglistenator/nemo-turbo.git
cd nemo-turbo
./install.sh
```

The installer builds the tiny C module (`libnemo-turbo.so`), registers the CLI (`nemo-turbo`), and enables the user systemd service.

---

## CLI Usage

`nemo-turbo` includes a companion CLI for inspection and benchmarks:

```bash
# Check daemon status, PID, and memory footprint
nemo-turbo status

# Measure live window spawn latency on your hardware
nemo-turbo bench

# Apply non-destructive Nemo engine settings (stops Samba & cloud-mount stalls)
nemo-turbo optimize

# Service management
nemo-turbo restart
nemo-turbo stop
nemo-turbo start

# View daemon logs
nemo-turbo logs
```

### Example `nemo-turbo status` Output:
```text
=== nemo-turbo status ===
  Service Status:   ACTIVE (running)
  Daemon PID:       15842
  Memory Footprint: 24.8 MB
  CPU Utilization:  0.0% (asleep in event loop)
  Active Windows:   1
=========================
```

---

## Recommended Engine Optimizations (`nemo-turbo optimize`)

Running `nemo-turbo optimize` applies non-destructive `gsettings` tweaks to eliminate other common Nemo bottlenecks:

1. **Disables Unused Samba Probes:** Stops Nemo from executing `net usershare info` on launch when Samba sharing is unconfigured.
2. **Prevents Cloud Mount Stalling:** If you have Google Drive, OneDrive, or network drives mounted in Home (`~`), disables recursive item counting and deep MIME detection so opening Home never hangs.

*(All settings are 100% reversible anytime).*

---

## Uninstallation

To restore stock Nemo behavior completely:

```bash
cd nemo-turbo
./uninstall.sh
```

---

## License

MIT License. Copyright (c) 2026 [Kyle Choi](https://github.com/mailinglistenator).
