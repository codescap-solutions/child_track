# Implementation Documentation: Multi-Child Profile Support

This document details the architectural and functional implementation of multiple child profile support within the NAVIQ Child App. 

## 1. Local Data Model – SharedPreferences

### Previous Model (Single Child – Deprecated)
The legacy implementation relied on a flat key-value structure within `SharedPreferences`:
- `child_id`: A single string representing the registered child.
- `auth_token`: The JWT associated with that ID.

This model was inherently limited to one child per device session. To support a different child, the user would have to perform a complete logout, clearing the local state, and re-authenticate.

### New Model (Multi-Child – Current)
The current implementation utilizes a more robust, collection-based structure stored locally:

**SharedPreferences Keys:**
- `children`: A serialized JSON list of `ChildProfile` objects.
  Each `ChildProfile` includes:
    - `child_id` (String): Unique identifier.
    - `child_name` (String): Display name.
    - `auth_token` (String): Identity-specific JWT.
    - `avatar` (String, optional): Path or URL to the child’s profile image.
    - `last_active_at` (Timestamp): Last time this profile was the active identity.

- `active_child_id`: A string pointing to the `child_id` of the profile currently designated as active.

**Architectural Rules:**
- **Zero-to-Many Profiles**: Multiple profiles can reside in local storage, each with its own authentication context.
- **Single-Active Invariant**: Only one profile can be `active` at any given time.
- **Identity Isolation**: Background tracking (Location, Screen-Time) is strictly piped using the credentials and ID of the `active_child_id`.
- **Stateless Backend Impact**: Backend APIs remain unchanged. The backend continues to expect a singular identity per request; the app handles the multiplexing locally by switching which token is attached to outbound telemetry.
- **Selective Purge**: Logging out a child removes only their specific `ChildProfile` from the `children` list. The device state and other sibling profiles remain untouched.

---

## 2. Settings Screen – Multi-Child Design

### Existing Structure
The Settings screen maintains its role as the central configuration hub, featuring a child header section followed by granular control categories (Security, Content, Notifications, etc.).

### Updated Child Section – Expandable Child Switcher
The header section has been evolved into an expandable accordion to manage identity switching:
- **Collapsed State**: Shows only the currently **ACTIVE** child profile.
- **Expanded State**: Reveals a vertical list consisting of:
    - The **Active Child Tile**.
    - A divider.
    - Any **Inactive Child Tiles** stored locally.
    - A secondary divider.
    - An **"Add New Child"** action tile.

### Active Child Tile
The active profile is highlighted at the top of the section, displaying:
- Profile Avatar.
- Child's Name and unique Child Code.
- A prominent "Active" badge.
- An "Edit" action to modify local display name/metadata.

### Switch Child Tile (Inactive Child)
Selecting an inactive child initiates the identity transition protocol. To prevent data corruption, a confirmation dialog is strictly enforced:
> *“Switching child will stop background tracking for [Current Child] and activate [Selected Child].”*

**Transition Workflow (Atomic):**
1. Immediate termination of all running background services (Location, App Usage).
2. Updating the `active_child_id` in local storage.
3. Swapping the active memory-loaded Auth Token with the selected child's token.
4. Reinitalizing background services with the new identity context.
5. Re-registering the FCM token with the backend to ensure push notifications are routed to the new `active_child_id`.

### Add New Child Tile
This action triggers the standard "Connect to Parent" pairing flow:
- Prompts for the pairing code.
- On successful validation, a new `ChildProfile` is appended to the local `children` list.
- If no previous profiles existed, this child is automatically promoted to the "Active" state.

---

## 3. Settings Options – Functional Behavior

### Restrict from Deleting
- **Purpose**: Hardening the app against unauthorized removal or tempering by the child.
- **Behavior**: When enabled, it disables the "Logout" action and blocks access to critical system-level clearing prompts.
- **Enforcement**: Stored as a local toggle; requires the Parent PIN (established during onboarding) to unlock.

### Block 18+ Websites
- **Platform Strategy**:
    - **Android**: Enforced via a local DNS filter or through accessibility services that monitor browser URLs against a blacklist.
    - **iOS**: Due to sandbox limitations, this action redirects the user directly to the system `Settings -> Screen Time -> Content & Privacy Restrictions` page.

### Notification Settings
- **Implementation**: Manages visibility of SOS alerts, parent pings, and permission health warnings.
- **Management**: State is synchronized with the backend via FCM topic subscriptions associated with the specific `child_id`.

### Request Location
- **Classification**: This is an **Action**, not a persistent setting.
- **Flow**: Tapping the button triggers an immediate FCM "PING_LOCATION" request. The app, even in the background, responds by broadcasting its current high-accuracy GPS coordinates to the parent dashboard.

### Emergency Contacts
- **Config**: A local/synced list of trusted contacts.
- **Scope**: Managed per `child_id`. These contacts are displayed in the SOS view for rapid dialing during emergencies.

### Subscription
- **Status**: Read-only in the Child App. 
- **Behavior**: Polls the backend for current plan tier and expiry date. 
- **UX**: Displays "Managed by Parent" to indicate that billing actions must take place on the Parent device.

### Saved Places
- **Status**: Component remains as previously implemented, managing geofenced locations specific to the child's routine.

### Account
- **Display**: High-level metadata for the active child (Name, Child ID, Primary Parent Name, and the timestamp of the last successful data synchronization).

### Device
- **Display**: Hardware and status telemetry (Model, OS version, Battery %, Network connectivity).
- **Service Monitoring**: Real-time status indicator showing whether background services are "Running" (Tracking Active) or "Stopped" (Tracking Paused).

---

## 4. Background Service Switch Logic

The transition between child identities is governed by the following strict execution sequence to ensure the **"Single-Active-Child Invariant"**:

1. **Service Teardown**: Shutdown of location tracking and screen-time polling loops.
2. **Context Cleanup**: Clearing in-memory authentication tokens and caching.
3. **Identity Swap**: Loading the target child’s JWT and profile from `SharedPreferences`.
4. **Service Boot**: Restarting the Foreground Service (Android) or Background Task (iOS) with the new credentials.
5. **Messaging Rebind**: Updating the backend with the latest FCM token-to-child_id mapping.

> **Final Architectural Guarantee**: At no point may two child identities run background services simultaneously on the same device.
