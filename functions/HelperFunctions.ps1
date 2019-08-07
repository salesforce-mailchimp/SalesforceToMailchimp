# This function computes the MD5 of a string
function Get-StringMD5 {
    param($string)

    # Compute the MD5 value of the input string
    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = New-Object -TypeName System.Text.UTF8Encoding
    $hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($string)))

    # Remove the '-' and convert to lower case
    $hash = $hash.Replace("-", "").ToLower()
    return $hash
}

# The function replaces the non-ascii characters in a string with their unicode representation
function Encode-NonAsciiString {
    param($string)

    # Initialize a string builder
    $sb = [System.Text.StringBuilder]::new()

    # Convert the input string to a char array
    $charArray = $string.toCharArray()
    foreach ($char in $charArray) {
        # Replace the non ascii character with escaped unicode
        if ($char.toInt32($null) -gt 127) {
            $encoded = "\u" + $char.toInt32($null).ToString( "x4" )
            Write-Information "$char in the input string will be replaced by $encoded"
            $sb.Append($encoded) | Out-Null
        }

        # Keep the ascii character
        else {
            $sb.Append($char) | Out-Null
        }
    }
    return $sb.ToString()
}
