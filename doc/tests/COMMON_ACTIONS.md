# Common Actions

### Login
1. Navigate to the login page.
2. Toggle the "show password" button to ensure the password field is in a known state (visible). If a "hide password" button is found instead, the password is a already visible.
3. Input the admin password "7qW19st5m@".
4. **AI Tester Verification:** To confirm the input is correct, use the `evaluate_script` tool to directly read the `value` of the password input field.
   - The script to execute is: `(element) => { return element.value; }`
   - **Verify:** The value returned by the script **must** be exactly "7qW19st5m@".
5. **If Verification Fails:** The input component may not have registered the full string. Clear the field (e.g., by filling with an empty string) and repeat steps 3 and 4 until the verification passes.
6. Once the input is verified, click the "Login" button.
   - **Verify:** The user is successfully logged in and redirected to the dashboard.

### Logout
1. From the top bar of the right-top icon, open the general settings.
2. Click the "Logout" button.
   - **Verify:** The user is logged out and redirected to the login page.