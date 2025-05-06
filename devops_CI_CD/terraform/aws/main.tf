
module "vpc" {
  source     = "../modules/aws/vpc"
  cidr_block = var.vpc_cidr
}

module "security_group" {
  source = "../modules/aws/security_group/gitea_groups"
  vpc_id = module.vpc.vpc_id
}

module "route_tables" {
  source              = "../modules/aws/route_tables"
  vpc_id              = module.vpc.vpc_id
  internet_gateway_id = module.vpc.internet_gateway_id
  public_subnet_id    = module.vpc.public_subnet_id
}



module "ec2" {
  source            = "../modules/aws/ec2"
  instance_type     = var.instance_type
  ami_id            = data.aws_ami.ubuntu.id
  subnet_id         = module.vpc.public_subnet_id
  security_group_id = module.security_group.ec2_sg
  instance_name     = "gitea_web"
  iam_instance_profile = module.iam.instance_profile_name
}

# module "bastion" {
#   source            = "../modules/aws/bastion"
#   subnet_id         = module.vpc.public_subnet_id
#   ami_id            = data.aws_ami.ubuntu.id
#   security_group_id = module.security_group.bastion_sg
# }

module "s3_bucket" {
  source      = "../modules/aws/s3"
  bucket_name = var.bucket_name
  #env         = var.env
}

data "aws_ssm_parameter" "db_user" {
  name            = "/rds/mysql/username"
  with_decryption = true
}

data "aws_ssm_parameter" "db_password" {
  name            = "/rds/mysql/password"
  with_decryption = true
}

module "rds" {
  source      = "../modules/aws/rds"
  db_user     = data.aws_ssm_parameter.db_user.value
  db_password = data.aws_ssm_parameter.db_password.value
  subnet_ids  = module.vpc.private_subnet_ids
  vpc_id      = module.vpc.vpc_id
  rds_sg_id   = module.security_group.rds_sg
}

module "iam" {
  source    = "../modules/aws/iam"
  role_name = "gitea-web-role"
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
}