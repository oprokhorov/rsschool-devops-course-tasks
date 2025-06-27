# Task 2: Basic Infrastructure Configuration

This task creates infrastructure described in [task_2](https://github.com/rolling-scopes-school/tasks/blob/master/devops/modules/1_basic-configuration/task_2.md)

Disclamer - commands in this doc are written for windows host and Powershell

First deploy Github Actions role so CI workflow can deploy aws infrrastructure (i have destroyed the infra from task 1 to have a new plan, and now i have to bootstrap github role again in this hacky way. But hey, its a lerning process 😅):

```powershell
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

We will create the underlying network resources and 4 EC2 instances. But first, we need to generate a keypair that will be used for ssh connection via bastion host connection. Open poweshell window and generate a key (you can skipp the passphrase if you want)

```powershell
ssh-keygen -t ed25519 -f "$HOME/.ssh/deployer-key"
```
Set proper permissions for the private key

```powershell
icacls "$HOME\.ssh\deployer-key" /inheritance:r /remove:g "*S-1-1-0" /grant "$env:USERNAME:F"
```

Specify your IP address in management_ip environment variable or tfvars file. Only this IP address will be allowed to make SSH connections to bastion host.

Deploy insfrastructure from this task branch:

```powershell
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

wait for infrastructure to be provisioned, and use the IP addresses provided in the outputs

Try to connect to public ip of the bastion host

```powershell
ssh ec2-user@<bastion-public-ip> -i .\.ssh\deployer-key.pub
```
You should be able to connect. Now disconnect from bastion and copy the private key to the bastion (securely):
```powershell
scp -i "$HOME/.ssh/deployer-key" "$HOME/.ssh/deployer-key" ec2-user@<bastion-public-ip>:~/.ssh/
```
now ssh to bastion host again and set proper permissions to the private key
```bash
chmod 600 ~/.ssh/deployer-key
```

while connected to bastion host, try to connect to control node using its private ip address

```bash
ssh ec2-user@<control-node-private-ip> -i .ssh/deployer-key
```

Verify that all 4 nodes have internet connection with
```bash
ping 8.8.8.8
```

Task complete.