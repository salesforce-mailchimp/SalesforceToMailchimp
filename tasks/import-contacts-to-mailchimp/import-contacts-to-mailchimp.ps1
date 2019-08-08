param(

    $contactsCsv,

    # The name of the Mailchimp credentials
    $mailchimpCredentialsName,

    # The name of the list in Mailchimp to import the SalesForce contacts to
    $listName
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

$base64AuthInfo = $mailchimpCredentialsObject.base64AuthInfo
$hostName = $mailchimpCredentialsObject.base64AuthInfo

# Retrieve the list to import the contacts
Write-Information "Retrieving Mailchimp lists"
$mailchimpLists = Get-MailChimpList -HostName $hostName -Base64AuthInfo $base64AuthInfo
$matchingList = $mailchimpLists | Where-Object { $_.name -eq $listName }

# Output an error if the list cannot be found
if (!$matchingList) {
    Write-Error "The list does not exist!"
    exit
}
$listId = $matchingList.id

# Get the contacts information from the csv file
#$csvFilePath = $outputCsvFilePath
#$csvContent = Get-Content -Path $csvFilePath -Raw
$salesForceContacts = Convert-CsvStringToObject -CsvString $contactsCsv

# Declare the variable mapping from SalesForce to Mailchimp
$salesForceToMailchimpMap = @{
    MailingCountry              = "Country"
    Voleer_Registration_Date__c = "Voleer Registration Date"
    Region__c                   = "Region"
}

# Prepare all the interest id, to add all of them to the user later
Write-Information "Retrieving Mailchimp interests."
$allInterestId = Get-MailchimpAllInterestId -HostName $hostName -Base64AuthInfo $base64AuthInfo -ListId $listId
$interestObject = [PSCustomObject]@{ }
foreach ($id in $allInterestId) {
    $interestObject | Add-Member -NotePropertyName $id -NotePropertyValue $true
}

# Retrieve the existing merge fields, and use a hash table to store the mapping of names and tags
Write-Information "Retrieving Mailchimp merge fields."
$existingMergeFields = Get-MailchimpMergeFields -HostName $hostName -Base64AuthInfo $base64AuthInfo -ListId $listId
$nameToTag = @{ }
foreach ($field in $existingMergeFields) {
    $nameToTag.($field.name) = $field.tag
}

# Create the necessary merge fields if they don't exist
foreach ($name in $salesForceToMailchimpMap.Values) {
    if ([string]::IsNullOrWhiteSpace($nameToTag.$name)) {
        $newMergeFieldParam = @{
            HostName       = $hostName
            Base64AuthInfo = $base64AuthInfo
            Name           = $name
            NameToTag      = $nameToTag
            ListId         = $listId
        }
        if ($name -eq "Voleer Registration Date") {
            $newMergeFieldParam.type = "date"
        }

        # Create the merge field
        Write-Information "Creating merge field '$($name)'."
        $newTag = New-MailChimpMergeField @newMergeFieldParam

        # Update the name-to-tag hash table if the creation is successful
        if (![string]::IsNullOrWhiteSpace($newTag)) {
            $nameToTag.$name = $newTag
        } else {
            Write-Warning "Creation failed."
        }
    }
}

# Create or update the contacts
foreach ($contact in $salesForceContacts) {
    # Add basic fields
    $mergeFields = [PSCustomObject]@{
        FNAME = $contact.FirstName
        LNAME = $contact.LastName
    }

    # Add the other necessary fields
    foreach ($salesForceName in $salesForceToMailchimpMap.Keys) {
        if ([string]::IsNullOrWhiteSpace($contact.($salesForceName))) {
            continue
        }
        $mailChimpName = $salesForceToMailchimpMap.($salesForceName)
        $mergeFields | Add-Member -NotePropertyName $nameToTag.$mailChimpName -NotePropertyValue "$($contact.($salesForceName))" -Force
    }

    # Prepare the parameters
    $userParams = @{
        HostName       = $hostName
        Base64AuthInfo = $base64AuthInfo
        ListId         = $listId
        EmailAddress   = $contact.Email
        MergeFields    = $mergeFields
        Interests      = $interestObject
    }

    # Add or update the contact
    Write-Information "Adding/Updating '$($contact.Name)' in Mailchimp."
    $newUser = Upsert-MailchimpContact @userParams
}