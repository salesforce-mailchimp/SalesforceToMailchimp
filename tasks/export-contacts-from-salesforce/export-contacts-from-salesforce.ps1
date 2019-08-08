param(
    # Name of the Salesforce credentials
    $salesforceCredentialsName,

    # The query to retrieve Salesforce contacts
    $query
)

# Import the necessary functions
@(
    "SalesForceFunctions",
    "Get-SavedCredentials"
) | ForEach-Object -Process {
    . "$($PSScriptRoot)\..\..\functions\$($_).ps1"
}

# Retrieve the saved Salesforce credentials
$salesforceCredentialsObject = Get-SavedCredentials -CredentialsName $salesforceCredentialsName -SalesforceCredentials

# Construct a hash table from the credentials object
$connectSalesForceParam = @{
    ClientId      = $salesforceCredentialsObject.clientId
    ClientSecret  = $salesforceCredentialsObject.clientSecret
    Username      = $salesforceCredentialsObject.username
    Password      = $salesforceCredentialsObject.password
    SecurityToken = $salesforceCredentialsObject.securityToken
}

# Obtain the access token and instance url using the credentials
Write-Information "Connecting to Salesforce."
$salesForceSession = Connect-SalesForce @connectSalesForceParam
$accessToken = $salesForceSession.AccessToken
$instanceUrl = $salesForceSession.InstanceUrl

if ([String]::IsNullOrWhiteSpace($accessToken)) {
    Write-Warning "Failed to connect to Salesforce."
    exit
}
else {
    Write-Information "The instance url is $instanceUrl."
}

# Encode the query
#$query = "Select name from contact where contact.Instance_Executed__C >= 10"
$encodedQuery = [uri]::EscapeDataString($query)

# Retrieve the id of all the contacts who have a Voleer registration date
$invokeRestMethodParams = @{
    Uri     = "$($instanceUrl)/services/data/v20.0/query/?q=$encodedQuery"
    Method  = "GET"
    Headers = @{
        Authorization = "Bearer $($accessToken)"
    }
}
Write-Information "Executing query '$($query)' in Salesforce."
$response = Invoke-RestMethod @invokeRestMethodParams
$contacts = $response.records

# Retrieve the detailed information of all filtered contacts
$allContacts = @()
foreach ($contact in $contacts) {
    # Construct the url
    $url = $instanceUrl + $contact.attributes.url

    # Retrieve the information and add to the list
    $getContactParams = @{
        AccessToken = $accessToken
        Url         = $url
    }
    Write-Information "Exporting contact '$($contact.Name)' from Salesforce."
    $contactInfo = Get-SalesForceContact @getContactParams
    $allContacts += $contactInfo
}

# Convert the contacts information to a csv string
$contactsCsv = Convert-CsvObjectToString -CsvObject $allContacts

$context.outputs.contactsCsv = $contactsCsv