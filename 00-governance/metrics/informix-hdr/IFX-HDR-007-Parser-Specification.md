# IFX-HDR-007 — Parser Specification

## Current Operational Status

`DEFINED — SOURCE SEMANTICS REQUIRE VALIDATION`

No log-progress or backlog parser exists yet.

## 1. Purpose

Define the future parsing contract for per-peer HDR sent and acknowledged log progress, and the release gate for any derived backlog.

## 2. Candidate Input Contract

The candidate fields are `logid_sent`, `logpage_sent`, `logid_acked` and `logpage_acked` from validated `syscluster` HDR records.

## 3. First Output Stage

After field validation, preserve individual source components as typed values. Do not calculate a backlog merely because all four fields are present.

## 4. Derived Backlog Gate

Any backlog output requires an approved formula that documents ordering, page/log rollover, units, reset behavior and handling of inconsistent progress.

The following are invalid until explicitly validated:

```text
logid_sent - logid_acked
logpage_sent - logpage_acked
```

## 5. Invalid Input

Missing field, malformed value, unsupported schema, rollback/inconsistency without defined semantics, or an unproven rollover condition must produce unknown/failure rather than negative or zero backlog.

## 6. Mock Validation

After a formula is approved, validate equal progress, normal lag, warning/high backlog, rollover, inconsistent source values and disconnected-peer gating.

## 7. Acceptance Criteria

- Target fields and types are recorded from real HDR.
- Rollover-safe ordering is proven.
- A derived backlog has one documented unit.
- No threshold is enabled before the unit is accepted.

