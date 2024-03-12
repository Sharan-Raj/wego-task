provider "aws" {
  region = "ap-south-1" 
}

# Creating a VPC
resource "aws_vpc" "mumbai_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Creating subnets in different availability zones
resource "aws_subnet" "subnet-a" {
  vpc_id            = aws_vpc.mumbai_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"  
}

resource "aws_subnet" "subnet-b" {
  vpc_id            = aws_vpc.mumbai_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
}

# Creating an Internet Gateway & attaching to our VPC
resource "aws_internet_gateway" "mumbai_igw" {
  vpc_id = aws_vpc.mumbai_vpc.id
}

# Creating a Route Table and associating it with the VPC
resource "aws_route_table" "mumbai_route_table" {
  vpc_id = aws_vpc.mumbai_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mumbai_igw.id
  }
}

# Associating subnets with the route table
resource "aws_route_table_association" "subnet-a_association" {
  subnet_id      = aws_subnet.subnet-a.id
  route_table_id = aws_route_table.mumbai_route_table.id
}

resource "aws_route_table_association" "subnet-b_association" {
  subnet_id      = aws_subnet.subnet-b.id
  route_table_id = aws_route_table.mumbai_route_table.id
}

# Creating a security group for ECS
resource "aws_security_group" "my-ecs-sg" {
  vpc_id = aws_vpc.mumbai_vpc.id

  # Allowing incoming traffic on ports 443 & 80
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   # Allowing outgoing traffic to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating an Application Load Balancer
resource "aws_lb" "my-ecs-alb" {
  name               = "my-ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my-ecs-sg.id]
  subnets            = [aws_subnet.subnet-a.id, aws_subnet.subnet-b.id]
}

# Creating a Target Group
resource "aws_lb_target_group" "ecs-alb-TG" {
  name     = "ecs-alb-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.mumbai_vpc.id
  target_type = "ip"
}

# Creating ALB Listener
resource "aws_lb_listener" "ecs-alb-listener" {
  load_balancer_arn = aws_lb.my-ecs-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs-alb-TG.arn
  }
}

# Creating an ECS cluster
resource "aws_ecs_cluster" "fortune-api-cluster" {
  name = "fortune-api-cluster"
}

# Creating a Task Definition
# data "aws_ecs_task_definition" "fortune-api" {
 # task_definition = "fortune-api"
# }

resource "aws_ecs_task_definition" "fortune-api" {
  family                   = "fortune-api"
  network_mode             = "awsvpc"
  cpu       = 256
  memory    = 512
  requires_compatibilities = ["FARGATE"]
  container_definitions    = jsonencode([
    {
      name      = "fortune-api"
      image     = "sharanraj2112/fortune-api:latest"
      cpu       = 256
      memory    = 512
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# Creating cluster configurations
resource "aws_ecs_service" "fortune-api" {
  name            = "fortune-api-service"
  cluster         = aws_ecs_cluster.fortune-api-cluster.arn
  task_definition = aws_ecs_task_definition.fortune-api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.subnet-a.id]
    security_groups  = [aws_security_group.my-ecs-sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs-alb-TG.arn
    container_name   = "fortune-api"
    container_port   = 8080
  }

  depends_on = [aws_lb.my-ecs-alb]
}
