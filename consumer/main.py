
import json

import boto3
from secret_keys import SecretKeys

secret_keys = SecretKeys()
sqs_client = boto3.client("sqs" , region_name=secret_keys.REGION_NAME)

ecs_client=boto3.client("ecs" , region_name=secret_keys.REGION_NAME)

def poll_sqs():
    while True:
        respone = sqs_client.receive_message(
            QueueUrl=secret_keys.AWS_SQS_VIDEO_PROCESSING_QUEUE,
            MaxNumberOfMessages=1,
            WaitTimeSeconds=10
        )

        for message in respone.get("Messages" , []):
            message_body = json.loads(message.get("Body"))

            if ("Service" in message_body and "Event" in message_body and message_body.get("Event") == "s3:TestEvent"):
                sqs_client.delete_message(
                    QueueUrl=secret_keys.AWS_SQS_VIDEO_PROCESSING_QUEUE,
                    ReceiptHandle=message.get("ReceiptHandle")
                )
                continue

            if "Records" in message_body:
                s3_record = message_body["Records"][0]["s3"]
                bucket_name = s3_record["bucket"]["name"]
                s3_key = s3_record["object"]["key"]

                response = ecs_client.run_task(
                    cluster="arn:aws:ecs:ap-south-1:441923768778:cluster/videoTranscoderCluster",
                    launchType="FARGATE",
                    taskDefinition="arn:aws:ecs:ap-south-1:441923768778:task-definition/video-transcoder:10",
                    overrides={
                        "containerOverrides": [
                            {
                                "name": "video-transcoder",
                                "environment": [
                                    {"name": "S3_BUCKET", "value": bucket_name},
                                    {"name": "S3_KEY", "value": s3_key},
                                ]
                            }
                        ]
                    },
                    networkConfiguration={
                        "awsvpcConfiguration":{
                            "subnets":[
                                "subnet-00ea3ad83d34d8d42",
                                "subnet-03486a6fa4f18b475",
                                "subnet-0fcb597abe0a4d634",
                            ],
                            "assignPublicIp":"ENABLED",
                            "securityGroups":[
                                "sg-0a1d450dbc3089997",
                            ]
                        }
                    }
                )

                sqs_client.delete_message(
                    QueueUrl=secret_keys.AWS_SQS_VIDEO_PROCESSING_QUEUE,
                    ReceiptHandle=message.get("ReceiptHandle")
                )


poll_sqs()