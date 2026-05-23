# Troubleshooting Guide

> Common issues encountered during ESL automation setup and operation.
> Covers both Approach A (Power Automate) and Approach B (n8n).

---

## 🔴 Power Automate Issues

### Flow Does Not Trigger

**Symptom:** Emails with `[ESL-AUTO]` tag arrive in the security inbox but the flow does not fire.

**Possible Causes & Fixes:**

| Cause | Check | Fix |
|-------|-------|-----|
| Flow is turned off | Flow status in Power Automate | Toggle flow to **On** |
| Wrong folder | Trigger folder setting | Set to **Inbox** (not other folders) |
| Subject filter mismatch | Subject filter value | Must be exactly `[ESL-AUTO]` (with brackets) |
| Condition filter syntax | Filter expression | Ensure valid: `contains(toLower(...), '[esl-auto]')` |
| Account access | Flow owner's M365 account | Ensure account has access to the mailbox |
| Mailbox type | Shared vs user mailbox | Power Automate trigger works with both, but may need separate connector configuration |

### HTTP Action Fails (Groq API)

**Symptom:** Flow triggers but fails at the HTTP action step.

**Error:** `400 Bad Request` or `401 Unauthorized`

| Check | Fix |
|-------|-----|
| API key valid? | Regenerate at [console.groq.com](https://console.groq.com) |
| API key expired? | Check key creation date — Groq keys do not expire, but regenerate if unsure |
| Authorization header format | Must be: `Bearer sk-xxx...` (exact format) |
| Environment variable accessible? | Verify the environment variable name matches in the HTTP action |
| Model name correct? | Must be: `llama-3.3-70b-versatile` |
| Request body valid JSON? | Use a JSON validator to check for syntax errors |
| Rate limited (429)? | Check Groq console → Usage; wait 1 minute and retry |

### Parse JSON Action Fails

**Symptom:** HTTP action succeeds but "Parse JSON" fails.

| Cause | Fix |
|-------|-----|
| Schema mismatch | Update the schema to match the actual Groq response structure. Generate fresh schema from a sample response. |
| AI returned non-JSON | The Groq API with `response_format: json_object` should always return valid JSON. Check the raw HTTP response body in Run History. |
| Body is empty | Confirm the HTTP action received a response (status 200) |

### Teams Notification Not Sending

**Symptom:** Low-confidence flow reaches the draft path but Teams notification does not arrive.

| Check | Fix |
|-------|-----|
| Teams connector configured? | Add "Post message in a chat or channel" action |
| Channel/webhook URL correct? | Verify the Teams channel or chat ID |
| Flow service account permissions | The flow runs under your account — ensure it can post to Teams |
| Organization policy | Some organizations restrict Teams automation; check with IT |

---

## 🔴 n8n Issues

### n8n Won't Start

**Symptom:** `n8n` command fails or returns error.

```bash
Error: Cannot find module 'n8n'
```

| Cause | Fix |
|-------|-----|
| n8n not installed | Run: `npm install -g n8n` |
| Node.js not installed | Install from [nodejs.org](https://nodejs.org) (LTS version) |
| Node.js version too old | Minimum Node.js 18.x; upgrade to LTS |
| Port 5678 in use | Kill the process using port 5678 or change n8n's port with `n8n --port=5679` |
| Permission denied (macOS/Linux) | Run with `sudo npm install -g n8n` or fix npm permissions |

### OAuth Connection Fails

**Symptom:** Clicking "Connect my account" in n8n shows "Need Admin Approval."

**Solution:** See [`oauth-setup.md`](oauth-setup.md) for the complete admin consent request guide.

**Symptom:** OAuth popup opens but shows "Invalid redirect URI."

| Check | Fix |
|-------|-----|
| Redirect URI matches Azure | Must be exactly `http://localhost:5678/rest/oauth2-credential/callback` |
| Redirect URI was saved in Azure | Go to Azure → App Registrations → your app → **Authentication** → verify redirect URI |
| Trailing slash | Ensure no trailing slash in the URI |

**Symptom:** OAuth popup opens, I sign in, but get "AADSTS500113: No reply address registered."

| Cause | Fix |
|-------|-----|
| Redirect URI missing or wrong in Azure | Add the exact redirect URI to your app registration's **Authentication** → **Redirect URIs** |

### Outlook Trigger Fails

**Symptom:** The Outlook Trigger node shows an error when executed.

| Error | Cause | Fix |
|-------|-------|-----|
| `401 Unauthorized` | OAuth credential expired or invalid | Reconnect the credential in n8n → Settings → Credentials |
| `403 Forbidden` | Insufficient permissions | Verify the Azure app has all 5 delegated permissions |
| `404 Not Found` | Mailbox doesn't exist | Check the mailbox address in the node configuration |
| No results (but no error) | Poll interval too short, or no matching emails | Wait for next poll cycle (1 min) or reduce poll interval in advanced settings |
| `Resource not found for the segment 'messages'` | Using a shared mailbox incorrectly | Use the shared mailbox email address in the **Mailbox** field |

### HTTP Request Node Fails (Groq API)

**Symptom:** Groq API returns an error.

```json
{
  "error": {
    "message": "Invalid API key",
    "type": "invalid_request_error"
  }
}
```

| Check | Fix |
|-------|-----|
| API key stored correctly? | In n8n, use **Credentials → New Credential → Header Auth** to store the key; do NOT paste it directly into the node body |
| Header name correct? | Must be `Authorization` |
| Header value format? | Must be `Bearer sk-xxx...` |
| Body is valid JSON? | Validate the JSON body — check for template errors in the `{{ }}` expressions |

### Code Node Throws Error

**Symptom:** Code node execution fails.

```javascript
// Common errors:
TypeError: Cannot read properties of undefined (reading '0')
SyntaxError: Unexpected token u in JSON at position 0
```

| Cause | Fix |
|-------|-----|
| Groq response malformed | Add try/catch to the Code node (the importable workflow already includes this) |
| Expression syntax wrong | Use `$input.item.json.choices[0].message.content` to access Groq response |
| Return format wrong | Must be `return [{ json: parsed }];` — not `return parsed;` |

**Working Code Node template:**
```javascript
const raw = $input.item.json.choices[0].message.content;
let parsed;
try {
  parsed = JSON.parse(raw);
} catch (e) {
  parsed = {
    verdict: 'ACKNOWLEDGEMENT',
    threat_classification: 'Unknown',
    indicators: ['AI response could not be parsed'],
    recommendation: 'A team member will review this email manually.',
    operator_insights: 'The AI analysis returned an unparseable response.',
    confidence_score: 0
  };
}
return [{ json: parsed }];
```

### Send Email Node Fails

**Symptom:** Send Email node shows error after Switch node executes.

| Error | Cause | Fix |
|-------|-------|-----|
| `The from address doesn't match the mailbox` | The OAuth credential is for a different mailbox | Use the same mailbox in Send Email as the one authorized via OAuth |
| `Error: Message exceeds max size` | Email body too large | Check HTML template size; reduce inline CSS if necessary |
| Empty `To` field | Expression not resolving | Check: `{{ $('Outlook Trigger').item.json.from }}` — verify the node name matches exactly |

---

## 🔴 Cross-Cutting Issues

### Email Body Contains Raw JSON

**Symptom:** The reply email body shows raw JSON instead of rendered HTML.

| Cause | Fix |
|-------|-----|
| Body format set to Text instead of HTML | Change to **HTML** |
| Template variable not replaced | Check for unrendered `@{field}` (Power Automate) or `{{ field }}` (n8n) placeholders in the sent email |

### Low-Confidence Notifications Not Received

**Symptom:** AI returns < 85% confidence but no notification or draft is created.

| Power Automate | n8n |
|---------------|-----|
| Check the Condition action — confirm it's reading `confidence_score` from Parse JSON output | n8n doesn't have native confidence branching — add an IF node between Code and Switch nodes |
| Verify the Condition expression: `@greaterOrEquals(body('Parse_JSON')?['confidence_score'], 85)` | Consider adding a Code node that routes based on score |

### HTML Templates Look Wrong in Outlook

**Symptom:** Email renders correctly in Gmail/Apple Mail but looks broken in Outlook.

| Issue | Fix |
|-------|-----|
| Outlook ignores `<style>` blocks | Use **inline CSS only** — no `<style>` tags |
| Background colors missing | Apply `background-color` to `<table>` and `<td>` elements, not `<body>` |
| Padding/margin differences | Use `<table>` for layout — avoid `<div>` based layouts |
| Font rendering | Use web-safe fonts: `'Segoe UI', Arial, Helvetica, sans-serif` |
| Images blocked | Don't rely on images for critical information (Outlook blocks images by default) |

---

## 🔧 Diagnostic Checklist

Use this checklist when troubleshooting:

1. **Is the flow/workflow active?** (Power Automate: On / n8n: Active toggle)
2. **Did the trigger fire?** (Check Run History / Execution List)
3. **Did the Groq API call succeed?** (Status 200? JSON response valid?)
4. **Was the JSON parsed correctly?** (All 6 fields present?)
5. **Was the correct template selected?** (Verdict match?)
6. **Was the email sent/drafted?** (Check Sent Items / Drafts folder)
7. **Did the recipient get it?** (Check recipient's inbox)
8. **Does the HTML render correctly?** (Check Outlook Web + Desktop)

---

## 📞 Getting Help

| Resource | Where |
|----------|-------|
| **Groq API Status** | [status.groq.com](https://status.groq.com) |
| **Groq Console** | [console.groq.com](https://console.groq.com) |
| **n8n Documentation** | [docs.n8n.io](https://docs.n8n.io) |
| **Power Automate Docs** | [learn.microsoft.com/power-automate](https://learn.microsoft.com/en-us/power-automate/) |
| **Outlook HTML Email Guide** | [htmlemail.io](https://htmlemail.io) |
