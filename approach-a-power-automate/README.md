# Approach A: Microsoft Power Automate — ESL Automation

> **Status:** ✅ Complete & Production Ready  
> **Tool:** Microsoft Power Automate + Groq API (Free Tier)  
> **Setup Time:** ~2 hours  
> **Cost:** $0 (included in M365 license)

---

## 📋 Overview

This approach uses **Microsoft Power Automate** to orchestrate the ESL email security automation. Power Automate is included in your M365 license — no additional software or hosting required.

### How It Works

```
[Suspicious Email Forwarded to Security Inbox]
        ↓
[Power Automate Trigger — Subject contains "[ESL-AUTO]"]
        ↓
[HTTP Action → Groq API (free) — AI threat analysis]
        ↓
[AI output injected into ESL response template]
        ↓
[Conditional logic: confidence ≥ 85% → Auto-send | < 85% → Draft]
        ↓
[Outlook sends reply to forwarding employee]
        ↓
[Optional: Log entry to SharePoint / Teams alert]
```

---

## 🚀 Step-by-Step Setup

### Prerequisites

| Requirement | Details |
|-------------|---------|
| Microsoft 365 Work Account | With access to [flow.microsoft.com](https://flow.microsoft.com) |
| Groq API Key | From [console.groq.com](https://console.groq.com) — free, no credit card |
| ESL Templates | Included in this directory → [`templates/`](templates/) |

### Step 1 — Get Your Groq API Key

1. Go to [console.groq.com](https://console.groq.com) and sign up (no credit card)
2. Navigate to **API Keys** → **Create API Key**
3. Copy and store securely

### Step 2 — Create the Flow

1. Go to [flow.microsoft.com](https://flow.microsoft.com) and sign in
2. Click **+ New flow** → **Automated cloud flow**
3. Name: `ESL AI Automation`
4. Search for and select: **"When a new email arrives (V3)"** (Outlook connector)
5. Click **Create**

### Step 3 — Configure the Trigger

| Field | Value |
|-------|-------|
| Folder | Inbox |
| Include Attachments | No |
| Subject Filter | `[ESL-AUTO]` |

Add a **condition filter** for case-insensitive matching:
```powerautomate
contains(toLower(triggerOutputs()?['body/subject']), '[esl-auto]')
```

### Step 4 — Extract Email Metadata

Add a **"Get email (V2)"** action. This extracts:
- `From` — forwarding employee's email
- `Subject` — original subject line
- `Body` — full email content
- `ReceivedDateTime` — timestamp

### Step 5 — Call the Groq API

Add an **HTTP** action:

| Field | Value |
|-------|-------|
| **Method** | `POST` |
| **URI** | `https://api.groq.com/openai/v1/chat/completions` |

**Headers:**
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer [YOUR_GROQ_API_KEY]"
}
```

**Body** (use dynamic content from trigger):
```json
{
  "model": "llama-3.3-70b-versatile",
  "messages": [
    {
      "role": "system",
      "content": "You are an expert email security analyst..."
    },
    {
      "role": "user",
      "content": "Forwarded by: @{triggerOutputs()?['body/from']}\nOriginal Subject: @{triggerOutputs()?['body/subject']}\nEmail Body:\n@{triggerOutputs()?['body/body']}"
    }
  ],
  "response_format": { "type": "json_object" }
}
```

> **Security:** Store the Groq API key as a **Power Automate Environment Variable** — do NOT hardcode it in the HTTP action.

### Step 6 — Parse the AI Response

Add a **"Parse JSON"** action.

- **Content:** Body output from the HTTP action
- **Schema:** Use the schema from [`../shared/ai-response-schema.json`](../shared/ai-response-schema.json)

This extracts: `verdict`, `threat_classification`, `indicators`, `recommendation`, `operator_insights`, `confidence_score`.

### Step 7 — Confidence Branching

Add a **Condition** action:

```
confidence_score is greater than or equal to 85
```

| Path | Action |
|------|--------|
| **≥ 85** (YES) | → Auto-send reply (Step 8A) |
| **< 85** (NO) | → Create draft + Teams notification (Step 8B) |

### Step 8A — Auto-Send (High Confidence)

Add **"Reply to email (V3)"** action:

| Field | Value |
|-------|-------|
| Message ID | From trigger |
| Subject | `[Company] Cybersecurity: ASSESSMENT – [Original Subject]` |
| Body (HTML) | See templates below |

### Step 8B — Draft for Review (Low Confidence)

Add **"Create draft (V3)"** action → Add **Teams notification** to alert the analyst.

### Step 9 — Verdict Routing

Add a **Switch** action on the `verdict` field:

| Case | Template |
|------|----------|
| `SAFE` | [`templates/safe.html`](templates/safe.html) |
| `SUSPICIOUS` | [`templates/suspicious-malicious.html`](templates/suspicious-malicious.html) |
| `MALICIOUS` | [`templates/suspicious-malicious.html`](templates/suspicious-malicious.html) |
| `ACKNOWLEDGEMENT` | [`templates/acknowledgement.html`](templates/acknowledgement.html) |

### Step 10 — Test the Flow

1. Send test email to `[security-inbox]@[company-domain].com`
2. Subject: `[ESL-AUTO] Test phishing email`
3. Go to **flow.microsoft.com** → your flow → **Run history**
4. Verify each step's input/output
5. Confirm reply was sent or draft created

---

## 📄 Flow Definition

A documented version of the flow is available at [`flow-definition.json`](flow-definition.json). This serves as a reference for rebuilding the flow or as infrastructure-as-code documentation.

---

## 📋 Verification Checklist

- [ ] Flow triggers on `[ESL-AUTO]` tagged emails
- [ ] Case-insensitive subject filter working
- [ ] Groq API returns 200 OK with valid JSON
- [ ] Parse JSON action extracts all 6 fields
- [ ] Confidence ≥85 → auto-send reply
- [ ] Confidence <85 → draft + Teams notification
- [ ] All 4 verdict templates render correctly
- [ ] HTML renders correctly in Outlook Web & Desktop
- [ ] Confidentiality footer present on all replies
- [ ] Groq API key stored as environment variable (not hardcoded)

---

## 🔒 Security Notes

- **API key:** Store in Power Automate Environment Variables — never in flow body
- **Scope:** Only acts on `[ESL-AUTO]` tagged emails
- **Human review:** Low-confidence results → draft mode (never auto-send)
- **Data minimization:** No email body content stored in logs
