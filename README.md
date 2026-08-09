# Vapux Manager

A simple, straightforward manager for running Minecraft (**FreesmLauncher**) and **VapeV4** on Linux, powered by **UMU Launcher**, Proton and [wine-vapev4](https://github.com/MiguVT/wine-vapev4).

---

## Prerequisites

Before running the script, make sure you have the required system dependencies installed:

* **Arch Linux / Steam Deck:**
```bash
sudo pacman -S umu-launcher unzip curl

```


* **Proton:** The script is optimized to use **Proton-CachyOS-Native-Msgwaitall** by default, placed in `/usr/share/steam/compatibilitytools.d/`. You can change this path anytime through the script's setup menu.

---

## Quick Start

1. Clone or download the script into your workspace.
2. Make the script executable:
```bash
chmod +x vapux.sh

```


3. Run the manager:
```bash
./vapux.sh

```



---

## Features & Usage

When you launch the script, you'll be greeted with an interactive terminal menu:

* **1) Run Minecraft (FreesmLauncher):** Automatically downloads and sets up the latest MSVC Portable version of FreesmLauncher if it isn't already installed, then launches it in a shared Wine prefix.
* **2) Run VapeV4:** Prompts you to point to your VapeV4 `.exe` file on the first run, saves it securely, and safely injects it into the active Minecraft prefix using UMU's `runinprefix` verb.
* **3) Setup / Configure Proton Path:** Allows you to update or verify your target Proton compatibility directory.
* **4) Exit:** Safely closes the manager.

---

## Directory Structure

Vapux Manager adheres to XDG standards, keeping your files cleanly organized:

* **Config:** `~/.config/vapux/`
* **Data & Prefixes:** `~/.local/share/vapux/`
