/* 
                        REFER TERRAFORM OFFICIAL DOCUMENTATION


                        before running this script;
                        -> terraform init
                        -> terraform validate
                        -> terraform plan
                        -> terraform apply  /   terraform apply -auto-approve                   
*/

// set AWS credentials as environment variables in the system 
// cli 
provider "aws" {
  region = "ap-south-1"
}


# 1. Create VPC
resource "aws_vpc" "vpc-chat" {
    cidr_block = "10.0.0.0/16"         
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "igw-chat"{
    vpc_id = aws_vpc.vpc-chat.id
    tags = {
        Name= "intgateway-chatapp"
    }
}


# 4. Create a Subnet
resource "aws_subnet" "subnet-chatapp-1" {
    vpc_id = aws_vpc.vpc-chat.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "subnet-chatapp"
    }
}


# 3. Create Custom Route Table
resource "aws_route_table" "route-chatapp" {
    vpc_id = aws_vpc.vpc-chat.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw-chat.id
    }
    tags = {
        Name = "route_table_chatapp"
    }
}


# 5. Associate subnet with Route Table
resource "aws_main_route_table_association" "mainrt-chatapp"{
    vpc_id         = aws_vpc.vpc-chat.id
    route_table_id = aws_route_table.route-chatapp.id
}


# 6. Create Security Group to allow port 22,80,443
resource "aws_security_group" "allow_ports" {
    vpc_id         = aws_vpc.vpc-chat.id

    ingress {
        description = "HTTPS FROM VPC"
        protocol  = "tcp"
        from_port = 443
        to_port   = 443
        cidr_blocks = ["0.0.0.0/0"]
    }
        ingress {
        description = "HTTP FROM VPC"
        protocol  = "tcp"
        from_port = 80
        to_port   = 80
        cidr_blocks = ["0.0.0.0/0"]
    }
        ingress {
        description = "SSH FROM VPC"
        protocol  = "tcp"
        from_port = 22
        to_port   = 22
        cidr_blocks = ["0.0.0.0/0"]
    }
        ingress { 
        description = "Docker Compose Port"
        protocol = "tcp"
        from_port = 12345
        to_port = 12345
        cidr_blocks = ["0.0.0.0/0"]
        }
        egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    tags = {
        Name = "allow web"
    }
}


#Creating a key pair
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "generated_key_pair" {
  key_name   = "generated-key-pair"
  public_key = tls_private_key.example.public_key_openssh
}

output "private_key" {
  value     = tls_private_key.example.private_key_pem
  sensitive = true
}

resource "local_file" "TF_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/generated-key.pem"
}


# 9. Create Ubuntu server and install/git/docker

resource "aws_instance" "chatapp_server" {
    ami = "ami-0ad21ae1d0696ad58" 
    instance_type = "t2.micro"
    availability_zone = "ap-south-1a"
    key_name = aws_key_pair.generated_key_pair.key_name 

    associate_public_ip_address  = true
    subnet_id                    = aws_subnet.subnet-chatapp-1.id
    security_groups              = [aws_security_group.allow_ports.id]

#    provisioner "file" {
#     source      = "C:\\Devansh Work\\EXTRAS\\Wipro\\Chat-App\\Chat-App-W\\script.sh"  // Correct absolute path
#     destination = "/home/ubuntu/script.sh"
#   }

#     provisioner "remote-exec" {
#   inline = [
#     "sudo apt update -y",
#     "sudo apt install -y apt-transport-https ca-certificates software-properties-common",
#     "sudo apt-get update",
#     "sudo apt-get install ca-certificates curl -y",
#     "sudo install -m 0755 -d /etc/apt/keyrings",
#     "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc",
#     "sudo chmod a+r /etc/apt/keyrings/docker.asc",
#     "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
#     "sudo apt-get update",
#     "sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y",
#     "sudo git clone https://github.com/yashaswi29/CICD-Realtime-ChatApp.git",
#     "cd CICD-Realtime-ChatApp",
#     "sudo docker compose -f docker-compose.yaml up"
#   ]
# }


    connection {
        type = "ssh"
        user = "ubuntu"
        private_key = file(local_file.TF_key.filename)
        host = self.public_ip
        timeout = "4m"
    }
    tags = {
        Name = "Server-Web"
    }
}