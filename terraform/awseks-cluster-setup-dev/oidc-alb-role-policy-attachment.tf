
locals {
    aws_iam_oidc_connect_provider_extract_from_arn = element(split("oidc-provider/", "${aws_iam_openid_connect_provider.eks.arn}"), 1)
}
resource "aws_iam_role" "oidc_iam_role" {
  name = "oidc-iam-role"

  # Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "${aws_iam_openid_connect_provider.eks.arn}"
        }
        Condition = {
          StringEquals = {
             "${local.aws_iam_oidc_connect_provider_extract_from_arn}:aud": "sts.amazonaws.com",
            "${local.aws_iam_oidc_connect_provider_extract_from_arn}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }        

      },
    ]
  })

  
}

# Associate IAM Role and Policy
resource "aws_iam_role_policy_attachment" "oidc_alb_role_policy_attach" {
  policy_arn = aws_iam_policy.alb.arn
  role       = aws_iam_role.oidc_iam_role.name
}

