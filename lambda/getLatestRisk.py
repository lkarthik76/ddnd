import json
import boto3
from boto3.dynamodb.conditions import Key
from decimal import Decimal

dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
table = dynamodb.Table("DDnDHealthRecords")

def clean_decimal(obj):
    if isinstance(obj, list):
        return [clean_decimal(v) for v in obj]
    elif isinstance(obj, dict):
        return {k: clean_decimal(v) for k, v in obj.items()}
    elif isinstance(obj, Decimal):
        return float(obj)
    else:
        return obj


def lambda_handler(event, context):
    params = event.get("queryStringParameters", {}) or {}
    user_id = params.get("short_user_id")
    driver_id = params.get("driver_id")
    
    print("✅ Received query params:", json.dumps(event.get("queryStringParameters")))
    
    if not user_id:
        return {"statusCode": 400, "body": json.dumps({"error": "Missing short_user_id"})}

    try:
        # Query by short_user_id sorted by ts descending
        response = table.query(
            KeyConditionExpression=Key("short_user_id").eq(user_id),
            ScanIndexForward=False,  # newest first
            Limit=10
        )

        # Optionally filter by driver_id
        items = response.get("Items", [])
        if driver_id:
            items = [item for item in items if item.get("driver_id") == driver_id]

        if not items:
            return {"statusCode": 404, "body": json.dumps({"error": "No records found"})}

        latest = items[0]
        cleaned = clean_decimal(latest)
        print("📤 Cleaned response for return:\n", json.dumps(cleaned, indent=2))
        return {"statusCode": 200, "body": json.dumps(clean_decimal(latest), default=str)}
    
    except Exception as e:
        print("❌ Query error:", str(e))
        return {"statusCode": 500, "body": json.dumps({"error": "Server error"})}
    
