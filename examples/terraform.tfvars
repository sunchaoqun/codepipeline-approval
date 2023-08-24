project_name       = "tf-approval_testing"
environment        = "dev"
source_repo_name   = "tf-test"
source_repo_branch = "main"
create_new_repo    = true
repo_approvers_arn = "arn:aws:iam::925352035051:user/billysun" #Update ARN (IAM Role/User/Group) of Approval Members
create_new_role    = true
approver_names     = ["billysun", "chaoqun"]

#codepipeline_iam_role_name = <Role name> - Use this to specify the role name to be used by codepipeline if the create_new_role flag is set to false.
stage_input = [
  { name = "need_to_approval", category = "Approval", owner = "AWS", provider = "Manual", input_artifacts = "SourceOutput", output_artifacts = "ValidateOutput", actions = [
    {name = "basic_check", category = "Approval", provider = "Manual", run_order = 1, configuration = {}},
    {name = "finance_check", category = "Approval", provider = "Manual", run_order = 1, configuration = {}},
    {name = "lambda_checker", category = "Invoke", provider = "Lambda", run_order = 2, configuration = {
      FunctionName = "lambda_checker_function"
    }}
  ]},
  { name = "Deploy", category = "Approval", owner = "AWS", provider = "Manual", input_artifacts = "ValidateOutput", output_artifacts = "DestroyOutput", actions = [
    {name = "Deploy", category = "Approval", provider = "Manual", run_order = 1, configuration = {}},
  ]},
]
