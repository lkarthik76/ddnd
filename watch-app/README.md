# 🚗 DDnD – Don’t Drink and Drive AI Companion

## 💡 Inspiration

Every year, thousands of lives are lost to preventable DUI-related accidents. We wanted to create a **real-time, wearable safety assistant** that empowers users with biometric insights before they drive. With Apple Watch always on the wrist and AWS Bedrock providing powerful AI, we built a system to stop risky decisions before they happen.

---

## 🚀 What It Does

- Collects **live biometrics** using HealthKit on Apple Watch
- Sends data every **10 seconds** to AWS via REST API
- Uses **Amazon Titan** (via Bedrock) to classify driving fitness as:
  - ✅ Normal
  - ⚠️ Moderate
  - 🚫 High Risk
- Displays risk on Watch UI
- Pulses haptics for high risk
- Triggers **SNS alerts** if necessary

---

## 🔧 How We Built It

- **Frontend (watchOS)**:
  - SwiftUI + HealthKit + HKLiveWorkoutBuilder
  - WKExtendedRuntimeSession for background updates

- **Backend (AWS)**:
  - API Gateway + Lambda (Python)
  - Amazon Bedrock (Titan)
  - DynamoDB to store risk + vitals
  - CloudWatch logging
  - SNS alert for critical risk

---

## ⚠️ Challenges We Ran Into

- Live HR streaming was tricky — required workout sessions
- Decimal handling in DynamoDB (float not supported natively)
- Prompt tuning Titan to return **only** `normal`, `moderate`, or `high`
- Lambda runtime permissions + Bedrock model access

---

## 🏆 Accomplishments We’re Proud Of

- End-to-end pipeline works in **under 10s**
- Watch app haptics + animation + real alerts ✅
- Titan prompt response consistent and explainable
- Used real biometric input (not just mock data!)
- Built this across both frontend & backend in under a week

---

## 📚 What We Learned

- How to prompt Amazon Titan on Bedrock for deterministic output
- Real-time watchOS development and biometric streaming
- AWS security/role setup for Bedrock and DynamoDB
- Visualizing biometric trends in a meaningful way
- Building health tech with AI that can save lives

---

## 🔮 What’s Next

- iOS dashboard with risk history + trend insights
- Push alerts to caregivers or emergency contacts
- Trip logging and smart recommendations
- Integrate with cars (e.g., block ignition if risk is high)
- Expand dataset and refine Titan prompt using real-world inputs

---

## 🛠 Built With

- **SwiftUI** / **HealthKit**
- **AWS Lambda** (Python 3.12)
- **Amazon Bedrock** (Titan Text Express)
- **API Gateway**, **DynamoDB**, **SNS**, **CloudWatch**
- `boto3`, `decimal.Decimal`

---

## 🎥 Demo Video

📺 [Watch the Demo on YouTube](https://youtu.be/_qWqZ2p4gCg)

---

## 🔗 Live API Test

```http
GET /getRisk?short_user_id=1234567890
Host: https://x3lurwrtk3.execute-api.us-east-1.amazonaws.com/prod
