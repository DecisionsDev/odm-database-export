param( 
[Parameter(Mandatory=$true, HelpMessage='Provide the url of the decisioncenter host http(s)://host:port')][string]$serverURL = ''
)

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

# Accept any certificate (same behaviour as wget --no-check-certificate in the .sh script)
if ($PSVersionTable.PSVersion.Major -ge 6) {
    $PSDefaultParameterValues['Invoke-WebRequest:SkipCertificateCheck'] = $true
    $PSDefaultParameterValues['Invoke-RestMethod:SkipCertificateCheck'] = $true
} else {
    # Windows PowerShell 5.1 has no -SkipCertificateCheck
    Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(ServicePoint sp, X509Certificate cert, WebRequest req, int problem) { return true; }
}
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
}


$odmPath = Join-Path $scriptRoot 'odm'
New-Item -ItemType Directory -Path $odmPath -Force | Out-Null
Set-Location -Path $odmPath

$dc_assets=$serverURL+$(if ($serverURL -match '/$'){''} else {"/"} )  +"decisioncenter/assets/decision-center-client-api.zip"
$dcrepairapi="https://api.github.com/repos/DecisionsDev/odm-database-export/contents/resources/repair"
$antbase="https://dlcdn.apache.org/ant/binaries/"

# download asset from decisioncenter
Try {
    Invoke-WebRequest -Uri ($dc_assets) -OutFile ("assets.zip") 
    Expand-Archive -Force -Path "assets.zip" -DestinationPath .
    
# Optional: verify expected directory exists after extraction
    $dcbin = Join-Path $pwd.Path 'teamserver\bin'
    if (-not (Test-Path $dcbin)) {
        throw "Expected path not found after extraction: $dcbin"
    }

    # Cleanup archive
    Remove-Item "assets.zip" -Force

    Write-Host "Assets installed successfully from $dc_assets"

}Catch{
    Write-Host $_
    Write-Host 'Unable to install assets from ' $dc_assets
    Set-Location .. | Out-Null
    return
}
# download dcrepair zip
try {
    # find the latest DC_Repair-<version>.zip published in the directory
    $files = Invoke-RestMethod -Uri $dcrepairapi
    $latest = $files | Where-Object { $_.name -match '^DC_Repair-[\d._]+\.zip$' } |
        Sort-Object { [version](($_.name -replace '^DC_Repair-|\.zip$','') -replace '_','.') } | Select-Object -Last 1
    if (-not $latest) { throw "No DC_Repair-<version>.zip found at $dcrepairapi" }
    $dcrepairpath = $latest.download_url
    Invoke-WebRequest   -Uri ($dcrepairpath) -OutFile ("dcrepair.zip")
    Expand-Archive -Force -Path "dcrepair.zip" -DestinationPath "teamserver/bin"
    Remove-Item "dcrepair.zip"
}Catch{
    Write-Host 'Unable to install repair scripts from ' $dcrepairpath
    Set-Location .. | Out-Null
    return
}
# download ant
try {
    # dlcdn only hosts current releases, so look up the latest 1.10.x
    $antzip = [regex]::Matches((Invoke-WebRequest -UseBasicParsing -Uri $antbase).Content, 'apache-ant-1\.10\.\d+-bin\.zip') |
        ForEach-Object { $_.Value } | Sort-Object -Unique { [version]($_ -replace 'apache-ant-|-bin\.zip','') } | Select-Object -Last 1
    if (-not $antzip) { throw "No ant 1.10.x found at $antbase" }
    $antdownload = $antbase + $antzip
    $antdir = $antzip -replace '-bin\.zip$',''
    Invoke-WebRequest   -Uri ($antdownload) -OutFile ("apache-ant.zip")
    Expand-Archive  -Force -Path "apache-ant.zip" -DestinationPath .
    Rename-Item $antdir ant
    Remove-Item "apache-ant.zip"
}Catch{
    Write-Host 'Unable to install ant from ' $antdownload
    Set-Location .. | Out-Null
    return
}

Set-Location .. | Out-Null

