# Native PowerShell script to enhance operations of Stasiun Geofisika Alor.
# Originally designed by Gemini 3 and assembled by rhh.

$ErrorActionPreference = "Stop"

Write-Host "Starting.."

# Location of the project folder
$LOCATION = $PSScriptRoot

# Convert backslashes to forward slashes for ImageMagick configuration
$FONT_DIR = ($LOCATION + "\Fonts").Replace('\', '/') + '/'
$FONT_BODY = $FONT_DIR + "Poppins-Regular.ttf"
$FONT_HEADER = $FONT_DIR + "Poppins-Bold.ttf"

# Set input, assets, and output folder locations
$INPUT_DIR = Join-Path $LOCATION "Source"
$ASSETS_DIR = Join-Path $LOCATION "Assets"
$OUTPUT_DIR = Join-Path $LOCATION "Output"

# Ensure output directory exists
if (-not (Test-Path $OUTPUT_DIR)) {
    New-Item -ItemType Directory -Path $OUTPUT_DIR | Out-Null
}

# --- 0. Check for FFmpeg and ImageMagick ---

# Fix for the database lock error: Clear any stuck winget processes
Stop-Process -Name "winget" -Force -ErrorAction SilentlyContinue

$WINGET_LINKS_DIR = "$env:USERPROFILE\AppData\Local\Microsoft\WinGet\Links"
$PROGRAM_FILES_DIR = $env:ProgramFiles

# 1. Check/Install ImageMagick
$checkMagick = winget list --id ImageMagick.ImageMagick 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "[FOUND] ImageMagick is installed."
} else {
    Write-Host "[INSTALLING] ImageMagick not found. Installing now..."
    winget install --id ImageMagick.ImageMagick --exact --accept-source-agreements --accept-package-agreements --silent
}

# 2. Check/Install Gyan.FFmpeg
$checkFFmpeg = winget list --id Gyan.FFmpeg 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "[FOUND] Gyan.FFmpeg is installed."
} else {
    Write-Host "[INSTALLING] Gyan.FFmpeg not found. Installing now..."
    winget install --id Gyan.FFmpeg --exact --accept-source-agreements --accept-package-agreements --silent
}

Write-Host "======================================================================================================================="
Write-Host "[0/6] All requirements met. Starting next program..."
Write-Host "======================================================================================================================="
Write-Host "Running next steps..."

# -------------------------------------------------------------------------
# DYNAMICALLY LOCATE THE TOOLS (WITHOUT USING $env:PATH)
# -------------------------------------------------------------------------

$FFMPEG_CMD = ""
$ffmpegPaths = Get-ChildItem -Path "$env:USERPROFILE\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg*" -ErrorAction SilentlyContinue
foreach ($dir in $ffmpegPaths) {
    $potentialPath = Join-Path $dir.FullName "bin\ffmpeg.exe"
    if (Test-Path $potentialPath) { $FFMPEG_CMD = $potentialPath }
}

$MAGICK_CMD = ""
$magickPaths = Get-ChildItem -Path "$env:ProgramFiles\ImageMagick*" -ErrorAction SilentlyContinue
foreach ($dir in $magickPaths) {
    $potentialPath = Join-Path $dir.FullName "magick.exe"
    if (Test-Path $potentialPath) { $MAGICK_CMD = $potentialPath }
}

# --- CRITICAL FAILSAFE ---
if ([string]::IsNullOrEmpty($FFMPEG_CMD)) {
    Write-Warning "Dynamic FFmpeg path failed. Falling back to system global."
    $FFMPEG_CMD = "ffmpeg.exe"
}
if ([string]::IsNullOrEmpty($MAGICK_CMD)) {
    Write-Warning "Dynamic ImageMagick path failed. Falling back to system global."
    $MAGICK_CMD = "magick.exe"
}

Write-Host "--------------------------------------------------"
Write-Host "Verified FFmpeg Executive: '$FFMPEG_CMD'"
Write-Host "Verified ImageMagick Exec: '$MAGICK_CMD'"
Write-Host "--------------------------------------------------"

# --- I. Processing Data From MICA ---

if (-not (Test-Path $INPUT_DIR)) {
    Write-Error "Error: Could not find the input folder '$INPUT_DIR'"
    Read-Host "Press Enter to exit..."
    exit
}

Set-Location $INPUT_DIR

Write-Host "======================================================================================================================="
Write-Host "Terbit Terbenam Otomatis"
$SEARCH_WORD = Read-Host "Input the date (e.g.: Mar,09)"

$TargetFiles = @("Kabir.csv", "Kalabahi.csv", "Larantuka.csv", "Lewoleba.csv", "Maritaing.csv")

foreach ($file in $TargetFiles) {
    if (Test-Path $file) {
        Write-Host "Searching in $file..."
        
        # Native PowerShell search + context extraction
        Select-String -Path $file -Pattern $SEARCH_WORD -Context 0,7 | ForEach-Object {
            $_.Line
            $_.Context.PostContext
        } | Out-File -FilePath "$OUTPUT_DIR\$($file.Split('.')[0])_temp.csv" -Encoding utf8
    } else {
        Write-Host "Skipping $file - File not found in the Source folder."
    }
}

Write-Host "`nBatch search complete! Your _temp.csv files are saved in: $OUTPUT_DIR"
Write-Host "======================================================================================================================="
Write-Host "[1/6] Extraction and cleanup initializing..."
Write-Host "======================================================================================================================="

# --- II. EXTRACTING COLUMNS 6 AND 10 & REMOVING QUOTES ---
Write-Host "`nExtracting columns 6 and 10 into clean files..."

foreach ($file in $TargetFiles) {
    $baseName = ($file.Split('.')[0])
    $tempFile = "$OUTPUT_DIR\${baseName}_temp.csv"
    
    if (Test-Path $tempFile) {
        Write-Host "Extracting and cleaning ${baseName}_temp.csv..."
        
        # Import as headers (1..50), extract columns 6 and 10, remove double quotes, save
        Import-Csv -Path $tempFile -Header (1..50) | 
            Select-Object -Property '6', '10' | 
            ConvertTo-Csv -NoTypeInformation | 
            Select-Object -Skip 1 | 
            ForEach-Object { $_ -replace '"', '' } | 
            Out-File -FilePath "$OUTPUT_DIR\${baseName}_temp1.csv" -Encoding utf8
    }
}

Write-Host "======================================================================================================================="
Write-Host "[2/6] Extraction and cleanup complete! Generating cover.png..."
Write-Host "======================================================================================================================="

# --- III. Generate Images as Cover ---
Write-Host "Calculating dates for $SEARCH_WORD..."

$parts = $SEARCH_WORD.Split(',')
$dateStr = "$($parts[1]) $($parts[0]) $((Get-Date).Year)"
$start = [datetime]$dateStr
$end = $start.AddDays(6)

$culture = [System.Globalization.CultureInfo]::CreateSpecificCulture('id-ID')
$DATE_TEXT = $start.ToString('dd MMMM yyyy', $culture) + ' - ' + $end.ToString('dd MMMM yyyy', $culture)
$MONTH_NUM = $start.Month

# Check if month is odd or even
if (($MONTH_NUM % 2) -eq 1) {
    $BASE_VIDEO = "base_ganjil"
} else {
    $BASE_VIDEO = "base_genap"
}

Write-Host "Variable BASE_VIDEO is set to: $BASE_VIDEO"
Write-Host "Text to print: $DATE_TEXT"

Write-Host "Generating cover image..."
& $MAGICK_CMD -size 1080x1080 canvas:transparent -font $FONT_HEADER -pointsize 45 -gravity center -fill "#fac016" -annotate 0x0+45+50 "$DATE_TEXT" "$OUTPUT_DIR\cover_temp.png"

Write-Host "======================================================================================================================="
Write-Host "[3/6] Generated cover.png successfully! Generating content images for each CSV file..."
Write-Host "======================================================================================================================="

# --- IV. Generate Contents Terbit Terbenam ---
$DATES = @()
0..6 | ForEach-Object {
    $DATES += $start.AddDays($_).ToString('dd/MM/yyyy')
}

$csvFiles = Get-ChildItem -Path "$OUTPUT_DIR\*_temp1.csv"
foreach ($f in $csvFiles) {
    Write-Host "`n=========================================="
    Write-Host "Processing file: $($f.FullName)"
    
    $lines = Get-Content -Path $f.FullName
    $TERBIT = @()
    $TERBENAM = @()
    
    for ($i = 0; $i -lt 7; $i++) {
        if ($i -lt $lines.Count) {
            $row = $lines[$i].Split(',')
            # Extract only last 5 characters to clean up hidden BOM markers
            $rawTerbit = $row[0]
            $cleanTerbit = if ($rawTerbit.Length -ge 5) { $rawTerbit.Substring($rawTerbit.Length - 5) } else { $rawTerbit }
            
            $TERBIT += $cleanTerbit
            $TERBENAM += $row[1]
        } else {
            $TERBIT += ""
            $TERBENAM += ""
        }
        Write-Host "Day $($i+1) Times - Terbit: $($TERBIT[$i]), Terbenam: $($TERBENAM[$i])"
    }
    
    # Calculate Y Layout offsets dynamically
    $Pos1 = 70
    $dv = 68
    $Y = @()
    0..6 | ForEach-Object { $Y += ($Pos1 + ($dv * $_)) }
    
    Write-Host "Generating content image graphic..."
    
    # Construct arguments dynamically for ImageMagick
    $magickArgs = @("-size", "1080x1080", "canvas:transparent", "-pointsize", "24", "-gravity", "center", "-fill", "#141414")
    
    # Add Date strings
    0..6 | ForEach-Object {
        $magickArgs += @("-font", $FONT_BODY, "-annotate", "0x0-160+$($Y[$_])", $DATES[$_])
    }
    # Add Terbit strings
    0..6 | ForEach-Object {
        $magickArgs += @("-font", $FONT_BODY, "-annotate", "0x0+70+$($Y[$_])", $TERBIT[$_])
    }
    # Add Terbenam strings
    0..6 | ForEach-Object {
        $magickArgs += @("-font", $FONT_BODY, "-annotate", "0x0+330+$($Y[$_])", $TERBENAM[$_])
    }
    
    # ... (inside the foreach ($f in $csvFiles) loop) ...
    
    # FIX: Preserve '_temp1' so it matches what filters.txt expects
    $outputImgName = $f.Name.Replace(".csv", ".png") 
    $magickArgs += "$OUTPUT_DIR\$outputImgName"
    
    # Execute ImageMagick cleanly
    & $MAGICK_CMD $magickArgs
    Write-Host "Success! Image saved as $outputImgName"
}

Write-Host "======================================================================================================================="
Write-Host "[4/6] Content images generated! Now merging into one video with FFmpeg..."
Write-Host "======================================================================================================================="

# --- V. Merge it All in one video ---
$FILTER_FILE = (Join-Path $LOCATION "Config\filters.txt").Replace('\', '/')

$BASE_ARGS = @("-i", "$ASSETS_DIR\$BASE_VIDEO.mp4")
$IMAGE_ARGS = @(
    "-loop", "1", "-i", "$OUTPUT_DIR\cover_temp.png",
    "-loop", "1", "-i", "$OUTPUT_DIR\cover_temp.png",
    "-loop", "1", "-i", "$OUTPUT_DIR\Maritaing_temp1.png",
    "-loop", "1", "-i", "$OUTPUT_DIR\Kalabahi_temp1.png",
    "-loop", "1", "-i", "$OUTPUT_DIR\Kabir_temp1.png",
    "-loop", "1", "-i", "$OUTPUT_DIR\Lewoleba_temp1.png",
    "-loop", "1", "-i", "$OUTPUT_DIR\Larantuka_temp1.png"
)

$FFMPEG_ARGS = @("-y") + $BASE_ARGS + $IMAGE_ARGS + @(
    "-filter_complex_script", $FILTER_FILE,
    "-c:a", "copy",
    "-c:v", "libx264",
    "-crf", "20",
    "-preset", "medium",
    "-pix_fmt", "yuv420p",
    "-t", "34.19",
    "$OUTPUT_DIR\$DATE_TEXT.mp4"
)

# Execution of FFmpeg
& $FFMPEG_CMD $FFMPEG_ARGS

Write-Host "======================================================================================================================="
Write-Host "[5/6] Process complete! Check the folder for $DATE_TEXT.mp4."
Write-Host "======================================================================================================================="

# Cleanup temporary files
Get-ChildItem -Path $OUTPUT_DIR -Filter "*_temp*" | Remove-Item -Force

Write-Host "======================================================================================================================="
Write-Host "[6/6] Cleaned up temporary files! Video process finalized."
Write-Host "======================================================================================================================="

Read-Host "Press Enter to continue..."