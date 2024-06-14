terraform {
  required_version = ">= 0.13.6"
  required_providers {
    aws = "~>3.0"
  }
  backend "s3" {
  }
}

provider "aws" {
    region = var.region
    max_retries = 1
    allowed_account_ids = var.allowed_account_ids  
}

resource "aws_vpc" "my-vpc" {
    cidr_block = var.vpc_cidr
    instance_tenancy = "default"  
}

resource "aws_subnet" "public-subnets" {
    vpc_id = aws_vpc.my-vpc.id
    count = length(var.public-subnets)
    cidr_block = var.public-subnets[count.index]
    availability_zone = var.azs[count.index]  
}

resource "aws_subnet" "private-subnets" {
    vpc_id = aws_vpc.my-vpc.id
    count = length(var.private-subnets)
    cidr_block = var.private-subnets[count.index]
    availability_zone = var.azs[count.index]  
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id
}

resource "aws_nat_gateway" "nat-gw" {
    count = length(var.public-subnets)
    allocation_id = aws_eip.nat-eip[count.index].id
    subnet_id = element(aws_subnet.public-subnets.*.id, count.index)
  
    depends_on = [aws_internet_gateway.igw]
}


resource "aws_eip" "nat-eip" {
    count = length (var.public-subnets)
    vpc = true
}


resource "aws_route_table" "nat-route-table" {
    vpc_id = aws_vpc.my-vpc.id

    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
}
}

resource "aws_route_table" "private-route-table" {
    vpc_id = aws_vpc.my-vpc.id
    count = length (var.public-subnets)
    route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element (aws_nat_gateway. nat-gw.*. id, count.index)
    }
}

resource "aws_route_table_association" "public-subnets" {
    count = length (var.public-subnets)
    subnet_id = element (aws_subnet.public-subnets.*.id, count.index)
    route_table_id = aws_route_table.nat-route-table.id
}




resource "aws_route_table _association" "private-subnets" {
    count = length(var-private-subnets)
    subnet_id = element (aws_subnet.private-subnets.*.id, count.index)
    route_table_id = element (
        aws_route_table.private-route-table.*.id, 
        count.index
    )
}


resource "aws_security_group" "instance-sg"{
    vpc_id = aws_vpc.my-vpc.id
    
    ingress{
    from_port = var.profile-ui-port
    to_port = var.profile-ui-port
    protocol = "tcp"
    cidr_blocks = [var.vpc_cidr]
    }
    
    egress {
     from_port = 0
     to_port =0
     protocol = "-1"
     cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_security_group" "loadbalancer-sg"{
    vpc_id = aws_vpc.my-vpc.id
    
    ingress{
        description = "security group"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [
            "183.52.8.20/32"
        ]
    }

    egress {
     from_port = 0
     to_port =0
     protocol = "-1"
     cidr_blocks = ["0.0.0.0/0"]
    }
}





