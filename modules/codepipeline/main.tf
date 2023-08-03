#This solution, non-production-ready template describes AWS Codepipeline based CICD Pipeline for terraform code deployment.
#© 2023 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
#This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
#http://aws.amazon.com/agreement or other written agreement between Customer and either
#Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

resource "aws_codepipeline" "terraform_pipeline" {

  name     = "${var.project_name}-pipeline"
  role_arn = var.codepipeline_role_arn
  tags     = var.tags

  artifact_store {
    location = var.s3_bucket_name
    type     = "S3"
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
        RepositoryName       = var.source_repo_name
        BranchName           = var.source_repo_branch
        PollForSourceChanges = "true"
      }
    }
  }

  dynamic "stage" {
    for_each = var.stages

    content {
      name = "${stage.value["name"]}"
      
      dynamic "action" {
        for_each = stage.value["actions"]
        content {
          name             = "${action.value["name"]}"
          category         = action.value["category"]
          owner            = stage.value["owner"]
          provider         = action.value.provider
          version          = "1"
          run_order        = action.value["run_order"]
          configuration    = action.value["configuration"]
        }
      }
    }
  }
}