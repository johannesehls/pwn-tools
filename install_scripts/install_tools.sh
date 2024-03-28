#!/usr/bin/bash

# #############################################################################
#                             Utils stuff.
# #############################################################################

# Print output functions.
p_try_install() { echo "[Info] Try to install $1..."; }
p_finish_install() { echo "[Info] Finish installation of $1."; }
p_error_install() { echo "[!] Error during installation of $1!"; }

p_check_installed() { echo "[Info] Check if $1 is installed..."; }
p_check_pos() { echo "[Info] -> $1 is installed."; }
p_check_neg() { echo "[Info] -> $1 is not installed."; }

# Identify systems package manager.
declare -A osInfoPm;
osInfoPm[/etc/redhat-release]=yum
osInfoPm[/etc/arch-release]=pacman
osInfoPm[/etc/gentoo-release]=emerge
osInfoPm[/etc/SuSE-release]=zypp
osInfoPm[/etc/debian_version]=apt-get
osInfoPm[/etc/alpine-release]=apk

for f in "${!osInfoPm[@]}"
do
    if [[ -f $f ]]; then
        # Check if a package manager was found already.
        if [[ -n "$PM" ]]; then
            echo "[!] Error! Two package managers detected:"
            echo "'$PM' and '${osInfoPm[$f]}'"
            echo "[!] Resolve this and start script again."
            exit 1
        fi
        PM="${osInfoPm[$f]}"
        echo "[Info] Detected package manager: $PM"
    fi
done

# Install function handling different package managers ('independent' install).
ind_install() {
    p_try_install "$1"

    if [[ "$PM" == "pacman" ]]; then
        sudo pacman -S "$1"
    elif [[ "$PM" == "apt-get" ]]; then
        sudo apt-get install "$1"
    elif [[ "$PM" == "yum" ]]; then
        sudo yum install "$1"
    elif [[ "$PM" == "apk" ]]; then
        sudo apk add "$1"
    elif [[ "$PM" == "zypp" ]]; then
        sudo zypper install "$1"
    elif [[ "$PM" == "emerge" ]]; then
        sudo emerge --ask --verbose "$1"
    fi

    p_finish_install "$1"
} 


# #############################################################################
#                             Install ghidra.
# #############################################################################
p_try_install "ghidra"

# 1. Check if java installed.
p_check_installed "jdk-openjdk"

if type -p java; then
    echo "-> found java executable in PATH"
    _java=java
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    echo "-> found java executable in JAVA_HOME"
    _java="$JAVA_HOME/bin/java"
fi

if [[ -z "$_java" ]]; then
    p_check_neg "jdk-openjdk"

    # Install java.
    ind_install "jdk-openjdk"
else
    p_check_pos "jdk-openjdk"
fi

p_finish_install "ghidra"
