<#
.SYNOPSIS
    Save Salesforce Credentials

.DESCRIPTION
    Saves a set of Salesforce credentials.

.OUTPUTS

#>
[CmdletBinding()]
[OutputType()]
param (
    # Skip Task?
    # Selects whether this task should be skipped.
    [Parameter(Mandatory=$false)]
    [ValidateSet("Yes", "No")]
    [String]$skipTask = "No",

    # Credentials Name
    # The name used to save the credentials.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$credentialName,

    # Application ID
    # The application ID.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$clientId,

    # Client Secret
    # The client secret.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$clientSecret,

    # Username
    # The username.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$username,

    # Password
    # The password.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$password,

    # Security Token
    # The security token.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$securityToken,

    # Verify Credentials?
    # Select whether to verify the provided credentials against Salesforce.
    [Parameter(Mandatory=$true)]
    [ValidateSet("Yes", "No")]
    [String]$verifyCredentials = "No"
)

####################################################################################################
# Verify the PowerShell edition and version
####################################################################################################

$RequiredPSEdition = "Desktop"
$MinimumPowerShellVersion = [Version]"5.1"
if ($PSVersionTable.PSEdition -ne $RequiredPSEdition) {
    Write-Warning ("The PowerShell edition required is $($RequiredPSEdition). The edition installed is $($PSVersionTable.PSEdition).")
    exit
}
if ($PSVersionTable.PSVersion -lt $MinimumPowerShellVersion) {
    Write-Warning ("The minimum PowerShell version required is $($MinimumPowerShellVersion.ToString()). The current version installed is $($PSVersionTable.PSVersion.ToString()).")
    exit
}

####################################################################################################
# Declarations
####################################################################################################

# Set the default parameter values for the Write-OutputMessage function
$PSDefaultParameterValues["Write-OutputMessage:AppendNewLines"] = 1
$PSDefaultParameterValues["Write-OutputMessage:ToWarning"] = [Switch]::Present

####################################################################################################
# Import functions
####################################################################################################

@(
    "SalesForceFunctions"
) | ForEach-Object -Process {
    . "$($PSScriptRoot)\..\..\functions\$($_).ps1"
}

####################################################################################################
# Initialize the local context
####################################################################################################

$localContextPath = Join-Path $PSScriptRoot "..\local-context.ps1"
if (Test-Path $localContextPath) {
    . $localContextPath
}

####################################################################################################
# The main program
####################################################################################################

try {
    # Output the publisher, package name, version and task name
    Write-Information "yixiao001/salesforce-mailchimp@0.1.3/save-salesforce-credentials"

    # Check if this task should be skipped
    if ($skipTask -eq "Yes") {
        Write-Information "This task will be skipped."
        exit
    }

    # Test if the credentials can retrieve an authentication token
    $credentialsVerificationSuccessful = $true
    if ($verifyCredentials -eq "Yes") {
        try {
            $connectSalesForceParam = @{
                ClientId      = $clientId
                ClientSecret  = $clientSecret
                Username      = $username
                Password      = $password
                SecurityToken = $securityToken
            }

            $salesForceSession = Connect-SalesForce @connectSalesForceParam
            $accessToken = $salesForceSession.AccessToken
            if ([String]::IsNullOrWhiteSpace($accessToken)) {
                Write-Error "Received a null or empty Salesforce authentication token when using the provided credentials."
                $credentialsVerificationSuccessful = $false
            }
            else {
                Write-Information "Credentials verified successfully against Salesforce."
            }
        }
        catch {
            Write-Error "Exception occurred while verifying the provided credentials against Salesforce.`r`n$($_.Exception.Message)"
            $credentialsVerificationSuccessful = $false
        }
    }

    # Save the credentials if the verification was successful or skipped
    if ($credentialsVerificationSuccessful) {
        # Generate the json file contents containing the credentials
        $credentialsJson = @{
            clientId      = $clientId
            clientSecret  = $clientSecret
            username      = $username
            password      = $password
            securityToken = $securityToken
        } | ConvertTo-Json

        # Generate the credentials file name
        $credentialsFileName = "SalesforceCredentials_" + $credentialName + ".json"

        # Save the file containing the credentials to the package scope
        $context.SaveVendorText($credentialsFileName, $credentialsJson)
        Write-Information "The provided credentials have been saved as '$($credentialName)'."
    }

    # Output an error message explaining the outcome
    else {
        Write-Error "The provided credentials have not been verified successfully. The provided credentials have not been saved."
    }
}
catch {
    Write-Warning "Exception occurred on line $($_.InvocationInfo.ScriptLineNumber):`r`n$($_.Exception.Message)"
}
finally {
    # Nothing to clean up
}
