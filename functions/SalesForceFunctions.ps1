# This function connects to SalesForce and returns the instance url and access token
function Connect-SalesForce {
    param(
        $clientId,
        $clientSecret,
        $username,
        $password,
        $securityToken
    )

    # prepare the request
    $invokeRestMethodParams = @{
        Uri    = "https://login.salesforce.com/services/oauth2/token"
        Method = "POST"
        Body   = @{
            client_id     = $clientId
            client_secret = $clientSecret
            username      = $username
            password      = "$($password)$($securityToken)"
            grant_type    = "password"
        }
    }

    # invoke the request
    $response = Invoke-RestMethod @invokeRestMethodParams

    # return the instance url and access token
    return [PSCustomObject]@{
        AccessToken = $response.access_token
        InstanceUrl = $response.instance_url
    }
}

# This function retrieves a SalesForce contact
function Get-SalesForceContact {
    param(
        $accessToken,
        $instanceUrl,
        $id,
        $url
    )

    # Construct the url if it's not provided
    if ([string]::IsNullOrWhiteSpace($url)) {
        $url = "$($instanceUrl)/services/data/v39.0/sobjects/Contact/$id"
    }

    # Prepare the request
    $invokeRestMethodParams = @{
        Uri     = $url
        Method  = "GET"
        Headers = @{
            Authorization  = "Bearer $($accessToken)"
            "Content-Type" = "application/json"
        }
    }

    # Invoke the request
    return Invoke-RestMethod @invokeRestMethodParams
}