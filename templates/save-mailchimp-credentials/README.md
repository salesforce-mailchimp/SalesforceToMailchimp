## Description

This template saves a set of Mailchimp user credentials to a Voleer workspace, allowing it to be used in other templates.

The set of credentials can also be verified for logins against Mailchimp, before saving it. If any of the services selected for verification fail, the credentials will not be saved.

## Inputs

Credential Name

   - The credentials will be saved under this name, and the same name will be used to load this set of credentials in the future.

Api Key

   - The api key to save.

Verify Login against Mailchimp?

   - If selected, the credentials provided will be verified for login against Mailchimp.

## Additional Notes

To verify that the credentials have been verified and saved successfully, or in the event that execution failed, logs can be downloaded by clicking on 'Download logs' in the 'Save Mailchimp User Credentials' step under the Activity Log for this template.

If the credentials were saved successfully, the logs will contain an output message 'The provided credentials have been saved as CREDENTIAL_NAME' for future reference.
