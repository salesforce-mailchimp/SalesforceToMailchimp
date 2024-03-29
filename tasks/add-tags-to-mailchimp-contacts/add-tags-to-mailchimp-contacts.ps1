param(
    # A csv string containing the information of the contacts to add the tag to
    $contactsCsv,

    # The name of the column in csv that correspond to email. Defaults to 'Email'
    $emailColumnName = "Email",

    # The name of the Mailchimp credentials
    $mailchimpCredentialsName,

    # The name of the list in Mailchimp to import the SalesForce contacts to
    $listName,

    # The name of the tag in Mailchimp to add the contact
    $tagName
)

# Import the necessary functions
@(
    "MailchimpFunctions",
    "HelperFunctions",
    "Get-SavedCredentials"
) | ForEach-Object -Process {
    . "$($PSScriptRoot)\..\..\functions\$($_).ps1"
}

# Retrieve the saved Mailchimp credentials
$mailchimpCredentialsObject = Get-SavedCredentials -CredentialsName $mailchimpCredentialsName -MailchimpCredentials
if (!$mailchimpCredentialsObject) {
    Write-Error "Failed to retrieve the Mailchimp credentials."
    exit
}
$base64AuthInfo = $mailchimpCredentialsObject.base64AuthInfo
$hostName = $mailchimpCredentialsObject.hostName

# Retrieve the list to import the contacts
$mailchimpLists = Get-MailChimpList -HostName $hostName -Base64AuthInfo $base64AuthInfo
$matchingList = $mailchimpLists | Where-Object { $_.name -eq $listName }

# Output an error if the list cannot be found
if (!$matchingList) {
    Write-Error "The list '$($listName)' does not exist!"
    exit
}
$listId = $matchingList.id

# Retrieve the tag to add to the contacts
$mailChimpTags = Get-MailChimpTag -HostName $hostName -Base64AuthInfo $base64AuthInfo -ListId $listId
$matchingTag = $mailChimpTags | Where-Object { $_.name -eq $tagName }

# Output an error if the tag cannot be found
if (!$matchingTag) {
    Write-Error "The tag '$($tagName)' does not exist!"
    exit
}
$tagId = $matchingTag.id

# Get the contacts information from the csv
$salesForceContacts = Convert-CsvStringToObject -CsvString $contactsCsv

# Add the tag to the contacts
$membersToAdd = ConvertTo-Array $salesForceContacts.$($emailColumnName)
Write-Information "Adding the tag '$($tagName)' to contacts '$($membersToAdd -join ",")'."
$membersAdded = Add-TagToMembers -HostName $hostName -Base64AuthInfo $base64AuthInfo -ListId $listId -SegmentId $tagId -MembersToAdd $membersToAdd
Write-Information "The tag '$($tagName)' was added to contacts '$($membersAdded.email_address -join ",")'."