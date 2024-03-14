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

#### Clone the repository:
``` git clone https://github.com/iYasser95/kubernetes ```

#### Master Node Setup:
- Copy the ```cluster-master.sh``` file into the Master node machine
- Run ```sh cluster-master.sh```

##### After the Master Node setup:
Run the following commands after the script is finished
- ```echo export KUBECONFIG=/etc/kubernetes/admin.conf >> ~/.bashrc``` 
- ```source ~/.bashrc```

#### Worker Node Setup:
- Copy the ```cluster-worker.sh``` file into the Master node machine
- Run ```sh cluster-worker.sh```

### Resources:
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Kubeadm Documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [CentOS Download](https://www.centos.org/download/)

### License
[MIT](https://choosealicense.com/licenses/mit/)
