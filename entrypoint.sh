#!/bin/sh
set -e

USER_CONFIG_DIR="/etc/edcb/user_config"
TEMPLATE_DIR="/etc/edcb/template"
TARGET_DIR="/var/local/edcb"

echo "[entrypoint] Setting up shared library search path..."
echo "/usr/local/lib/edcb" > /etc/ld.so.conf.d/edcb.conf
ldconfig

echo "[entrypoint] Starting initialization..."
mkdir -p "$USER_CONFIG_DIR"
mkdir -p "$USER_CONFIG_DIR/Setting"
mkdir -p "$TARGET_DIR"

# Ensure BonDriver_LinuxMirakc.so and SendTSTCP.so are linked in TARGET_DIR
ln -sf /usr/local/lib/edcb/BonDriver_LinuxMirakc.so "$TARGET_DIR/BonDriver_LinuxMirakc.so"
ln -sf /usr/local/lib/edcb/SendTSTCP.so "$TARGET_DIR/SendTSTCP.so"

if [ -d "$TEMPLATE_DIR" ]; then
    for item in EpgTimerSrv.ini Common.ini BonCtrl.ini Bitrate.ini ContentTypeText.txt; do
        if [ ! -f "$USER_CONFIG_DIR/$item" ] && [ -f "$TEMPLATE_DIR/$item" ]; then
            echo "[entrypoint] Copying template $item to user_config"
            cp "$TEMPLATE_DIR/$item" "$USER_CONFIG_DIR/$item"
        fi
    done
fi

for item in EpgTimerSrv.ini Common.ini BonCtrl.ini Bitrate.ini ContentTypeText.txt; do
    if [ -f "$USER_CONFIG_DIR/$item" ]; then
        echo "[entrypoint] Copying $item to $TARGET_DIR"
        cp -f "$USER_CONFIG_DIR/$item" "$TARGET_DIR/$item"
    fi
done

if [ -d "$USER_CONFIG_DIR/Setting" ]; then
    mkdir -p "$TARGET_DIR/Setting"
    mkdir -p "$TARGET_DIR/data"
    cp -rn "$USER_CONFIG_DIR/Setting/"* "$TARGET_DIR/Setting/" 2>/dev/null || true
    cp -rn "$USER_CONFIG_DIR/Setting/"* "$TARGET_DIR/data/" 2>/dev/null || true
fi

if [ -f "$USER_CONFIG_DIR/BonDriver_LinuxMirakc.so.ini" ]; then
    echo "[entrypoint] Copying BonDriver_LinuxMirakc.so.ini"
    cp -f "$USER_CONFIG_DIR/BonDriver_LinuxMirakc.so.ini" /usr/local/lib/edcb/BonDriver_LinuxMirakc.so.ini
    cp -f "$USER_CONFIG_DIR/BonDriver_LinuxMirakc.so.ini" "$TARGET_DIR/BonDriver_LinuxMirakc.so.ini"
fi

if [ -f "$USER_CONFIG_DIR/EpgDataCap_Bon.ini" ]; then
    echo "[entrypoint] Copying EpgDataCap_Bon.ini"
    cp -f "$USER_CONFIG_DIR/EpgDataCap_Bon.ini" "$TARGET_DIR/EpgDataCap_Bon.ini"
fi

if [ ! -d "$TARGET_DIR/HttpPublic" ] && [ -d "$TEMPLATE_DIR/HttpPublic" ]; then
    echo "[entrypoint] Copying HttpPublic template"
    cp -r "$TEMPLATE_DIR/HttpPublic" "$TARGET_DIR/HttpPublic"
fi

echo "[entrypoint] Starting EpgTimerSrv..."
exec "$@"
