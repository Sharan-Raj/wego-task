# wego-task
This document provides instructions and details on how to deploy the application using Docker, AWS ECS, and Terraform.

1. Containerization of the Application
  The application has been containerized using Docker. Follow the steps below to build the Docker image and push it to Docker Hub.

  a.Clone the repository:
      git clone <repo-url>
  
  b.Navigate to the application directory:
      cd <application-directory>
  
  c.Build the Docker image:
      docker build -t <image-name> .
  
  d.Tag the Docker image:
      docker tag <image-name> <dockerhub-username>/<image-name>:<tag>
  
  e.Push the Docker image to Docker Hub:
      docker push <dockerhub-username>/<image-name>:<tag>

2. Setup a Runtime for the Application and Deploy it using AWS ECS
  For the runtime environment, AWS ECS has been chosen. Terraform has been used to provision and manage the AWS ECS infrastructure. Follow the steps below to set up the runtime      environment and deployment of the application. The required configurations and services for this ecs runtime are: VPC, Subnets, IGW, Route Table, ALB, TG, Listener Rules,          Security Groups, ECS Cluster, Task Definition Resources and Service.

  a.Install Terraform in your local machine
  
  b.Create and navigate to the Terraform directory
      cd <terraform-directory>
  
  c.Create a Terraform file to write all the Terraform configurations.
    
  d.Initialize Terraform:
    terraform init
  
  e.Please execute a Terraform plan to preview the changes that will be applied to your infrastructure
      terraform plan -out
      
  e.Review and apply the Terraform configuration
    terraform apply -auto-approve
    
  f.Verify that the ECS cluster and associated resources are provisioned and the application deployment is completed in the AWS Management Console

3. To access the application, you can use either the DNS endpoint of the Application Load Balancer (ALB) or the public IP address of the ECS service task.
   ALB DNS Endpoint: my-ecs-alb-685118793.ap-south-1.elb.amazonaws.com
   Public IP: 13.233.165.166:8080/
