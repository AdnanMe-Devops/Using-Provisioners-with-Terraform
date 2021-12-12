terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.7"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_ecr_repository" "ecr" {
  name = "catest"

  provisioner "local-exec" {
    when = destroy

    command = <<EOF
    $(aws ecr get-login --region us-west-2 --no-include-email)
    docker pull ${self.repository_url}:latest
    docker save --output catest.tar ${self.repository_url}:latest 
    EOF
  }

}


#Import Container Image to Elastic Container Registry
resource "null_resource" "image" {

  provisioner "local-exec" {
    command = <<EOF
       $(aws ecr get-login --region us-west-2 --no-include-email)
       docker pull hello-world:latest
       docker tag hello-world:latest ${aws_ecr_repository.ecr.repository_url}
       docker push ${aws_ecr_repository.ecr.repository_url}:latest
   EOF
  }
}
---
This configuration will create an Elastic Container Registry in AWS account.Also there is a null_resource resource block with a provisioner block inside. This is an empty resource that will run a series of commands on the local endpoint running Terraform. When the code is executed in this main.tf file, it will create an ECR resource and then perform the commands stated in the provisioner block to automatically upload a Docker image to the container registry. 

Take a note  The Docker client and AWS CLI tools have been installed in this IDE session, or the provisioner block would not work since the commands are executed locally. This is one of the reasons why Provisioner blocks are not a good idea. They implement dependencies on the code. Now, this main.tf cannot be run on just any endpoint. It needs to have additional tools installed. 

The reference to the ECR repository URL creates an implicit dependency inside the provisioner block that is telling Terraform to create the null_resource block and run the provisioner block after the ECR resource has been created:
