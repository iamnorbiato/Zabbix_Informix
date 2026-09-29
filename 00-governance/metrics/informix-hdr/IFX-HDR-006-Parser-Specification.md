# IFX-HDR-006 — Parser Specification

## Current Operational Status

`DEFINED — SOURCE SEMANTICS REQUIRE VALIDATION`

No acknowledgement-age parser or item exists yet.

## 1. Purpose

Define the future parsing and calculation contract for HDR acknowledgement age.

## 2. Candidate Input Contract

The candidate peer source is `ack_time` from validated `syscluster` data, together with a collection timestamp in a confirmed compatible time basis.

## 3. Output Contract

After validation, output is one non-negative elapsed value in seconds:

```text
acknowledgement_age_seconds
```

## 4. Calculation Gate

No calculation is allowed until target evidence proves field existence, type, unit, clock basis and behavior under idle workload, disconnection and reconnect.

Negative output, guessed epoch conversion, null-to-zero conversion and calculation across incompatible time bases are prohibited.

## 5. Invalid Input

Missing/null acknowledgement time for a connected peer, malformed value, unsupported schema and incompatible time basis produce unknown or collection failure according to the approved implementation contract; none may produce `0` seconds.

## 6. Real Source Validation

Validate `ack_time` on a real HDR pair during active, idle, disconnected, and recovered states. Until representation, clock basis, and update semantics are proven, no age calculation or threshold is approved.

## 7. Acceptance Criteria

- Timestamp semantics and units are proven on real HDR.
- Output is demonstrably non-negative and correctly scaled in seconds.
- Idle workload does not cause unjustified alerting.

