param(
    # Information of SalesForce app
    $clientId,
    $clientSecret,
    $redirectUrl,

    # Credentials of SalesForce user
    $username,
    $password,
    $securityToken,

    # The query to retrieve Salesforce contacts
    $query
)

# Import the necessary functions
@(
    "SalesForceFunctions"
) | ForEach-Object -Process {
    . "$($PSScriptRoot)\..\..\functions\$($_).ps1"
}

# Declare the path of the output csv file
#$outputCsvFilePath = "C:\Users\yshen\Desktop\VoleerContactsFake.csv"

# Obtain the access token and instance url using the credentials
$connectSalesForceParam = @{
    ClientId      = $clientId
    ClientSecret  = $clientSecret
    RedirectUrl   = $redirectUrl
    Username      = $username
    Password      = $password
    SecurityToken = $securityToken
}
$salesForceSession = Connect-SalesForce @connectSalesForceParam
$accessToken = $salesForceSession.AccessToken
$instanceUrl = $salesForceSession.InstanceUrl

# Encode the query
$query = "Select name from contact where contact.Instance_Executed__C >= 10"
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