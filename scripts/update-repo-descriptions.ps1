<#
.SYNOPSIS
  Update GitHub repository descriptions in bulk from a JSON file.

.DESCRIPTION
  Reads a JSON file mapping repository names (repo) to description strings and
  updates each repository's description using the GitHub REST API. The script
  uses the environment variable GITHUB_TOKEN for authentication (recommended
  for security). The token needs `repo` scope for private repos or `public_repo`
  for public repos updates.

.EXAMPLE
  $env:GITHUB_TOKEN = 'ghp_xxx'
  .\update-repo-descriptions.ps1 -Owner MASMELAM -File descriptions.json

#>

param(
  [string]$Owner = 'MASMELAM',
  [string]$File = 'descriptions.json'
)

function Fail([string]$msg) {
  Write-Error $msg
  exit 1
}

if (-not (Test-Path $File)) {
  Fail "Descriptions file '$File' not found. Create a JSON mapping file (see descriptions.json.example)."
}

$token = $env:GITHUB_TOKEN
if (-not $token) {
  Fail "Environment variable GITHUB_TOKEN is not set. Create a GitHub personal access token and set it in your environment before running the script. Example (PowerShell):`$env:GITHUB_TOKEN = 'ghp_xxx'`"
}

try {
  $content = Get-Content $File -Raw
  $map = $content | ConvertFrom-Json
} catch {
  Fail "Failed to read or parse '$File': $_"
}

foreach ($prop in $map.PSObject.Properties) {
  $repo = $prop.Name
  $desc = $prop.Value
  $url = "https://api.github.com/repos/$Owner/$repo"
  $body = @{ description = $desc } | ConvertTo-Json
  try {
    Invoke-RestMethod -Uri $url -Method Patch -Headers @{ Authorization = "Bearer $token"; 'User-Agent' = "$Owner-update-script" } -Body $body -ContentType 'application/json' -ErrorAction Stop
    Write-Host "Updated description for $Owner/$repo"
  } catch {
    Write-Warning "Failed to update $Owner/$repo: $($_.Exception.Message)"
  }
}
