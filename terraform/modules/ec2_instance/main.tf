data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]
  key_name               = var.key_name
  user_data              = var.user_data
  iam_instance_profile   = var.instance_profile

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}

resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "Security group for ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name = "${var.name}-sg"
    },
    var.tags
  )
}

# TCP/UDP rules from CIDR blocks
resource "aws_vpc_security_group_ingress_rule" "allowed_inbound_cidr_tcp" {
  for_each = { 
    for idx, rule in var.allowed_inbound_cidr_ports : idx => rule 
    if rule.port != -1
  }

  security_group_id = aws_security_group.this.id
  description       = each.value.description
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = lookup(each.value, "protocol", "tcp")
  cidr_ipv4         = each.value.cidr
}

# ICMP rules from CIDR blocks
resource "aws_vpc_security_group_ingress_rule" "allowed_inbound_cidr_icmp" {
  for_each = { 
    for idx, rule in var.allowed_inbound_cidr_ports : idx => rule 
    if rule.port == -1
  }

  security_group_id = aws_security_group.this.id
  description       = each.value.description
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
  cidr_ipv4         = each.value.cidr
}

# TCP/UDP rules from Security Groups
resource "aws_vpc_security_group_ingress_rule" "allowed_inbound_sg_tcp" {
  for_each = { 
    for idx, rule in var.allowed_inbound_sg_ports : idx => rule 
    if lookup(rule, "protocol", "tcp") != "icmp"
  }

  security_group_id            = aws_security_group.this.id
  description                  = each.value.description
  from_port                    = each.value.port
  to_port                      = each.value.port
  ip_protocol                  = lookup(each.value, "protocol", "tcp")
  referenced_security_group_id = each.value.source_security_group_id
}

# ICMP rules from Security Groups
resource "aws_vpc_security_group_ingress_rule" "allowed_inbound_sg_icmp" {
  for_each = { 
    for idx, rule in var.allowed_inbound_sg_ports : idx => rule 
    if lookup(rule, "protocol", "tcp") == "icmp"
  }

  security_group_id            = aws_security_group.this.id
  description                  = each.value.description
  from_port                    = -1
  to_port                      = -1
  ip_protocol                  = "icmp"
  referenced_security_group_id = each.value.source_security_group_id
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = "0.0.0.0/0"
}
