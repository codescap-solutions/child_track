# ADR-001: Supporting Multiple Child Profiles on a Single Mobile Device

**Status**: Accepted
**Deciders**: Principal Mobile Architect
**Date**: 2026-01-29

## Context
The NAVIQ Child App is designed to run on physical devices owned or used by children. Its primary function involves continuous background operations, specifically location tracking and screen-time telemetry collection. These data streams are critical for parental oversight and must be attributed with 100% accuracy to a specific child identity.

Historically, the system was architected for a 1:1 relationship between a physical device and a child identity. This simplification was driven by:
- The assumption of personal device ownership among children.
- Simplified background service management (tracking a single `child_id`).
- Backend expectations of a single active session per device hardware identifier.

## Problem Statement
Real-world usage patterns have revealed that parents often have multiple children sharing a single mobile device (e.g., siblings sharing a tablet or a hand-me-down phone). 

The new requirements are:
1. The Child App must support multiple child profiles stored locally on one device.
2. The system must eliminate any possibility of telemetry data mixing (e.g., Child A's location being attributed to Child B).
3. Switching between children must be seamless but architecturally robust.

## Decision
We will support multiple child profiles on a single device under a strict lifecycle constraint:

> **“This system enforces a single-active-child invariant.”**

- A single device may **STORE** multiple child profiles (identities, tokens, and metadata).
- Only **ONE** child profile may be **ACTIVE** at any given time.
- All background services (location, app usage, device status) are bound exclusively to the `active_child_id`.

## Key Constraints

### Mobile OS Constraints
- **Android Foreground Services**: Running multiple identity-bound trackers simultaneously in the background is resource-intensive and prone to OS-level termination. Managing separate service lifecycles for multiple identities on a single device is inherently unstable.
- **iOS Background Execution**: iOS severely limits background tasks. Identity switching must be an explicit, user-initiated action to ensure the OS correctly attributes activity and permissions.

### Data Integrity Constraints
- **Telemetry Ambiguity**: Parallel tracking would create interleaved data points that are difficult to de-duplicate or correctly attribute at the backend layer.
- **Parental Dashboarding**: The backend and frontend dashboards are optimized for single-identity streams. Moving away from this would require a massive migration of the data ingestion pipeline.

### Security Constraints
- **JWT Scoping**: Each child identity is issued a unique JWT with specific scopes. Storing multiple active JWTs and ensuring background threads use the correct one for each network request increases the attack surface and implementation complexity.

## Alternatives Considered

### 1. Multiple Active Children Simultaneously
- **Reason for Rejection**: Rejected due to high risk of telemetry mixing and severe mobile OS limitations regarding concurrent foreground services. The battery drain and complexity of managing multiple background streams outweighed the benefit of "always-on" tracking for multiple users.

### 2. Separate App Installs (Work Profiles/Cloning)
- **Reason for Rejection**: Relies on OS-specific features (like Android Work Profiles) which are not universally available or user-friendly for the target demographic. This would result in a fragmented UX and an unscalable support model.

### 3. Backend-level Multiplexing
- **Reason for Rejection**: Attempting to split a single device stream into multiple child identities at the backend layer based on metadata. This was rejected due to the extreme complexity of state management and the high risk of data corruption during edge cases (e.g., poor connectivity transitions).

## Consequences

### Positive
- **Clear Data Ownership**: Telemetry is guaranteed to belong to the active child.
- **Architectural Simplicity**: Minimal changes required for the backend ingestion layer.
- **Predictable Lifecycle**: Background services have a clear "Start/Stop" trigger linked to the active profile.

### Trade-offs
- **Manual Intervention**: Parents or children must manually switch profiles when the device changes hands.
- **Tracking Gaps**: Data collection is paused during the transition period when switching profiles.

## Enforcement Mechanisms
Technical enforcement of this decision is handled via:
- **Local Persistence**: The `active_child_id` is the single source of truth for all local operations.
- **Service Initialization**: Background services are architected to read the identity **ONLY** at startup.
- **Explicit Restart**: Switching a child profile triggers a mandatory "Stop All Services" -> "Update Identity" -> "Restart All Services" sequence.
- **FCM Rebinding**: The Firebase Cloud Messaging token is rebound to the new `active_child_id` upon switching to ensure targeted notifications.

## Final Statement
> **“At no point can telemetry from a device be attributed to more than one child identity.”**
