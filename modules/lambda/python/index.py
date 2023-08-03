from __future__ import print_function
import boto3
import traceback
import os

code_pipeline = boto3.client('codepipeline')

def put_job_success(job, message):
    code_pipeline.put_job_success_result(jobId=job)
  
def put_job_failure(job, message):
    code_pipeline.put_job_failure_result(jobId=job, failureDetails={'message': message, 'type': 'JobFailed'})

def lambda_handler(event, context):
    try:
        job_id = event['CodePipeline.job']['id']

        code_pipeline_name = os.environ.get("CODEPIPELINE_NAME", "approval_testing")

        state = code_pipeline.get_pipeline_state(name=code_pipeline_name)
        
        stage = state['stageStates'][1]
        basic_check = stage['actionStates'][0]['latestExecution']['lastUpdatedBy']
        finance_check = stage['actionStates'][1]['latestExecution']['lastUpdatedBy']

        if basic_check == finance_check:
            put_job_failure(job_id, "错误: 两次审批均为一个审批人 ({}) ，流程失败!".format(basic_check))
        else:
            put_job_success(job_id, "审批成功:两个审批人分别为 {} , {}".format(basic_check, finance_check))


    except Exception as e:
        # If any other exceptions which we didn't expect are raised
        # then fail the job and log the exception message.
        traceback.print_exc()
        put_job_failure(job_id, 'Function exception: ' + str(e))
        
    return