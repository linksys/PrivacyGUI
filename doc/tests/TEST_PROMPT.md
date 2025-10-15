# Prompt for AI Tester

**Objective:**
Your goal is to execute the E2E (End-to-End) test cases defined in the YAML files within this directory to verify the functionality of the device's web UI, which is a chrome-devtools MCP (Management and Control Plane).

**Glossary:**
*   **General settings:** The settings menu accessible from the icon on the top-right of the screen.
*   **UI version:** The UI version is displayed within the "General settings" pop-up.

**Instructions:**
1.  **Environment Setup:**
    *   For each test case, open a new, clean browser session to ensure a stateless environment.
    *   Navigate to the web UI URL: `http://192.168.1.1`.

2.  **Test Execution Scope:**
    *   You should be prepared to execute a subset of tests based on the criteria provided in the execution command. The criteria can be:
        a.  **All Tests:** Execute all test cases from all `.yaml` files in this directory sequentially.
        b.  **By Test Case ID:** Execute a specific list of tests by their `id` (e.g., `1, 5, 14`).
        c.  **By Tag:** Execute all test cases that contain a specific tag (e.g., `firewall`).
    *   Follow the **Test Steps** for each selected test case precisely as written.
    *   For each step that includes a `Verify:` point, perform the specified check immediately. This is your assertion.
    *   If all steps and verification points pass, mark the test case as **PASSED**.

3.  **Error Handling and Data Collection:**
    *   If any `Verify:` step fails, immediately mark the test case as **FAILED**.
    *   Upon failure, perform the following data collection steps:
        a.  **Collect Network Requests:** Export all browser network requests as a `.har` file.
        b.  **Take a Screenshot:** Capture a full-page screenshot of the UI at the moment of failure.
        c.  **Collect UI Logs:**
            *   Press the shortcut key combination `CTRL + SHIFT + L` six times consecutively.
            *   Alternatively, if applicable, tap the top bar of the application six times.
            *   Copy the collected logs to a text file.

4.  **Reporting:**
    *   After completing all test cases, generate a single, comprehensive **HTML Test Report**.
    *   The report must include:
        a.  **Header:** Date, Device Firmware Version, Device UI Version, and Browser.
        b.  **Summary Chart:** A pie chart or bar chart visualizing the number of Passed vs. Failed tests.
        c.  **Detailed Results Table:** A table with the following columns:
            | Test Case ID | Symbolic ID | Status (with color coding) | Notes (if FAILED) |
            |:---|:---|:---|:---|
        d.  **Embedded Artifacts:** For any FAILED test case, the "Notes" column should contain links to the collected evidence (logs, network requests, screenshots).

    **Example Markdown Structure for the Report (to be rendered as HTML):**
    ```markdown
    ## E2E Test Execution Report

    **Date:** [YYYY-MM-DD]
    **Device Firmware Version:** [Firmware Version Under Test]
    **Device UI Version:** [UI Version Under Test]
    **Browser:** [Browser Name and Version]

    ### Summary
    ![Test Results Chart](path/to/chart.png)

    ### Detailed Results
    | Test Case ID | Symbolic ID                       | Status | Notes (if FAILED)                               |
    | :----------- | :-------------------------------- | :----- | :---------------------------------------------- |
    | 1            | ADM_UPNP_TOGGLE_AND_SAVE          | PASSED | -                                               |
    | 2            | ADM_UPNP_DEPENDENCY_CHECK         | FAILED | Step 3: Checkboxes were still visible. [Screenshot](path/to/screenshot.png) - [HAR](path/to/har.har) - [Logs](path/to/logs.txt) |
    | ...          | ...                               | ...    | ...                                             |
    ```