# Sovereign Operator Manual – Safe Mode & Escalation (v1.0)

System: Sovereign System / Boardroom-13  
Role: Constitutional Operator – Steven Jones  
Scope: Operational control of Safe Mode, Elevated Mode, and critical transitions.

---

## 1. Purpose & Scope

This manual defines **how the Sovereign System is operated under stress**:

- When to enter **Safe Mode**.
- How to move between **Normal ? Safe ? Elevated ? Locked-Down**.
- What the operator (Steven) can and cannot do.
- How decisions are logged for later legal and governance review.

This is about **damage prevention**, not productivity.

---

## 2. Roles & Authority

### 2.1 Constitutional Operator (Steven)

Steven holds **Constitutional Operator** status:

- Can **request mode changes** (Normal/Safe/Elevated/Locked-Down).
- Can **approve or deny** high-risk actions proposed by the system.
- Cannot bypass:
  - Ledger logging.
  - Constitutional checks hard-coded in policies.

### 2.2 System / Boardroom-13

The system:

- Enforces the **constitutional ruleset**.
- Refuses actions that violate:
  - Safety constraints.
  - Data protection constraints.
  - Critical governance rules.

It must:

- Log all mode changes.
- Emit **justifications** for proposed high-risk actions.

### 2.3 Other Human Operators

Other humans (including Andy, Owen, others):

- May propose actions / tasks.
- Do **not** have constitutional override powers unless explicitly delegated in future revisions.

---

## 3. Modes & Definitions

| Mode        | Description                                                       | Typical Trigger                                       |
|-------------|-------------------------------------------------------------------|--------------------------------------------------------|
| Normal      | Standard operating state; tasks run with full capabilities        | Day-to-day operations; no major incident detected     |
| Safe        | Restricted state; high-risk actions blocked; system self-limits   | Operator overload, uncertainty, or suspected anomaly  |
| Elevated    | Focused high-scrutiny mode; some risky operations allowed but logged with extra justification and confirmations | Incident handling, legal bundle preparation, urgent fixes |
| Locked-Down | Maximum restriction; only core preservation tasks allowed         | Suspected compromise, legal freeze, or serious breach |

---

## 4. Triggers & Transitions

### 4.1 Entering Safe Mode

Recommended triggers:

- Operator is **exhausted**, overwhelmed, or unable to supervise.
- Recent configuration changes or code changes are not yet reviewed.
- Evidence of possible:
  - Data leakage.
  - Misconfiguration.
  - Conflicting instructions from different tools/models.

Procedure (conceptual):

1. Operator (Steven or Andy) issues a **"Request Safe Mode"** command.
2. System:
   - Confirms current mode.
   - Logs:
     - Timestamp
     - Requester
     - Reason (short text)
3. System enforces Safe Mode rules:
   - Disables or restricts:
     - External network anchoring (or runs only in strict dry-run).
     - Destructive file operations.
     - High-risk automation (e.g., mass cleanup, migrations).

### 4.2 Exiting Safe Mode (back to Normal)

Conditions:

- Recent changes have been reviewed.
- No active incidents.
- Operator is capable of supervising.

Procedure:

1. Operator issues **"Request Return to Normal"**.
2. System:
   - Summarises what happened in Safe Mode (key events).
   - Requests confirmation.
3. Once approved:
   - Logs transition.
   - Restores Normal Mode capabilities.

### 4.3 Transition to Elevated Mode

Triggered when:

- A real issue must be investigated/resolved **now**.
- Actions may have impact but are necessary (e.g., preparing court bundle, running powerful scripts).

In Elevated Mode:

- Risky actions are **allowed only with explicit, logged approval**.
- The system:
  - Requires more detailed justifications.
  - May require multi-step confirmation (e.g. type an explicit phrase, or confirm twice).

### 4.4 Locked-Down Mode

Use in extreme cases:

- Suspected compromise of:
  - NAS.
  - Keys.
  - Repos.
- Legal instruction to preserve state (e.g., litigation hold).

In Locked-Down:

- System only:
  - Writes to append-only logs.
  - Runs integrity checks.
- No destructive or modifying actions allowed until the lock is released with a **documented, exceptional override**.

---

## 5. Daily & Weekly Operator Checklists

### 5.1 Daily

- Confirm system mode (Normal/Safe/Elevated/Locked).
- Glance through:
  - Last 24h logs of:
    - Mode changes.
    - High-risk actions proposed or executed.
- Check NAS status:
  - Bundle accessible.
  - Snapshot schedule on track.

### 5.2 Weekly

- Review a **summary report**:
  - Count of mode transitions.
  - Any blocked actions in Safe Mode.
  - Any Elevated Mode operations.
- Decide if:
  - Additional Safe Mode rules are needed.
  - Any automation should be restricted.

---

## 6. Incident Handling (Conceptual Flow)

1. **Detect**: System or operator sees something off (drift, unexpected behaviour).
2. **Stabilise**:
   - Enter Safe or Locked-Down Mode.
   - Snapshot relevant logs / bundles.
3. **Investigate**:
   - Use dry-run simulators and read-only analyses.
4. **Repair**:
   - Perform changes in Elevated Mode with full logging and justification.
5. **Return**:
   - Move back to Normal Mode once stable.
   - Record an incident summary.

---

## 7. Evolution of this Manual

This v1.0 document is a **starting law**, not the final word.

- Every significant incident or near-miss should prompt an update.
- Changes to this manual:
  - Must be logged and versioned in `docs/ops/archive/`.
  - Should be referenced by hash in governance logs for traceability.
