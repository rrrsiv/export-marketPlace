data "aws_iam_role" "example3" {
  name = var.build_role
}

data "aws_security_group" "selected3" {
  id = var.security_group_id
}


resource "aws_codebuild_project" "confi" {
  name          = "${var.project}-${var.configurationCodebuildName}-${var.env}"
  description   = "codebuild_project_for_configuration_service"
  build_timeout = "50"
  service_role  = data.aws_iam_role.example3.arn

  source {
    type            = "CODECOMMIT"
    location        = "${var.sourceCodeUrl}${var.configuration_repo_name}"
    git_clone_depth = 0
    buildspec       = "buildspec-prod.yml"

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
      data.aws_security_group.selected3.id,
      
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
      group_name  = "/aws/codebuild/${var.project}-${var.configurationCodebuildName}-${var.env}"
      stream_name = "log-stream"
    }
  }

  tags = {
    Environment = "prod"
  }

}

################# codepipeline ###################

data "aws_iam_role" "pipeline3" {
  name = var.pipeline_role
}

data "aws_s3_bucket" "selected3" {
  bucket = var.s3_bucket
}
data "aws_kms_alias" "s3kmskey3" {
  name = "alias/aws/s3"
}

resource "aws_codepipeline" "confi_pipeline" {

  name     = "${var.project}-${var.configurationCodebuildName}-${var.env}"
  role_arn = data.aws_iam_role.pipeline3.arn

  artifact_store {
    location = data.aws_s3_bucket.selected3.bucket
    type     = "S3"
    encryption_key {
      id   = data.aws_kms_alias.s3kmskey3.arn
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
        RepositoryName       = var.configuration_repo_name
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
        ProjectName = aws_codebuild_project.confi.name
        
      }
    }
  }

}