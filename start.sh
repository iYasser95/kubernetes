#!/bin/bash

# This script is used to automate the installation of kubernetes cluster for both Master and Worker Nodes
# Helper Function
print_message() {
    case "$1" in
        success) echo -e "\e[32m$2\e[0m";;
        info) echo -e "\e[33m$2\e[0m";;
        error) echo -e "\e[31m$2\e[0m";;
        line) echo -e "\e[90m$2\e[0m";;
        *) echo "$2";;
    esac
}

# Get the directory of the script
script_dir="$(pwd)"

get_script_name() {
    local choice="$1"
    local file_name=""
    if [ "$choice" = "1" ]; then
        if  echo "$DISTRO_NAME" | tr '[:upper:]' '[:lower:]' | grep -Eq "centos|fedora"; then
            file_name="redhat-master.sh"
        elif  echo "$DISTRO_NAME" | grep -qiE "ubuntu|debian"; then
            file_name="debian-master.sh"
        fi

    elif [ "$choice" = "2" ]; then
        if  echo "$DISTRO_NAME" | tr '[:upper:]' '[:lower:]' | grep -Eq "centos|fedora"; then
            file_name="redhat-worker.sh"
        elif  echo "$DISTRO_NAME" | grep -qiE "ubuntu|debian"; then
            file_name="debian-worker.sh"
        fi
    fi
    echo $file_name
}
run_scripts() {
    file_name=$(get_script_name "$choice")
    file_path="$script_dir/$file_name"
    echo "https://raw.githubusercontent.com/iYasser95/kubernetes/main/$file_name"

    if [ -f "$file_path" ]; then
        echo ''
        print_message line '***************************************************************************************'
        print_message info 'Script found in the current directory, Running Script..'
        print_message line '***************************************************************************************'
        sudo su -c ". $file_path"
    else
        echo ''
        print_message line '***************************************************************************************'
        print_message info 'Script Not found in the current directory, Starting Download..'
        print_message line '***************************************************************************************'
        curl -O "https://raw.githubusercontent.com/iYasser95/kubernetes/main/$file_name"
        if [ $? -eq 0 ]; then
            echo ''
            print_message line '***************************************************************************************'
            print_message info 'Script Download Successful, Running Script..'
            print_message line '***************************************************************************************'
            sudo su -c ". $file_path"
        else
            echo ''
            print_message line '***************************************************************************************'
            print_message error 'Script Download Failed. Please try again later.'
            print_message line '***************************************************************************************'
        fi
    fi
}

# Check architecture
print_message line '***************************************************************************************'
print_message info 'Checking System Requirements ..'
print_message line '***************************************************************************************'
ARCH=$(uname -m) 
DOWNLOAD_URL=""
if [ "$ARCH" == "x86_64" ]; then
  ARCH_SUFFIX="amd64"
elif [ "$ARCH" == "aarch64" ]; then
  ARCH_SUFFIX="arm64"
elif [ "$ARCH" == "i386" ]; then
  ARCH_SUFFIX="386"
else
  print_message error "Unsupported architecture: $ARCH. Please check the provided links for compatibility."
  exit 1
fi

# Check System Type 
DISTRO_NAME=$(awk -F'=' '/^NAME=/{gsub(/"/, "", $2); print $2}' /etc/*release*)
read -p "Enter 1 for Master Node, Enter 2 for Worker Node: " choice
if [[ "$choice" != "1" && "$choice" != "2" ]]; then
    print_message error "Invalid choice. Please enter 1 for Master Node or 2 for Worker Node."
else
# Check if the variable contains "centos" or "fedora"
    if  echo "$DISTRO_NAME" | tr '[:upper:]' '[:lower:]' | grep -Eq "centos|fedora|ubuntu|debian"; then
        run_scripts
    else
        print_message line '***************************************************************************************'
        print_message error 'This script is only compatible with CentOS, Fedora, Ubuntu and Debian'
        print_message line '***************************************************************************************'
    fi
fi
