# Task 3: K8s Cluster Configuration and Creation

![task_3 schema](/docs/aws_architecture.png )

## Table of Contents

- [Configuring a k3s Cluster on AWS Infrastructure](#configuring-a-k3s-cluster-on-aws-infrastructure)
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


## Configuring a k3s Cluster on AWS Infrastructure

This guide provides step-by-step instructions to set up a k3s cluster on the AWS infrastructure defined in this repository. The cluster will consist of two nodes: a ControlNode (master) and a WorkerNode. The end goal is to run `kubectl get nodes` and see both nodes listed in the cluster, as well as deploy a sample workload (Nginx)

This guide is intended for a windows host and all commands are executed in a PowerShell console.

## Prerequisites

- The infrastructure described in this repository is up and running.
- Network connectivity exists between all EC2 instances (Bastion, ControlNode, WorkerNode).
- You have SSH access to the Bastion host and can reach the private IPs of ControlNode and WorkerNode from there.
- The Bastion host has `kubectl` installed (if not, install it as part of the setup).

## Infrastructure deployment and bootrapping

Check out the code an deploy the bootstrap resources required for terraform running in CI:

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

1. After running `terraform apply`, note the Ouptut containing IP addresses required for steps described in this guide.

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
   Replace <bastion-public-ip>` with the actual public IP.

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

You now have a functioning k3s cluster with one ControlNode and one WorkerNode. You can manage the cluster using `kubectl` from the Bastion host and from a local machine via SSH tunnel. Further configuration, such as deploying applications or adding more worker nodes, can be done using standard Kubernetes practices.


## Docs
You can find per-task solutions for this course using these links:

- [Task 1: AWS Account Configuration](./docs/task_1.md)
- [Task 2: Basic Infrastructure Configuration](./docs/task_2.md)
- [Task 3: K8s Cluster Configuration and Creationn](./docs/task_3.md)
