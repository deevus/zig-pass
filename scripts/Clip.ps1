param(
    [Parameter()]
    [string]
    $Name,
    [Parameter()]
    [string]
    $Value,
    [Parameter()]
    [Int32]
    $ClipTime
)

$TempFile = Join-Path -Path $env:TEMP -ChildPath "zig-pass"

$Before = Get-Clipboard

Set-Clipboard -Value $Value

$BeforeBase64 = if ($Before) { [Convert]::ToBase64String($Before.ToCharArray()) } else { "" }
$ValueBase64 = [Convert]::ToBase64String($Value.ToCharArray())

$ResetClipPath = Join-Path -Path $PSScriptRoot -ChildPath "Reset-Clip.ps1"
$ResetClipArgs = @(
    "-NoProfile", 
    "-Command", 
    $ResetClipPath, 
    "-ClipTime", 
    $ClipTime, 
    "-ValueBase64", 
    "'$ValueBase64'", 
    "-BeforeBase64", 
    "'$BeforeBase64'",
    "-PidFile",
    "'$TempFile'"
)

$Process = Start-Process -WindowStyle Normal -ArgumentList $ResetClipArgs "powershell.exe" -PassThru
$Process.Id | Out-File -FilePath $TempFile

Write-Host "Copied $Name to clipboard. Will clear in $ClipTime seconds."