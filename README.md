# Kubernetes Cluster Setup Scripts
- This repository contains master and worker node scripts for both Debian and Red-Hat based distributions.
- The Script were tested on (CentOS - Fedora - Debian - Ubuntu) in both Virtual and Cloud VM.

## Requirements:

- 2 Linux Machines (You can use one incase you only need master node)
- At least 2 CPU on the machine used for the master node
- 2 GB or more of RAM per machine (any less will leave little room for your apps).
- ```yum``` Package manager for Red-Hat Distributions | ```apt``` Package manager for Debian Distributions
- ```sudo``` access for all machines

## Automated Setup using Curl
- You can use ```start.sh``` Script to setup both the Master and Worker Node using the following commands
- Run ```curl -O https://raw.githubusercontent.com/iYasser95/kubernetes/main/start.sh```
- Run ```. start.sh```
- You will be promted to enter either 1 to start the Master Node setup or 2 to start the Worker Node setup
- The Linux Distribution will be detected and the correct Script for it will Run.
## Automated Setup using Clone
- You can use ```start.sh``` Script to setup both the Master and Worker Node using the following commands
- Run ```git clone https://github.com/iYasser95/kubernetes.git```
- Run ```cd kubernetes```
- Run ```. start.sh```
- You will be promted to enter either 1 to start the Master Node setup or 2 to start the Worker Node setup
- The Linux Distribution will be detected and the correct Script for it will Run.

## Master Node Setup:
##### Red Hat-based distributions Setup 
- In the Master Node Machine run the following commands to start the setup of the Node.
- Run ```curl -O https://raw.githubusercontent.com/iYasser95/kubernetes/main/redhat-master.sh```
- Run ```. redhat-master.sh```
##### Debian-based distributions Setup
- In the Master Node Machine run the following commands to start the setup of the Node.
- Run ```curl -O https://raw.githubusercontent.com/iYasser95/kubernetes/main/debian-master.sh```
- Run ```. debian-master.sh```

##### After the Master Node setup:
Run the following command after the script is finished to be able to use ```kubectl```  commands
- ```source ~/.bashrc```

## Worker Node Setup:
##### Red Hat-based distributions Setup
- In the Worker Node Machine run the following commands to start the setup of the Node.
- Run ```curl -O https://raw.githubusercontent.com/iYasser95/kubernetes/main/redhat-worker.sh```
- Run ```. redhat-worker.sh```
- Worker Nodes Name must be unique, you'll be asked to enter the name once the script starts
##### Debian-based distributions Setup
- In the Worker Node Machine run the following commands to start the setup of the Node.
- Run ```curl -O https://raw.githubusercontent.com/iYasser95/kubernetes/main/debian-worker.sh```
- Run ```. debian-worker.sh```
- Worker Nodes Name must be unique, you'll be asked to enter the name once the script starts

##### After the Worker Node setup:
Run the following command on the Master Node to get the command to join the Worker node to the Master: 
- ```sudo kubeadm token create --print-join-command```

## Exceptions 

##### If you get connection error while running ```kubectl``` commands then make sure the following commands were run correctly:
- ```echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> ~/.bashrc```
- ```source ~/.bashrc```
##### If the Node is showing status NotReady make sure the Networking pods were installed correctly using the following command:
- ```kubectl get pod -nkube-flannel```
- If the pods were not installed then run the following command:
- ```kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml```

### Resources:
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Kubeadm Documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)

### License
[MIT](https://choosealicense.com/licenses/mit/)
