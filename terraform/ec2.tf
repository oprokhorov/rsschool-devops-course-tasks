module "bastion" {
  source = "./modules/ec2_instance"

  name          = "Bastion"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_1.id
  vpc_id        = aws_vpc.main.id
  key_name      = aws_key_pair.deployer.key_name

  allowed_inbound_cidr_ports = [
    {
      port        = 22
      cidr        = local.management_ip_cidr
      description = "SSH from management IP"
    },
    {
      port        = 80
      cidr        = local.management_ip_cidr
      description = "HTTP from management IP"
    },
    {
      port        = 443
      cidr        = local.management_ip_cidr
      description = "HTTPS from management IP"
    },
    {
      port        = -1
      cidr        = aws_vpc.main.cidr_block
      description = "ICMP (ping) from within VPC"
      protocol    = "icmp"
    }
  ]
  allowed_inbound_sg_ports = []

  user_data = file("${path.module}/modules/ec2_instance/user_data/bastion.sh")

  tags = {
    Environment = "prod"
  }
}

module "control_node" {
  source = "./modules/ec2_instance"

  name          = "ControlNode"
  instance_type = "t3.small"
  subnet_id     = aws_subnet.private_1.id
  vpc_id        = aws_vpc.main.id
  key_name      = aws_key_pair.deployer.key_name

  allowed_inbound_cidr_ports = [
    {
      port        = -1
      cidr        = aws_vpc.main.cidr_block
      description = "ICMP (ping) from within VPC"
      protocol    = "icmp"
    }
  ]
  allowed_inbound_sg_ports = [
    {
      port                     = 22
      source_security_group_id = module.bastion.security_group_id
      description              = "SSH from Bastion"
    },
    {
      port                     = 6443
      source_security_group_id = module.bastion.security_group_id
      description              = "K3s API from Bastion"
    },
    {
      port                     = 6443
      source_security_group_id = module.worker_node.security_group_id
      description              = "K3s API from Worker Node"
    }
  ]

  user_data = file("${path.module}/modules/ec2_instance/user_data/control_node.sh")

  tags = {
    Environment = "prod"
  }
}

module "worker_node" {
  source = "./modules/ec2_instance"

  name          = "WorkerNode"
  instance_type = "t3.small"
  subnet_id     = aws_subnet.private_2.id
  vpc_id        = aws_vpc.main.id
  key_name      = aws_key_pair.deployer.key_name

  allowed_inbound_cidr_ports = [
    {
      port        = -1
      cidr        = aws_vpc.main.cidr_block
      description = "ICMP (ping) from within VPC"
      protocol    = "icmp"
    }
  ]
  allowed_inbound_sg_ports = [
    {
      port                     = 22
      source_security_group_id = module.bastion.security_group_id
      description              = "SSH from Bastion"
    },
    {
      port                     = 6443
      source_security_group_id = module.bastion.security_group_id
      description              = "K3s API from Bastion"
    },
    {
      port                     = 6443
      source_security_group_id = module.control_node.security_group_id
      description              = "K3s API from Control Node"
    }
  ]

  user_data = file("${path.module}/modules/ec2_instance/user_data/worker_node.sh")

  tags = {
    Environment = "prod"
  }
}

locals {
  management_ip_cidr = "${nonsensitive(var.management_ip)}/32"
}

