resource "aws_iam_role" "admin" {
  name               = var.admin_role_name
  description        = "Provides administrator level access"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid = "allowAdmin"

    principals {
      type        = "AWS"
      identifiers = var.admin_principals
    }

    actions = ["sts:AssumeRole"]
  }
}

output "admin_role" {
  value = aws_iam_role.admin.arn
}
