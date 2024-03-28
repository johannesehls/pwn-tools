#!/usr/bin/bash

# #############################################################################
#                             Utils stuff.
# #############################################################################

# Require script to be executed in root mode.
if [ `id -u` -ne "0" ]
  then echo "Please run this script as root or using sudo!"
  exit
fi

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

# 2. Check if jdk directory is added to path.
# Assume some path starting with '/usr/lib/jvm/*'.
if [[ "$PATH" != *"/usr/lib/jvm"* ]]; then
    if grep -q "export PATH=/usr/lib/jvm" ".bashrc"; then
        if [[ -f "/usr/lib/jvm/default/bin" ]]; then
            echo "" >> .bashrc
            echo "export PATH=/usr/lib/jvm/default/bin:\$PATH" >> .bashrc
        else
            echo "Error during adding right path of jdk to PATH!"
            exit 1
        fi
    fi
    source "$HOME/.bashrc"
fi

# 3. Check if ghidra installed, if not download and install.
p_check_installed "ghidra"
ghidra=$(find '/opt' -maxdepth 1 -regextype sed -regex '.*ghidra_.*_PUBLIC')
if [[ -z "$ghidra" ]]; then
    p_check_neg "ghidra"
    p_try_install "ghidra binary"
    # Download latest prebuild github release from github.
    gh_site=$(curl -L -s "https://github.com/NationalSecurityAgency/ghidra/releases/latest")
    release_date=$(
        echo "$gh_site" \
        | grep "datetime" \
        | awk -F'datetime=\"' '{ print $2 }' \
        | head -c 10 \
        | sed s/-//g
    )
    release_date=$(date '+%Y%m%d' -d "$release_date - 1 day")
    version=$(
        echo "$gh_site" \
        | grep "<title>Release Ghidra " \
        | cut -c 25- \
        | awk -F' ' '{ print $1 }'
    )
    echo "-> Latest version: ${version}"
    file_name="ghidra_${version}_PUBLIC_${release_date}.zip"
    dl_url="https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_11.0.2_build/${file_name}"

    #wget -P "/tmp/" -i "$dl_url" # Download latest release.
    curl -o "/tmp/${file_name}" -LO "$dl_url" # Download latest release.

    unzip "/tmp/${file_name}" -d "/opt/" # unzip to /opt.

    rm -f "/tmp/${file_name}"
    p_finish_install "ghidra binary"
else
    p_check_pos "ghidra"
fi

# Check if symlinked to /bin/.
if [[ "$(ls -A1 /bin)" != *"ghidra"* ]]; then 
    ln -s "${ghidra}/ghidraRun" "/bin/ghidra"
    echo "[Info] Symlinked ghidra into binaries."
fi

p_finish_install "ghidra"


