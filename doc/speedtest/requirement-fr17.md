# Requirement Specification: Speed Test Server Selection (FR-017)

## 1. Introduction
This document outlines the requirements for implementing a dynamic server selection feature for the Speed Test functionality within the PrivacyGUI application. This feature allows users to manually select a specific speed test server to ensure more accurate and relevant test results.

## 2. Scope
The scope of this feature includes:
- **Core Logic:** Integration of new JNAP services and actions to fetch server lists.
- **UI Implementation:**
    - **Health Check Page:** A dropdown menu for server selection.
    - **Dashboard & Instant Verify:** A dialog-based selection flow.
- **Backward Compatibility:** Graceful fallback for devices that do not support this feature.

## 3. Functional Requirements

### 3.1. Server List Retrieval
- The application **MUST** fetch the list of available speed test servers using the JNAP action `GetCloseHealthCheckServers`.
- The data source **MUST** be the `HealthCheckManager2` service.
- **Data Model:** The server list **MUST** be parsed into a `HealthCheckServer` model containing:
    - `serverID` (int/string)
    - `serverName` (string)
    - `serverLocation` (string)
    - `serverCountry` (string)

### 3.2. Manual Server Selection
- The application **MUST** allow the user to select one server from the retrieved list.
- **Mandatory Selection:** The user **MUST** select a server before a speed test can be initiated in the Health Check view. There is **NO** default server selection.

### 3.3. Speed Test Execution
- When a server is selected, the `serverID` **MUST** be passed as the `targetServerId` parameter in the `runHealthCheck` JNAP command.
- If no server is selected (only applicable in legacy fallback), the `targetServerId` parameter **MUST** be omitted.

### 3.4. Feature Availability Check
- The application **MUST** check for the availability of the `HealthCheckManager2` service via `ServiceHelper.isSupportHealthCheckManager2`.
- If the service is **NOT** supported or the server list is empty, the Server Selection UI **MUST** be hidden, and the speed test **MUST** function in legacy mode (automatic server selection by the router).

## 4. UI/UX Requirements

### 4.1. Health Check Page (`SpeedTestView`)
- **Display:** A `DropdownButton` (or equivalent styled component) displaying the list of servers (`serverName` - `serverLocation`).
- **State:**
    - If `isSupportHealthCheckManager2` is `true` AND server list is not empty: Show Dropdown.
    - If `selectedServer` is `null`: The "GO" (Start Test) button **MUST** be disabled.
    - Upon selection: The "GO" button becomes enabled.

### 4.2. Dashboard & Instant Verify (`PortAndSpeed`, `SpeedTestWidget`)
- **Interaction:**
    - User clicks the "Speed Test" / "GO" button.
    - **Check:** If `isSupportHealthCheckManager2` is `true` AND server list is not empty:
        - **Action:** Open a Dialog (`AppDialog`) presenting the list of servers.
        - **Confirm:** User selects a server and confirms -> Speed test starts with `targetServerId`.
        - **Cancel:** User cancels -> Speed test does **NOT** start.
    - **Check:** If `isSupportHealthCheckManager2` is `false`:
        - **Action:** Speed test starts immediately (Legacy behavior) without `targetServerId`.

## 5. API / Integration Requirements

### 5.1. JNAP Service
- **Service Name:** `HealthCheckManager2`
- **URI:** `http://linksys.com/jnap/healthcheck/HealthCheckManager/2`

### 5.2. JNAP Action: GetCloseHealthCheckServers
- **Action:** `http://linksys.com/jnap/healthcheck/GetCloseHealthCheckServers`
- **Input:** None.
- **Output:**
    ```json
    {
      "healthCheckServers": [
        {
          "serverID": "1234",
          "serverName": "Ookla Server",
          "serverLocation": "City, Country",
          ...
        }
      ]
    }
    ```

### 5.3. JNAP Action: RunHealthCheck (Updated)
- **Action:** `http://linksys.com/jnap/healthcheck/RunHealthCheck`
- **Input Parameter Extensions:**
    - `targetServerId`: (Optional) The ID of the selected server.

## 6. Acceptance Criteria
1.  **Server List Population:** The dropdown/dialog is correctly populated with servers returned from the router.
2.  **Mandatory Selection:** In the Health Check page, the test cannot be started without selecting a server.
3.  **Parameter Passing:** The selected `serverID` is correctly sent in the JNAP payload as `targetServerId`.
4.  **Legacy Fallback:** Routers without `HealthCheckManager2` support continue to run speed tests normally without the selection UI.
5.  **Dashboard Flow:** The dialog appears correctly on the Dashboard and Instant Verify pages when supported.
