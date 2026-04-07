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
