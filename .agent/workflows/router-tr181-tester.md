# Router TR-181 (USP) Tester Workflow

This workflow provides instructions for AI agents and developers to query, test, and verify TR-181 data models and operations directly on the router using SSH.

## Prerequisites
- The `tools/router_tr181_tester.sh` script must exist and be executable.
- The router must be accessible at `192.168.1.1`.

## How to use the Tool
You can use the helper script to execute commands on the router without worrying about SSH password prompts. It automatically handles the connection.

```bash
./tools/router_tr181_tester.sh "<command>"
```

## Standard Verification Procedures

### 1. Verify a Data Field (GET)
To verify if a field exists and check its value, use `ubus call bbfdm`:
```bash
./tools/router_tr181_tester.sh "ubus call bbfdm get '{\"path\":\"Device.DeviceInfo.Manufacturer\"}'"
```
You can also use OBUSPA CLI (which goes through the TR-181 Agent layer):
```bash
./tools/router_tr181_tester.sh "obuspa -s /tmp/usp_cli -c get 'Device.DeviceInfo.'"
```

### 2. Verify an Operation (Operate) - Synchronous Check (bbfdm layer)
To check if a firmware operation is wrongly implemented as synchronous (returns output instantly without backgrounding), directly query `bbfdm`:
```bash
./tools/router_tr181_tester.sh "ubus call bbfdm operate '{\"path\":\"Device.IP.Diagnostics.UploadDiagnostics()\", \"input\": {\"UploadURL\": \"http://example.com/100m.bin\", \"TestFileLength\": \"1000000\"}}'"
```
* **Analysis**: If the response contains the actual diagnostic results (e.g., `Status`, `TestBytesSent`) in the `results` array, the operation is running **synchronously**. This will break USP non-blocking expectations.

### 3. Verify an Operation (Operate) - Asynchronous Check (OBUSPA layer)
To verify how the USP Agent (OBUSPA) processes the command based on TR-181 specification:
```bash
./tools/router_tr181_tester.sh "obuspa -s /tmp/usp_cli -c operate 'Device.IP.Diagnostics.UploadDiagnostics()' '{\"UploadURL\": \"http://example.com/100m.bin\"}'"
```
* **Analysis**: If it prints `Asynchronous Operation Started successfully` and creates a `Device.LocalAgent.Request` object, OBUSPA considers it asynchronous and is waiting for an `OperationComplete` event.

### 4. Verify UBUS Events (The missing link)
To check if `bbfdm` actually emits an event when an operation finishes, use `ubus listen` combined with the operate command:
```bash
./tools/router_tr181_tester.sh "ubus listen & sleep 1; obuspa -s /tmp/usp_cli -c operate 'Device.IP.Diagnostics.IPPing()' '{\"Host\":\"8.8.8.8\", \"NumberOfRepetitions\":\"1\"}'; sleep 3; killall ubus"
```
* **Analysis**: If you see `{ "bbfdm.event": {"name": "OperationComplete", ...} }` in the output, the asynchronous flow works perfectly. If not, the operation is broken for USP and the app will experience SSE timeouts.

### 5. TR-369 Command Limitations & The "Death Chain" Bug
If an operation is missing events, be aware of these critical TR-369 (USP) architectural constraints:
* **No Polling Commands**: Unlike TR-069, USP Commands (e.g., `Device.IP.Diagnostics.UploadDiagnostics()`) **cannot be read via GET**. `obuspa -c get` will return `Path is invalid`. You cannot poll for diagnostic results via `usp_bridge`.
* **The Death Chain**: If `bbfdm` erroneously returns operation results synchronously (instead of sending a UBUS Event), OBUSPA will **drop the data** entirely because TR-181 mandates the command is asynchronous. The data never reaches `usp_bridge` or the App. This is unfixable from the App side and requires firmware correction.

## When to use this skill
Use this workflow whenever the user asks to `/router-tr181-tester`, `/verify-tr`, debug SSE timeouts, or confirm if the firmware properly supports a TR-181 command.
