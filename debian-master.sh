#!/bin/bash
# This Script is configured to be used with Debian Distributions.

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

# Check architecture
echo ''
print_message line '***************************************************************************************'
print_message info 'Checking System Requirements ..'
ARCH=$(uname -m) 
DOWNLOAD_URL=""
if [ "$ARCH" = "x86_64" ]; then
  ARCH_SUFFIX="amd64"
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_SUFFIX="arm64"
elif [ "$ARCH" = "i386" ]; then
  ARCH_SUFFIX="386"
else
  print_message error "Unsupported architecture: $ARCH. Please check the provided links for compatibility."
  exit 1
fi

# Check System Type 
DISTRO_NAME=$(lsb_release -si)
LOWER_DISTRO_NAME=$(echo "$DISTRO_NAME" | tr '[:upper:]' '[:lower:]')

if ! echo "$LOWER_DISTRO_NAME" | grep -qiE "ubuntu|debian"; then
    echo "This Script is only valid for Ubuntu or Debian. Modify at your own risk" >&2
    exit 1
fi

# Check CPU and RAM Requirements
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
CPU_COUNT=$(nproc)

print_message info "System Architecture is: $ARCH_SUFFIX"
print_message info "System Type is: $DISTRO_NAME"
print_message info "Total RAM: ${TOTAL_RAM}MB"
print_message info "CPU Count: ${CPU_COUNT}"
# Master Node Requires 2 GB RAM
if [ "$TOTAL_RAM" -lt 2048 ]; then
    echo ''
    print_message info '** WARNING **'
    print_message info "Insufficient RAM. The Minimum requirement for Master Node is 2 GB."
    echo ''
    print_message info '** WARNING **'
fi

# Master Node Requires 2 CPU
if [ "$CPU_COUNT" -lt 2 ]; then
    echo ''
    print_message info '** WARNING **'
    print_message info "Insufficient CPU count. The Minimum requirement for Master Node is 2 CPUs."
    echo ''
    print_message info '** WARNING **'
fi
print_message success 'System Requirement Check is Done ..'
# Prompt for user input
read -p "Enter the desired hostname (e.g., master-node - make sure it unique from other nodes): " hostname

# Validate input
if [[ -z "$hostname" ]]; then
  echo "Error: Please enter a hostname."
  exit 1
fi
print_message line '***************************************************************************************'
print_message info 'Updating Hostname'
print_message line '***************************************************************************************'
# Set hostname
sudo hostnamectl set-hostname "$hostname"
echo ''
print_message line '***************************************************************************************'
print_message info 'Updating the System ..'
print_message line '***************************************************************************************'
# Update Ubuntu System
sudo apt update && sudo apt upgrade -y

# Prepare for containerd installation
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
echo ''
export DEFAULT_GATEWAY_IP=$(hostname -I | awk '{print $1}')
print_message line '***************************************************************************************'
print_message info 'Updating Hostfile'
print_message line '***************************************************************************************'

# Modify /etc/hosts file
sudo bash -c "echo \"$DEFAULT_GATEWAY_IP $hostname\" >> /etc/hosts"
print_message line '***************************************************************************************'
print_message success "Hostname Changed into: $hostname | Default IP Detected: $DEFAULT_GATEWAY_IP"
print_message line '***************************************************************************************'
echo ''
# Disable Swap - Kubelet doesn't work if Swap is enabled.
sudo sed -i '/swap/d' /etc/fstab
sudo swapoff -a
print_message line '***************************************************************************************'
print_message success 'Swap is Disabled..'
print_message line '***************************************************************************************'
sudo sysctl --system
print_message line '***************************************************************************************'
print_message info 'Installing Container D..'
print_message line '***************************************************************************************'
# Install and configure containerd
sudo apt install -y containerd

sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable --now containerd
print_message line '***************************************************************************************'
print_message success 'Container D is now enabled and working'
print_message line '***************************************************************************************'
# Make SELinux permissive
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
print_message line '***************************************************************************************'
print_message info 'Installing kubeadm, kubelet and kubectl ..'
print_message line '***************************************************************************************'
echo ''
# Install kubeadm, kubelet and kubectl
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet
print_message line '***************************************************************************************'
print_message success 'kubelet is now enabled and working.. '
print_message line '***************************************************************************************'
echo ''
# Install crictl
echo ''
print_message line '***************************************************************************************'
print_message info 'Installing CRICTL (Command Line for Container Runtimes)'
VERSION="v1.29.0"
DOWNLOAD_URL="https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-$ARCH_SUFFIX.tar.gz"
print_message info "Version: $VERSION | Architecture: $ARCH_SUFFIX"
print_message info "Downloading CRICTL From: $DOWNLOAD_URL"
print_message line '***************************************************************************************'
curl -L "$DOWNLOAD_URL" --output crictl-${VERSION}-linux-${ARCH_SUFFIX}.tar.gz
sudo tar zxvf crictl-$VERSION-linux-$ARCH_SUFFIX.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-$ARCH_SUFFIX.tar.gz
echo ''

# Enable Ports
echo ''
print_message line '***************************************************************************************'
print_message info 'Enabling the Following Ports for Master Node'
print_message info '6443 | 2379-2380 | 10250 | 10251 | 10252 | 10255'
print_message line '***************************************************************************************'
if ! command -v ufw >/dev/null 2>&1; then
        sudo apt install ufw -y
fi
sudo echo "y" | sudo ufw enable
sudo ufw allow 6443/tcp
sudo ufw allow 2379:2380/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 10251/tcp
sudo ufw allow 10252/tcp
sudo ufw allow 10255/tcp
sudo ufw reload

echo ''
print_message line '***************************************************************************************'
print_message info 'Initializing Kubernetes controlplane (master) node using kubeadm...'
print_message line '***************************************************************************************'
# Create the Kubernetes controlplane
sudo kubeadm init --pod-network-cidr 10.244.0.0/16

# Export Kube Config
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> ~/.bashrc
source ~/.bashrc
echo ''
print_message line '***************************************************************************************'
print_message info 'Initialize the Networking Pods with Flannel ...'
print_message line '***************************************************************************************'
# Initialize the Networking Pods
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo ''
print_message line '***************************************************************************************'
print_message info '* To generate the join command for the worker node using the following command'
print_message info '* sudo kubeadm token create --print-join-command'
print_message line '***************************************************************************************'
echo ''

print_message line '***************************************************************************************'
print_message success 'Initialization of Kubernetes controlplane (master) node is complete. You can start using the cluster.'
print_message line '***************************************************************************************'

echo ''
print_message line '***************************************************************************************'
print_message info '* Run the following command to start using (kubectl) Commands *'
print_message info 'source ~/.bashrc'
print_message line '***************************************************************************************'
