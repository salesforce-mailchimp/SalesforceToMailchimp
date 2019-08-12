# This function retrieves the lists
function Get-MailChimpList {
    param(
        $hostName,
        $base64AuthInfo
    )

    # Prepare the request
    $invokeRestMethodParams = @{
        Uri     = "$($hostName)/lists"
        Method  = "GET"
        Headers = @{
            Authorization = "Basic $($base64AuthInfo)"
        }
    }

    # Invoke the request
    $response =  Invoke-RestMethod @invokeRestMethodParams
    return $response.lists
}

# This function retrieves the name and tag of all the merge fields
function Get-MailchimpMergeFields {
    param(
        $hostName,
        $base64AuthInfo,
        $listId
    )

    # Prepare the request
    $invokeRestMethodParams = @{
        Uri     = "$($hostName)/lists/$($ListId)/merge-fields?count=1000&fields=merge_fields.name,merge_fields.tag"
        Method  = "GET"
        Headers = @{
            Authorization  = "Basic $($base64AuthInfo)"
            "Content-Type" = "application/json"
        }
    }

    # Invoke the request and return all the merge fields
    $response = Invoke-RestMethod @invokeRestMethodParams
    return $response.merge_fields
}

# This function retrieves the id of all the groups (interest-categories)
function Get-MailchimpGroupId {
    param(
        $hostName,
        $base64AuthInfo,
        $listId
    )

    # Prepare the request
    $invokeRestMethodParams = @{
        Uri     = "$($hostName)/lists/$($ListId)/interest-categories?count=1000"
        Method  = "GET"
        Headers = @{
            Authorization = "Basic $($base64AuthInfo)"
        }
    }

    # Invoke the request and return the ids
    $response = Invoke-RestMethod @invokeRestMethodParams
    return $response.categories.id
}

# This function retrieves all the interest id within a group (interest-category)
function Get-MailchimpInterestId {
    param(
        $hostName,
        $base64AuthInfo,
        $ListId,
        $interestCategoryId
    )

    # Prepare the request
    $invokeRestMethodParams = @{
        Uri     = "$($hostName)/lists/$($ListId)/interest-categories/$($interestCategoryId)/interests"
        Method  = "GET"
        Headers = @{
            Authorization = "Basic $($base64AuthInfo)"
        }
    }

    # Invoke the request and only return the ids
    $response = Invoke-RestMethod @invokeRestMethodParams
    return $response.interests.id
}

# This function retrieves the id of all the interests
function Get-MailchimpAllInterestId {
    param(
        $hostName,
        $base64AuthInfo,
        $ListId
    )

    # Retrieve the id of all the groups (interest-categories)
    $allGroupId = Get-MailchimpGroupId -HostName $hostName -Base64AuthInfo $base64AuthInfo -ListId $listId

    # Retrieve the id of the interests in each group (interest-category)
    $allInterestId = @()
    foreach ($groupId in $allGroupId) {
        $allInterestId += Get-MailchimpInterestId -HostName $hostName -Base64AuthInfo $base64AuthInfo -ListId $listId -InterestCategoryId $groupId
    }

    # Return all the id
    return $allInterestId
}

# This function creates a new merge field
function New-MailChimpMergeField {
    param(
        $hostName,
        $base64AuthInfo,
        $name,
        $type = "text",
        $listId
    )

    # Prepare the request parameters
    $invokeRestMethodParams = @{
        Uri     = "$($hostName)/lists/$($ListId)/merge-fields"
        Method  = "POST"
        Headers = @{
            Authorization  = "Basic $($base64AuthInfo)"
            "Content-Type" = "application/json"
        }
        Body    = @{
            name = $name
            type = $type
        } | ConvertTo-Json
    }

    # Invoke the request and get the newly created tag
    $response = Invoke-RestMethod @invokeRestMethodParams
    return $response.tag
}

# This function inserts a user if it doesn't exist, and update a user if it exists
function Upsert-MailchimpContact {
    param(
        $hostName,
        $base64AuthInfo,
        $listId,
        $emailAddress,
        $status = "subscribed",
        $mergeFields,
        $interests
    )

    # Compute the MD5 hash of the lower case version of the user's email address
    $subscriberHash = Get-StringMD5 -String $emailAddress.ToLower()

    # Construct the request body and convert it to a json string
    $body = @{
        email_address = $emailAddress
        status        = $status
        merge_fields  = $mergeFields
        interests     = $interests
    } | ConvertTo-Json

    # Encode the non ascii characters in the string
    $encodedJson = Encode-NonAsciiString -String $body

    # Prepare the request parameters
    $invokeRestMethodParams = @{
        Uri     = "$($hostName)/lists/$($ListId)/members/$($subscriberHash)"
        Method  = "PUT"
        Headers = @{
            Authorization  = "Basic $($base64AuthInfo)"
            "Content-Type" = "application/json"
        }
        Body    = $encodedJson
    }

    # Adding or updating the user
    return Invoke-RestMethod @invokeRestMethodParams
}

function Add-TagToMembers {
    param(
        $hostName,
        $base64AuthInfo,
        $listId,
        $segmentId,

        # An array of email addresses
        $membersToAdd
    )
    $invokeRestMethodParams = @{
        Uri     = "$($hostName)/lists/$listId/segments/$segmentId"
        Method  = "POST"
        Headers = @{
            Authorization  = "Basic $($base64AuthInfo)"
            "Content-Type" = "application/json; charset=utf-8"
        }
        Body    = @{
            members_to_add = $membersToAdd
        } | ConvertTo-Json
    }

    $response = Invoke-RestMethod @invokeRestMethodParams
    return $response.members_added
}

function Get-MailchimpTag {
    param(
        $hostName,
        $base64AuthInfo,
        $listId
    )

    $invokeRestMethodParams = @{
        Uri     = "$($hostName)/lists/$listId/segments"
        Method  = "GET"
        Headers = @{
            Authorization = "Basic $($base64AuthInfo)"
        }
    }

    $response = Invoke-RestMethod @invokeRestMethodParams
    return $response.segments
}

function New-MailchimpTag {
    param(
        $hostName,
        $base64AuthInfo,
        $listId,
        $tagName
    )

    $invokeRestMethodParams = @{
        Uri     = "$($hostName)/lists/$listId/segments"
        Method  = "POST"
        Headers = @{
            Authorization = "Basic $($base64AuthInfo)"
        }
        Body    = @{
            name           = $tagName
            static_segment = @()
        } | ConvertTo-Json
    }

    $response = Invoke-RestMethod @invokeRestMethodParams
    return $response.segments
}

function Search-MailchimpMember {
    param(
        $hostName,
        $base64AuthInfo,
        $listId
    )

    $invokeRestMethodParams = @{
        Uri     = "$($hostName)/search-members"
        Method  = "GET"
        Headers = @{
            Authorization = "Basic $($base64AuthInfo)"
        }
        Body    = @{
            query = "instance"
        }
    }

    $response = Invoke-RestMethod @invokeRestMethodParams
    #return $response.segments
}

function Test-MailchimpCredentials {
    param(
        $base64AuthInfo,
        $hostName
    )

    $invokeRestMethodParams = @{
        Uri     = "$($hostName)/"
        Method  = "GET"
        Headers = @{
            Authorization = "Basic $($base64AuthInfo)"
        }
    }

    return Invoke-RestMethod @invokeRestMethodParams
}

