data "aws_iam_role" "example1" {
  name = "codebuild-emp-seller-service-service-role"
}

data "aws_security_group" "selected1" {
  id = var.security_group_id
}


resource "aws_codebuild_project" "buyer" {
  name          = "${var.project}-${var.buyerCodebuildName}-${var.env}"
  description   = "codebuild_project_for_buyer_service"
  build_timeout = "50"
  service_role  = data.aws_iam_role.example1.arn

  source {
    type            = "CODECOMMIT"
    location        = "${var.sourceCodeUrl}${var.buyer_repo_name}"
    git_clone_depth = 0
    buildspec       = "buildspec.yml"

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
      data.aws_security_group.selected1.id,
      
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
      value = var.AWS_ACCESS_KEY_ID
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "AWS_SECRET_ACCESS_KEY"
      value = var.AWS_SECRET_ACCESS_KEY
      type  = "PLAINTEXT"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project}-${var.buyerCodebuildName}-${var.env}"
      stream_name = "log-stream"
    }
  }

  tags = {
    Environment = "Uat"
  }

}

################# codepipeline ###################

data "aws_iam_role" "pipeline1" {
  name = "AWSCodePipelineServiceRole-ap-south-1-emp-seller-service-qa"
}

data "aws_s3_bucket" "selected1" {
  bucket = "codepipeline-ap-south-1-403910783684"
}
data "aws_kms_alias" "s3kmskey1" {
  name = "alias/aws/s3"
}

resource "aws_codepipeline" "buyer_pipeline" {

  name     = "${var.project}-${var.buyerCodebuildName}-${var.env}"
  role_arn = data.aws_iam_role.pipeline1.arn

  artifact_store {
    location = data.aws_s3_bucket.selected1.bucket
    type     = "S3"
    encryption_key {
      id   = data.aws_kms_alias.s3kmskey1.arn
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
        RepositoryName       = var.buyer_repo_name
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
        ProjectName = aws_codebuild_project.buyer.name
        
      }
    }
  }

}