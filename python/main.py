import boto3
import json
import os

# env variable
BUCKET = os.environ['BUCKET']
REGION = os.environ['REGION']
JSON_FILE = os.environ['JSON_FILE']
SENDER = os.environ['SENDER']


def s3_read():
    s3 = boto3.resource('s3', region_name=REGION)
    content_object = s3.Object(BUCKET, JSON_FILE)
    file_content = content_object.get()['Body'].read().decode('utf-8')
    json_content = json.loads(file_content)
    emailAddress = []
    smsNotification = []
    for i in json_content:
        emailAddress.append(json_content[i][0])
        smsNotification.append(json_content[i][1])
    print(emailAddress)
    return {
        "email": emailAddress,
        "mobile": smsNotification
    }


def email_notification():
    ses = boto3.client('ses', region_name=REGION)
    EA = s3_read()

    response = ses.send_email(
        Destination={
            'ToAddresses': EA['email'],
        },
        Message={
            'Body': {
                'Text': {
                    'Charset': 'UTF-8',
                    'Data': 'Thank you for participating in the interview process. well done!',
                },
            },
            'Subject': {
                'Charset': 'UTF-8',
                'Data': 'interview process',
            },
        },
        Source=SENDER,
    )
    print("Email sent! Message ID:"),
    print(response['MessageId'])

def lambda_handler(event, context):
    email_notification()