#!/bin/bash
# This script downloads proprietary software from Google.
# The user must accept Google's terms of use.
# Android Studio: https://developer.android.com/studio

detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    elif command -v apk >/dev/null 2>&1; then
        echo "apk"
    else
        echo "unknown"
    fi
}

install_dependencies() {
    missing_curl=0
    missing_unzip=0
    command -v curl >/dev/null 2>&1 || missing_curl=1
    command -v unzip >/dev/null 2>&1 || missing_unzip=1

    if [ $missing_curl -eq 0 ] && [ $missing_unzip -eq 0 ]; then
        return 0
    fi

    pkg_manager=$(detect_package_manager)
    echo "Instalando dependencias usando: $pkg_manager"

    if [ "$(id -u)" -eq 0 ]; then
        SUDO_CMD=""
    else
        SUDO_CMD="sudo"
    fi

    case "$pkg_manager" in
        apt)
            $SUDO_CMD apt-get update
            [ $missing_curl -eq 1 ] && $SUDO_CMD apt-get install -y curl
            [ $missing_unzip -eq 1 ] && $SUDO_CMD apt-get install -y unzip
            ;;
        dnf)
            [ $missing_curl -eq 1 ] && $SUDO_CMD dnf install -y curl
            [ $missing_unzip -eq 1 ] && $SUDO_CMD dnf install -y unzip
            ;;
        yum)
            [ $missing_curl -eq 1 ] && $SUDO_CMD yum install -y curl
            [ $missing_unzip -eq 1 ] && $SUDO_CMD yum install -y unzip
            ;;
        pacman)
            [ $missing_curl -eq 1 ] && $SUDO_CMD pacman -Sy --noconfirm curl
            [ $missing_unzip -eq 1 ] && $SUDO_CMD pacman -Sy --noconfirm unzip
            ;;
        zypper)
            [ $missing_curl -eq 1 ] && $SUDO_CMD zypper --non-interactive install curl
            [ $missing_unzip -eq 1 ] && $SUDO_CMD zypper --non-interactive install unzip
            ;;
        apk)
            [ $missing_curl -eq 1 ] && $SUDO_CMD apk add --no-cache curl
            [ $missing_unzip -eq 1 ] && $SUDO_CMD apk add --no-cache unzip
            ;;
        *)
            echo "No se pudo instalar dependencias automáticamente."
            return 1
            ;;
    esac
}

# LOAD CONFIGURATION
if [ -f "./config.env" ]; then
    . ./config.env
else
    echo "ERROR: config.env no encontrado en el directorio actual."
    exit 1
fi

install_dependencies || exit 1

if [ -z "$URL_ANDROID_STUDIO" ]; then
    echo "ERROR: URL_ANDROID_STUDIO no esta definida en config.env"
    exit 1
fi

if [ -z "$URL_JDK" ]; then
    echo "ERROR: URL_JDK no esta definida en config.env"
    exit 1
fi


# FIND CURL VERSION
version=$(curl --version | head -n1 | awk '{print $2}')

# VALIDATE CURL
if [ -z "$version" ]; then
    echo "NOT INSTALLING CURL"
else
    echo "CURL OK : $version"
    echo "DELETE TAR.GZ + ANDROID STUDIO FOLDER IF EXISTS"
    rm -rf *.tar.gz
    rm -rf android-studio
    rm -rf "$HOME/android-studio"

    echo "START DOWNLOAD: $URL_ANDROID_STUDIO"
    curl -O -S "$URL_ANDROID_STUDIO"
    echo "FINISH DOWNLOAD"

    file=$(ls | grep tar.gz)

    if [ -z "$file" ]; then
        echo "ERROR DOWNLOAD ANDROID STUDIO"
    else
        echo "DOWNLOAD OK : $file"
        echo "TAR FILE"
        tar -xzf *.tar.gz
        file=$(ls | grep -x "android-studio")

        if [ -z "$file" ]; then
            echo "ERROR EXTRACTING FILE"
        else
            echo "EXTRACTING FILE: OK"
            echo "MOVE android-studio TO $HOME/android-studio"
            mv "android-studio" "$HOME/android-studio"

            echo "CREATE ICON"
            cp androidstudio.desktop.template androidstudio.desktop
            sed -i "s|\$HOME|$HOME|g" androidstudio.desktop
            mv androidstudio.desktop "$HOME/.local/share/applications/androidstudio.desktop"

            echo "PERMISSION ICON"
            chmod +x "$HOME/.local/share/applications/androidstudio.desktop"

            echo "UPDATE DESKTOP ICON"
            update-desktop-database "$HOME/.local/share/applications/androidstudio.desktop"

            rm -rf *.tar.gz
            rm -rf android-studio
            echo "DELETE FOLDER androidstudio_install"

            echo "START DOWNLOAD: JDK from $URL_JDK"
            curl -O -S "$URL_JDK"
            echo "FINISH DOWNLOAD JDK"

            jdk_file=$(basename "$URL_JDK")

            if [ -f "$jdk_file" ]; then
                echo "DOWNLOAD OK: $jdk_file"
                echo "EXTRACT JDK"
                tar -xzf "$jdk_file"
                jdk_dir=$(tar -tf "$jdk_file" | head -1 | cut -f1 -d"/")

                if [ -d "$jdk_dir" ]; then
                    echo "MOVE JDK TO $HOME/android-studio/"
                    mv "$jdk_dir" "$HOME/android-studio/"
                    echo "JDK COPIED"
                    
                    STUDIO_JDK_PATH="$HOME/android-studio/$jdk_dir"
                    STUDIO_JDK_LINE="export STUDIO_JDK=\"$STUDIO_JDK_PATH\""
                    if ! grep -qF "export STUDIO_JDK=" "$HOME/.bashrc"; then
                        echo "" >> "$HOME/.bashrc"
                        echo "# Added by Android Studio Install Script" >> "$HOME/.bashrc"
                        echo "$STUDIO_JDK_LINE" >> "$HOME/.bashrc"
                        echo "STUDIO_JDK SET IN .bashrc"
                    fi

                    echo "UPDATING DESKTOP ICON WITH ENV VARS"
                    # Modificamos el .desktop para que incluya las variables al lanzarse desde el menú
                    DESKTOP_PATH="$HOME/.local/share/applications/androidstudio.desktop"
                    EXEC_LINE="Exec=env STUDIO_JDK=\"$STUDIO_JDK_PATH\" $HOME/android-studio/bin/studio.sh"
                    sed -i "s|^Exec=.*|$EXEC_LINE|" "$DESKTOP_PATH"
                else
                    echo "ERROR EXTRACTING JDK"
                fi

                echo "CLEANING UP JDK TAR"
                rm -f "$jdk_file"
            else
                echo "ERROR DOWNLOADING JDK"
            fi
        fi
    fi
fi
