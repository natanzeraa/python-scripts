# Output file path
$outputFile = ".\licensed_users.txt"

# Initialize output list
$outputList = @()

# Get all users and process each one
Get-MgUser -All | ForEach-Object {
    $user = $_
    $licenses = Get-MgUserLicenseDetail -UserId $user.Id
    $licenseNames = ($licenses.SkuPartNumber -join ", ")

    $entry = [PSCustomObject]@{
        DisplayName       = $user.DisplayName
        Id                = $user.Id
        Email             = $user.Mail
        UserPrincipalName = $user.UserPrincipalName
        Licenses          = $licenseNames
    }

    # Show in terminal
    Write-Output $entry

    # Add to output list
    $outputList += $entry
}

# Write to file (semicolon-separated)
$outputList | ForEach-Object {
    "$($_.DisplayName);$($_.Id);$($_.Email);$($_.UserPrincipalName);$($_.Licenses)"
} | Set-Content -Path $outputFile -Encoding UTF8

Write-Host "✅ File saved at: $outputFile"
