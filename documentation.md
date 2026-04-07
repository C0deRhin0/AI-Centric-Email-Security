# ESL Automation — Documentation

> **Project:** AI-Centric Email Security Layer (ESL) Automation
> **Last Updated:** April 2026

---

## Phase 0 — Architecture & Foundation

### Day 1

#### Task 1 — ESL Trigger Contract

- **Subject tag convention:** `[ESL-AUTO]` (case-insensitive match)
- **Security inbox:** `security-inbox@company-domain.com` (placeholder)
- **Trigger rule:** Only emails with the tag in subject should initiate automation

**Reference:** See `docs/trigger-specification.md` for full rules and examples.

---

## Phase 1 — Approach A: Power Automate — Trigger & AI Integration

### Day 1

#### Task 1 — Create the Automated Cloud Flow

- **Flow name:** `ESL AI Automation`
- **Location:** `https://flow.microsoft.com` → Create → **Automated cloud flow**
- **Outcome:** New flow created and ready for trigger configuration

#### Task 2 — Add Outlook Trigger with Subject Filter

- **Trigger:** "When a new email arrives (V3)" (Outlook)
- **Folder:** Inbox
- **Subject filter:** `[ESL-AUTO]`
- **Outcome:** Flow triggers only on tagged emails

#### Task 3 — Add Case-Insensitive Trigger Expression

- **Expression:** `contains(toLower(triggerOutputs()?['body/subject']), '[esl-auto]')`
- **Usage:** Configure in trigger settings to enforce case-insensitive match
- **Outcome:** Trigger is resilient to subject casing variations

#### Task 4 — Add "Get Email (V2)" Metadata Extraction

- **Action:** "Get email (V2)"
- **Extracted fields:** From, Subject, Body, ReceivedDateTime
- **Outcome:** Email metadata captured as named dynamic content
