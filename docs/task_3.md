# Task 3: Configuring a k3s Cluster

## Table of Contents
- [Section 1: Configuring a k3s Cluster on Hyper-V VMs (Windows Host)](#section-1-configuring-a-k3s-cluster-on-hyper-v-vms-windows-host)
  - [Prerequisites](#prerequisites)
  - [1. Set Up Static IPs for VMs](#1-set-up-static-ips-for-vms)
  - [2. Install k3s on Control Node (Master)](#2-install-k3s-on-control-node-master)
  - [3. Install k3s on Worker Node](#3-install-k3s-on-worker-node)
  - [4. Verify Cluster Setup](#4-verify-cluster-setup)
  - [5. Deploy a Simple Workload](#5-deploy-a-simple-workload)
- [Section 2: Configuring a k3s Cluster on AWS Infrastructure](#section-2-configuring-a-k3s-cluster-on-aws-infrastructure)
  - [Prerequisites](#prerequisites-1)
  - [1. Gather Instance Information](#1-gather-instance-information)
  - [2. SSH into the Bastion Host](#2-ssh-into-the-bastion-host)
  - [3. Install k3s on ControlNode (Master)](#3-install-k3s-on-controlnode-master)
  - [4. Install k3s on WorkerNode](#4-install-k3s-on-workernode)
  - [5. Configure kubectl on Bastion Host](#5-configure-kubectl-on-bastion-host)
  - [6. Deploy sample workload](#6-deploy-sample-workload)
  - [7. Configure kubectl on your local machine](#7-configure-kubectl-on-your-local-machine)
  - [Conclusion](#conclusion)
  - [Docs](#docs)

This document provides guides for setting up a k3s cluster in different environments. The first section covers installation on Hyper-V VMs on a Windows host, and the second section covers installation on AWS infrastructure. In both cases our local machine is a windows host and all commaand are executed in a powershell console.

## Section 1: Configuring a k3s Cluster on Hyper-V VMs (Windows Host)

This guide explains how to set up a k3s cluster on Hyper-V virtual machines (VMs) hosted on a Windows machine. The cluster will consist of two nodes: a Control Node (master) and a Worker Node.

### Prerequisites

- Hyper-V is enabled on your Windows host.
- Two Ubuntu VMs are created in Hyper-V (one for Control Node, one for Worker Node).
- You have administrative access to both VMs.

### 1. Set Up Static IPs for VMs

Using static IPs is necessary because if you restart your PC, the guest VMs might get different IPs, which could break the cluster due to TLS mismatches.

1. Run the following commands to get IP parameters assigned by the Hyper-V default switch to the VMs:
   - IP address:
     ```bash
     ip add
     ```
   - DNS server IP address and search domain:
     ```bash
     resolvectl status
     ```
   - Default gateway (address from the first hop in the output):
     ```bash
     tracepath -n 8.8.8.8
     ```

2. For both Control and Worker VMs, configure static IPs:
   - Back up your current netplan config:
     ```bash
     sudo cp /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.bak
     ```
   - Edit the netplan config:
     ```bash
     sudo vi /etc/netplan/00-installer-config.yaml
     ```
   - Delete everything and paste a static config with IP addresses adjusted according to the parameters collected from the dynamic configuration. Example for Control Node:
     ```yaml
     network:
       version: 2
       ethernets:
         eth0:
           dhcp4: false
           dhcp6: false
           addresses:
             - 172.20.130.6/20
           routes:
             - to: default
               via: 172.20.128.1
           nameservers:
             search: [mshome.net]
             addresses:
               - 172.20.128.1
     ```
     Example for Worker Node:
     ```yaml
     network:
       version: 2
       ethernets:
         eth0:
           dhcp4: false
           dhcp6: false
           addresses:
             - 172.20.133.78/20
           routes:
             - to: default
               via: 172.20.128.1
           nameservers:
             search: [mshome.net]
             addresses:
               - 172.20.128.1
     ```
   - Test the config:
     ```bash
     sudo netplan try
     ```
     If you are not locked out, the configuration works. Apply it with:
     ```bash
     sudo netplan apply
     ```
   - Reboot the VM to verify that the IP address persists:
     ```bash
     sudo shutdown -r now
     ```

### 2. Install k3s on Control Node (Master)

1. Log into the Control Node VM.
2. Install k3s with the following command:
   ```bash
   curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
   ```
   This installs k3s and kubectl.
3. Verify the installation:
   ```bash
   kubectl get nodes
   ```
   It should return that the node is a master and control-plane.
4. Copy the config to your local machine:
   ```powershell
   mkdir $HOME/.kube
   scp derp@control-node.mshome.net:/etc/rancher/k3s/k3s.yaml $HOME/.kube/config
   ```
5. Open `k3s.yaml` on your local machine and change the server from `127.0.0.1` to the Control Node's IP address:
   ```yaml
   server: https://172.20.130.6:6443
   ```
6. Running `kubectl get nodes` from your host computer should now return one master/control-plane node.
7. On the Control Node, get the token for the Worker Node to join the cluster:
   ```bash
   sudo cat /var/lib/rancher/k3s/server/node-token
   ```
   You will get output similar to:
   ```
   K10a500d9ff77e03d4a84d2717275aee4dc38214ab9439a2f11931d028cdfc36d26::server:98f015bb5ef03c331d4965a1b556e5f4
   ```
   Copy this somewhere safe.

### 3. Install k3s on Worker Node

1. Log into the Worker Node VM.
2. Install k3s with the following command, using the Control Node's IP and token:
   ```bash
   curl -sfL https://get.k3s.io | K3S_URL=https://<CONTROL-IP>:6443 K3S_TOKEN=<NODE-TOKEN> sh -
   ```
   In our example:
   ```bash
   curl -sfL https://get.k3s.io | K3S_URL=https://172.20.130.6:6443 K3S_TOKEN=K10a500d9ff77e03d4a84d2717275aee4dc38214ab9439a2f11931d028cdfc36d26::server:98f015bb5ef03c331d4965a1b556e5f4 sh -
   ```

### 4. Verify Cluster Setup

1. From your host computer (or bastion), run:
   ```bash
   kubectl get nodes
   ```
   This should now return both nodes.

### 5. Deploy a Simple Workload

1. Deploy a simple Nginx workload:
   ```bash
   kubectl apply -f https://k8s.io/examples/pods/simple-pod.yaml
   ```
2. Verify that you can see the Nginx pod:
   ```bash
   kubectl get pods
   ```

## Section 2: Configuring a k3s Cluster on AWS Infrastructure

This guide provides step-by-step instructions to set up a k3s cluster on the AWS infrastructure defined in this repository. The cluster will consist of two nodes: a ControlNode (master) and a WorkerNode. The end goal is to run `kubectl get nodes` and see both nodes listed in the cluster, as well as deploy a sample workload (Nginx)

## Prerequisites

- The infrastructure described in this repository is up and running.
- Network connectivity exists between all EC2 instances (Bastion, ControlNode, WorkerNode).
- You have SSH access to the Bastion host and can reach the private IPs of ControlNode and WorkerNode from there.
- The Bastion host has `kubectl` installed (if not, install it as part of the setup).

## Infrastructure deployment and bootrapping

Disclamer - commands in this doc are written for windows host and Powershell

check out the code an deploy the bootstrap resources required for terraform running in CI:

```powershell
cd .\terraform\
terraform plan --target=aws_iam_role.github_actions_role `
  --target=aws_iam_role_policy_attachment.ec2_full_access `
  --target=aws_iam_role_policy_attachment.route53_full_access `
  --target=aws_iam_role_policy_attachment.s3_full_access `
  --target=aws_iam_role_policy_attachment.iam_full_access `
  --target=aws_iam_role_policy_attachment.vpc_full_access `
  --target=aws_iam_role_policy_attachment.sqs_full_access `
  --target=aws_iam_role_policy_attachment.eventbridge_full_access `
  --target=aws_key_pair.deployer `
  --out=tfplan

terraform apply tfplan
```

Once they are deployed, apply again to create the rest of the infra

```powershell
terraform plan
terraform apply
```

## 1. Gather Instance Information

1. After running `terraform apply`, note the private IP addresses of the ControlNode and WorkerNode from the Terraform outputs:
   - `control_node_private_ip`
   - `worker_node_private_ip`
2. Also, note the public IP of the Bastion host (`bastion_instance_public_ip`) for SSH access.

Example output:

```powershell
bastion_instance_private_ip = "172.21.32.105"
bastion_instance_public_ip = "34.232.105.226"
control_node_private_ip = "172.21.33.171"
worker_node_private_ip = "172.21.35.107"
```


## 2. SSH into the Bastion Host

1. Use the public IP of the Bastion host to SSH into it:
   ```bash
   ssh -i ~/.ssh/deployer-key ubuntu@<bastion-public-ip>
   ```
   Replace `~/.ssh/deployer-key` with the path to your private key and `<bastion-public-ip>` with the actual public IP.

   While you on the bastion, verify that user-data script installed the kubectl:

   ```bash
   kubectl version
   ```
   Command should print kubectl version

   Now disconnect from bastion and copy the private key to the bastion (securely), we need this to connect to cluster nodes using key auth:
   ```powershell
   scp -i "$HOME/.ssh/deployer-key" "$HOME/.ssh/deployer-key" ubuntu@<bastion-public-ip>:~/.ssh/
   ```
   now ssh to bastion host again and set proper permissions to the private key
   ```bash
   chmod 600 ~/.ssh/deployer-key
   ```


## 3. Install k3s on ControlNode (Master)

1. From the Bastion host, SSH into the ControlNode using its private IP:
   ```bash
   ssh -i ~/.ssh/deployer-key ubuntu@<control-node-private-ip>
   ```
2. Install k3s as the master node on the ControlNode:
   ```bash
   curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
   ```
   This command installs k3s and sets up the kubeconfig file with appropriate permissions.
3. Verify that k3s is running by listing all pods:
   ```bash
   kubectl get all
   ```
4. Get the node token needed for joining worker nodes and paste it to a notepad on your machine for the next step:
   ```bash
   sudo cat /var/lib/rancher/k3s/server/node-token
   ```


## 4. Install k3s on WorkerNode

1. From the Bastion host, SSH into the WorkerNode using its private IP:
   ```bash
   ssh -i ~/.ssh/deployer-key ubuntu@<worker-node-private-ip>
   ```
2. Install k3s as a worker node, using the token from the ControlNode:
   ```bash
   curl -sfL https://get.k3s.io | K3S_URL=https://<control-node-private-ip>:6443 K3S_TOKEN=<node-token-from-control-node> sh -
   ```
   Replace `<control-node-private-ip>` with the actual private IP of the ControlNode and `<node-token-from-control-node>` with the token obtained in 3.
3. Verify that k3s agent is running:
   ```bash
   sudo systemctl status k3s-agent
   ```

## 5. Configure kubectl on Bastion Host

1. Log into to the Bastion and securely copy the kubeconfig file from the control node:
   ```bash
   mkdir -p ~/.kube
   scp -i ~/.ssh/deployer-key ubuntu@<control-node-private-ip>:/etc/rancher/k3s/k3s.yaml ~/.kube/config
   ```
   Update the `server` field in the config in your favorite text editior to use the ControlNode's private IP, save the file and verify that you can manage cluster from the Bastion with kubectl:
   ```bash
   kubectl get nodes
   ```
   You should see two nodes in response

## 6. Deploy sample workload

1. Deploy a simple Nginx workload:
   ```bash
   kubectl apply -f https://k8s.io/examples/pods/simple-pod.yaml
   ```
2. Verify that you can see the Nginx pod:
   ```bash
   kubectl get pods
   ```
   You should see a pod with ngnix in its name

## 7. Configure kubectl on your local machine

1. Install kubectl and verify its available:
   ```powershell
   winget search kubernetes.kubectl --disable-interactivity
   kubectl version
   ```

2. Securely copy kubeconfig from Bastion to local machine:
   ```powershell
   mkdir $HOME/.kube
   scp -i ~/.ssh/deployer-key ubuntu@<bastion-public-ip>:~/.kube/config $HOME/.kube/config
   ```
3. Open .kube/config in a text editor and replace server ip address with localhost

4. Open a separate PowerShell console and run command that will establish an SSH tunnel to bastion:
   ```powershell
   ssh -i .\.ssh\deployer-key -L 6443:<control-node-private-ip>:6443 ubuntu@<bastion-public-ip> -N

5. While SSH tunnel command is active, in a separate PowerShell session run command to verify that we can access cluster from our local computer:
   ```powershell
   kubectl get pods
   ```

## Conclusion

You now have a functioning k3s cluster with one ControlNode and one WorkerNode. You can manage the cluster using `kubectl` from the Bastion host. Further configuration, such as deploying applications or adding more worker nodes, can be done using standard Kubernetes practices.
