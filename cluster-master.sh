# This Script is configured to be used with CentOS Stream 9.

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

# Check if the variable contains "centos" (case-insensitive and ignoring spaces)
if [[ $(echo "$DISTRO_NAME" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]') != *"centos"* ]]; then
    print_message error "This Script is only valid for CentOS. Modify on your own risk"
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
print_message line '***************************************************************************************'
print_message info 'Updating the System ..'
print_message line '***************************************************************************************'
# Update CentOS System
yum update -y

# Prepare for containerd installation
sudo dnf install -y yum-utils


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
print_message line '***************************************************************************************'
print_message info 'Updating Hostname and Hosts file'
print_message line '***************************************************************************************'
echo ''
# Change hostname
sudo hostnamectl set-hostname master-node

export DEFAULT_GATEWAY_IP=$(ip route show | awk '/default/ {print $9}')

# Modify /etc/hosts file
sudo bash -c "echo \"$DEFAULT_GATEWAY_IP master-node\" >> /etc/hosts"
print_message line '***************************************************************************************'
print_message success "Hostname Changed into: master-node | Default IP Detected: $DEFAULT_GATEWAY_IP"
print_message line '***************************************************************************************'
echo ''
# Disable Swap 
sudo sed -i '/swap/d' /etc/fstab
sudo swapoff -a
print_message line '***************************************************************************************'
print_message success 'Swap is Disabled..'
print_message line '***************************************************************************************'
sudo sysctl --system
print_message line '***************************************************************************************'
print_message info 'Removing podman..'
print_message line '***************************************************************************************'
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf remove -y podman # podman might cause issues/conflicts with containerd
print_message line '***************************************************************************************'
print_message success 'podman removed..'
print_message line '***************************************************************************************'
echo ''
print_message line '***************************************************************************************'
print_message info 'Installing Container D..'
print_message line '***************************************************************************************'
# Install and configure containerd
sudo dnf install -y containerd.io

sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable --now containerd
print_message line '***************************************************************************************'
print_message success 'Container D is now enabled and working'
print_message line '***************************************************************************************'
# Make SELinux permissive
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
print_message line '***************************************************************************************'
print_message info 'Installing kubeadm, kubelet and kubectl ..'
print_message line '***************************************************************************************'
echo ''
# Install kubeadm, kubelet and kubectl
sudo tee /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF
sudo yum install -y kubelet kubeadm kubectl \
--disableexcludes=kubernetes

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
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-port=2379-2380/tcp
sudo firewall-cmd --permanent --add-port=10250/tcp
sudo firewall-cmd --permanent --add-port=10251/tcp
sudo firewall-cmd --permanent --add-port=10252/tcp
sudo firewall-cmd --permanent --add-port=10255/tcp
sudo firewall-cmd --reload

echo ''
print_message line '***************************************************************************************'
print_message info 'Intalizeing Kubernetes controlplane (master) node using kubeadm...'
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
print_message info '* If you get connection error using (kubectl) commands then use the following commands'
print_message info '* echo export KUBECONFIG=/etc/kubernetes/admin.conf >> ~/.bashrc'
print_message info '* source ~/.bashrc'
print_message line '***************************************************************************************'
echo ''
echo ''
print_message line '***************************************************************************************'
print_message info '* To generate the join command for the worker node using the following command'
print_message info '* sudo kubeadm token create --print-join-command'
print_message line '***************************************************************************************'
echo ''

print_message line '***************************************************************************************'
print_message success 'Intalizeing of Kubernetes controlplane (master) node is complete you can start using the cluster..'
print_message line '***************************************************************************************'
# Get Join Command for Worker node. 
# sudo kubeadm token create --print-join-command
