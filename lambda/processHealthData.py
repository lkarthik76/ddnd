import json
import boto3
import re
from decimal import Decimal

# Create a Bedrock client
bedrock = boto3.client("bedrock-runtime", region_name="us-east-1")
dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
table = dynamodb.Table("DDnDHealthRecords")
sns = boto3.client("sns", region_name="us-east-1")
SNS_TOPIC_ARN = "arn:aws:sns:us-east-1:016696895736:DDnDAlerts"

# Prompt builder
def build_classification_prompt(health_data):
    prompt = (
        "You are a driving fitness risk classifier. Based on the user's health vitals, "
        "respond with only one of the following risk levels: normal, moderate, or high.\n\n"

        "Classification Rules:\n"
        "- HIGH RISK if: HR > 120 OR HRV < 30 OR SpO2 < 93 OR RR > 24\n"
        "- MODERATE RISK if: 101 ≤ HR ≤ 120 OR 30 ≤ HRV ≤ 49 OR 93 ≤ SpO2 ≤ 94 OR 21 ≤ RR ≤ 24\n"
        "- NORMAL RISK if: HR ≤ 100 and no known risks are present\n"

        "Important:\n"
        "- Return only one of: normal, moderate, high\n"
        "- Respond with a single word label only — no explanations\n\n"
        "Health Data:\n"
    )

    for metric, values in health_data.items():
        try:
            value, timestamp = values
        except (TypeError, ValueError):
            value = values
            timestamp = "unknown"
        prompt += f"- {metric}: {value} at {timestamp}\n"

    return prompt

# Bedrock model inference
def classify_ddnd_risk(health_data):
    prompt = build_classification_prompt(health_data)
    print("🧠 Prompt sent to Bedrock:\n", prompt)

    try:
        response = bedrock.invoke_model(
            modelId="amazon.titan-text-express-v1",
            contentType="application/json",
            accept="application/json",
            body=json.dumps({"inputText": prompt})
        )

        response_body = json.loads(response["body"].read())
        output = response_body.get("results", [{}])[0].get("outputText", "").strip().lower()
        print("🧠 Titan response:", output)

        match = re.search(r'\b(normal|moderate|high)\b', output)
        return match.group(1) if match else "unknown"

    except Exception as e:
        print("❌ Bedrock classification failed:", str(e))
        return "error"

# Store data in DynamoDB
def store_to_dynamodb(short_user_id, driver_id, timestamp, risk, health_data):
    try:
        # Convert float to Decimal recursively
        def convert(value):
            if isinstance(value, float):
                return Decimal(str(value))
            elif isinstance(value, list):
                return [convert(v) for v in value]
            elif isinstance(value, dict):
                return {k: convert(v) for k, v in value.items()}
            else:
                return value

        health_data_decimal = convert(health_data)

        item = {
            "short_user_id": short_user_id,
            "ts": timestamp,
            "driver_id": driver_id or "unknown",
            "risk": risk,
            "health_data": health_data_decimal
        }

        table.put_item(Item=item)
        print("💾 Stored in DynamoDB:\n", json.dumps(item, indent=2, default=str))

    except Exception as e:
        print("❌ Failed to store in DynamoDB:", str(e))

# Lambda handler
def lambda_handler(event, context):
    print(f"🔍 Incoming event:\n{json.dumps(event)}")

    try:
        body = json.loads(event["body"]) if "body" in event else event
    except Exception as e:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": f"Invalid input format: {str(e)}"})
        }

    uid = body.get("uid", "unknown")
    did = body.get("did", "unknown")
    timestamp = body.get("ts", "unknown")
    device_type = body.get("dt", "unknown")
    health_data = body.get("hd", {})

    if not isinstance(health_data, dict):
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Invalid or missing health data."})
        }

    print(f"📥 Received data from {uid} ({device_type})")
    for metric, values in health_data.items():
        if isinstance(values, (list, tuple)) and len(values) >= 2:
            print(f" - {metric}: {values[0]} at {values[1]}")
        else:
            print(f" - {metric}: Malformed entry → {values}")

    risk = classify_ddnd_risk(health_data)
    store_to_dynamodb(uid, did, timestamp, risk, health_data)
    
    if risk == "high":
        try:
            sns.publish(
                TopicArn=SNS_TOPIC_ARN, 
                Message=f"🚨 DDnD High Risk Alert for user {uid}!\nRisk Level: HIGH\nTimestamp: {timestamp}",
                Subject="🚫 Don't Drive: High Risk Detected")
            print("🔔 SNS alert sent for high risk")
        except Exception as e:
            print("❌ Failed to send SNS alert:", str(e))
    else:
        print("✅ No high risk detected, no SNS alert sent {risk}")
    
    response = {
        "message": "Health data received",
        "risk": risk,
        "received": health_data,
        "uid": uid,
        "did": did,
        "timestamp": timestamp
    }

    print("📤 Final JSON Response:\n", json.dumps(response, indent=2))

    return {
        "statusCode": 200,
        "body": json.dumps(response)
    }
