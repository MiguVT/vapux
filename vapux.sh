#!/usr/bin/env bash
# ==============================================================================
# Vapux Manager - A Professional VapeV4 & Minecraft Manager for Linux
# Powered by UMU Launcher & Proton-CachyOS-Native-Msgwaitall
# ==============================================================================

# Strict safety error handling
set -euo pipefail
IFS=$'\n\t'

# Graceful exit handling
trap 'echo -e "\n\033[1;32m[*] Exiting Vapux Manager gracefully. Goodbye!\033[0m"; exit 0' SIGINT SIGTERM

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
if [[ -f "$CONFIG_FILE" ]]; then
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

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "\033[1;31m[!] Error: Missing required system dependencies: ${missing[*]}\033[0m"
        echo "Please install them via your package manager."
        echo "  -> For Arch-based: sudo pacman -S umu-launcher unzip curl"
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
    if [[ ! -d "$PROTON_PATH" ]] || [[ ! -f "$PROTON_PATH/toolmanifest.vdf" ]]; then
        echo -e "\033[1;33m[!] Warning: Valid toolmanifest.vdf not found in: $PROTON_PATH\033[0m"
        echo "[*] Opening configuration setup to fix path..."
        sleep 1.5
        setup_menu
        return 1
    fi
    return 0
}

get_vape_exe() {
    # Safely find the first .exe in the Vape directory using nullglob
    shopt -s nullglob
    local exes=("$VAPE_DIR"/*.exe)
    shopt -u nullglob

    if [[ ${#exes[@]} -gt 0 ]]; then
        echo "${exes[0]}"
    else
        echo ""
    fi
}

# --- CORE FUNCTIONS ---
setup_menu() {
    clear
    echo "=================================================="
    echo "        Vapux Manager - Setup & Configuration     "
    echo "=================================================="
    echo -e "\033[1;36mCurrent Proton directory:\033[0m $PROTON_PATH"
    echo -e "\033[1;36mShared Prefix path:\033[0m       $SHARED_PREFIX"
    echo ""
    read -rp "Enter path to Proton compatibility folder (or press Enter to keep): " new_path
    
    # Clean quotes if path was dragged and dropped from terminal
    new_path=$(echo "$new_path" | sed -e "s/^'//" -e "s/'$//" -e 's/^"//' -e 's/"$//')

    if [[ -n "$new_path" ]]; then
        if [[ "$new_path" == */proton ]]; then
            new_path="$(dirname "$new_path")"
        fi

        if [[ -d "$new_path" ]] && [[ -f "$new_path/toolmanifest.vdf" ]]; then
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

    local EXE_PATH="$FREESM_DIR/freesmlauncher.exe"

    if [[ ! -f "$EXE_PATH" ]]; then
        echo "[*] FreesmLauncher not found. Downloading MSVC Portable version..."
        local ZIP_URL="https://github.com/FreesmTeam/FreesmLauncher/releases/download/2.2.2/FreesmLauncher-Windows-MSVC-Portable-2.2.2.zip"
        local ZIP_PATH="$DATA_DIR/freesm.zip"

        # Using --fail to catch HTTP errors (like 404) natively
        if ! curl --fail -L --progress-bar "$ZIP_URL" -o "$ZIP_PATH"; then
            echo -e "\033[1;31m[!] Failed to download FreesmLauncher package. Check network or URL.\033[0m"
            sleep 2
            return
        fi

        echo "[*] Extracting package files..."
        unzip -qo "$ZIP_PATH" -d "$FREESM_DIR"
        rm -f "$ZIP_PATH"
        echo -e "\033[1;32m[+] FreesmLauncher installed successfully to $FREESM_DIR\033[0m"
        sleep 1
    fi

    echo -e "\033[1;32m[*] Launching Minecraft (FreesmLauncher) silently in background...\033[0m"
    
    # Suppress output, run in background, and detach so terminal remains clean
    env WINEPREFIX="$SHARED_PREFIX" \
        PROTONPATH="$PROTON_PATH" \
        WINEDEBUG="-all" \
        UMU_LOG_LEVEL=0 \
        umu-run "$EXE_PATH" > /dev/null 2>&1 & disown
    
    sleep 1
}

run_vape() {
    verify_proton || return

    local VAPE_EXE
    VAPE_EXE=$(get_vape_exe)

    if [[ -z "$VAPE_EXE" ]]; then
        clear
        echo "=================================================="
        echo "              Vapux Manager - VapeV4 Setup        "
        echo "=================================================="
        echo -e "\033[1;33m[!] No VapeV4 executable found in $VAPE_DIR\033[0m"
        read -rp "Drag and drop or type the full path to your VapeV4 .exe file: " source_exe
        
        # Clean potential quotes from terminal drag-and-drop
        source_exe=$(echo "$source_exe" | sed -e "s/^'//" -e "s/'$//" -e 's/^"//' -e 's/"$//')

        if [[ -f "$source_exe" ]]; then
            cp "$source_exe" "$VAPE_DIR/"
            VAPE_EXE=$(get_vape_exe)
            echo -e "\033[1;32m[+] VapeV4 saved successfully to $VAPE_DIR\033[0m"
            sleep 1
        else
            echo -e "\033[1;31m[!] Invalid file path provided. Aborting setup.\033[0m"
            sleep 2
            return
        fi
    fi

    echo -e "\033[1;32m[*] Launching VapeV4 silently into the shared prefix...\033[0m"
    
    # PROTON_VERB=runinprefix tells umu-run to attach to the active prefix
    env WINEPREFIX="$SHARED_PREFIX" \
        PROTONPATH="$PROTON_PATH" \
        PROTON_VERB="runinprefix" \
        WINEDEBUG="-all" \
        UMU_LOG_LEVEL=0 \
        umu-run "$VAPE_EXE" > /dev/null 2>&1 & disown
        
    sleep 1
}

# --- INITIALIZATION ROUTINE ---
check_system

# --- MAIN INTERACTIVE LOOP ---
while true; do
    clear
    echo "=================================================="
    echo -e " \033[1;36mVapux Manager - A VapeV4 Manager for Linux\033[0m "
    echo "=================================================="
    echo " 1) Run Minecraft (FreesmLauncher)"
    echo " 2) Run VapeV4 (Attaches to Prefix)"
    echo " 3) Setup / Configure Proton Path"
    echo " 4) Exit"
    echo "=================================================="
    read -rp "Select an option [1-4]: " choice

    case "$choice" in
        1)
            run_minecraft
            ;;
        2)
            run_vape
            ;;
        3)
            setup_menu
            ;;
        4)
            echo -e "\n\033[1;32mExiting Vapux Manager. Have a nice day!\033[0m"
            exit 0
            ;;
        *)
            echo -e "\033[1;31m[!] Invalid option, please choose between 1 and 4.\033[0m"
            sleep 1.5
            ;;
    esac
done
