# Kubernetes Cluster Setup Scripts

This repository contains two shell scripts to automate the setup of a basic Kubernetes cluster:
- ```cluster-master.sh```: This script sets up the master node for your Kubernetes cluster.
- ```cluster-worker.sh```: This script sets up a worker node to join the existing Kubernetes cluster.

### Requirements:

- 2 CentOS Machine (You can use one incase you only need master node)
- At least 2 CPU on the machine used for the master node
- 2GB RAM or more per machine (any less would cause issues)
- ```sudo``` access for both machines

### Getting Started:

#### Master Node Setup:
- In the Master Node Machine run the following commands to start the setup of the Node.
- Run ```curl -O https://raw.githubusercontent.com/iYasser95/kubernetes/main/cluster-master.sh```
- Run ```sh cluster-master.sh```

##### After the Master Node setup:
Run the following command after the script is finished
- ```source ~/.bashrc```

#### Worker Node Setup:
- In the Worker Node Machine run the following commands to start the setup of the Node.
- Run ```curl -O https://raw.githubusercontent.com/iYasser95/kubernetes/main/cluster-worker.sh```
- Run ```sh cluster-worker.sh```

### Resources:
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Kubeadm Documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [CentOS Download](https://www.centos.org/download/)

### License
[MIT](https://choosealicense.com/licenses/mit/)
