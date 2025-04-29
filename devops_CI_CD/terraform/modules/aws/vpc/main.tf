
resource "aws_vpc" "gitea_main" {
  cidr_block = var.cidr_block
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.gitea_main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 0)
  availability_zone = "us-east-1a"
}

