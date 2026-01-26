# SSP NFC Configurator - Flutter App Specification

## Overview

A dedicated Flutter mobile app for restaurant staff to rapidly provision NFC tags to tables. The app reads NFC tag UIDs, registers them to tables via the SSP API, and writes the URL directly to the tag—all in a single tap workflow.

**Target Users**: Restaurant managers, SSP support staff, onboarding team

**Platforms**: iOS, Android

---

## Why a Dedicated App?

| Web UI Flow | Dedicated App Flow |
|-------------|-------------------|
| Read UID from tag packaging | Tap phone → UID auto-captured |
| Type UID manually into form | No manual typing |
| Copy URL to clipboard | App writes URL directly to tag |
| Open separate NFC writer app | All-in-one solution |
| ~2 minutes per tag | ~15 seconds per tag |

**ROI**: For a 20-table restaurant, saves ~35 minutes of setup time.

---

## Core Features

### MVP (Phase 1)
- [x] Staff authentication (existing SSP credentials)
- [x] Organization/location selection
- [x] NFC tag UID reading
- [x] Table selection with status indicators
- [x] Tag registration via GraphQL API
- [x] URL writing to NFC tag
- [x] Session history tracking
- [x] Error handling with clear messages

### Future (Phase 2)
- [ ] Batch mode (pre-assign table sequence)
- [ ] Tag verification mode (scan to verify correct URL)
- [ ] Offline queue (register when back online)
- [ ] Tag replacement flow
- [ ] Export session report (PDF/CSV)

---

## User Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER FLOW                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐             │
│  │  Login   │───▶│  Select  │───▶│  Select  │───▶│   Scan   │             │
│  │          │    │   Org    │    │ Location │    │   Mode   │             │
│  └──────────┘    └──────────┘    └──────────┘    └────┬─────┘             │
│                                                       │                    │
│                                                       ▼                    │
│                                              ┌────────────────┐            │
│                                              │  Waiting for   │            │
│                                              │   NFC tag      │◀─────┐     │
│                                              └────────┬───────┘      │     │
│                                                       │              │     │
│                                                       ▼              │     │
│                                              ┌────────────────┐      │     │
│                                              │  Tag Detected  │      │     │
│                                              │  Select Table  │      │     │
│                                              └────────┬───────┘      │     │
│                                                       │              │     │
│                                                       ▼              │     │
│                                              ┌────────────────┐      │     │
│                                              │  Registering   │      │     │
│                                              │  + Writing URL │      │     │
│                                              └────────┬───────┘      │     │
│                                                       │              │     │
│                                                       ▼              │     │
│                                              ┌────────────────┐      │     │
│                                              │    Success!    │      │     │
│                                              │                │──────┘     │
│                                              │ [Scan Next]    │            │
│                                              └────────────────┘            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Screen Specifications

### Screen 1: Login

**Purpose**: Authenticate staff using existing SSP credentials

```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│         ┌─────────────┐             │
│         │   SSP       │             │
│         │   NFC Setup │             │
│         └─────────────┘             │
│                                     │
│                                     │
│  Email                              │
│  ┌─────────────────────────────┐    │
│  │ manager@grillbistro.com     │    │
│  └─────────────────────────────┘    │
│                                     │
│  Password                           │
│  ┌─────────────────────────────┐    │
│  │ ••••••••••••           👁   │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │          Sign In            │    │
│  └─────────────────────────────┘    │
│                                     │
│                                     │
│  Use your SSP Manager credentials   │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

**Behavior**:
- Validates email format
- Shows loading state during auth
- Stores JWT in secure storage
- On success → Navigate to Location Select
- On error → Show inline error message

**API**: Uses `loginSSPUser` mutation (see GraphQL API Reference)

---

### Screen 2: Location Selection

**Purpose**: Select organization and location to configure

```
┌─────────────────────────────────────┐
│ ←  Select Location                  │
├─────────────────────────────────────┤
│                                     │
│  🔍 Search locations...             │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  GRILL BISTRO                       │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 📍 Downtown                 │    │
│  │    12 tables                │    │
│  │    8 with NFC • 4 without   │    │
│  │                         ▶   │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 📍 Uptown Mall              │    │
│  │    8 tables                 │    │
│  │    0 with NFC • 8 without   │    │
│  │                         ▶   │    │
│  └─────────────────────────────┘    │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  MARIO'S KITCHEN                    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 📍 Main Street              │    │
│  │    20 tables                │    │
│  │    15 with NFC • 5 without  │    │
│  │                         ▶   │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

**Behavior**:
- Groups locations by organization
- Shows NFC tag statistics per location
- Search filters by location or org name
- On select → Navigate to Scan Mode

**API**: `getUserLocations` query (returns locations grouped by organization)

---

### Screen 3: Scan Mode (Main Screen)

**Purpose**: Primary interface for tag scanning and registration

#### State 3A: Ready to Scan

```
┌─────────────────────────────────────┐
│ ← Grill Bistro - Downtown       ⚙️  │
├─────────────────────────────────────┤
│                                     │
│                                     │
│         ┌─────────────────┐         │
│         │                 │         │
│         │    ╭───────╮    │         │
│         │    │  📱   │    │         │
│         │    │       │    │         │
│         │    ╰───────╯    │         │
│         │    ○ ○ ○ ○      │         │
│         │   (pulsing)     │         │
│         │                 │         │
│         └─────────────────┘         │
│                                     │
│          Ready to scan              │
│                                     │
│     Tap NFC tag to back of phone    │
│                                     │
│                                     │
│  ───────────────────────────────    │
│                                     │
│  This session: 0 tags registered    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │       View All Tables       │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

#### State 3B: Tag Detected - Select Table

```
┌─────────────────────────────────────┐
│ ← Grill Bistro - Downtown       ⚙️  │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐    │
│  │  🏷️  Tag Detected            │    │
│  │                             │    │
│  │  UID: 04:A8:14:4A:BE:2A:81  │    │
│  └─────────────────────────────┘    │
│                                     │
│  Assign to table:                   │
│                                     │
│  🔍 Filter...        [No tag only]  │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ ○  Table 1                  │    │
│  │    7 seats • Occupied   📶  │    │
│  ├─────────────────────────────┤    │
│  │ ○  Table 2                  │    │
│  │    4 seats • Available  📶  │    │
│  ├─────────────────────────────┤    │
│  │ ●  Table 3                  │    │
│  │    10 seats • Available  —  │    │
│  ├─────────────────────────────┤    │
│  │ ○  Table 4                  │    │
│  │    2 seats • Reserved    —  │    │
│  ├─────────────────────────────┤    │
│  │ ○  Table 5                  │    │
│  │    6 seats • Available   —  │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ ☑ Write URL to tag          │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │   Register to Table 3       │    │
│  └─────────────────────────────┘    │
│                                     │
│  [Cancel]                           │
│                                     │
└─────────────────────────────────────┘
```

**Table List Indicators**:
- 📶 = Has active NFC tag (disabled for selection)
- ⚠️ = Has damaged/lost tag (can be replaced)
- — = No tag (available for registration)

#### State 3C: Registering

```
┌─────────────────────────────────────┐
│ ← Grill Bistro - Downtown           │
├─────────────────────────────────────┤
│                                     │
│                                     │
│                                     │
│                                     │
│              ┌─────┐                │
│              │ ⟳  │                │
│              └─────┘                │
│                                     │
│       Registering tag...            │
│                                     │
│       Table 3 • 04:A8:14:4A         │
│                                     │
│                                     │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

#### State 3D: Writing URL to Tag

```
┌─────────────────────────────────────┐
│ ← Grill Bistro - Downtown           │
├─────────────────────────────────────┤
│                                     │
│                                     │
│                                     │
│         ┌─────────────────┐         │
│         │                 │         │
│         │    ╭───────╮    │         │
│         │    │  📱   │    │         │
│         │    │  ═══  │    │         │
│         │    ╰───────╯    │         │
│         │                 │         │
│         └─────────────────┘         │
│                                     │
│        Writing URL to tag...        │
│                                     │
│        Keep phone on tag            │
│                                     │
│       ████████████░░░░ 75%          │
│                                     │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

**Important**: User must keep phone on tag during write operation.

#### State 3E: Success

```
┌─────────────────────────────────────┐
│ ← Grill Bistro - Downtown           │
├─────────────────────────────────────┤
│                                     │
│                                     │
│                                     │
│               ✅                    │
│                                     │
│        Tag Registered!              │
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │  Table 3                    │    │
│  │  10 seats                   │    │
│  │                             │    │
│  │  UID: 04:A8:14:4A:BE:2A:81  │    │
│  │                             │    │
│  │  URL written:               │    │
│  │  ssp.app/t/grill-bistro/    │    │
│  │  downtown/3                 │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │       Scan Next Tag         │    │
│  └─────────────────────────────┘    │
│                                     │
│  [View Tables]          [Done]      │
│                                     │
└─────────────────────────────────────┘
```

#### State 3F: Error

```
┌─────────────────────────────────────┐
│ ← Grill Bistro - Downtown           │
├─────────────────────────────────────┤
│                                     │
│                                     │
│                                     │
│               ❌                    │
│                                     │
│       Registration Failed           │
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │  This NFC tag is already    │    │
│  │  registered.                │    │
│  │                             │    │
│  │  UID 04:A8:14:4A:BE:2A:81   │    │
│  │  is assigned to Table 7     │    │
│  │  at Downtown location.      │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │         Try Again           │    │
│  └─────────────────────────────┘    │
│                                     │
│  [View Tables]          [Cancel]    │
│                                     │
└─────────────────────────────────────┘
```

---

### Screen 4: All Tables View

**Purpose**: Overview of all tables and their NFC status

```
┌─────────────────────────────────────┐
│ ← Tables                   [Filter] │
├─────────────────────────────────────┤
│                                     │
│  Grill Bistro - Downtown            │
│  12 tables • 8 with NFC tags        │
│                                     │
│  ───────────────────────────────    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Table 1              📶     │    │
│  │ 7 seats • Occupied          │    │
│  │ Tag: 04:A8:14:4A:BE:2A:81   │    │
│  │ Last scan: 2 hours ago      │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Table 2              📶     │    │
│  │ 4 seats • Available         │    │
│  │ Tag: 04:B9:25:5B:CF:3B:92   │    │
│  │ Last scan: 1 day ago        │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Table 3              —      │    │
│  │ 10 seats • Available        │    │
│  │ No NFC tag      [+ Add Tag] │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Table 4              ⚠️     │    │
│  │ 2 seats • Reserved          │    │
│  │ Tag DAMAGED                 │    │
│  │ "Cracked 01/20"  [Replace]  │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

**Filter Options**:
- All tables
- Without NFC tag
- With NFC tag
- Damaged/Lost tags

**Actions**:
- [+ Add Tag] → Opens scan mode with table pre-selected
- [Replace] → Deactivates old tag, opens scan mode

---

### Screen 5: Session Summary

**Purpose**: Review tags registered in current session

```
┌─────────────────────────────────────┐
│ ← Session Summary                   │
├─────────────────────────────────────┤
│                                     │
│  Grill Bistro - Downtown            │
│  Session started: 2:30 PM           │
│                                     │
│  ───────────────────────────────    │
│                                     │
│  ✅ 5 tags registered               │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ ✓ Table 3      2:31 PM      │    │
│  │   04:A8:14:4A:BE:2A:81      │    │
│  ├─────────────────────────────┤    │
│  │ ✓ Table 4      2:32 PM      │    │
│  │   04:B9:25:5B:CF:3B:92      │    │
│  ├─────────────────────────────┤    │
│  │ ✓ Table 6      2:33 PM      │    │
│  │   04:CA:36:6C:D0:4C:A3      │    │
│  ├─────────────────────────────┤    │
│  │ ✓ Table 9      2:35 PM      │    │
│  │   04:DB:47:7D:E1:5D:B4      │    │
│  ├─────────────────────────────┤    │
│  │ ✓ Table 10     2:36 PM      │    │
│  │   04:EC:58:8E:F2:6E:C5      │    │
│  └─────────────────────────────┘    │
│                                     │
│  ───────────────────────────────    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │      Continue Scanning      │    │
│  └─────────────────────────────┘    │
│                                     │
│  [Export Report]      [End Session] │
│                                     │
└─────────────────────────────────────┘
```

---

### Screen 6: Settings

**Purpose**: App configuration and account management

```
┌─────────────────────────────────────┐
│ ← Settings                          │
├─────────────────────────────────────┤
│                                     │
│  ACCOUNT                            │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 👤 Martin                    │    │
│  │    manager@grillbistro.com  │    │
│  │                      [Logout]│    │
│  └─────────────────────────────┘    │
│                                     │
│  ───────────────────────────────    │
│                                     │
│  SCANNING                           │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Auto-write URL to tag       │    │
│  │ Write immediately after  ◉  │    │
│  │ registration                │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Vibrate on scan             │    │
│  │ Haptic feedback when tag ◉  │    │
│  │ is detected                 │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Sound on success            │    │
│  │ Play sound after        ◉   │    │
│  │ successful registration     │    │
│  └─────────────────────────────┘    │
│                                     │
│  ───────────────────────────────    │
│                                     │
│  ABOUT                              │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Version 1.0.0               │    │
│  │ API: api.ssp.app            │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

---

## GraphQL API Reference

> **Note**: All authenticated queries/mutations require the `Authorization: Bearer {token}` header.

### Authentication

#### Login

```graphql
mutation LoginSSPUser($email: String!, $password: String!) {
  loginSSPUser(email: $email, password: $password) {
    token                           # JWT token for subsequent requests
    user {
      id
      name
      email
    }
    requiresTwoFactor               # If true, use verifyTwoFactorAuthentication
    requiresOrganizationSelection   # If true, use selectOrganization
    challenge_token                 # For 2FA flow
    selection_token                 # For org selection flow
    organizations {                 # Available orgs (multi-org users)
      id
      name
    }
  }
}
```

**Flow Notes**:
- If `requiresTwoFactor=true`: Use `verifyTwoFactorAuthentication` with `challenge_token`
- If `requiresOrganizationSelection=true`: Use `selectOrganization` with `selection_token`
- Otherwise: Use `token` directly for authenticated requests

---

### Queries

#### 1. Get Current User

```graphql
query GetCurrentUser {
  me {
    id
    name
    email
  }
}
```

---

#### 2. Get User Locations

Returns all locations the authenticated user has access to (grouped by organization).

```graphql
query GetUserLocations {
  getUserLocations {
    id
    name
    organization {
      id
      name
      uuid
    }
  }
}
```

---

#### 3. Get Tables for Location

```graphql
query GetLocationTables($locationId: ID!) {
  getLocationTables(locationId: $locationId) {
    id
    name
    local_id              # Used in NFC URL path
    number_of_seats
    status                # AVAILABLE, OCCUPIED, RESERVED, etc.
    nfcTag {              # null if no tag assigned
      id
      uid
      status              # ACTIVE, LOST, DAMAGED, DEACTIVATED
      label
      writtenUrl
      lastScannedAt
    }
    location {
      id
      name
      organization {
        uuid              # Used in NFC URL path
      }
    }
  }
}
```

**Type Definition**:
```graphql
type SSPTable {
  id: ID!
  name: String!
  local_id: Int              # URL identifier (e.g., 7 in /t/org/loc/7)
  number_of_seats: Int!
  status: String!
  nfcTag: NFCTag             # null if no active tag
  location: SSPLocation
}

type NFCTag {
  id: ID!
  uid: String!               # Hardware serial: "04:AB:CD:12:34:56:80"
  status: NFCTagStatus!
  label: String
  writtenUrl: String         # URL written to tag
  lastScannedAt: DateTime
  registeredAt: DateTime!
  registeredBy: SSPUser
  notes: String
}

enum NFCTagStatus {
  ACTIVE
  LOST
  DAMAGED
  DEACTIVATED
}
```

---

#### 4. Get NFC Tags by Location

```graphql
query GetNFCTagsByLocation($locationId: ID!) {
  getNFCTagsByLocation(locationId: $locationId) {
    id
    uid
    status
    label
    writtenUrl
    lastScannedAt
    registeredAt
    notes
    table {
      id
      name
      local_id
    }
    registeredBy {
      id
      name
    }
  }
}
```

**Required Permission**: `view_nfc_tags`

---

#### 5. Get Single NFC Tag

```graphql
query GetNFCTag($id: ID!) {
  getNFCTag(id: $id) {
    id
    uid
    status
    label
    writtenUrl
    lastScannedAt
    registeredAt
    notes
    table {
      id
      name
      local_id
    }
  }
}
```

---

#### 6. Get NFC Tag by Table

```graphql
query GetNFCTagByTable($tableId: ID!) {
  getNFCTagByTable(tableId: $tableId) {
    id
    uid
    status
    label
    writtenUrl
    lastScannedAt
  }
}
```

---

### Mutations

#### 1. Register NFC Tag

Registers a new NFC tag to a table. Returns the URL to write to the tag.

```graphql
mutation RegisterNFCTag($input: RegisterNFCTagInput!) {
  registerNFCTag(input: $input) {
    id
    uid
    status
    label
    writtenUrl              # URL to write to the NFC tag
    registeredAt
    table {
      id
      name
      local_id
    }
  }
}
```

**Input**:
```graphql
input RegisterNFCTagInput {
  uid: String!              # Hardware UID: "04:A8:14:4A:BE:2A:81"
  tableId: ID!              # Table database ID
  label: String             # Optional friendly name
  notes: String             # Optional admin notes
}
```

**Required Permission**: `manage_nfc_tags`

**Error Responses**:

| Error Code | Message | Scenario |
|------------|---------|----------|
| `NFC_UID_DUPLICATE` | "This NFC tag is already registered" | UID exists in system |
| `TABLE_HAS_ACTIVE_TAG` | "Table already has an active NFC tag" | Table has tag with status=ACTIVE |
| `TABLE_NOT_FOUND` | "Table not found" | Invalid tableId |
| `PERMISSION_DENIED` | "You don't have permission to manage NFC tags" | Missing permission |

---

#### 2. Update NFC Tag Status

Update tag status (mark as lost, damaged, or deactivated).

```graphql
mutation UpdateNFCTagStatus($input: UpdateNFCTagStatusInput!) {
  updateNFCTagStatus(input: $input) {
    id
    status
  }
}
```

**Input**:
```graphql
input UpdateNFCTagStatusInput {
  id: ID!                   # NFC tag database ID
  status: NFCTagStatus!     # ACTIVE, LOST, DAMAGED, DEACTIVATED
}
```

**Required Permission**: `manage_nfc_tags`

---

#### 3. Reassign NFC Tag

Move a tag to a different table. Updates the `writtenUrl`.

```graphql
mutation ReassignNFCTag($input: ReassignNFCTagInput!) {
  reassignNFCTag(input: $input) {
    id
    writtenUrl              # New URL to write to tag
    table {
      id
      name
      local_id
    }
  }
}
```

**Input**:
```graphql
input ReassignNFCTagInput {
  id: ID!                   # NFC tag database ID
  newTableId: ID!           # New table database ID
}
```

**Required Permission**: `manage_nfc_tags`

---

#### 4. Delete NFC Tag

Soft-delete an NFC tag (preserves scan history).

```graphql
mutation DeleteNFCTag($id: ID!) {
  deleteNFCTag(id: $id)     # Returns Boolean!
}
```

**Required Permission**: `manage_nfc_tags`

---

## NFC Technical Implementation

### Dependencies

```yaml
# pubspec.yaml
dependencies:
  nfc_manager: ^3.3.0    # NFC read/write
```

### Platform Configuration

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- NFC Permissions -->
    <uses-permission android:name="android.permission.NFC" />
    
    <!-- Declare NFC feature (optional = true allows install on non-NFC devices) -->
    <uses-feature android:name="android.hardware.nfc" android:required="false" />
    
    <application ...>
        <activity ...>
            <!-- Enable NFC foreground dispatch -->
            <intent-filter>
                <action android:name="android.nfc.action.NDEF_DISCOVERED"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <data android:scheme="https" android:host="ssp.app" />
            </intent-filter>
            
            <intent-filter>
                <action android:name="android.nfc.action.TAG_DISCOVERED"/>
                <category android:name="android.intent.category.DEFAULT"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

#### iOS (`ios/Runner/Info.plist`)

```xml
<key>NFCReaderUsageDescription</key>
<string>SSP NFC Configurator needs NFC access to read and write table tags</string>

<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
    <string>D2760000850101</string>  <!-- NDEF -->
</array>

<key>com.apple.developer.nfc.readersession.felica.systemcodes</key>
<array/>

<key>com.apple.developer.nfc.readersession.formats</key>
<array>
    <string>NDEF</string>
    <string>TAG</string>
</array>
```

Also enable "Near Field Communication Tag Reading" capability in Xcode.

---

### NFC Service Implementation

```dart
// lib/core/nfc/nfc_service.dart

import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';

class NFCService {
  NfcTag? _currentTag;
  
  /// Check if device supports NFC
  Future<bool> isAvailable() async {
    return await NfcManager.instance.isAvailable();
  }
  
  /// Start NFC session and listen for tags
  Future<void> startSession({
    required Function(String uid, NfcTag tag) onTagDetected,
    required Function(String error) onError,
  }) async {
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          _currentTag = tag;
          
          final uid = _extractUid(tag);
          if (uid != null) {
            onTagDetected(uid, tag);
          } else {
            onError('Could not read tag UID');
          }
        },
        onError: (NfcError error) async {
          onError(error.message);
        },
      );
    } catch (e) {
      onError('Failed to start NFC session: $e');
    }
  }
  
  /// Extract UID from tag (handles multiple NFC types)
  String? _extractUid(NfcTag tag) {
    List<int>? identifier;
    
    // Try each NFC technology
    final nfca = NfcA.from(tag);
    if (nfca != null) {
      identifier = nfca.identifier;
    }
    
    final nfcb = NfcB.from(tag);
    if (nfcb != null && identifier == null) {
      identifier = nfcb.identifier;
    }
    
    final nfcf = NfcF.from(tag);
    if (nfcf != null && identifier == null) {
      identifier = nfcf.identifier;
    }
    
    final nfcv = NfcV.from(tag);
    if (nfcv != null && identifier == null) {
      identifier = nfcv.identifier;
    }
    
    final isoDep = IsoDep.from(tag);
    if (isoDep != null && identifier == null) {
      identifier = isoDep.identifier;
    }
    
    if (identifier == null) return null;
    
    // Format as colon-separated hex string: "04:A8:14:4A:BE:2A:81"
    return identifier
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }
  
  /// Write URL to NFC tag as NDEF record
  Future<void> writeUrl(String url) async {
    if (_currentTag == null) {
      throw NFCException('No tag available. Scan a tag first.');
    }
    
    final ndef = Ndef.from(_currentTag!);
    
    if (ndef == null) {
      throw NFCException('Tag does not support NDEF format');
    }
    
    if (!ndef.isWritable) {
      throw NFCException('Tag is write-protected');
    }
    
    // Create NDEF message with URL record
    final message = NdefMessage([
      NdefRecord.createUri(Uri.parse(url)),
    ]);
    
    // Check if URL fits on tag
    final messageSize = message.byteLength;
    if (messageSize > ndef.maxSize) {
      throw NFCException(
        'URL too long for tag ($messageSize bytes > ${ndef.maxSize} max)'
      );
    }
    
    try {
      await ndef.write(message);
    } catch (e) {
      throw NFCException('Failed to write to tag: $e');
    }
  }
  
  /// Stop NFC session
  void stopSession() {
    NfcManager.instance.stopSession();
    _currentTag = null;
  }
  
  /// Get current tag (for write after read)
  NfcTag? get currentTag => _currentTag;
}

class NFCException implements Exception {
  final String message;
  NFCException(this.message);
  
  @override
  String toString() => message;
}
```

---

### URL Builder

```dart
// lib/core/nfc/nfc_url_builder.dart

class NFCUrlBuilder {
  static const String baseUrl = 'https://ssp.app/t';
  
  /// Build NFC URL for a table
  /// Format: ssp.app/t/{orgSlug}/{locationSlug}/{tableLocalId}
  static String buildUrl({
    required String organizationSlug,
    required String locationSlug,
    required int tableLocalId,
  }) {
    return '$baseUrl/$organizationSlug/$locationSlug/$tableLocalId';
  }
  
  /// Parse URL to extract components (for verification)
  static NFCUrlComponents? parseUrl(String url) {
    final regex = RegExp(r'ssp\.app/t/([^/]+)/([^/]+)/(\d+)');
    final match = regex.firstMatch(url);
    
    if (match == null) return null;
    
    return NFCUrlComponents(
      organizationSlug: match.group(1)!,
      locationSlug: match.group(2)!,
      tableLocalId: int.parse(match.group(3)!),
    );
  }
}

class NFCUrlComponents {
  final String organizationSlug;
  final String locationSlug;
  final int tableLocalId;
  
  NFCUrlComponents({
    required this.organizationSlug,
    required this.locationSlug,
    required this.tableLocalId,
  });
}
```

---

## State Management

### Using Riverpod

```dart
// lib/features/scan/scan_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Scan state enum
enum ScanStatus {
  initial,       // App just opened, checking NFC
  ready,         // NFC ready, waiting for tag
  tagDetected,   // Tag scanned, selecting table
  registering,   // API call in progress
  writing,       // Writing URL to tag
  success,       // Registration complete
  error,         // Something went wrong
}

// State class
class ScanState {
  final ScanStatus status;
  final String? detectedUid;
  final String? selectedTableId;
  final NFCTag? registeredTag;
  final String? errorMessage;
  final List<NFCTag> sessionHistory;
  final bool writeUrlEnabled;
  
  const ScanState({
    this.status = ScanStatus.initial,
    this.detectedUid,
    this.selectedTableId,
    this.registeredTag,
    this.errorMessage,
    this.sessionHistory = const [],
    this.writeUrlEnabled = true,
  });
  
  ScanState copyWith({
    ScanStatus? status,
    String? detectedUid,
    String? selectedTableId,
    NFCTag? registeredTag,
    String? errorMessage,
    List<NFCTag>? sessionHistory,
    bool? writeUrlEnabled,
  }) {
    return ScanState(
      status: status ?? this.status,
      detectedUid: detectedUid ?? this.detectedUid,
      selectedTableId: selectedTableId ?? this.selectedTableId,
      registeredTag: registeredTag ?? this.registeredTag,
      errorMessage: errorMessage ?? this.errorMessage,
      sessionHistory: sessionHistory ?? this.sessionHistory,
      writeUrlEnabled: writeUrlEnabled ?? this.writeUrlEnabled,
    );
  }
}

// State notifier
class ScanNotifier extends StateNotifier<ScanState> {
  final NFCService _nfcService;
  final GraphQLClient _apiClient;
  
  ScanNotifier(this._nfcService, this._apiClient) : super(const ScanState());
  
  /// Initialize NFC and start scanning
  Future<void> initialize() async {
    final isAvailable = await _nfcService.isAvailable();
    
    if (!isAvailable) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'NFC is not available on this device',
      );
      return;
    }
    
    await startScanning();
  }
  
  /// Start listening for NFC tags
  Future<void> startScanning() async {
    state = state.copyWith(
      status: ScanStatus.ready,
      detectedUid: null,
      selectedTableId: null,
      registeredTag: null,
      errorMessage: null,
    );
    
    await _nfcService.startSession(
      onTagDetected: (uid, tag) {
        state = state.copyWith(
          status: ScanStatus.tagDetected,
          detectedUid: uid,
        );
      },
      onError: (error) {
        state = state.copyWith(
          status: ScanStatus.error,
          errorMessage: error,
        );
      },
    );
  }
  
  /// Select a table for the detected tag
  void selectTable(String tableId) {
    state = state.copyWith(selectedTableId: tableId);
  }
  
  /// Toggle write URL checkbox
  void toggleWriteUrl(bool enabled) {
    state = state.copyWith(writeUrlEnabled: enabled);
  }
  
  /// Register tag and optionally write URL
  Future<void> registerTag({
    required String tableId,
    required String organizationUuid,
    required String locationSlug,
    required int tableLocalId,
    String? label,
  }) async {
    final uid = state.detectedUid;
    if (uid == null) return;

    state = state.copyWith(status: ScanStatus.registering);

    try {
      // 1. Register in backend via registerNFCTag mutation
      final result = await _apiClient.mutate(
        MutationOptions(
          document: gql('''
            mutation RegisterNFCTag(\$input: RegisterNFCTagInput!) {
              registerNFCTag(input: \$input) {
                id
                uid
                status
                label
                writtenUrl
                registeredAt
                table {
                  id
                  name
                  local_id
                }
              }
            }
          '''),
          variables: {
            'input': {
              'uid': uid,
              'tableId': tableId,
              'label': label,
            },
          },
        ),
      );
      
      if (result.hasException) {
        throw result.exception!;
      }

      final tagData = result.data!['registerNFCTag'];
      final tag = NFCTag.fromJson(tagData);

      // 2. Write URL to tag if enabled
      // Use writtenUrl from the response - the backend generates the correct URL
      if (state.writeUrlEnabled && tagData['writtenUrl'] != null) {
        state = state.copyWith(status: ScanStatus.writing);

        // writtenUrl is returned by backend: ssp.app/t/{orgUuid}/{locationSlug}/{tableLocalId}
        await _nfcService.writeUrl(tagData['writtenUrl']);
      }
      
      // 3. Success!
      state = state.copyWith(
        status: ScanStatus.success,
        registeredTag: tag,
        sessionHistory: [...state.sessionHistory, tag],
      );
      
    } catch (e) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: _parseError(e),
      );
    }
  }
  
  /// Reset for next tag scan
  void resetForNextTag() {
    _nfcService.stopSession();
    startScanning();
  }
  
  /// Parse GraphQL errors to user-friendly messages
  String _parseError(dynamic error) {
    if (error is OperationException) {
      final graphqlErrors = error.graphqlErrors;
      if (graphqlErrors.isNotEmpty) {
        final code = graphqlErrors.first.extensions?['code'];
        switch (code) {
          case 'NFC_UID_DUPLICATE':
            return 'This NFC tag is already registered to another table.';
          case 'TABLE_HAS_ACTIVE_TAG':
            return 'This table already has an active NFC tag. Remove it first.';
          case 'PERMISSION_DENIED':
            return 'You don\'t have permission to manage NFC tags.';
          default:
            return graphqlErrors.first.message;
        }
      }
    }
    return error.toString();
  }
  
  @override
  void dispose() {
    _nfcService.stopSession();
    super.dispose();
  }
}

// Provider
final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  final nfcService = ref.watch(nfcServiceProvider);
  final apiClient = ref.watch(graphqlClientProvider);
  return ScanNotifier(nfcService, apiClient);
});
```

---

## Project Structure

```
ssp_nfc_configurator/
├── android/
│   └── app/src/main/AndroidManifest.xml    # NFC permissions
├── ios/
│   └── Runner/Info.plist                    # NFC permissions
├── lib/
│   ├── main.dart                            # Entry point
│   ├── app.dart                             # App configuration
│   │
│   ├── core/
│   │   ├── api/
│   │   │   ├── graphql_client.dart          # GraphQL setup
│   │   │   ├── queries.graphql              # All queries (see below)
│   │   │   └── mutations.graphql            # All mutations (see below)
│   │   │
│   │   ├── nfc/
│   │   │   ├── nfc_service.dart             # NFC read/write
│   │   │   └── nfc_url_builder.dart         # URL construction
│   │   │
│   │   ├── storage/
│   │   │   └── secure_storage.dart          # JWT persistence
│   │   │
│   │   └── theme/
│   │       └── app_theme.dart               # SSP brand colors
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── auth_provider.dart
│   │   │   └── auth_state.dart
│   │   │
│   │   ├── location/
│   │   │   ├── location_select_screen.dart
│   │   │   ├── location_provider.dart
│   │   │   └── location_state.dart
│   │   │
│   │   ├── scan/
│   │   │   ├── scan_screen.dart             # Main scanning UI
│   │   │   ├── scan_provider.dart           # State management
│   │   │   ├── scan_state.dart
│   │   │   └── widgets/
│   │   │       ├── nfc_pulse_animation.dart
│   │   │       ├── table_selector.dart
│   │   │       ├── writing_indicator.dart
│   │   │       └── success_card.dart
│   │   │
│   │   ├── tables/
│   │   │   ├── tables_screen.dart           # All tables view
│   │   │   └── tables_provider.dart
│   │   │
│   │   ├── session/
│   │   │   └── session_summary_screen.dart
│   │   │
│   │   └── settings/
│   │       └── settings_screen.dart
│   │
│   ├── models/
│   │   ├── user.dart
│   │   ├── organization.dart
│   │   ├── location.dart
│   │   ├── table.dart
│   │   └── nfc_tag.dart
│   │
│   └── widgets/
│       ├── ssp_button.dart
│       ├── ssp_card.dart
│       ├── loading_overlay.dart
│       └── error_dialog.dart
│
├── pubspec.yaml
└── README.md
```

---

## Complete GraphQL Operations

### queries.graphql

```graphql
# Authentication check
query GetCurrentUser {
  me {
    id
    name
    email
  }
}

# Get all locations user has access to
query GetUserLocations {
  getUserLocations {
    id
    name
    organization {
      id
      name
      uuid
    }
  }
}

# Get tables for a location with NFC status
query GetLocationTables($locationId: ID!) {
  getLocationTables(locationId: $locationId) {
    id
    name
    local_id
    number_of_seats
    status
    nfcTag {
      id
      uid
      status
      label
      writtenUrl
      lastScannedAt
    }
    location {
      id
      name
      organization {
        uuid
      }
    }
  }
}

# Get all NFC tags for a location
query GetNFCTagsByLocation($locationId: ID!) {
  getNFCTagsByLocation(locationId: $locationId) {
    id
    uid
    status
    label
    writtenUrl
    lastScannedAt
    registeredAt
    notes
    table {
      id
      name
      local_id
    }
    registeredBy {
      id
      name
    }
  }
}

# Get single NFC tag details
query GetNFCTag($id: ID!) {
  getNFCTag(id: $id) {
    id
    uid
    status
    label
    writtenUrl
    lastScannedAt
    registeredAt
    notes
    table {
      id
      name
      local_id
    }
  }
}

# Get NFC tag assigned to a specific table
query GetNFCTagByTable($tableId: ID!) {
  getNFCTagByTable(tableId: $tableId) {
    id
    uid
    status
    label
    writtenUrl
    lastScannedAt
  }
}
```

### mutations.graphql

```graphql
# Login mutation
mutation LoginSSPUser($email: String!, $password: String!) {
  loginSSPUser(email: $email, password: $password) {
    token
    user {
      id
      name
      email
    }
    requiresTwoFactor
    requiresOrganizationSelection
    challenge_token
    selection_token
    organizations {
      id
      name
    }
  }
}

# Register a new NFC tag to a table
mutation RegisterNFCTag($input: RegisterNFCTagInput!) {
  registerNFCTag(input: $input) {
    id
    uid
    status
    label
    writtenUrl
    registeredAt
    table {
      id
      name
      local_id
    }
  }
}

# Update NFC tag status
mutation UpdateNFCTagStatus($input: UpdateNFCTagStatusInput!) {
  updateNFCTagStatus(input: $input) {
    id
    status
  }
}

# Reassign NFC tag to different table
mutation ReassignNFCTag($input: ReassignNFCTagInput!) {
  reassignNFCTag(input: $input) {
    id
    writtenUrl
    table {
      id
      name
      local_id
    }
  }
}

# Delete NFC tag
mutation DeleteNFCTag($id: ID!) {
  deleteNFCTag(id: $id)
}
```

---

## Dependencies

```yaml
# pubspec.yaml
name: ssp_nfc_configurator
description: NFC tag configuration tool for SSP restaurants
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.9
  
  # GraphQL
  graphql_flutter: ^5.1.2
  
  # NFC
  nfc_manager: ^3.3.0
  
  # Storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2
  
  # Navigation
  go_router: ^13.0.0
  
  # UI
  flutter_svg: ^2.0.9
  shimmer: ^3.0.0
  lottie: ^2.7.0           # For animations
  
  # Utilities
  intl: ^0.18.1            # Date formatting
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  mockito: ^5.4.4
  build_runner: ^2.4.8

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/animations/
```

---

## Error Messages (Localization Ready)

```dart
// lib/core/constants/error_messages.dart

class ErrorMessages {
  // NFC Errors
  static const nfcNotAvailable = 'NFC is not available on this device';
  static const nfcNotEnabled = 'Please enable NFC in your device settings';
  static const tagNotSupported = 'This tag type is not supported';
  static const tagNotWritable = 'This tag is write-protected';
  static const tagTooSmall = 'URL is too long for this tag';
  static const tagReadFailed = 'Failed to read tag. Try again.';
  static const tagWriteFailed = 'Failed to write to tag. Keep phone steady.';
  static const tagRemoved = 'Tag was removed. Keep phone on tag while writing.';
  
  // API Errors
  static const uidDuplicate = 'This NFC tag is already registered.';
  static const tableHasTag = 'This table already has an active NFC tag.';
  static const tableNotFound = 'Table not found.';
  static const permissionDenied = 'You don\'t have permission to manage NFC tags.';
  static const networkError = 'Network error. Check your connection.';
  static const serverError = 'Server error. Please try again later.';
  static const sessionExpired = 'Session expired. Please log in again.';
  
  // General
  static const unknownError = 'Something went wrong. Please try again.';
}
```

---

## Testing Checklist

### Unit Tests
- [ ] NFCService.extractUid handles all NFC types
- [ ] NFCUrlBuilder.buildUrl generates correct format
- [ ] NFCUrlBuilder.parseUrl extracts components
- [ ] ScanNotifier state transitions
- [ ] Error message parsing

### Integration Tests
- [ ] Login flow with valid credentials
- [ ] Login flow with invalid credentials
- [ ] Location list loads correctly
- [ ] Tables list loads with NFC status
- [ ] Tag registration API call succeeds
- [ ] Tag registration handles duplicate UID error
- [ ] Tag registration handles permission error

### Manual Testing
- [ ] NFC read on Android
- [ ] NFC read on iOS
- [ ] NFC write on Android
- [ ] NFC write on iOS
- [ ] Tag removed during write (error handling)
- [ ] Multiple tags in sequence
- [ ] Session history persists during session
- [ ] Logout clears session

### Device Testing
- [ ] Android with NFC
- [ ] Android without NFC (graceful error)
- [ ] iPhone with NFC (iPhone 7+)
- [ ] iPad (no NFC - graceful error)

---

## App Store Notes

### Android (Play Store)
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- NFC permission declared
- App category: Business / Utilities

### iOS (App Store)
- Minimum iOS: 13.0
- NFC capability required
- Privacy description for NFC usage
- App category: Business

---

## Future Enhancements (Phase 2)

### Batch Mode
Pre-assign tables, then scan tags in sequence without selecting each time.

### Verification Mode
Scan existing tags to verify URL is correct and tag is readable.

### Offline Support
Queue registrations when offline, sync when back online.

### Tag Replacement
Streamlined flow for replacing damaged/lost tags.

### Export Reports
Generate PDF/CSV of session registrations for records.

### Multi-Language
Support for Spanish, French (for Canada/Mexico markets).
