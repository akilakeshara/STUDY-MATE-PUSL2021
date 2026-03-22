# Study Mate Funding Gateway Contract

This spec defines the backend contract for the Sponsor Funding flow implemented in the app screen:
- `lib/screens/sponsor/study_mate_funding_screen.dart`

The app supports 2 modes:
- `sandbox`: local mock confirmation dialog
- `live`: backend checkout session endpoint + gateway redirect + webhook confirmation

---

## 1) Checkout Session Endpoint (Live Mode)

### Endpoint
- `POST /payments/checkout-session`
- Content-Type: `application/json`

### Request Body (from app)
```json
{
  "paymentId": "firestore_doc_id",
  "sponsorUid": "firebase_uid",
  "sponsorName": "Sponsor Name",
  "email": "sponsor@email.com",
  "amountLkr": 2500,
  "currency": "LKR",
  "method": "Card",
  "note": "optional note",
  "successUrl": "studymate://payment-success/{paymentId}",
  "cancelUrl": "studymate://payment-cancel/{paymentId}"
}
```

### Success Response (2xx)
```json
{
  "checkoutUrl": "https://gateway.example.com/checkout/session_123",
  "sessionId": "session_123",
  "provider": "PayHere"
}
```

### Error Response (4xx/5xx)
```json
{
  "error": "reason"
}
```

### Backend Rules
- Validate `amountLkr > 0` and numeric.
- Verify `paymentId` exists in Firestore collection `study_mate_funding_payments`.
- Create gateway session with metadata: `paymentId`, `sponsorUid`.
- Return `checkoutUrl` + `sessionId`.

---

## 2) Webhook Endpoint (Required for Final Confirmation)

### Endpoint
- `POST /payments/webhook`

### Expected Behavior
- Verify gateway signature first.
- Extract status and metadata (`paymentId`, `sessionId`, amount, currency).
- Update Firestore doc:
  - Collection: `study_mate_funding_payments`
  - Doc: `{paymentId}`

### Firestore Status Mapping
- Gateway success -> `status: "paid"`, set `paidAt`
- Gateway failed -> `status: "failed"`
- Gateway cancelled -> `status: "cancelled"`
- Always update `updatedAt`
- Store raw gateway payload for audit (recommended): `gatewayPayload`

---

## 3) Firestore Config for App

Create this document so app can find your backend endpoint:
- Collection: `app_config`
- Document: `payment_gateway`
- Field:
  - `checkoutSessionEndpoint`: `https://your-backend.com/payments/checkout-session`

If missing, app marks payment as `gateway_config_missing` and shows a setup message.

---

## 4) Payment Record Schema (App-created)

Collection: `study_mate_funding_payments`

Common fields:
- `paymentId`
- `sponsorUid`
- `sponsorName`
- `sponsorID`
- `email`
- `amountLkr`
- `currency` (`LKR`)
- `method`
- `note`
- `gatewayMode` (`sandbox` | `live`)
- `gateway`
- `status`
- `createdAt`
- `updatedAt`

Live-only fields (after backend):
- `checkoutUrl`
- `sessionId`
- `gatewayProvider`
- `gatewayError`
- `paidAt`
- `gatewayPayload` (recommended)

---

## 5) Recommended Security

- Keep gateway secret keys on backend only.
- Never trust `amountLkr` from client without validation.
- Verify webhook signatures.
- Add idempotency by `paymentId`/`sessionId`.
- Restrict Firestore writes so only backend service account can set final paid state.

---

## 6) Test Checklist

- App live mode opens external checkout URL.
- Successful gateway callback marks Firestore status `paid`.
- Cancel callback marks `cancelled`.
- Invalid amount/request rejected by backend.
- Duplicate webhook events do not create inconsistent states.
