# 🛡️ DDnD – Don’t Drink and Drive AI Companion

A real-time AI-powered Apple Watch app that helps prevent unsafe driving by monitoring live health data and classifying risk using Amazon Bedrock.

---

## 📲 Watch App Overview

**DDnD** uses HealthKit on Apple Watch to capture:

- ❤️ Heart Rate (BPM)
- 💓 HRV (Heart Rate Variability)
- 🫁 Respiratory Rate
- 🩸 Blood Oxygen

It then:

1. Sends this data to an AWS API every 10 seconds  
2. Classifies the driving fitness level using Amazon Titan  
3. Alerts the user visually and with haptic feedback if the risk is high

---
## 🧠 Architecture

![Architecture Diagram](assets/architecture.png)

Apple Watch ⌚
↳ Collects health data via HealthKit
↳ Sends data every 10s via HTTPS to API Gateway

AWS Backend ☁️
↳ API Gateway (REST API)
↳ AWS Lambda (Python)
↳ Amazon Bedrock (Titan)
↳ Returns "normal", "moderate", or "high"
↳ DynamoDB (stores risk + timestamp)
↳ SNS (planned for alerts)
---

## ⚙️ Technologies Used

### 📱 Frontend (Watch App)
- [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- [HealthKit](https://developer.apple.com/documentation/healthkit)
- [WKExtendedRuntimeSession](https://developer.apple.com/documentation/watchkit/wkextendedruntimesession)
- [WKInterfaceDevice](https://developer.apple.com/documentation/watchkit/wkinterfacedevice) for haptic alerts

### ☁️ AWS Cloud Backend
- [Amazon API Gateway](https://aws.amazon.com/api-gateway/)
- [AWS Lambda](https://aws.amazon.com/lambda/)
- [Amazon Bedrock](https://aws.amazon.com/bedrock/) (Titan Model)
- [Amazon DynamoDB](https://aws.amazon.com/dynamodb/)
- [Amazon SNS](https://aws.amazon.com/sns/) *(planned for push alerts)*

### 🧰 Libraries & Tools
- [`boto3`](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)
- `decimal.Decimal` for DynamoDB compatibility
- JSON / ISO8601 formatting

---

## 🔗 Try It Out

### 🔸 Live API (Risk Lookup)

```http
GET /getRisk?short_user_id=1234567890
Host: https://x3lurwrtk3.execute-api.us-east-1.amazonaws.com/prod

## 🧠 Architecture

