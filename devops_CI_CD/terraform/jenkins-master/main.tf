module "vpc" {
  source     = "../modules/aws/vpc"
  cidr_block = var.vpc_cidr
}

module "security_group" {
  source = "../modules/aws/security_group/jenkins_master_groups"
  vpc_id = module.vpc.vpc_id
}

module "route_tables" {
  source              = "../modules/aws/route_tables"
  vpc_id              = module.vpc.vpc_id
  internet_gateway_id = module.vpc.internet_gateway_id
  public_subnet_id    = module.vpc.public_subnet_id
}


module "jenkins_master" {
  source               = "../modules/aws/ec2"
  ami_id               = data.aws_ami.ubuntu_with_ssm.id
  instance_type        = var.instance_type
  subnet_id            = module.vpc.public_subnet_id
  security_group_id    = module.security_group.jenkins_sg
  instance_name        = "jenkins-master"
  iam_instance_profile = module.iam.instance_profile_name
  

}


resource "aws_iam_policy" "jenkins_ssm_exec" {
  name        = "jenkins-ssm-execution-policy"
  path        = "/"
  description = "Permite que Jenkins Master ejecute y recupere comandos vía SSM"
  policy      = file("${path.module}/jenkins-ssm-execution-policy.json")
}



module "iam" {
  source    = "../modules/aws/iam"
  role_name = "jenkins-master-role"
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess",
    aws_iam_policy.jenkins_ssm_exec.arn
  ]
}
