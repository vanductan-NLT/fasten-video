[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Path,

    [int]$MaxSeconds = 120
)

$ErrorActionPreference = 'Stop'

function Resolve-Tool {
    param([string]$Name, [string]$Fallback)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    if (Test-Path $Fallback) { return $Fallback }
    throw "$Name not found. Install ffmpeg or place at $Fallback."
}

$ffmpeg  = Resolve-Tool 'ffmpeg'  'C:\ffmpeg\bin\ffmpeg.exe'
$ffprobe = Resolve-Tool 'ffprobe' 'C:\ffmpeg\bin\ffprobe.exe'

if ([string]::IsNullOrWhiteSpace($Path)) {
    $candidateDirs = @(
        (Join-Path $env:USERPROFILE 'OneDrive\Pictures\Camera Roll'),
        (Join-Path ([System.Environment]::GetFolderPath('MyPictures')) 'Camera Roll'),
        (Join-Path $env:USERPROFILE 'Pictures\Camera Roll')
    ) | Select-Object -Unique

    $videoExtensions = @('.mp4', '.mov', '.mkv', '.avi', '.m4v', '.wmv', '.flv', '.webm')
    $latest = $null

    foreach ($dir in $candidateDirs) {
        if (Test-Path -LiteralPath $dir) {
            $found = Get-ChildItem -LiteralPath $dir -File |
                Where-Object { $videoExtensions -contains $_.Extension.ToLower() } |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1
            if ($found -and (-not $latest -or $found.LastWriteTime -gt $latest.LastWriteTime)) {
                $latest = $found
            }
        }
    }

    if (-not $latest) {
        throw "No video file found in Camera Roll (`"C:\Users\tan\OneDrive\Pictures\Camera Roll`")."
    }
    $Path = $latest.FullName
    Write-Host "Auto-detected video: $Path"
}

if (-not (Test-Path -LiteralPath $Path)) {
    throw "Input not found: $Path"
}
$input = (Resolve-Path -LiteralPath $Path).Path

$durationStr = & $ffprobe -v error -show_entries format=duration -of csv=p=0 -- $input
$duration = [double]$durationStr
if ($duration -le 0) { throw "Could not read duration for $input" }

$speed = [Math]::Max(1.0, $duration / $MaxSeconds)
$speedStr = $speed.ToString('0.0000', [System.Globalization.CultureInfo]::InvariantCulture)

$baseName = [System.IO.Path]::GetFileNameWithoutExtension($input)
$downloads = Join-Path $env:USERPROFILE 'Downloads'
$output = Join-Path $downloads ("{0}-fast.mp4" -f $baseName)

Write-Host "Input    : $input"
Write-Host "Duration : $([Math]::Round($duration, 1))s"
Write-Host "Speed    : ${speedStr}x"
Write-Host "Output   : $output"

& $ffmpeg -y -i $input -an -vf "setpts=PTS/$speedStr" `
    -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p -movflags +faststart `
    -- $output

if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed (exit $LASTEXITCODE). Original kept." }
if (-not (Test-Path -LiteralPath $output) -or (Get-Item -LiteralPath $output).Length -le 0) {
    throw "Output missing or empty. Original kept."
}

Remove-Item -LiteralPath $input -Force
Write-Host "Done. Original deleted."
