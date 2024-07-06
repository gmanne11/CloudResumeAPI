import json
import boto3

def lambda_handler(event, context):
    try:
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table('ResumeTable')

        response = table.get_item(Key={'id': '1'})
        resume = response.get('Item', {})

        # Convert sets to lists (if necessary)
        for key, value in resume.items():
            if isinstance(value, set):
                resume[key] = list(value)

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'  # Adjust CORS policy as needed
            },
            'body': json.dumps(resume)
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }