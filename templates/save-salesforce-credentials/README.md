## Description

This template saves a set of Salesforce credentials to a Voleer workspace, allowing it to be used in other templates.

The set of credentials can also be verified against Salesforce before saving it. If the verification fails, the credentials will not be saved.

## Inputs

Credential Name

   - This name will be used to load this set of credentials in the future.

Client ID

   - The client ID to save.

Client Secret

   - The client secret to save.

Username

   - The username to save.

Password

   - The password to save.

Security Token

   - The security token to save.

Verify Credentials?

   - If selected, the provided credentials will be verified against Salesforce.

## Additional Notes

To verify that the credentials have been verified and saved successfully, or in the event that execution failed, logs can be downloaded by clicking on 'Download logs' in the 'Save Salesforce Credentials' step under the Activity Log.

If the credentials were saved successfully, the logs will contain an output message 'The provided credentials have been saved as CREDENTIAL_NAME' for future reference.
