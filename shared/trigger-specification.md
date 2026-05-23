# ESL Trigger Specification

> Defines the trigger contract for the Email Security Layer (ESL) automation system.
> Applies to both Approach A (Power Automate) and Approach B (n8n).

---

## 1. Trigger Condition

The automation activates **only** when an email arrives in the security inbox that matches **all** of the following conditions:

| Condition | Value | Notes |
|-----------|-------|-------|
| Recipient Inbox | `security-inbox@[company-domain].com` | The designated security forwarding address |
| Subject Tag | `[ESL-AUTO]` | Case-insensitive match |
| Email Origin | Any internal or external sender | Tag-and-forward model ensures analyst intent |

### Subject Tag Matching Rules

- **Tag format:** `[ESL-AUTO]` — square brackets, hyphen, uppercase letters
- **Match type:** Case-insensitive substring match
- **Examples that trigger:**
  - `[ESL-AUTO] Suspicious email received`
  - `[esl-auto] FW: phishing attempt`
  - `[Esl-Auto] Urgent: CEO impersonation`
- **Examples that do NOT trigger:**
  - `ESL-AUTO` (missing brackets)
  - `[ESL] Suspicious email` (wrong tag)
  - `[ESL-AUTO-SUSPICIOUS]` (modified tag format)
  - `RE: [ESL-AUTO] ...` (⚠️ forwarded/replied emails — see edge case below)

### Case-Insensitive Filter Expression

Both platforms implement this via a case-normalization expression:

**Power Automate:**
```powerautomate
contains(toLower(triggerOutputs()?['body/subject']), '[esl-auto]')
```

**n8n:**
```javascript
// Applied in the Outlook Trigger node subject filter field
// n8n's Outlook trigger handles case-insensitive matching natively
[ESL-AUTO]
```

---

## 2. Edge Cases & Handling

| Edge Case | Behavior | Notes |
|-----------|----------|-------|
| **Email in reply chain** contains `[ESL-AUTO]` in subject | ⚠️ May re-trigger if the automated reply subject also contains this tag | Mitigation: Auto-reply subjects should NOT include `[ESL-AUTO]` — use `ASSESSMENT` instead |
| **Multiple `[ESL-AUTO]` emails arrive simultaneously** | Both triggers fire independently | Power Automate handles parallel execution; n8n processes sequentially per poll cycle |
| **Email has `[ESL-AUTO]` but body is empty** | Trigger fires, Groq API receives empty body | The system prompt instructs the AI to handle minimal input gracefully |
| **Non-Latin characters in subject/body** | Treated as plain text by trigger and Groq API | No special handling needed — the system prompt is English-only, but input encoding is universal |
| **Tag appears in body but not subject** | ❌ Does NOT trigger | The trigger only checks the subject line, not body content |

---

## 3. Trigger Configuration Reference

### Power Automate (Approach A)

```json
{
  "trigger": {
    "type": "When a new email arrives (V3)",
    "connector": "Outlook",
    "folder": "Inbox",
    "subjectFilter": "[ESL-AUTO]",
    "includeAttachments": false,
    "filterExpression": "contains(toLower(triggerOutputs()?['body/subject']), '[esl-auto]')"
  }
}
```

### n8n (Approach B)

```json
{
  "node": "Microsoft Outlook Trigger",
  "operation": "On Message Received",
  "mailbox": "security-inbox@[company-domain].com",
  "subjectFilter": "[ESL-AUTO]",
  "pollInterval": 1,
  "pollUnit": "minute"
}
```

---

## 4. Security Inbox Address

| Detail | Value |
|--------|-------|
| **Default address** | `security-inbox@[company-domain].com` |
| **Replace `[company-domain]` with** | Your organization's actual domain |
| **Shared or user mailbox** | Works with both — configure accordingly |
| **Forwarding setup** | Employees forward suspicious emails to this address with the `[ESL-AUTO]` subject tag |

---

## 5. Testing the Trigger

To verify the trigger is working:

1. Send an email from any test account to `security-inbox@[company-domain].com`
2. Set subject to: `[ESL-AUTO] Test email — please ignore`
3. Verify:
   - **Power Automate:** Flow appears in **Run History** with a successful trigger
   - **n8n:** Workflow execution log shows the trigger node fired
4. If the trigger did not fire, check:
   - Subject tag is correctly formatted with brackets
   - Email arrived in the correct inbox folder
   - Flow/workflow is in **Active/On** state
   - (n8n only) OAuth credential is green/connected
