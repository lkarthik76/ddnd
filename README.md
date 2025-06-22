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

## 🔗 Try the Live API

```http
GET /getRisk?short_user_id=1234567890
Host: https://x3lurwrtk3.execute-api.us-east-1.amazonaws.com/prod
