# Approach B: n8n — ESL Automation

> **Status:** ✅ Complete (Workflow designed, OAuth process documented)  
> **Tool:** n8n (self-hosted) + Microsoft Outlook + Groq API (Free Tier)  
> **Setup Time:** ~4 hours (includes Azure OAuth setup)  
> **Cost:** $0 (self-hosted, open source)

---

## 📋 Overview

This approach uses **n8n**, an open-source workflow automation tool, to replicate the ESL email security automation. n8n runs on your own infrastructure (PC, VPS, or n8n Cloud) and provides a visual node-based canvas that mirrors the Power Automate flow.

### Why n8n?

| Feature | Power Automate | n8n |
|---------|---------------|-----|
| Hosting | Microsoft Cloud | Your own PC / server |
| Cost | Included in M365 | Free (open source) |
| Full Control | Limited | Complete |
| No M365 Dependency | ❌ | ✅ |
| Outlook Integration | Native (seamless) | OAuth 2.0 (needs setup) |

---

## 🚀 Step-by-Step Setup

### Prerequisites

| Requirement | Details |
|-------------|---------|
| Node.js LTS | Download from [nodejs.org](https://nodejs.org) |
| Microsoft 365 Account | For Outlook access (needs OAuth) |
| Groq API Key | From [console.groq.com](https://console.groq.com) — free |
| IT Admin Assistance | Required for OAuth consent (see below) |

### Phase 1 — Install n8n

```bash
# Install n8n globally
npm install -g n8n

# Start n8n
n8n
```

Open [http://localhost:5678](http://localhost:5678) in your browser and create a local account.

> ⚠️ n8n only runs while the terminal is open. See Phase 5 for always-on options.

### Phase 2 — Workflow Mapping

The n8n workflow mirrors the Power Automate flow exactly:

| Power Automate | n8n Equivalent |
|---------------|----------------|
| "When a new email arrives (V3)" | Outlook Trigger Node |
| HTTP action | HTTP Request Node |
| Parse JSON | Code Node (JavaScript) |
| Condition + Switch | Switch Node |
| "Reply to email (V3)" | Outlook → Send Email Node |
| `@{field}` expression | `{{ $('NodeName').item.json.field }}` |

### Phase 3 — Microsoft OAuth Setup

This is the **most involved step**. n8n needs permission to read and send emails from your Outlook inbox via OAuth.

#### Step 1 — Azure App Registration

1. Go to [portal.azure.com](https://portal.azure.com)
2. Navigate to **Azure Active Directory** → **App Registrations** → **New Registration**
3. **Name:** `ESL-n8n-Automation`
4. **Supported account types:** "Accounts in this organizational directory only"
5. **Redirect URI:** `http://localhost:5678/rest/oauth2-credential/callback`
6. Click **Register**

#### Step 2 — API Permissions

Add these **delegated permissions** under Microsoft Graph:

| Permission | Purpose |
|-----------|---------|
| `Mail.Read` | Read emails from security inbox |
| `Mail.ReadWrite` | Mark emails as read |
| `Mail.Send` | Send ESL reply emails |
| `User.Read` | Read user profile |
| `offline_access` | Maintain persistent session |

#### Step 3 — Create n8n Credential

1. In n8n: **Settings** → **Credentials** → **New Credential**
2. Search: **Microsoft Outlook OAuth2 API**
3. Enter **Client ID**, **Client Secret**, and **Tenant ID** from Azure
4. Click **Connect my account**

#### ⚠️ Common Blocker: IT Admin Consent

If your organization blocks user consent, you'll see a **"Need Admin Approval"** screen. See [`../docs/oauth-setup.md`](../docs/oauth-setup.md) for the full IT admin consent request template.

### Phase 4 — Import the Workflow

The workflow is pre-built and ready to import:

1. In n8n: **Workflows** → **Import from File**
2. Select [`workflow.json`](workflow.json) from this directory
3. Configure:
   - **Outlook Trigger:** Your OAuth credential, mailbox address
   - **HTTP Request:** Your Groq API key credential
   - **Send Email nodes:** Your OAuth credential

### Phase 5 — Always-On Configuration

n8n only runs while the process is alive. Choose your uptime strategy:

| Option | Cost | Uptime | Complexity |
|--------|------|--------|------------|
| [Windows Task Scheduler](scripts/setup-n8n.ps1) | Free | PC-on hours only | Low |
| [Linux VPS + pm2](scripts/setup-n8n.sh) | ~$5/month | 24/7 | Medium |
| n8n Cloud | ~$20/month | 24/7 managed | Low (import workflow) |

---

## 📋 Verification Checklist

- [ ] n8n running at `http://localhost:5678`
- [ ] Microsoft OAuth credential shows green "Connected" status
- [ ] Workflow imports without errors
- [ ] Outlook Trigger node fires on `[ESL-AUTO]` emails
- [ ] Groq API returns 200 OK with valid JSON
- [ ] Code Node parses response without errors
- [ ] Switch Node routes to correct branch by verdict
- [ ] HTML templates render correctly in Outlook client
- [ ] All 4 verdict branches send correct replies
- [ ] Workflow activated (toggle from Inactive → Active)

---

## 🔒 Security Notes

- **Groq API key:** Store in n8n's Credentials store (Header Auth) — never in node config
- **OAuth scope:** Only 5 delegated permissions — no app-level access
- **Secrets:** Client Secret stored only in n8n credentials, never in code
- **Human review:** Low-confidence responses routed to draft/notification

> 📖 **Detailed guide & walkthrough:** See [`../docs/oauth-setup.md`](../docs/oauth-setup.md) for the complete OAuth setup with IT admin consent request template.
