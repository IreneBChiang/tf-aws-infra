import json

def handler(event, context):
    print("=== Received SNS Event ===")
    print(json.dumps(event))
    return {"status": "ok"}
