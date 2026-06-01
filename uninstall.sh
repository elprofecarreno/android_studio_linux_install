#!/bin/bash

# LOAD CONFIGURATION
if [ -f "./config.env" ]; then
    . ./config.env
else
    echo "ERROR: config.env no encontrado en el directorio actual."
    exit 1
fi

echo "ANDROID STUDIO UNINSTALLING..."

# Eliminar carpeta de instalación
if [ -d "$HOME/android-studio" ]; then
    echo "REMOVING: $HOME/android-studio"
    rm -rf "$HOME/android-studio"
else
    echo "SKIPPED: $HOME/android-studio not found"
fi

# Eliminar carpeta del SDK (usando variable de config.env)
# Evaluamos $ANDROID_SDK_PATH para expandir $HOME si es necesario
EXPANDED_SDK_PATH=$(eval echo "$ANDROID_SDK_PATH")
if [ -d "$EXPANDED_SDK_PATH" ]; then
    echo "REMOVING SDK: $EXPANDED_SDK_PATH"
    rm -rf "$EXPANDED_SDK_PATH"
else
    echo "SKIPPED: SDK folder not found at $EXPANDED_SDK_PATH"
fi

## Eliminar carpeta de configuración
#if [ -d "$HOME/.sqldeveloper" ]; then
#    echo "REMOVING: $HOME/.sqldeveloper"
#    rm -rf "$HOME/.sqldeveloper"
#else
#    echo "SKIPPED: $HOME/.sqldeveloper not found"
#fi

# Eliminar ícono de escritorio
desktop_file="$HOME/.local/share/applications/androidstudio.desktop"
if [ -f "$desktop_file" ]; then
    echo "REMOVING: $desktop_file"
    rm -f "$desktop_file"
else
    echo "SKIPPED: $desktop_file not found"
fi

# Actualizar base de datos de íconos del escritorio
echo "UPDATE DESKTOP ICONS"
update-desktop-database "$HOME/.local/share/applications/"

# Limpiar .bashrc
if [ -f "$HOME/.bashrc" ]; then
    echo "CLEANING .bashrc..."
    # Eliminar las líneas agregadas por el script de instalación
    sed -i '/# Added by Android Studio Install Script/d' "$HOME/.bashrc"
    sed -i '/export STUDIO_JDK=/d' "$HOME/.bashrc"
    sed -i '/# Android SDK configuration/d' "$HOME/.bashrc"
    sed -i '/export ANDROID_HOME=/d' "$HOME/.bashrc"
    sed -i '/export ANDROID_SDK_ROOT=/d' "$HOME/.bashrc"
    sed -i '/ANDROID_HOME\/emulator/d' "$HOME/.bashrc"
    echo ".bashrc CLEANED"
fi

echo "ANDROID STUDIO UNINSTALLED SUCCESSFULLY."
