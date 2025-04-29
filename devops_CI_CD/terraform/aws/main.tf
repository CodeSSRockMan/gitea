
module "vpc" {
  source     = "../modules/aws/vpc"
  cidr_block = var.vpc_cidr
}

module "ec2" {
  source            = "../modules/aws/ec2"
  instance_type     = var.instance_type
  ami_id            = data.aws_ami.ubuntu.id
  subnet_id         = module.vpc.public_subnet_id
  security_group_id = module.security_group.id
}



module "s3_bucket" {
  source      = "../modules/aws/s3"
  bucket_name = var.bucket_name
  #env         = var.env
}

module "security_group" {
  source = "../modules/aws/security_group"
  vpc_id = module.vpc.vpc_id
}
