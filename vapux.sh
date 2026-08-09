#!/usr/bin/env bash
# ==============================================================================
# Vapux Manager - A Professional VapeV4 & Minecraft Manager for Linux
# Powered by UMU Launcher & Proton-CachyOS-Native-Msgwaitall
# ==============================================================================

# Strict safety error handling
set -uo pipefail

# XDG Standard Directories for Vapux
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/vapux"
CONFIG_FILE="$CONFIG_DIR/settings.conf"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/vapux"
SHARED_PREFIX="$DATA_DIR/compatdata"
FREESM_DIR="$DATA_DIR/freesmlauncher"
VAPE_DIR="$DATA_DIR/vape"

# Ensure core directory structure exists
mkdir -p "$CONFIG_DIR" "$DATA_DIR" "$SHARED_PREFIX" "$FREESM_DIR" "$VAPE_DIR"

# Strict requirement: Target strictly the msgwaitall variant folder directory
DEFAULT_PROTON="/usr/share/steam/compatibilitytools.d/proton-cachyos-native-msgwaitall"

# Load or initialize configuration file
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    PROTON_PATH="$DEFAULT_PROTON"
    echo "PROTON_PATH=\"$PROTON_PATH\"" > "$CONFIG_FILE"
fi

# --- DEPENDENCY & SYSTEM VALIDATION ---
check_system() {
    local missing=()
    for cmd in umu-run unzip curl; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "\033[1;31m[!] Error: Missing required system dependencies: ${missing[*]}\033[0m"
        echo "Please install them via your package manager:"
        echo "  -> sudo pacman -S umu-launcher unzip curl"
        exit 1
    fi
}

verify_proton() {
    # Auto-fix legacy paths ending in '/proton' from older script iterations
    if [[ "$PROTON_PATH" == */proton ]]; then
        PROTON_PATH="$(dirname "$PROTON_PATH")"
        echo "PROTON_PATH=\"$PROTON_PATH\"" > "$CONFIG_FILE"
    fi

    # Check if directory exists and contains toolmanifest.vdf
    if [ ! -d "$PROTON_PATH" ] || [ ! -f "$PROTON_PATH/toolmanifest.vdf" ]; then
        echo -e "\033[1;33m[!] Warning: Valid toolmanifest.vdf not found in: $PROTON_PATH\033[0m"
        echo "[*] Opening configuration setup to fix path..."
        sleep 1.5
        setup_menu
        return 1
    fi
    return 0
}

# --- CORE FUNCTIONS ---

setup_menu() {
    clear
    echo "=================================================="
    echo "        Vapux Manager - Setup & Configuration     "
    echo "=================================================="
    echo "Current Proton directory: $PROTON_PATH"
    echo "Shared Prefix path:       $SHARED_PREFIX"
    echo ""
    read -rp "Enter path to Proton compatibility folder (or press Enter to keep): " new_path
    
    # Clean quotes if path was dragged and dropped from terminal
    new_path=$(echo "$new_path" | sed "s/^'//;s/'$//")

    if [ -n "$new_path" ]; then
        if [[ "$new_path" == */proton ]]; then
            new_path="$(dirname "$new_path")"
        fi

        if [ -d "$new_path" ] && [ -f "$new_path/toolmanifest.vdf" ]; then
            PROTON_PATH="$new_path"
            echo "PROTON_PATH=\"$PROTON_PATH\"" > "$CONFIG_FILE"
            echo -e "\033[1;32m[+] Proton directory updated successfully!\033[0m"
        else
            echo -e "\033[1;31m[!] Invalid path: Directory does not exist or lacks toolmanifest.vdf.\033[0m"
        fi
    else
        echo "[*] Keeping existing path configuration."
    fi
    sleep 1.5
}

run_minecraft() {
    verify_proton || return

    EXE_PATH="$FREESM_DIR/freesmlauncher.exe"

    if [ ! -f "$EXE_PATH" ]; then
        echo "[*] FreesmLauncher not found. Downloading MSVC Portable version..."
        ZIP_URL="https://github.com/FreesmTeam/FreesmLauncher/releases/download/2.2.2/FreesmLauncher-Windows-MSVC-Portable-2.2.2.zip"
        ZIP_PATH="$DATA_DIR/freesm.zip"

        curl -L "$ZIP_URL" -o "$ZIP_PATH" || {
            echo -e "\033[1;31m[!] Failed to download FreesmLauncher package.\033[0m"
            sleep 2
            return
        }

        echo "[*] Extracting package files..."
        unzip -qo "$ZIP_PATH" -d "$FREESM_DIR"
        rm -f "$ZIP_PATH"
        echo -e "\033[1;32m[+] FreesmLauncher installed successfully to $FREESM_DIR\033[0m"
    fi

    echo "[*] Launching Minecraft (FreesmLauncher) via umu-run..."
    WINEPREFIX="$SHARED_PREFIX" PROTONPATH="$PROTON_PATH" umu-run "$EXE_PATH" &
    sleep 1
}

run_vape() {
    verify_proton || return

    VAPE_EXE=$(find "$VAPE_DIR" -maxdepth 1 -name "*.exe" | head -n 1)

    if [ -z "$VAPE_EXE" ]; then
        clear
        echo "=================================================="
        echo "              Vapux Manager - VapeV4 Setup        "
        echo "=================================================="
        echo "[!] No VapeV4 executable found in $VAPE_DIR"
        read -rp "Drag and drop or type the full path to your VapeV4 .exe file: " source_exe
        
        source_exe=$(echo "$source_exe" | sed "s/^'//;s/'$//")

        if [ -f "$source_exe" ]; then
            cp "$source_exe" "$VAPE_DIR/"
            VAPE_EXE=$(find "$VAPE_DIR" -maxdepth 1 -name "*.exe" | head -n 1)
            echo -e "\033[1;32m[+] VapeV4 saved successfully to $VAPE_DIR\033[0m"
        else
            echo -e "\033[1;31m[!] Invalid file path provided. Aborting setup.\033[0m"
            sleep 2
            return
        fi
    fi

    echo "[*] Launching VapeV4 via umu-run into the shared prefix..."
    # PROTON_VERB=runinprefix tells umu-run to attach to the active prefix without lock collisions
    WINEPREFIX="$SHARED_PREFIX" PROTONPATH="$PROTON_PATH" PROTON_VERB=runinprefix umu-run "$VAPE_EXE" &
    sleep 1
}

# --- INITIALIZATION ROUTINE ---
check_system

# --- MAIN INTERACTIVE LOOP ---
while true; do
    clear
    echo "=================================================="
    echo "       Vapux Manager - A VapeV4 Manager for Linux   "
    echo "=================================================="
    echo " 1) Run Minecraft (FreesmLauncher)"
    echo " 2) Run VapeV4"
    echo " 3) Setup / Configure Proton Path"
    echo " 4) Exit"
    echo "=================================================="
    read -rp "Select an option [1-4]: " choice

    case $choice in
        1)
            run_minecraft
            sleep 1.5
            ;;
        2)
            run_vape
            sleep 1.5
            ;;
        3)
            setup_menu
            ;;
        4)
            echo "Exiting Vapux Manager. Have a nice day!"
            exit 0
            ;;
        *)
            echo -e "\033[1;31m[!] Invalid option, please choose between 1 and 4.\033[0m"
            sleep 1
            ;;
    esac
done
