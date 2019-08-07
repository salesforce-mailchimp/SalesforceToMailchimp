param(
    $contactsCsv,

    # Api Key from Mailchimp
    $apiKey,

    # The name of the list in Mailchimp to import the SalesForce contacts to
    $listName,

    # The name of the tag in Mailchimp to add the contact
    $tagName
)

# Import the necessary functions
@(
    "MailchimpFunctions",
    "HelperFunctions"
) | ForEach-Object -Process {
    . "$($PSScriptRoot)\..\..\functions\$($_).ps1"
}

# Construct the base64 string for basic authentication in Mailchimp
# Username can be any string
$username = "LetsGoWarriors"
$password = $apiKey
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))

# Get the data center from the api key
# For example, the data center of the api key "abc123-us8" is "us8"
$dataCenter = $apiKey.Substring($apiKey.IndexOf("-") + 1)
$hostName = "https://$($dataCenter).api.mailchimp.com/3.0/"

# Retrieve the list to import the contacts
$mailchimpLists = Get-MailChimpList -HostName $hostName -Base64AuthInfo $base64AuthInfo
$matchingList = $mailchimpLists | Where-Object { $_.name -eq $listName }

# Output an error if the list cannot be found
if (!$matchingList) {
    Write-Error "The list '$listName' does not exist!"
    exit
}
$listId = $matchingList.id

$mailChimpTags = Get-MailChimpTag -HostName $hostName -Base64AuthInfo $base64AuthInfo -ListId $listId
$matchingTag = $mailChimpTags | Where-Object { $_.name -eq $tagName }

# Output an error if the list cannot be found
if (!$matchingTag) {
    Write-Error "The tag '$tagName' does not exist!"
    exit
}
$tagId = $matchingTag.id

# Get the contacts information from the csv file
#$csvFilePath = $outputCsvFilePath
#$csvContent = Get-Content -Path $csvFilePath -Raw
$salesForceContacts = Convert-CsvStringToObject -CsvString $contactsCsv

# Add the tag to the contacts
$membersToAdd = ConvertTo-Array $salesForceContacts.Email
Write-Information "Adding the tag '$tagName' to contacts '$($membersToAdd -join ",")'."
$membersAdded = Add-TagToMembers -HostName $hostName -Base64AuthInfo $base64AuthInfo -ListId $listId -SegmentId $tagId -MembersToAdd $membersToAdd
Write-Information "The tag '$tagName' was added to contacts '$($membersAdded.email_address -join ",")'."