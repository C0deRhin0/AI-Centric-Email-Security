# System Architecture

> Deep-dive into the Email Security Layer (ESL) automation architecture.
> Covers system design, data flow, decisions, and trade-offs for both approaches.

---

## 1. System Overview

The ESL automation is a **3-stage pipeline**:

```
┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
│    TRIGGER   │────▶│  AI ANALYSIS │────▶│ AUTOMATED REPLY  │
│  (Inbound    │     │  (Groq API)  │     │  (ESL Templates) │
│   Email)     │     │              │     │                  │
└──────────────┘     └──────────────┘     └──────────────────┘
```

### Stage 1 — Trigger

The system watches the corporate security inbox (`security-inbox@company.com`) and activates when an email arrives with `[ESL-AUTO]` in the subject line.

- **Power Automate:** Uses Outlook connector's "When a new email arrives (V3)" trigger with a subject filter and case-insensitive expression
- **n8n:** Uses Microsoft Outlook Trigger node polling at 1-minute intervals with subject filter

### Stage 2 — AI Analysis

The email content (sender, subject, body) is sent to Groq API with a structured system prompt that instructs LLaMA 3.3-70B to:

1. Analyze heuristic indicators (sender mismatch, urgency, attachments, etc.)
2. Check hyperlink/URL red flags
3. Evaluate OSINT / domain reputation
4. Assess header authentication (SPF/DKIM/DMARC)

The AI returns a structured JSON response with verdict, threat classification, indicators, recommendation, operator insights, and confidence score.

### Stage 3 — Automated Reply

Based on the AI verdict and confidence score:

| Condition | Action |
|-----------|--------|
| Confidence ≥ 85% | Auto-send ESL-formatted reply |
| Confidence < 85% | Create draft + notify analyst for review |
| MALICIOUS verdict | Same as above + domain block notification |

The reply is sent using one of four ESL Playbook templates (ACKNOWLEDGEMENT, SAFE, SUSPICIOUS, MALICIOUS).

---

## 2. Data Flow Diagram

### Power Automate (Approach A)

```
Outlook ──[new email]──▶ Power Automate ──[HTTP POST]──▶ Groq API
                           │                                  │
                           │                            [JSON Response]
                           │                                  │
                           ▼                                  ▼
                     Confidence ≥ 85? ◀─────────── Parse JSON
                        │          │
                     YES │          │ NO
                        ▼          ▼
                 Switch on    Create Draft
                 verdict      + Teams Notify
                  │   │  │         │
                  ▼   ▼  ▼         ▼
              ACK  SAFE  SUS/    Analyst
                         MAL      Review
                  │   │  │
                  ▼   ▼  ▼
              Reply to Email (V3)
```

### n8n (Approach B)

```
Outlook ──[poll every 1 min]──▶ n8n ──[HTTP Request]──▶ Groq API
                                  │                          │
                                  │                    [JSON Response]
                                  │                          │
                                  ▼                          ▼
                            Code Node ◀────────── JSON.parse()
                                  │
                                  ▼
                            Switch on verdict
                          │   │   │   │
                          ▼   ▼   ▼   ▼
                        ACK SAFE SUS MAL
                          │   │   │   │
                          ▼   ▼   ▼   ▼
                     Outlook Send Email (per branch)
```

---

## 3. Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| April 2026 | **Groq API (free tier) over Azure OpenAI** | Groq offers `llama-3.3-70b` at 30 req/min, 14,400 req/day at no cost. Azure OpenAI requires paid subscription and credit card. |
| April 2026 | **Develop Power Automate first** | Already included in M365 license — fastest path to functional flow. |
| April 2026 | **Develop n8n in parallel** | Self-hosted independence, backup capability, cross-platform benchmarking. |
| April 2026 | **85% confidence threshold** | Keeps human in the loop for ambiguous cases; reduces false-positive auto-sends. |
| April 2026 | **Metadata-only audit logging** | Privacy-by-design principle. Email body content is ephemeral and should not be persisted. |
| April 2026 | **No auto-domain-blocking** | False positives could disrupt business operations. MALICIOUS verdicts flag for human review. |

---

## 4. Technology Choices

### AI Backend

| Criteria | Groq | Azure OpenAI | Perplexity |
|----------|------|-------------|------------|
| Cost | Free (30 req/min) | Paid (subscription) | Paid |
| Model | LLaMA 3.3-70B | GPT-4o / GPT-4 | Sonar |
| Structured Output | `json_object` mode | `json_object` mode | Limited |
| Rate Limit | 14,400/day | Varies by tier | Varies |
| Credit Card Required | No | Yes | Yes |

### Approach Comparison

| Dimension | Power Automate | n8n |
|-----------|---------------|-----|
| **Deployment** | Cloud (Microsoft-managed) | Self-hosted (your infrastructure) |
| **Cost** | Included in M365 | Free & open source |
| **Time to Production** | ~2 hours | ~4 hours (OAuth + setup) |
| **Always-On** | Inherent (cloud) | Requires Task Scheduler or VPS |
| **Outlook Integration** | Native (one-click) | OAuth 2.0 (requires Azure App Registration) |
| **Expression Syntax** | `@{triggerBody()?['field']}` | `{{ $('NodeName').item.json.field }}` |
| **Template Format** | HTML in action body | HTML in node configuration |
| **Error Handling** | Configure Run After + Scope | Error Trigger workflow |
| **Secrets Management** | Environment Variables | Credentials store |

---

## 5. JSON Schema

The shared AI response schema is defined at [`../shared/ai-response-schema.json`](../shared/ai-response-schema.json).

```json
{
  "verdict": "SAFE | SUSPICIOUS | MALICIOUS | ACKNOWLEDGEMENT",
  "threat_classification": "Phishing | Spam | Malware | BEC | Legitimate",
  "indicators": ["array of detected red flags"],
  "recommendation": "string — action for the employee",
  "operator_insights": "string — professional paragraph for email body",
  "confidence_score": "integer 0-100"
}
```

---

## 6. Error Handling Strategy

| Failure Mode | Power Automate | n8n |
|-------------|---------------|-----|
| **Groq API timeout** | Configure Run After on HTTP action → fallback Teams alert | Error Trigger workflow → log + notify |
| **Malformed AI response** | Parse JSON action fails → default to draft + notify | Code node try/catch → default output |
| **Network outage** | Flow retries (Power Automate built-in) | Workflow execution error → retry policy |
| **OAuth token expired** | Not applicable (native connector) | n8n auto-refreshes with `offline_access` scope |
| **Rate limit hit (429)** | Flow fails → configured retry | HTTP Request node → automatic retry |

---

## 7. Security Model

```
┌─────────────────────────────────────────────────────────────┐
│                    SECURITY BOUNDARY                          │
│                                                               │
│  ╔═══════════════════════════════════════════════════════╗    │
│  ║                 CORPORATE NETWORK                      ║    │
│  ║                                                        ║    │
│  ║  Employee ──▶ Security Inbox ──▶ Automation ──▶ Reply  ║    │
│  ║       │                            │                    ║    │
│  ║       ▼                            ▼                    ║    │
│  ║  [ESL-AUTO] tag              Groq API (external)        ║    │
│  ║  required for trigger         (only metadata sent)      ║    │
│  ╚═══════════════════════════════════════════════════════╝    │
│                                                               │
│  • API keys stored in platform secrets (never in code)        │
│  • Email body NOT stored in logs (metadata only)              │
│  • No auto-blocking without human approval                    │
│  • Draft mode for low-confidence results                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 8. Monitoring & Observability

| Metric | Power Automate | n8n |
|--------|---------------|-----|
| Trigger latency | Run History → trigger timestamp | Execution list → started timestamp |
| AI response time | HTTP action duration | Node execution time |
| Success rate | Run History → status column | Execution list → success/failure |
| Per-verdict volume | (Optional) SharePoint log | (Optional) Google Sheets log |
| Error tracking | Run History → failed runs | Execution list → error node |
