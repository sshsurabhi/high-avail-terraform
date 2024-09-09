### Creation of VPC datascientest
resource "aws_vpc" "datascientest_vpc" {
  cidr_block              = var.cidr_vpc
  enable_dns_support      = true
  enable_dns_hostnames    = true
  tags = {
    Name = "datascientest-vpc"
  }
}

### Creation of 2 public subnets for datascientest servers

resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.datascientest_vpc.id
  cidr_block              = var.cidr_public_subnet_a
  map_public_ip_on_launch = true
  availability_zone       = var.az_a

  tags = {
    Name        = "public-a"
    Environment = var.environment
  }

  depends_on = [aws_vpc.datascientest_vpc]
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.datascientest_vpc.id
  cidr_block              = var.cidr_public_subnet_b
  map_public_ip_on_launch = true
  availability_zone       = var.az_b

  tags = {
    Name        = "public-b"
    Environment = var.environment
  }

  depends_on = [aws_vpc.datascientest_vpc]
}

### Creation of 2 private subnets for datascientest servers
resource "aws_subnet" "app_subnet_a" {
  vpc_id                  = aws_vpc.datascientest_vpc.id
  cidr_block              = var.cidr_app_subnet_a
  map_public_ip_on_launch = false
  availability_zone       = var.az_a

  tags = {
    Name        = "app-a"
    Environment = var.environment
  }

  depends_on = [aws_vpc.datascientest_vpc]
}

resource "aws_subnet" "app_subnet_b" {
  vpc_id                  = aws_vpc.datascientest_vpc.id
  cidr_block              = var.cidr_app_subnet_b
  map_public_ip_on_launch = false
  availability_zone       = var.az_b
  
  tags = {
    Name        = "app-b"
    Environment = var.environment
  }

  depends_on = [aws_vpc.datascientest_vpc]
}

# Create an Internet Gateway for our VPC
resource "aws_internet_gateway" "datascientest_igateway" {
  vpc_id = aws_vpc.datascientest_vpc.id
  tags = {
    Name = "datascientest-igateway"
  }

  depends_on = [aws_vpc.datascientest_vpc]
}

# Create a routing table for the public subnets
resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.datascientest_vpc.id
  tags = {
    Name = "datascientest-public-routetable"
  }

  depends_on = [aws_vpc.datascientest_vpc]
}

# Create a route in the routing table to access the public via an Internet Gateway
resource "aws_route" "route_igw" {
  route_table_id         = aws_route_table.rtb_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.datascientest_igateway.id

  depends_on = [aws_internet_gateway.datascientest_igateway]
}

##################################################################
# Add a public subnet A to the routing table
resource "aws_route_table_association" "rta_subnet_association_puba" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.rtb_public.id

  depends_on = [aws_route_table.rtb_public]
}

# Add a public subnet B to the routing table
resource "aws_route_table_association" "rta_subnet_association_pubb" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.rtb_public.id

  depends_on = [aws_route_table.rtb_public]
}

## Bastion server key pair creation.
resource "aws_key_pair" "myec2key" {
  key_name   = "datascientest_keypair"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "sg_22" {
  name   = "sg_22"
  vpc_id = aws_vpc.datascientest_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-22"
  }
}

# Create a Network ACL to access the bastion host via port 22
resource "aws_network_acl" "datascientest_public_a" {
  vpc_id = aws_vpc.datascientest_vpc.id

  subnet_ids = [aws_subnet.public_subnet_a.id]

  tags = {
    Name = "acl-datascientest-public-a"
  }
}

resource "aws_network_acl_rule" "nat_inbound" {
  network_acl_id = aws_network_acl.datascientest_public_a.id
  rule_number     = 200
  egress         = false
  protocol       = "-1" # Allow all protocols (TCP/UDP...)
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# It looks like you're trying to create a second NAC, but its resource definition is missing. 
# Assuming you need to create a second Network ACL here.
resource "aws_network_acl" "datascientest_public_b" {
  vpc_id = aws_vpc.datascientest_vpc.id

  subnet_ids = [aws_subnet.public_subnet_b.id]

  tags = {
    Name = "acl-datascientest-public-b"
  }
}

resource "aws_network_acl_rule" "nat_inbound_b" {
  network_acl_id = aws_network_acl.datascientest_public_b.id
  rule_number     = 200
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# Dynamic image retrieval with source data
data "aws_ami" "datascientest-ami" {
  most_recent = true 
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "datascientest_bastion" {
  ami                   = data.aws_ami.datascientest-ami.id
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.public_subnet_a.id
  vpc_security_group_ids = [aws_security_group.sg_22.id]
  key_name             = aws_key_pair.myec2key.key_name

  tags = {
    Name = "datascientest-bastion"
  }
}

## Create a NAT gateway for the public-a subnet and an Elastic IP
resource "aws_eip" "eip_public_a" {
  vpc = true
}

resource "aws_nat_gateway" "gw_public_a" {
  allocation_id = aws_eip.eip_public_a.id
  subnet_id     = aws_subnet.public_subnet_a.id

  tags = {
    Name = "datascientest-nat-public-a"
  }
}

## Create a routing table for application subnet A
resource "aws_route_table" "rtb_appa" {
  vpc_id = aws_vpc.datascientest_vpc.id

  tags = {
    Name = "datascientest-appa-routetable"
  }
}

# Create a route to the NAT gateway
resource "aws_route" "route_appa_nat" {
  route_table_id         = aws_route_table.rtb_appa.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.gw_public_a.id
}

resource "aws_route_table_association" "rta_subnet_association_appa" {
  subnet_id      = aws_subnet.app_subnet_a.id
  route_table_id = aws_route_table.rtb_appa.id
}

## Create a NAT gateway and routes for application subnet B and Elastic IP for gateway B
resource "aws_eip" "eip_public_b" {
  vpc = true
}

resource "aws_nat_gateway" "gw_public_b" {
  allocation_id = aws_eip.eip_public_b.id
  subnet_id     = aws_subnet.public_subnet_b.id

  tags = {
    Name = "datascientest-nat-public-b"
  }
}

resource "aws_route_table" "rtb_appb" {
  vpc_id = aws_vpc.datascientest_vpc.id

  tags = {
    Name = "datascientest-appb-routetable"
  }
}

resource "aws_route" "route_appb_nat" {
  route_table_id         = aws_route_table.rtb_appb.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.gw_public_b.id
}

resource "aws_route_table_association" "rta_subnet_association_appb" {
  subnet_id      = aws_subnet.app_subnet_b.id
  route_table_id = aws_route_table.rtb_appb.id
}

## Creation of datascientest servers for application subnet A
resource "aws_security_group" "sg_datascientest" {
  name   = "sg_datascientest"
  vpc_id = aws_vpc.datascientest_vpc.id

  tags = {
    Name = "sg-datascientest"
  }
}

resource "aws_security_group_rule" "allow_all" {
  type                = "ingress"
  cidr_blocks         = ["10.1.0.0/24"]
  to_port             = 0
  from_port           = 0
  protocol            = "-1"
  security_group_id   = aws_security_group.sg_datascientest.id
}

resource "aws_security_group_rule" "outbound_allow_all" {
  type                = "egress"
  cidr_blocks         = ["0.0.0.0/0"]
  to_port             = 0
  from_port           = 0
  protocol            = "-1"
  security_group_id   = aws_security_group.sg_datascientest.id
}

## Creation of datascientest server for application subnet A
resource "aws_instance" "datascientest_a" {
  ami                   = data.aws_ami.datascientest-ami.id
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.app_subnet_a.id
  vpc_security_group_ids = [aws_security_group.sg_datascientest.id]
  key_name             = aws_key_pair.myec2key.key_name
  user_data            = file("install_wordpress.sh")

  tags = {
    Name = "Datascientest-a"
  }
}

## Creation of datascientest server for application subnet B
resource "aws_instance" "datascientest_b" {
  ami                   = data.aws_ami.datascientest-ami.id
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.app_subnet_b.id
  vpc_security_group_ids = [aws_security_group.sg_datascientest.id]
  key_name             = aws_key_pair.myec2key.key_name
  user_data            = file("install_wordpress.sh")

  tags = {
    Name = "Datascientest-b"
  }
}

# Create a security group to allow traffic on port 80
resource "aws_security_group" "sg_application_lb" {
  name   = "sg_application_lb"
  vpc_id = aws_vpc.datascientest_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Please limit your entry to only the necessary IP addresses and ports.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Datascientest-alb"
  }
}

# Creating a load balancer in two public subnets
resource "aws_lb" "lb_datascientest" {
  name               = "datascientest-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
  security_groups    = [aws_security_group.sg_application_lb.id]
  enable_deletion_protection = false
}

# Create a load balancing listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb_datascientest.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.datascientest_vms.arn
  }
}

# Creating a target group
resource "aws_lb_target_group" "datascientest_vms" {
  name     = "tf-datascientest-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.datascientest_vpc.id
}

# Join instance A to availability zone A in the target group
resource "aws_lb_target_group_attachment" "datascientesta_tg_attachment" {
  target_group_arn = aws_lb_target_group.datascientest_vms.arn
  target_id        = aws_instance.datascientest_a.id
  port             = 80
}

# Join instance B to availability zone B in the target group
resource "aws_lb_target_group_attachment" "datascientestb_tg_attachment" {
  target_group_arn = aws_lb_target_group.datascientest_vms.arn
  target_id        = aws_instance.datascientest_b.id
  port             = 80
}