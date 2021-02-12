function Disable-Workflow {
    param (
        [string]$siteUrl,
        [string]$listTitle,
        [string]$workflowDefName,
        [string]$appId,
        [string]$appSecret
    )
    Connect-PnPOnline -AppId $appId -AppSecret $appSecret -Url $siteUrl
    $context = Get-PnPContext

    # Load List
    $list = $context.Web.Lists.GetByTitle($listTitle)
    $context.load($list)
    $context.load($list.WorkflowAssociations)
    $context.ExecuteQuery();

    $wf = $list.WorkflowAssociations | Where-Object { $_.Name -eq $workflowDefName }
    if ($null -ne $wf) {
        $wf.Enabled = $false
        $wf.Update()
        $context.ExecuteQuery()
        Write-Host $("Workflow {0} was disabled at list {1} on site {2}" -f $workflowDefName, $list.Title, $siteUrl)
    }
    Disconnect-PnPOnline

}

$ACSAppId = "[ACSAppId]"
$ACSAppSecret = "[ACSAppSecret]"
$csvFile = "[CSV file generated from SPMT tools]"

$scriptFullPath = $MyInvocation.MyCommand.Path
$scriptPath = Split-Path $scriptFullPath

Add-Type -Path $scriptPath\..\..\DLLs\Microsoft.SharePoint.Client.dll
Add-Type -Path $scriptPath\..\..\DLLs\Microsoft.SharePoint.Client.Runtime.dll

$scannerRows = @(Import-Csv -Path $csvFile)
$index = 0

Write-Host $("{0} rows were read." -f $scannerRows.Length)


foreach ($row in $scannerRows) {
    Disable-Workflow -ClientId $ACSAppId -ClientSecret $ACSAppSecret -siteUrl $row."Site Url" -listTitle $row."List Title" -workflowDefName $row."Definition Name"
    $index++
    $percentage = [math]::Truncate($index * 100 / $scannerRows.Length)
    Write-Progress -Activity "Process..." -Status "$percentage% Complete:" -PercentComplete $percentage;
}

