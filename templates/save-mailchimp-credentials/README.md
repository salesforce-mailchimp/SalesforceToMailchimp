## Description

This template saves a set of Azure AD user credentials to a Voleer workspace, allowing it to be used in other templates.

The set of credentials can also be verified for logins against various Microsoft services, before saving it. If any of the services selected for verification fail, the credentials will not be saved.

## Inputs

Credential Name

   - The credentials will be saved under this name, and the same name will be used to load this set of credentials in the future.

Username

   - The username to save.

Password

   - The password to save.

Verify Login against Azure?

   - If selected, the credentials provided will be verified for login against Azure.

Verify Login against Azure AD?

   - If selected, the credentials provided will be verified for login against Azure AD.

Verify Login against Exchange Online?

   - If selected, the credentials provided will be verified for login against Exchange Online.

Verify Login against MS Online?

   - If selected, the credentials provided will be verified for login against MS Online.

Verify Login against Office 365 Security and Compliance Center?

   - If selected, the credentials provided will be verified for login against Office 365 Security and Compliance Center.

## Additional Notes

The verification steps will not be successful if the user account has multi-factor authentication (MFA) enabled.

To verify that the credentials have been verified and saved successfully, or in the event that execution failed, logs can be downloaded by clicking on 'Download logs' in the 'Save Azure AD User Credentials' step under the Activity Log for this template.

If the credentials were saved successfully, the logs will contain an output message 'The provided credentials have been saved as CREDENTIAL_NAME' for future reference.
