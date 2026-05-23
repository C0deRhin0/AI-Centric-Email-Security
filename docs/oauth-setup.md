# n8n Microsoft OAuth Setup Guide

> Complete guide to configuring Microsoft OAuth2 for n8n's Outlook integration.
> Includes IT admin consent request template for enterprise tenants.

---

## 📋 Overview

For n8n to read from and send emails through your Outlook/Exchange mailbox, it needs OAuth 2.0 authorization via Microsoft Entra ID (formerly Azure Active Directory). This requires:

1. **Creating an Azure App Registration** — registers n8n as an authorized application
2. **Configuring API permissions** — defines what n8n can do (read/send mail)
3. **Connecting in n8n** — authorizes with your Microsoft account

---

## Step 1 — Azure App Registration

### 1.1 Navigate to Azure Portal

1. Go to [portal.azure.com](https://portal.azure.com)
2. Sign in with your Microsoft 365 account
3. Search for and select **Azure Active Directory** (or **Microsoft Entra ID**)

### 1.2 Register a New Application

1. In the left menu, click **App registrations** → **New registration**
2. Fill in:

   | Field | Value |
   |-------|-------|
   | **Name** | `ESL-n8n-Automation` (or any descriptive name) |
   | **Supported account types** | **"Accounts in this organizational directory only"** (single tenant) |
   | **Redirect URI** | `http://localhost:5678/rest/oauth2-credential/callback` |

3. Click **Register**

### 1.3 Note Application Credentials

After registration, the **Overview** page shows:
- **Application (Client) ID** — copy this
- **Directory (Tenant) ID** — copy this

### 1.4 Generate a Client Secret

1. In the left menu, click **Certificates & secrets** → **Client secrets** → **New client secret**
2. **Description:** `n8n-ESL-secret`
3. **Expires:** Choose a duration (recommend 12 or 24 months)
4. Click **Add**
5. **Immediately copy the secret value** (it is only shown once)

> ⚠️ Store the Client ID, Tenant ID, and Client Secret in a password manager. You will need all three in n8n.

---

## Step 2 — Configure API Permissions

1. In the left menu, click **API permissions** → **Add a permission**
2. Select **Microsoft Graph** → **Delegated permissions**
3. Add these 5 permissions:

   | Permission | Type | Purpose |
   |-----------|------|---------|
   | `Mail.Read` | Delegated | Read emails from your inbox |
   | `Mail.ReadWrite` | Delegated | Mark emails as read |
   | `Mail.Send` | Delegated | Send ESL reply emails |
   | `User.Read` | Delegated | Read your user profile |
   | `offline_access` | Delegated | Maintain session when you're away |

4. Click **Add permissions**

---

## Step 3 — Connect in n8n

1. In n8n (at `http://localhost:5678`):
   - Go to **Settings** (gear icon) → **Credentials** → **New Credential**
   - Search: **Microsoft Outlook OAuth2 API**
   - Fill in:

   | Field | Value |
   |-------|-------|
   | **Client ID** | Application (Client) ID from Azure |
   | **Client Secret** | Secret value from Azure |
   | **Tenant ID** | Directory (Tenant) ID from Azure |

2. Click **Connect my account**
3. A Microsoft login popup should appear:
   - Sign in with your work account (`[yourname]@[company-domain].com`)
   - Review the requested permissions
   - Click **Accept**

---

## ⚠️ Step 4 — Handling "Need Admin Approval"

### The Problem

Enterprise Microsoft 365 tenants often block user-initiated app consent entirely, even for delegated (non-admin) permissions. You'll see:

> **"Need Admin Approval"** — This app needs permission to access your organization's resources. Only an administrator can grant this permission.

### The Solution

You need an **Azure AD admin** to grant consent for your app registration.

### Option A: Direct Admin Consent (Preferred)

Send an IT/Azure admin this direct URL (replace bracketed values):

```
https://login.microsoftonline.com/[YOUR_TENANT_ID]/adminconsent
  ?client_id=[YOUR_CLIENT_ID]
  &redirect_uri=http://localhost:5678/rest/oauth2-credential/callback
```

The admin visits this URL, signs in, reviews the permissions, and clicks **Accept**.

### Option B: Admin Grants Consent in Azure Portal

Ask the admin to:

1. Go to **portal.azure.com** → **Azure Active Directory** → **App Registrations**
2. Find your app (`ESL-n8n-Automation` or whatever you named it)
3. Click **API Permissions**
4. Click **"Grant admin consent for [Your Company]"**
5. Click **Yes** to confirm

### Option C: Relax Tenant User Consent Policy (Not Recommended)

Ask the admin to:

1. Go to **portal.azure.com** → **Enterprise Applications** → **Security** → **Consent and permissions**
2. Under **User consent settings**, set to: **"Allow user consent for apps from verified publishers, for selected permissions"**
3. Save

> ⚠️ This affects all apps in the tenant — use with caution.

---

## 📝 IT Admin Consent Request Template

Copy-paste this message to your IT/Azure administrator:

---

**Subject:** Request: Admin Consent for Azure App Registration (n8n ESL Automation)

Hi,

I'm setting up an automated email security response tool (n8n) that connects to our Microsoft 365 tenant. I've already created an Azure App Registration called **[your-app-name]** (visible in Azure Portal → App Registrations).

I need you to grant admin consent for the app's permissions. Here are the two ways to do it:

**Option 1 — Grant admin consent directly (preferred, ~2 minutes):**
1. Go to portal.azure.com → Azure Active Directory → **App Registrations**
2. Find **[your-app-name]**
3. Click **API Permissions**
4. Click **"Grant admin consent for [Your Company]"**
5. Click **Yes** to confirm

**Option 2 — Direct consent URL:**
Visit this URL while signed in as admin:
`https://login.microsoftonline.com/[TENANT_ID]/adminconsent?client_id=[CLIENT_ID]&redirect_uri=http://localhost:5678/rest/oauth2-credential/callback`

**Permissions requested (all delegated — user-level only, not app-level):**
| Permission | Purpose |
|-----------|---------|
| `Mail.Read` | Read emails from my assigned mailbox |
| `Mail.ReadWrite` | Mark emails as read |
| `Mail.Send` | Send email replies through my account |
| `User.Read` | Read my profile |
| `offline_access` | Keep the connection active |

These permissions only act on behalf of my individual account (`[yourname]@[company-domain].com`) and do NOT grant application-level access to other users' mailboxes.

Please let me know once done. Thank you!

---

## ✅ After Admin Consent Is Granted

1. Return to n8n → **Settings** → **Credentials** → open the Microsoft Outlook credential
2. Click **"Connect my account"**
3. Sign in with your work account
4. The permissions consent screen should now allow you to click **Accept**
5. ✅ Credential status turns green — **Connected**

You can now proceed to build the full workflow.

---

## 🔄 Token Refresh

The `offline_access` permission allows n8n to automatically refresh the OAuth token when it expires. No additional configuration is needed — n8n handles this transparently as long as the credential remains connected.

---

## 🔒 Security Notes

| Item | Recommendation |
|------|---------------|
| **Client Secret** | Store in n8n's credential store only — never commit to code |
| **Scope** | Only 5 minimum-required delegated permissions |
| **Redirect URI** | Must be `http://localhost:5678/rest/oauth2-credential/callback` for local n8n |
| **Expiration** | Set a reminder to rotate Client Secret before it expires |
| **Rotation** | If secret is compromised, immediately create a new one in Azure and update n8n |
