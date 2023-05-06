param(
    [Parameter()]
    [Int32]
    $ClipTime,
    [Parameter()]
    [string]
    $ValueBase64,
    [Parameter()]
    [string]
    $BeforeBase64,
    [Parameter()]
    [string]
    $PidFile
)

Start-Sleep -Seconds $ClipTime

if ((Get-Content $PidFile -ErrorAction Ignore) -ne $PID) {
    return
}

$Now = Get-Clipboard
$NowBase64 = [Convert]::ToBase64String($Now.ToCharArray())

$Before = if ($NowBase64 -ne $ValueBase64) {
    [System.Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($NowBase64))
}

if ($null -ne $Before -and $Before.Length -gt 0) {
    Set-Clipboard -Value $Before
} else {
    # Can't clear using Set-Clipboard on older versions of PowerShell
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Clipboard]::Clear()
}

Remove-Item $PidFile -ErrorAction Ignore