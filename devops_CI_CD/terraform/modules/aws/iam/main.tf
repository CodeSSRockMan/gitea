resource "aws_iam_role" "role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


resource "aws_iam_instance_profile" "profie" {
  name = "${var.role_name}-instance-profile"
  role = aws_iam_role.role.name
}

resource "aws_iam_role_policy_attachment" "attachments" {
  for_each = toset(var.policy_arns)
  role     = aws_iam_role.role.name
  policy_arn = each.key
}