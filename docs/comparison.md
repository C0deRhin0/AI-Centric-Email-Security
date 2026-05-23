# Power Automate vs n8n: ESL Automation Comparison

> Comprehensive comparison of Approach A (Power Automate) and Approach B (n8n) for the ESL email security automation.

---

## 1. Quick Comparison Table

| Dimension | Power Automate | n8n |
|-----------|---------------|-----|
| **Hosting** | Microsoft Cloud | Self-hosted (your PC, VPS, or n8n Cloud) |
| **Cost** | Included in M365 E3/E5 license | Free (open source); optional n8n Cloud ~$20/mo |
| **Setup Time** | ~2 hours | ~4 hours (includes Azure OAuth setup) |
| **Skills Required** | No coding — drag and drop | Basic JavaScript for Code node |
| **Always-On** | ✅ Yes (cloud-native, 24/7) | ⚠️ Only when PC is on; requires VPS for 24/7 |
| **Outlook Integration** | Native connector — one click | OAuth 2.0 — needs Azure App Registration |
| **Enterprise OAuth** | Not needed (native) | May need IT Admin consent if tenant blocks user consent |
| **Expression Syntax** | `@{triggerBody()?['field']}` | `{{ $('NodeName').item.json.field }}` |
| **Error Handling** | Configure Run After + Scope nodes | Error Trigger workflow |
| **Secrets Management** | Environment Variables | Credentials store |
| **Audit Logging** | SharePoint/Excel | Google Sheets/SQLite |
| **Extensibility** | Limited to Microsoft ecosystem | Full (HTTP, code, community nodes) |
| **Export/Import** | Solution export (.zip) | Clean JSON export (version-control friendly) |

---

## 2. Performance & Reliability

| Metric | Power Automate | n8n (Self-hosted) |
|--------|---------------|-------------------|
| **Trigger Latency** | Near real-time (push-based) | Up to 1 min (poll-based) |
| **Uptime** | 99.9% (Microsoft SLA) | Depends on host uptime |
| **Execution Timeout** | 30 days (long-running) | Configurable (default 5 min) |
| **Retry Policy** | Built-in (3 retries) | Configurable per node |
| **Rate Limiting** | M365 API limits | Ditto (same Microsoft Graph) |

### Key Differences in Trigger Mechanism

**Power Automate** uses a **push-based** trigger — Microsoft's infrastructure notifies the flow instantly when a new email arrives. There is essentially zero delay between email arrival and flow activation.

**n8n** uses a **poll-based** trigger — it checks the inbox every N minutes (default: 1 minute). This means:
- Worst-case delay: ~60 seconds
- Average delay: ~30 seconds
- Acceptable for non-time-critical security responses

> For most ESL use cases, a 30-60 second delay is acceptable. If sub-second latency is required, Power Automate is the better choice.

---

## 3. Cost Analysis

### Power Automate

| Item | Cost |
|------|------|
| M365 license (with Power Automate) | Already paid |
| Groq API (free tier) | $0 |
| SharePoint/Excel logging | Included |
| **Total** | **$0** |

### n8n (Self-hosted)

| Item | Cost |
|------|------|
| n8n software | $0 (open source) |
| Node.js runtime | $0 |
| PC electricity | ~$5-10/month (during work hours) |
| VPS alternative (24/7) | ~$5/month (DigitalOcean/Vultr) |
| n8n Cloud alternative | ~$20/month |
| **Total (self-hosted, work hours)** | **~$5-10/month** (electricity) |
| **Total (VPS, 24/7)** | **~$5-10/month** |
| **Total (n8n Cloud, 24/7)** | **~$20-30/month** |

---

## 4. Feature Parity

| Feature | Power Automate | n8n | Notes |
|---------|---------------|-----|-------|
| `[ESL-AUTO]` trigger | ✅ Native subject filter | ✅ Subject filter in trigger | Both support case-insensitive matching |
| Email metadata extraction | ✅ Get email (V2) action | ✅ Native trigger output | Both extract From, Subject, Body |
| Groq API call | ✅ HTTP action | ✅ HTTP Request node | Both support POST + auth headers |
| JSON response parsing | ✅ Parse JSON action | ✅ Code node (JS) | Both extract structured AI output |
| Verdict routing | ✅ Switch action | ✅ Switch node | Both support 4-branch routing |
| Confidence branching | ✅ Condition (auto/draft) | ❌ Needs additional IF node | n8n requires extra node for parity |
| HTML email body | ✅ Supported inline | ✅ Supported with toggle | Both produce identical templates |
| Always-On | ✅ Cloud-native | ⚠️ Requires setup | Power Automate wins here |
| Teams notification | ✅ Native Teams connector | ✅ Webhook node | Both can alert analysts |
| Audit logging | ✅ SharePoint/Excel | ✅ Google Sheets/SQLite | Feature parity; different backends |
| Version control | ❌ (solution export) | ✅ (JSON in git) | n8n workflow is git-friendly JSON |

---

## 5. When to Choose Which

### Choose Power Automate if:

- **You already have M365 E3/E5** with Power Automate access
- **You need near-real-time response** (push-based trigger)
- **You want zero infrastructure** — no servers, no setup
- **Your IT policies are restrictive** (no self-hosted tools allowed)
- **You need native Teams/SharePoint integration**
- **You want the fastest path to production** (~2 hours)

### Choose n8n if:

- **You want full control** over the automation stack
- **You need version-controllable workflows** (JSON in git)
- **You may migrate away from M365** in the future
- **You want to avoid cloud vendor lock-in**
- **You need flexibility** (JavaScript, community nodes, custom APIs)
- **You're willing to manage infrastructure** (or pay for n8n Cloud)

---

## 6. Migration Path

### Power Automate → n8n

If you start with Power Automate and later decide to migrate to n8n:

1. Export the Power Automate flow definition (see `approach-a-power-automate/flow-definition.json`)
2. Reference the node mapping table in `approach-b-n8n/README.md`
3. Import the pre-built workflow from `approach-b-n8n/workflow.json`
4. Configure OAuth and credentials
5. Test all 4 verdict branches for parity

### Key migration steps:

| Power Automate | → | n8n Equivalent |
|---------------|---|---|
| Trigger expression `toLower([ESL-AUTO])` | → | Subject filter `[ESL-AUTO]` |
| HTTP action body with `@{field}` | → | `{{ $('NodeName').item.json.field }}` |
| Parse JSON schema | → | `JSON.parse()` in Code node |
| Switch on verdict | → | Switch node with 4 cases |
| Reply to email (V3) | → | Outlook Send Email node |
| Environment Variables | → | Credentials store |

---

## 7. Running Both in Parallel

The recommended approach: **run both and compare**.

1. **Power Automate** as your primary (always-on, no infrastructure)
2. **n8n** as your secondary/backup (runs on PC during work hours)

This gives you:
- Zero-cost primary automation
- A validated backup if Power Automate is ever restricted
- Side-by-side performance data for future decisions

Both approaches consume the same `shared/` resources:
- [`shared/system-prompt.txt`](../shared/system-prompt.txt)
- [`shared/ai-response-schema.json`](../shared/ai-response-schema.json)
- [`shared/trigger-specification.md`](../shared/trigger-specification.md)
