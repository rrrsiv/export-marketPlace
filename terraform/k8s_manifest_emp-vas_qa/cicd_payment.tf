###### codebuild Role #############
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "role" {
  name               = "codebuild-${var.project}-${var.vasCodebuildName}-${var.env}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "example" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]
  }

}

resource "aws_iam_policy" "default" {
  name        = "${var.project}-${var.vasCodebuildName}-${var.env}-policy"
  policy      = data.aws_iam_policy_document.example.json
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.default.arn
}
resource "aws_iam_role_policy_attachment" "role-policy" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeArtifactReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "role-policy1" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "role-policy2" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_security_group" "sg" {
  id = var.security_group_id
}


resource "aws_codebuild_project" "vas" {
  name          = "${var.project}-${var.vasCodebuildName}-${var.env}"
  description   = "codebuild_project_for_vas_service"
  build_timeout = "50"
  service_role  = aws_iam_role.role.arn

  source {
    type            = "CODECOMMIT"
    location        = "${var.sourceCodeUrl}${var.vas_repo_name}"
    git_clone_depth = 0
    buildspec       = "buildspec-${var.env}.yml"

    git_submodules_config {
      fetch_submodules = true
    }
  }
  source_version = var.source_repo_branch

  vpc_config {
    vpc_id = var.vpc_id

    subnets = [
      var.subnet1_id,
      var.subnet2_id,
    ]

    security_group_ids = [
      data.aws_security_group.sg.id,
      
    ]
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_ACCESS_KEY_ID"
      value = "/CODEBUILD/AWS_ACCESS_KEY_ID"
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "AWS_SECRET_ACCESS_KEY"
      value = "/CODEBUILD/AWS_SECRET_ACCESS_KEY"
      type  = "PARAMETER_STORE"
    }
    environment_variable {
      name  = "SONAR_PASSWORD"
      value = "/CODEBUILD/SONAR_PASSWORD"
      type  = "PARAMETER_STORE"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project}-${var.vasCodebuildName}-${var.env}"
      stream_name = "log-stream"
    }
  }

  tags = {
    Environment = var.env
  }
  depends_on = [
    aws_iam_role.role
  ]
}
########### codepipeline role #####################

data "aws_iam_policy_document" "assume_role_pipeline" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "codepipeline-${var.project}-${var.vasCodebuildName}-${var.env}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_pipeline.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }
  statement {
    effect = "Allow"

    actions = [
      "codecommit:CancelUploadArchive",
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:GetRepository",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:UploadArchive"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline-${var.project}-${var.vasCodebuildName}-${var.env}-policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

################# codepipeline ###################

data "aws_s3_bucket" "bucket" {
  bucket = "codepipeline-ap-south-1-403910783684"
}
data "aws_kms_alias" "s3kmskey" {
  name = "alias/aws/s3"
}

resource "aws_codepipeline" "vas_pipeline" {

  name     = "${var.project}-${var.vasCodebuildName}-${var.env}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = data.aws_s3_bucket.bucket.bucket
    type     = "S3"
    encryption_key {
      id   = data.aws_kms_alias.s3kmskey.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeCommit"
      namespace        = "SourceVariables"
      output_artifacts = ["SourceOutput"]
      run_order        = 1

      configuration = {
        RepositoryName       = var.vas_repo_name
        BranchName           = var.repo_branch
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      version          = "1"
      namespace        = "BuildVariables"
      configuration = {
        ProjectName = aws_codebuild_project.vas.name
        
      }
    }
  }
  depends_on = [
    aws_codebuild_project.vas
  ]
}