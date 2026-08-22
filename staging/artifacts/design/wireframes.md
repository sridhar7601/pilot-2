---
produced_by: architect
requirement_ids: [REQ-EXP-1, REQ-EXP-2, REQ-EXP-3, REQ-EXP-4, REQ-EXP-5, REQ-AUTH-1]
date: 2026-06-23
sources:
  - "Design-Document_Final.pdf — Expense Management & Reimbursement Platform (June 2026)"
  - "staging/requirements/expense-*.feature"
  - "staging/artifacts/design/architecture.md"
derivation: "Wireframe descriptions derived from SOW screen list, Gherkin acceptance criteria, and component architecture"
confidence: high
verified_by:
---

# Wireframes — Expense Management & Reimbursement Platform

> **Traceability:** REQ-AUTH-1 (Screen 0) · REQ-EXP-1 (Screens 1–3) · REQ-EXP-2 (Screens 4–5) · REQ-EXP-5 (Screen 6) · REQ-EXP-4 (Screen 7) · REQ-EXP-3 (Screens 8–9)

---

## Conventions

- Layouts use ASCII art with `[Button]`, `(input)`, `{section}`, `|col|` notation.
- **Edge-case banners** appear below each screen using `⚠ EDGE CASE:` prefix.
- All screens sit inside a **global shell** (nav bar + user avatar + role badge).

---

## Global Shell

```
┌─────────────────────────────────────────────────────────────────────┐
│ [≡ Logo]   Expenses   Approvals   Analytics   Admin        [👤 J.D.] │
│                                                         [Role: Finance]│
└─────────────────────────────────────────────────────────────────────┘
```

- Nav items rendered per role: Employee sees Expenses only; Approver sees + Approvals; Finance sees + Analytics; Admin sees + Admin.
- Role badge shown at all times; switches automatically on re-login if IdP claims change.

---

## Screen 0 — Login (SSO / Entra ID)  `REQ-AUTH-1`

```
┌────────────────────────────────────────────────────────┐
│                                                        │
│              ┌────────────────────────┐               │
│              │   [Company Logo]       │               │
│              │                        │               │
│              │  Expense Management    │               │
│              │  Platform              │               │
│              │                        │               │
│              │  [Sign in with         │               │
│              │   Microsoft]           │               │
│              │                        │               │
│              │  ─────────── or ────── │               │
│              │                        │               │
│              │  [Demo login ▾]        │               │ ← Pilot only; hidden in prod
│              └────────────────────────┘               │
│                                                        │
│            Secure sign-in · No password stored         │
└────────────────────────────────────────────────────────┘
```

**Components:**
- `MicrosoftSignInButton` — initiates OIDC auth-code + PKCE flow against Entra ID
- `DemoLoginDropdown` — select pre-configured demo role (Employee / Approver / Finance / Admin); visible only when `PILOT_DEMO_AUTH=true`
- `ErrorBanner` — shown on auth failure (e.g., account not in tenant)

**Interaction flow:** Click → redirect to Entra ID login page → OIDC callback → JWT validated → role extracted from claims → redirect to role-default home screen.

⚠ **EDGE CASE — Account not in tenant:** Show `"Your account is not authorised for this application. Contact your IT administrator."` — no internal error details exposed.

⚠ **EDGE CASE — Token expired mid-session:** Silent refresh attempted via iframe; if fails, full re-login prompted with session-expiry toast.

⚠ **EDGE CASE — Role claim missing:** User lands on a minimal screen with `"Your account has no assigned role. Contact your admin."` — no data access granted.

---

## Screen 1 — Employee Dashboard  `REQ-EXP-1, REQ-EXP-4, REQ-AUTH-1`

```
┌─────────────────────────────────────────────────────────────────────┐
│ [≡ Logo]   Expenses                                      [👤 J. Doe] │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Good morning, Jane.                   [+ New Expense]             │
│                                                                     │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌───────────┐  │
│  │ Submitted    │ │ In Approval  │ │ Approved     │ │ Paid      │  │
│  │     3        │ │      2       │ │      1       │ │    5      │  │
│  └──────────────┘ └──────────────┘ └──────────────┘ └───────────┘  │
│                                                                     │
│  Recent Expenses                          [Filter ▾] [Search (   )] │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ # │ Date       │ Merchant          │ Amount  │ Status       │   │
│  ├───┼────────────┼───────────────────┼─────────┼──────────────┤   │
│  │ 1 │ 2026-06-20 │ Acme Hotels       │ $210.00 │ 🟡 In Apprvl │   │
│  │ 2 │ 2026-06-18 │ Delta Airlines    │ $345.50 │ 🟢 Approved  │   │
│  │ 3 │ 2026-06-15 │ Marriott          │ $189.00 │ 🔴 Returned  │   │
│  │ 4 │ 2026-06-10 │ Uber              │  $24.00 │ ✅ Paid      │   │
│  └──────────────────────────────────────────────────────────────┘   │
│  [Load more]                                                        │
│                                                                     │
│  Upcoming Reimbursements                                            │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │  Expected payout:  Jun 28, 2026   •   Amount: $345.50      │     │
│  └────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
```

**Components:**
- `StatusSummaryCards` — count of expenses per lifecycle status; clickable to filter table
- `ExpenseTable` — paginated, filterable by date range / status / category; each row links to Screen 3
- `UpcomingReimbursementBanner` — shows next predicted payout date and amount

⚠ **EDGE CASE — No expenses:** Empty state illustration + `"Submit your first expense"` CTA.

⚠ **EDGE CASE — Returned expense:** Row highlighted red; inline `"Action required"` badge; click navigates to Screen 3 with edit form pre-opened.

⚠ **EDGE CASE — Duplicate detection warning:** Yellow banner above table if any submitted expense is flagged as possible duplicate.

---

## Screen 2 — New Expense  `REQ-EXP-1, REQ-EXP-3`

```
┌─────────────────────────────────────────────────────────────────────┐
│ ← Back    New Expense                                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Step 1 of 3: Receipt Upload          Step 2: Details   Step 3: Submit│
│  ══════════════════════════════════   ─────────────     ──────────  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                                                             │    │
│  │          ┌────────────────────────────────┐                │    │
│  │          │  📎 Drop receipt here           │                │    │
│  │          │     or [Browse files]           │                │    │
│  │          │     JPG / PNG / PDF · max 10 MB │                │    │
│  │          └────────────────────────────────┘                │    │
│  │                                                             │    │
│  │  ─────── After upload: AI extraction result ──────────     │    │
│  │                                                             │    │
│  │  Merchant   [ Acme Restaurant            ] ●●●●○ 87%       │    │
│  │  Date       [ 2026-06-20                 ] ●●●●● 99%       │    │
│  │  Amount     [ $45.00                     ] ●●●●● 98%       │    │
│  │  Currency   [ USD                        ] ●●●●● 99%       │    │
│  │  Category   [ Meals & Entertainment  ▾   ] ●●●○○ 71% ⚠     │    │
│  │                                                             │    │
│  │  ⚠ Low confidence on Category — please verify             │    │
│  │                                                             │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                     │
│  Description  (                                              )      │
│  Cost Centre  [ Engineering - Q2 ▾                          ]      │
│                                                                     │
│  + Add line item     + Split across cost centres                    │
│                                                                     │
│  ─────── Policy Check ──────────────────────────────────────────    │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ ✅ PASS — Meal within $75 per-person limit                   │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                     │
│                            [Save Draft]  [Submit Expense]           │
└─────────────────────────────────────────────────────────────────────┘
```

**Components:**
- `ReceiptDropzone` — drag-and-drop or file picker; validates file type and size client-side
- `ExtractionResultForm` — pre-filled form fields with per-field confidence progress bars; low-confidence fields highlighted amber
- `ConfidenceBadge` — `●●●●○` visual with percentage; fields below 80% show ⚠ icon
- `PolicyVerdictBanner` — shows `PASS` (green) / `WARN` (amber) / `BLOCK` (red) with AI-generated plain-language explanation
- `LineItemList` — expandable; each line item has its own category, amount, cost centre
- `CostCentreSplitModal` — triggered by "Split across cost centres"

**State machine:** `idle → uploading → extracting → review → (policy_check) → submitting → submitted`

⚠ **EDGE CASE — Extraction failure:** `extracting` times out after 30 s; show `"AI extraction unavailable — please fill in manually"` banner; form unlocked for manual entry; image retained.

⚠ **EDGE CASE — Policy BLOCK:** `Submit Expense` button disabled; red banner with explanation; `[Request Exception]` link shown.

⚠ **EDGE CASE — Policy WARN:** Amber banner shown; `Submit Expense` remains enabled; employee must check confirmation checkbox before proceeding.

⚠ **EDGE CASE — Duplicate detected:** After policy check, yellow banner `"This looks like a duplicate of Expense #42 (Jun 10)"` with `[View original]` link; employee must acknowledge before submitting.

⚠ **EDGE CASE — File too large:** Instant client-side rejection with `"File exceeds 10 MB limit. Please compress or scan at lower DPI."`.

---

## Screen 3 — Expense Detail  `REQ-EXP-1, REQ-EXP-2, REQ-EXP-4`

```
┌─────────────────────────────────────────────────────────────────────┐
│ ← Back    Expense #EXP-2024-0047 · Acme Restaurant · $45.00        │
│           Status: 🟡 In Approval                                    │
├──────────────────────────────────────┬──────────────────────────────┤
│  EXPENSE DETAILS                     │  RECEIPT                    │
│                                      │  ┌──────────────────────┐   │
│  Merchant    Acme Restaurant         │  │                      │   │
│  Date        2026-06-20              │  │  [Receipt thumbnail] │   │
│  Amount      $45.00 USD              │  │                      │   │
│  Category    Meals & Entertainment   │  │  [View full size ↗]  │   │
│  Cost Centre Engineering - Q2        │  └──────────────────────┘   │
│  Description Team lunch              │                             │
│  Policy      ✅ PASS                 │  AI Extraction Confidence   │
│                                      │  Merchant  ●●●●○ 87%        │
│  ─── Line Items ──────────────────── │  Date      ●●●●● 99%        │
│  1 · Team lunch · $45.00 · Eng Q2   │  Amount    ●●●●● 98%        │
│                                      │                             │
├──────────────────────────────────────┴──────────────────────────────┤
│  APPROVAL TIMELINE                                                  │
│                                                                     │
│  ● 2026-06-20 14:32  Submitted by Jane Doe                          │
│  ● 2026-06-20 14:32  Policy evaluated: PASS                         │
│  ○ 2026-06-21 09:00  Awaiting approval — Bob Smith (Manager)        │
│    SLA due: 2026-06-23  [2 days remaining]                          │
│  ○ ···  Finance approval (pending prior step)                       │
│                                                                     │
│  Predicted payout date:  Jun 28, 2026                               │
│                                                                     │
│  [Edit Expense]  (only if status = draft | returned_for_edit)       │
└─────────────────────────────────────────────────────────────────────┘
```

**Components:**
- `ExpenseMetadataPanel` — read-only fields panel (left)
- `ReceiptPreviewPanel` — thumbnail with full-size modal; per-field confidence sidebar (right)
- `ApprovalTimeline` — vertical stepper; completed steps solid circle, pending hollow; SLA countdown badge
- `PayoutDateBadge` — projected date computed from chain step SLAs
- `EditExpenseButton` — enabled only when `status ∈ {draft, returned_for_edit}`

⚠ **EDGE CASE — Expense rejected:** Red `REJECTED` status chip; rejection comment shown inline in timeline; `[Resubmit]` button shown.

⚠ **EDGE CASE — SLA at risk:** SLA badge turns amber (< 24 h) then red (overdue); tooltip explains escalation path.

⚠ **EDGE CASE — Receipt unavailable (S3 error):** Receipt panel shows `"Receipt temporarily unavailable"` with retry link; expense data still accessible.

⚠ **EDGE CASE — Returned for edit:** Yellow banner `"Returned by Bob Smith: [comment]"` at top; `[Edit Expense]` CTA highlighted.

---

## Screen 4 — Approver Queue  `REQ-EXP-2`

```
┌─────────────────────────────────────────────────────────────────────┐
│ [≡ Logo]   Approvals (7 pending)                         [👤 B. Smith]│
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌────────────────────┐ ┌──────────────────────────────────────┐   │
│  │ Needs Attention  4 │ │ Clean Items               3          │   │
│  └────────────────────┘ └──────────────────────────────────────┘   │
│                                                                     │
│  [□ Select all]  [Batch Approve (0 selected) ▾]  [Filter ▾]        │
│                                                                     │
│  ─── Flagged / High Risk ──────────────────────────────────────── ⚠│
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ □ │ #    │ Employee    │ Amount   │ Category │ Flags     │ ▶ │   │
│  ├───┼──────┼─────────────┼──────────┼──────────┼───────────┼───┤   │
│  │ □ │ 0047 │ Jane Doe    │ $420.00  │ Travel   │ ⚠ Dup, ⚠Lim│ ▶ │   │
│  │ □ │ 0051 │ Mike Chen   │ $210.00  │ Meals    │ ⚠ Weekend  │ ▶ │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ─── Clean Items ──────────────────────────────────────────────── ✅│
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ □ │ #    │ Employee    │ Amount   │ Category │ Flags     │ ▶ │   │
│  ├───┼──────┼─────────────┼──────────┼──────────┼───────────┼───┤   │
│  │ □ │ 0043 │ Alice Wu    │  $45.00  │ Meals    │ ✅ Clear   │ ▶ │   │
│  │ □ │ 0044 │ Tom Lee     │  $32.50  │ Transport│ ✅ Clear   │ ▶ │   │
│  │ □ │ 0045 │ Sara Park   │  $18.00  │ Office   │ ✅ Clear   │ ▶ │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  SLA Summary: 1 item overdue · 2 items due today                   │
└─────────────────────────────────────────────────────────────────────┘
```

**Components:**
- `RiskGroupTabs` — "Needs Attention" / "Clean Items" tabs with counts
- `ExpenseQueueTable` — sortable; checkbox per row; flag chips; row click → Screen 5
- `BatchApproveButton` — enabled when ≥1 clean (unflagged) item selected; disabled if any selected item is flagged
- `SLASummaryFooter` — overdue and due-today counts

**Risk sort algorithm:** AI-flagged items first (duplicate > over-limit > weekend); then by SLA urgency; then by submission date.

⚠ **EDGE CASE — Own expense in queue:** Row shown read-only with `"You submitted this"` badge and `[Cannot approve]` tooltip; self-approval button not rendered.

⚠ **EDGE CASE — Empty queue:** Friendly empty state: `"All caught up! No expenses awaiting your approval."`.

⚠ **EDGE CASE — Batch approve includes flagged item:** Warning modal lists flagged items; user must de-select or confirm individual review before proceeding.

⚠ **EDGE CASE — Approver opens item already approved by concurrent approver:** Stale item still visible until next poll; on action, server returns HTTP 409 and table refreshes.

---

## Screen 5 — Approval Review  `REQ-EXP-2, REQ-EXP-3`

```
┌─────────────────────────────────────────────────────────────────────┐
│ ← Queue    Approve Expense #0047 · Jane Doe · $420.00               │
├───────────────────────────────────┬─────────────────────────────────┤
│  EXPENSE + RECEIPT                │  POLICY & FLAGS                 │
│                                   │                                 │
│  ┌─────────────────────────────┐  │  Policy Verdict: ⚠ WARN         │
│  │  [Receipt image full view]  │  │  ┌─────────────────────────┐   │
│  │                             │  │  │ ⚠ Travel exceeds        │   │
│  └─────────────────────────────┘  │  │   $400 limit by $20.    │   │
│                                   │  │   AI: "The submitted     │   │
│  Merchant   Acme Airlines         │  │   amount of $420 exceeds │   │
│  Date       2026-06-19            │  │   the $400 travel limit. │   │
│  Amount     $420.00 USD           │  │   You may approve with   │   │
│  Category   Travel                │  │   a note."               │   │
│  Submitted  2026-06-20 09:14      │  └─────────────────────────┘   │
│  Employee   Jane Doe              │                                 │
│                                   │  AI Flags                       │
│  ─── Approval Timeline ────────── │  ┌─────────────────────────┐   │
│  ● Submitted  Jun 20              │  │ ⚠ Possible duplicate     │   │
│  ○ Awaiting   Bob Smith (you)     │  │   of EXP-0031 (Jun 10,   │   │
│                                   │  │   same merchant/amount)  │   │
│  Comment (required on rejection)  │  │   [View EXP-0031]        │   │
│  ┌─────────────────────────────┐  │  └─────────────────────────┘   │
│  │                             │  │                                 │
│  └─────────────────────────────┘  │  Confidence Scores              │
│                                   │  Merchant  ●●●●● 96%            │
│  [Return for Edit]                │  Amount    ●●●●● 99%            │
│  [Reject]   [Approve]             │  Date      ●●●●● 98%            │
└───────────────────────────────────┴─────────────────────────────────┘
```

**Components:**
- `ReceiptFullView` — zoomable receipt image (left panel)
- `ExpenseMetadataPanel` — read-only details (left panel)
- `PolicyVerdictPanel` — verdict chip + AI plain-language explanation (right panel)
- `AIFlagsPanel` — list of AI-generated flags with links to related expenses
- `ConfidenceScorePanel` — per-field extraction confidence (right panel)
- `CommentTextarea` — required if rejecting; optional if approving
- `ActionButtons` — `[Return for Edit]` `[Reject]` `[Approve]`; reject requires comment

⚠ **EDGE CASE — Reject without comment:** `[Reject]` button stays disabled until comment field has ≥10 characters; tooltip explains.

⚠ **EDGE CASE — Approver is submitter:** Action buttons replaced with `"You submitted this expense — routed to alternate approver [Name]."`.

⚠ **EDGE CASE — Expense already actioned:** If concurrent approval happened, show read-only banner `"This expense was already approved by [Name] at [time]."` and disable all actions.

⚠ **EDGE CASE — Receipt fails to load:** Receipt panel shows broken-image placeholder with `"Unable to load receipt. Original file reference: [filename]."`.

---

## Screen 6 — Finance Analytics  `REQ-EXP-5`

```
┌─────────────────────────────────────────────────────────────────────┐
│ [≡ Logo]   Analytics                                    [👤 Finance] │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Period: [Jun 2026 ▾]  Team: [All ▾]  Category: [All ▾]  [Apply]  │
│                                                                     │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌───────────┐  │
│  │ Total Spend  │ │ Avg / Expense│ │ Pending Reimb│ │ Flagged   │  │
│  │  $24,310     │ │    $187      │ │   $8,420     │ │    12     │  │
│  └──────────────┘ └──────────────┘ └──────────────┘ └───────────┘  │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │  Spend by Category (bar chart)                             │     │
│  │  Travel ████████████████ $14,200                           │     │
│  │  Meals  ████████         $6,100                            │     │
│  │  Office ████             $2,800                            │     │
│  │  Other  ██               $1,210                            │     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
│  Anomaly Alerts                                                     │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ ⚠ Dept Engineering: 3× spike in travel vs. prior month      │   │
│  │ ⚠ Employee J. Chen: $2,100 in meals (>3σ above peer group)  │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  NL Query                                                           │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ Ask a question about spend data...                           │   │
│  │ (  What was total travel spend for Engineering in Q2?      ) │   │
│  │                                              [Ask]           │   │
│  └──────────────────────────────────────────────────────────────┘   │
│  Answer: Engineering travel spend Q2 2026: $14,200                  │
│  [View SQL ▾]  [Export CSV]                                         │
└─────────────────────────────────────────────────────────────────────┘
```

**Components:**
- `PeriodFilterBar` — date range, team, category filters
- `KPISummaryCards` — total spend, average per expense, pending reimbursements, flagged count
- `SpendByCategoryChart` — horizontal bar chart; click drills into category
- `AnomalyAlertList` — AI-detected statistical anomalies with links to underlying expenses
- `NLQueryInput` — free-text question box; submits to analytics API
- `NLQueryResult` — answer text; expandable SQL view; export to CSV

⚠ **EDGE CASE — NL query fails guard (non-SELECT):** Show `"Query could not be safely executed. Please rephrase."` — no SQL exposed.

⚠ **EDGE CASE — Query timeout:** Show `"Query took too long. Try a narrower time range."` after 5 s.

⚠ **EDGE CASE — No data for selected period:** Empty state per chart section; KPI cards show `$0` / `0`.

⚠ **EDGE CASE — Finance role sees all orgs; Approver sees own team only:** Role-scoped filter automatically applied server-side; filter UI reflects visibility.

⚠ **EDGE CASE — Anomaly with no associated expenses (data gap):** Alert shows `"Insufficient data for reliable anomaly detection in this period."`.

---

## Screen 7 — Reimbursement Processing  `REQ-EXP-4`

```
┌─────────────────────────────────────────────────────────────────────┐
│ [≡ Logo]   Reimbursements                               [👤 Finance] │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Pay Run: [Jun 28, 2026 ▾]   [Generate Batch]   [Export for ERP]   │
│                                                                     │
│  Ready for Payment (approved, not yet paid)                         │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │ □ │ Expense │ Employee   │ Amount   │ Approved By │ ▶      │     │
│  ├───┼─────────┼────────────┼──────────┼─────────────┼────────┤     │
│  │ □ │ 0043    │ Alice Wu   │  $45.00  │ Bob Smith   │ ▶      │     │
│  │ □ │ 0044    │ Tom Lee    │  $32.50  │ Bob Smith   │ ▶      │     │
│  │ □ │ 0045    │ Sara Park  │  $18.00  │ Lisa Ray    │ ▶      │     │
│  └────────────────────────────────────────────────────────────┘     │
│  Total selected: $95.50   [Mark as Paid (0 selected)]               │
│                                                                     │
│  Recent Pay Runs                                                    │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │ Date        │ Count │ Total     │ Status     │ Reference   │     │
│  ├─────────────┼───────┼───────────┼────────────┼─────────────┤     │
│  │ 2026-06-14  │   12  │ $4,201.00 │ ✅ Paid     │ PAY-2024-06│     │
│  │ 2026-05-31  │    8  │ $1,890.50 │ ✅ Paid     │ PAY-2024-05│     │
│  └────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
```

**Components:**
- `PayRunSelector` — calendar-date dropdown; defaults to next scheduled pay date
- `ReadyForPaymentTable` — approved expenses awaiting payment; checkboxes; row expands to full detail
- `MarkAsPaidButton` — marks selected expenses as `reimbursement_paid`; triggers `ReimbursementPaid` event; emits notification to employee
- `BatchExportButton` — generates CSV for ERP upload
- `PayRunHistoryTable` — past pay runs with status and reference number

⚠ **EDGE CASE — Expense approved after batch cut-off:** Appears in next pay run automatically; banner informs finance.

⚠ **EDGE CASE — ERP export fails:** Toast error with retry; export file cached in S3 for 24 h.

⚠ **EDGE CASE — Mark as paid partial failure:** Transaction-safe; partial batch rolled back; failure log shown per expense.

⚠ **EDGE CASE — Employee's bank details not configured:** Row flagged `⚠ No payment details`; excluded from batch until employee updates profile.

---

## Screen 8 — Policy Editor (Admin)  `REQ-EXP-3`

```
┌─────────────────────────────────────────────────────────────────────┐
│ [≡ Logo]   Admin · Policy Editor                        [👤 Admin]  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Active Policies   [+ New Policy]                                   │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │ Name              │ Applies To    │ Rules │ Status │ Edit  │     │
│  ├───────────────────┼───────────────┼───────┼────────┼───────┤     │
│  │ Standard Employee │ role:employee │   5   │ Active │ [✏]   │     │
│  │ Manager Travel    │ role:manager  │   3   │ Active │ [✏]   │     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ─── Edit Policy: Standard Employee ─────────────────────────────── │
│                                                                     │
│  Policy Name  ( Standard Employee Policy              )             │
│  Applies To   [role: employee ▾]                                    │
│  Effective    [ 2026-01-01 ]   Expires [ — ]                        │
│                                                                     │
│  Rules                                            [+ Add Rule]      │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │ # │ Category     │ Rule Type      │ Threshold │ Verdict │ ✕│     │
│  ├───┼──────────────┼────────────────┼───────────┼─────────┼──┤     │
│  │ 1 │ Meals        │ per_person_max │ $75.00    │ block   │ ✕│     │
│  │ 2 │ Travel       │ per_trip_max   │ $500.00   │ warn    │ ✕│     │
│  │ 3 │ Any          │ missing_receipt│ —         │ block   │ ✕│     │
│  │ 4 │ Any          │ weekend_flag   │ —         │ warn    │ ✕│     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ⚠ Conflict check: No conflicts detected                            │
│                                                                     │
│  [Cancel]  [Preview Impact]  [Save Policy]                          │
└─────────────────────────────────────────────────────────────────────┘
```

**Components:**
- `PolicyList` — table of policies with status; click or `[✏]` to edit
- `PolicyForm` — name, scope (role/team/individual), effective dates
- `RuleEditor` — table with add/delete; each rule: category, rule type, threshold, verdict
- `ConflictChecker` — runs on save; detects overlapping rules with conflicting verdicts; blocks save if conflict found
- `PreviewImpactButton` — dry-run policy against last 30 days of expenses; shows affected count

⚠ **EDGE CASE — Conflicting rules:** Save blocked; conflict highlighted in red with `"Rule 1 (block) and Rule 5 (pass) conflict on Meals over $75. Remove one before saving."`.

⚠ **EDGE CASE — Policy with future effective date:** Badge `"Takes effect Jun 30"` shown; current submissions still use previous policy.

⚠ **EDGE CASE — Delete policy in use:** Soft-delete only; `"Policy has 3 open expenses. It will remain active for in-flight approvals."`.

⚠ **EDGE CASE — No rules on policy:** Save blocked with `"A policy must have at least one rule."`.

---

## Screen 9 — Approval Chain Builder (Admin)  `REQ-EXP-2`

```
┌─────────────────────────────────────────────────────────────────────┐
│ [≡ Logo]   Admin · Approval Chain Builder               [👤 Admin]  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Chains    [+ New Chain]                                            │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │ Name               │ Trigger           │ Steps │ Status    │     │
│  ├────────────────────┼───────────────────┼───────┼───────────┤     │
│  │ Standard (< $200)  │ amount < $200      │   1   │ Active    │     │
│  │ Mid-value ($200–1k)│ amount $200–$1000  │   2   │ Active    │     │
│  │ High-value (>$1k)  │ amount > $1000     │   3   │ Active    │     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ─── Edit Chain: Mid-value ───────────────────────────────────────  │
│                                                                     │
│  Chain Name    ( Mid-value Approval Chain             )             │
│  Trigger       [ amount between $200 and $1000 ▾    ]              │
│  Fallback approver [ CFO (Lisa Ray) ▾               ]              │
│                                                                     │
│  Steps  (drag to reorder)                  [+ Add Step]            │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │  ┌──────────────────────────────────────────────────────┐ │     │
│  │  │ Step 1 · Sequential                                  │ │     │
│  │  │ Approver:  [Direct Manager (dynamic) ▾]              │ │     │
│  │  │ SLA:       [3 days ▾]                                 │ │     │
│  │  │ Alternate: [Skip to step 2 on OOO ▾]                 │ │     │
│  │  └──────────────────────────────────────────────────────┘ │     │
│  │        │                                                   │     │
│  │        ▼                                                   │     │
│  │  ┌──────────────────────────────────────────────────────┐ │     │
│  │  │ Step 2 · Sequential                                  │ │     │
│  │  │ Approver:  [Finance Team ▾]                           │ │     │
│  │  │ SLA:       [2 days ▾]                                 │ │     │
│  │  │ Alternate: [Escalate to fallback ▾]                  │ │     │
│  │  └──────────────────────────────────────────────────────┘ │     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
│  [Cancel]  [Simulate Chain]  [Save Chain]                           │
└─────────────────────────────────────────────────────────────────────┘
```

**Components:**
- `ChainList` — table of chains with trigger condition and step count
- `ChainForm` — name, trigger rule (amount range / category / cost centre), fallback approver
- `StepBuilder` — draggable list of approval steps; each step: approver (role/person/dynamic), step type (sequential/parallel), SLA, alternate-approver/escalation rule
- `SimulateChainButton` — given test expense data, shows resolved approver list per step
- `ChainValidation` — detects: no steps, no fallback, circular delegation, invalid trigger overlap

⚠ **EDGE CASE — Overlapping triggers:** Save blocked; `"Chain 'Standard' and 'Mid-value' both match $199.99 — adjust thresholds."`.

⚠ **EDGE CASE — Dynamic approver resolves to nobody at runtime:** Workflow engine falls back to `fallback_approver_id`; admin alerted via notification.

⚠ **EDGE CASE — Delete chain in use:** Soft-delete; in-flight expenses complete on existing chain snapshot; new submissions use updated routing.

⚠ **EDGE CASE — Circular delegation chain:** Validated on save; `"Step 1 delegate loops back to Step 1 approver. Circular delegation is not allowed."`.

⚠ **EDGE CASE — Parallel step with single approver:** Warn but allow; `"Parallel step with one approver behaves identically to a sequential step."`.
