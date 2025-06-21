module "bastion" {
  source = "./modules/ec2_instance"

  name          = "Bastion"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_1.id
  vpc_id        = aws_vpc.main.id
  key_name      = aws_key_pair.deployer.key_name

  allowed_inbound_ports = {
    ssh = {
      port        = 22
      cidr        = local.management_ip_cidr
      description = "SSH from management IP"
    }
    http = {
      port        = 80
      cidr        = local.management_ip_cidr
      description = "HTTP from management IP"
    }
    https = {
      port        = 443
      cidr        = local.management_ip_cidr
      description = "HTTPS from management IP"
    }
  }

  user_data = file("${path.module}/modules/ec2_instance/user_data/bastion.sh")

  tags = {
    Environment = "prod"
  }
}

module "control_node" {
  source = "./modules/ec2_instance"

  name          = "ControlNode"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_1.id
  vpc_id        = aws_vpc.main.id
  key_name      = aws_key_pair.deployer.key_name

  allowed_inbound_ports = {
    ssh = {
      port                     = 22
      source_security_group_id = module.bastion.security_group_id
      description              = "SSH from Bastion SG"
    }
    kube_api = {
      port                     = 6443
      source_security_group_id = module.bastion.security_group_id
      description              = "Kubernetes API from Bastion SG"
    }
  }

  user_data = file("${path.module}/modules/ec2_instance/user_data/control_node.sh")

  tags = {
    Environment = "prod"
  }
}

module "worker_node" {
  source = "./modules/ec2_instance"

  name          = "WorkerNode"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_2.id
  vpc_id        = aws_vpc.main.id
  key_name      = aws_key_pair.deployer.key_name

  allowed_inbound_ports = {
    ssh = {
      port                     = 22
      source_security_group_id = module.bastion.security_group_id
      description              = "SSH from Bastion SG"
    }
  }

  user_data = file("${path.module}/modules/ec2_instance/user_data/worker_node.sh")

  tags = {
    Environment = "prod"
  }
}

module "public_vm" {
  source = "./modules/ec2_instance"

  name          = "PublicVM"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_2.id
  vpc_id        = aws_vpc.main.id
  key_name      = aws_key_pair.deployer.key_name

  allowed_inbound_ports = {
    ssh = {
      port                     = 22
      source_security_group_id = module.bastion.security_group_id
      description              = "SSH from Bastion SG"
    }
  }

  user_data = null

  tags = {
    Environment = "prod"
  }
}

locals {
  management_ip_cidr = "${nonsensitive(var.management_ip)}/32"
}

