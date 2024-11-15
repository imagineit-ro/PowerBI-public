
# Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser
# Install-Module Microsoft.Graph
#Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#Import-Module MicrosoftPowerBIMgmt

# Connect to Power BI service
Connect-PowerBIServiceAccount

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All"

$path = "C:\temp\zetatest"

# Set the date range (up to 30 days in the past)
$endDate = Get-Date
$startDate = $endDate.AddDays(-180)

# Create an empty array to store all events
$allEvents = @()


# Loop through each day
for ($date = $startDate; $date -le $endDate; $date = $date.AddDays(1)) {
    $dayStart = $date.ToString("yyyy-MM-ddT00:00:00")
    $dayEnd = $date.ToString("yyyy-MM-ddT23:59:59")

    # Get the activity events for the day
    $events = Get-PowerBIActivityEvent -StartDateTime $dayStart -EndDateTime $dayEnd

    # Convert the events to objects and add to the array
    $allEvents += $events 

    Write-Host "Retrive Log for Day: " $dayStart

}

$outf = $path + "\PowerBIActivityEvents.json"

# Export to JSON as well for comparison
$allEvents | ConvertTo-Json -Depth 4 | Out-File -FilePath $outf -Force

Write-Host "Activity events have been saved to PowerBIActivityEvents.json"

# Optional: Disconnect from Power BI
Disconnect-PowerBIServiceAccount


#-------------------------------------------------------------------------------------

# Get all users
$users = Get-MgUser -All

# Initialize an array to store results
$results = @()

# Process each user
foreach ($user in $users) {
    Write-Host "Processing user: $($user.UserPrincipalName)"
    
    # Get license details for the user
    $licenseDetails = Get-MgUserLicenseDetail -UserId $user.Id
    
    # If the user has licenses, process each one
    if ($licenseDetails) {
        foreach ($license in $licenseDetails) {
            $results += [PSCustomObject]@{
                UserPrincipalName = $user.UserPrincipalName
                DisplayName = $user.DisplayName
                LicenseSku = $license.SkuPartNumber
                LicenseId = $license.SkuId
            }
        }
    } else {
        # If the user has no licenses, add them to the results with blank license info
        $results += [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            DisplayName = $user.DisplayName
            LicenseSku = "No License"
            LicenseId = "No License"
        }
    }
}

# Define the output file path
$outputFile = $path + "\UserLicenses.csv"

# Export results to CSV
$results | Export-Csv -Path $outputFile -NoTypeInformation -Force

Write-Host "License information exported to $outputFile"

# Disconnect from Microsoft Graph
Disconnect-MgGraph

