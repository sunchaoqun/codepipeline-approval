#This solution, non-production-ready template describes AWS Codepipeline based CICD Pipeline for terraform code deployment.
#© 2023 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
#This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
#http://aws.amazon.com/agreement or other written agreement between Customer and either
#Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

resource "aws_iam_role" "codepipeline_role" {
  count              = var.create_new_role ? 1 : 0
  name               = var.codepipeline_iam_role_name
  tags               = var.tags
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Effect": "Allow"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  path               = "/"
}

# TO-DO : replace all * with resource names / arn
resource "aws_iam_policy" "codepipeline_policy" {
  count       = var.create_new_role ? 1 : 0
  name        = "${var.project_name}-codepipeline-policy"
  description = "Policy to allow codepipeline to execute"
  tags        = var.tags
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
          "lambda:InvokeFunction"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:lambda_checker_function"
    },
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": "${var.s3_bucket_arn}/*"
    },
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetBucketVersioning"
      ],
      "Resource": "${var.s3_bucket_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
         "kms:DescribeKey",
         "kms:GenerateDataKey*",
         "kms:Encrypt",
         "kms:ReEncrypt*",
         "kms:Decrypt"
      ],
      "Resource": "${var.kms_key_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
         "codecommit:GitPull",
         "codecommit:GitPush",
         "codecommit:GetBranch",
         "codecommit:CreateCommit",
         "codecommit:ListRepositories",
         "codecommit:BatchGetCommits",
         "codecommit:BatchGetRepositories",
         "codecommit:GetCommit",
         "codecommit:GetRepository",
         "codecommit:GetUploadArchiveStatus",
         "codecommit:ListBranches",
         "codecommit:UploadArchive"
      ],
      "Resource": "arn:aws:codecommit:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.source_repository_name}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild",
        "codebuild:BatchGetProjects"
      ],
      "Resource": "arn:aws:codebuild:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:project/${var.project_name}*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:CreateReportGroup",
        "codebuild:CreateReport",
        "codebuild:UpdateReport",
        "codebuild:BatchPutTestCases"
      ],
      "Resource": "arn:aws:codebuild:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:report-group/${var.project_name}*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codepipeline_role_attach" {
  count      = var.create_new_role ? 1 : 0
  role       = aws_iam_role.codepipeline_role[0].name
  policy_arn = aws_iam_policy.codepipeline_policy[0].arn
}

resource "aws_iam_policy" "codepipeline_approval_policy" {
  name        = "${var.project_name}-codepipeline-approval-policy"
  description = "Policy to allow codepipeline to approval"
  tags        = var.tags
policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codepipeline:ListPipelines"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codepipeline:GetPipeline",
                "codepipeline:GetPipelineState",
                "codepipeline:GetPipelineExecution",
                "codepipeline:StartPipelineExecution",
                "codepipeline:PutApprovalResult",
                "codepipeline:ListPipelineExecutions"
            ],
            "Resource": [
              "arn:aws:codepipeline:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.project_name}-pipeline",
              "arn:aws:codepipeline:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.project_name}-pipeline/*"
            ]
        },
    {
        "Effect": "Deny",
        "Action": [
            "codepipeline:PutApprovalResult"
        ],
        "Resource": "arn:aws:codepipeline:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.project_name}-pipeline/need_to_approval/basic_check",
        "Condition": {
            "StringNotEquals": {
                "aws:username": "billysun"
            }
        }
    },
    {
        "Effect": "Deny",
        "Action": [
            "codepipeline:PutApprovalResult"
        ],
        "Resource": "arn:aws:codepipeline:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.project_name}-pipeline/need_to_approval/finance_check",
        "Condition": {
            "StringNotEquals": {
                "aws:username": "billysun"
            }
        }
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "codepipeline_user_attach" {
  count      = "${length(var.approver_names)}"
  user       = "${element(var.approver_names,count.index )}"
  policy_arn = aws_iam_policy.codepipeline_approval_policy.arn
}
