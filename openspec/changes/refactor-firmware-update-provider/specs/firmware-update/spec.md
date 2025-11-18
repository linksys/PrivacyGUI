## ADDED Requirements

### Requirement: Firmware Update Availability Check
The system SHALL allow checking for available firmware updates.

#### Scenario: User checks for updates
- **WHEN** the user requests to check for firmware updates
- **THEN** the system SHALL query the router for available updates
- **AND** the system SHALL update the firmware status with any found updates

### Requirement: Firmware Update Policy Management
The system SHALL allow setting the firmware update policy (automatic or manual).

#### Scenario: User sets automatic update policy
- **WHEN** the user selects the automatic update policy
- **THEN** the system SHALL configure the router to automatically update firmware

#### Scenario: User sets manual update policy
- **WHEN** the user selects the manual update policy
- **THEN** the system SHALL configure the router to require manual initiation for firmware updates

### Requirement: Firmware Update Initiation
The system SHALL allow initiating a firmware update process.

#### Scenario: User initiates update
- **WHEN** the user initiates a firmware update
- **THEN** the system SHALL start the firmware update process on the router
- **AND** the system SHALL monitor the update progress

### Requirement: Manual Firmware Upload
The system SHALL allow uploading firmware files manually.

#### Scenario: User uploads firmware file
- **WHEN** the user provides a firmware file for manual upload
- **THEN** the system SHALL upload the file to the router
- **AND** the system SHALL initiate the manual firmware update process

### Requirement: Firmware Update Status Monitoring
The system SHALL provide real-time monitoring of the firmware update status for all relevant devices.

#### Scenario: System monitors update progress
- **WHEN** a firmware update is in progress
- **THEN** the system SHALL continuously poll the router for update status
- **AND** the system SHALL display the current operation (e.g., downloading, installing, rebooting) and progress percentage

### Requirement: Post-Update Router Reconnection Handling
The system SHALL handle router reconnection after a firmware update.

#### Scenario: Router reboots after update
- **WHEN** the router reboots as part of a firmware update
- **THEN** the system SHALL wait for the router to come back online
- **AND** the system SHALL resume normal operation or guide the user to reconnect
