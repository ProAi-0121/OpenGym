param(
    [Parameter(Mandatory = $true)]
    [string]$OutFile
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Use the right build for the OS architecture.
if ([Environment]::Is64BitOperatingSystem) {
    $url = "https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-windows-amd64.exe"
} else {
    $url = "https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-windows-386.exe"
}

$dir = Split-Path -Parent $OutFile
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

Write-Host "  Downloading mkcert from:"
Write-Host "    $url"
try {
    Invoke-WebRequest -Uri $url -OutFile $OutFile -UseBasicParsing
} catch {
    Write-Host "  ERROR: mkcert download failed: $($_.Exception.Message)"
    exit 1
}

if (Test-Path $OutFile) {
    Write-Host "  Saved to: $OutFile"
    exit 0
} else {
    Write-Host "  ERROR: download finished but file is missing"
    exit 1
}
