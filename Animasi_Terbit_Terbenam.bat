@echo off
setlocal enabledelayedexpansion

:: This program was created by Gemini 3 and assembled by rhh to enhance the operations of Stasiun Geofisika Alor.

:: Get the directory where this batch file is located (includes trailing backslash)
set "SCRIPT_DIR=%~dp0"
:: Convert backslashes to forward slashes for ImageMagick to prevent escape character issues (\T, \R)
set "FONT_DIR=%SCRIPT_DIR:\=/%"
set "FONT_BODY=%FONT_DIR%Poppins-Regular.ttf"
set "FONT_HEADER=%FONT_DIR%Poppins-Bold.ttf" 

:: --- I. Processing Data From MICA in a year ---

:: Set your input and output folder locations
set "INPUT_DIR=D:\TITIPAN_KITA\RAIHAN\Terbit Terbenam\Assets"
set "OUTPUT_DIR=D:\TITIPAN_KITA\RAIHAN\Terbit Terbenam"

:: Change directory to the input folder safely
cd /d "%INPUT_DIR%"
if errorlevel 1 (
    echo Error: Could not find the input folder "%INPUT_DIR%"
    pause
    exit /b
)

:: Prompt you to type the word
echo Terbit Terbenam Otomatis
set /p SEARCH_WORD="Input the date (e.g.: Mar,09): "

:: Loop through your specific files in the input folder
for %%F in (Kabir.csv Kalabahi.csv Larantuka.csv Lewoleba.csv Maritaing.csv) do (
    
    :: Check if the file actually exists before searching
    if exist "%%F" (
        echo Searching in %%F...
        
        :: Use PowerShell to find the word + 7 lines down, and save to the output folder
        powershell -NoProfile -Command "Select-String -Path '%%F' -Pattern '%SEARCH_WORD%' -Context 0,7 | ForEach-Object { $_.Line; $_.Context.PostContext } | Out-File -FilePath '%OUTPUT_DIR%\%%~nF_temp%%~xF' -Encoding utf8"
    ) else (
        echo Skipping %%F - File not found in the Assets folder.
    )
)

echo.
echo Batch search complete! Your _temp.csv files are saved in:
echo %OUTPUT_DIR%

echo =======================================================================================================================
echo [SUCCESS 1/5] Batch search complete! Your _temp.csv files are saved in %OUTPUT_DIR%. Now extracting columns 6 and 10 into _temp files and removing quotes...
echo =======================================================================================================================

:: --- II. NEW LINES FOR EXTRACTING COLUMNS 6 AND 10 & REMOVING QUOTES ---
echo.
echo Extracting columns 6 and 10 into _temp files and removing quotes...

:: Loop through the files to process the newly created _temp.csv files
for %%F in (Kabir.csv Kalabahi.csv Larantuka.csv Lewoleba.csv Maritaing.csv) do (
    
    :: Verify the temp file was actually created in the previous step
    if exist "%OUTPUT_DIR%\%%~nF_temp%%~xF" (
        echo Extracting and cleaning %%~nF_temp%%~xF...
        
        :: Grab columns 6 and 10, remove the double quotes, and save
        powershell -NoProfile -Command "Import-Csv -Path '%OUTPUT_DIR%\%%~nF_temp%%~xF' -Header (1..50) | Select-Object '6', '10' | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | ForEach-Object { $_ -replace '\x22', '' } | Out-File -FilePath '%OUTPUT_DIR%\%%~nF_temp1%%~xF' -Encoding utf8"
    )
)

echo =======================================================================================================================
echo [SUCCESS 2/5] Extraction and cleanup complete! Your _temp.csv files are ready! Now generating cover.png and content images for each CSV file...
echo =======================================================================================================================

:: --- III. Generate Images as Cover ---

:: 1. Use PowerShell to calculate the 7-day range and translate it to Indonesian
echo Calculating dates for %SEARCH_WORD%...
for /f "delims=" %%I in ('powershell -NoProfile -Command "$inputDate = '%SEARCH_WORD%'; $parts = $inputDate.Split(','); $dateStr = $parts[1] + ' ' + $parts[0] + ' ' + (Get-Date).Year; $start = [datetime]$dateStr; $end = $start.AddDays(6); $culture = [System.Globalization.CultureInfo]::CreateSpecificCulture('id-ID'); $out = $start.ToString('dd MMMM yyyy', $culture) + ' - ' + $end.ToString('dd MMMM yyyy', $culture); Write-Host $out"') do (
    set "DATE_TEXT=%%I"
)

echo Text to print: !DATE_TEXT!

:: 3. Run the ImageMagick command (Saved to OUTPUT_DIR)
echo Generating image...
magick -size 1080x1080 canvas:transparent -font "%FONT_HEADER%" -pointsize 45 -gravity center -fill #fac016 -annotate 0x0+45+50 "!DATE_TEXT!" "%OUTPUT_DIR%\cover_temp.png"

echo =======================================================================================================================
echo [SUCCESS 3/5] Generated cover.png and calculated dates successfully! Now generating content images for each CSV file...
echo =======================================================================================================================

:: --- IV. Generate Contents Terbit Terbenam ---

:: 1. Use PowerShell to calculate 7 distinct dates
echo Calculating dates for %SEARCH_WORD%...

set /a count=1
for /f "delims=" %%I in ('powershell -NoProfile -Command "$inputDate = '%SEARCH_WORD%'; $parts = $inputDate.Split(','); $dateStr = $parts[1] + ' ' + $parts[0] + ' ' + (Get-Date).Year; $start = [datetime]$dateStr; 0..6 | ForEach-Object { $start.AddDays($_).ToString('dd/MM/yyyy') }"') do (
    set "DATE_!count!=%%I"
    echo Day !count!: %%I
    set /a count+=1
)

:: 2. Loop through all matching CSV files in the OUTPUT folder
for %%F in ("%OUTPUT_DIR%\*_temp1.csv") do (
    echo.
    echo ==========================================
    echo Processing file: %%F
    echo Reading times...
    
    set /a csv_count=1
    
    :: Use 'usebackq' so we can safely quote the file name variable "%%F"
    for /f "usebackq tokens=1,2 delims=," %%A in ("%%F") do (
        if !csv_count! leq 7 (
            set "RAW_TERBIT=%%A"
            
            :: Extract only the last 5 characters (e.g., "05:46") to bypass the hidden BOM
            set "CLEAN_TERBIT=!RAW_TERBIT:~-5!"
            
            set "TERBIT_!csv_count!=!CLEAN_TERBIT!"
            set "TERBENAM_!csv_count!=%%B"
            
            echo Day !csv_count! Times - Terbit: !CLEAN_TERBIT!, Terbenam: %%B
            set /a csv_count+=1
        )
    )

    :: 3. Run the ImageMagick command and save it with the CSV's base name to OUTPUT_DIR
    set "Pos1=70"
    set "dv=68"

    :: Pre-calculate vertical offsets for annotations
    set /a "Y1=Pos1", "Y2=Pos1+dv", "Y3=Pos1+dv*2", "Y4=Pos1+dv*3", "Y5=Pos1+dv*4", "Y6=Pos1+dv*5", "Y7=Pos1+dv*6"

    echo Generating image for %%F...
    magick -size 1080x1080 canvas:transparent -pointsize 24 -gravity center -fill #141414 ^
        -font "%FONT_BODY%" -annotate 0x0-160+!Y1! "!DATE_1!" ^
        -font "%FONT_BODY%" -annotate 0x0-160+!Y2! "!DATE_2!" ^
        -font "%FONT_BODY%" -annotate 0x0-160+!Y3! "!DATE_3!" ^
        -font "%FONT_BODY%" -annotate 0x0-160+!Y4! "!DATE_4!" ^
        -font "%FONT_BODY%" -annotate 0x0-160+!Y5! "!DATE_5!" ^
        -font "%FONT_BODY%" -annotate 0x0-160+!Y6! "!DATE_6!" ^
        -font "%FONT_BODY%" -annotate 0x0-160+!Y7! "!DATE_7!" ^
        -font "%FONT_BODY%" -annotate 0x0+70+!Y1! "!TERBIT_1!" ^
        -font "%FONT_BODY%" -annotate 0x0+70+!Y2! "!TERBIT_2!" ^
        -font "%FONT_BODY%" -annotate 0x0+70+!Y3! "!TERBIT_3!" ^
        -font "%FONT_BODY%" -annotate 0x0+70+!Y4! "!TERBIT_4!" ^
        -font "%FONT_BODY%" -annotate 0x0+70+!Y5! "!TERBIT_5!" ^
        -font "%FONT_BODY%" -annotate 0x0+70+!Y6! "!TERBIT_6!" ^
        -font "%FONT_BODY%" -annotate 0x0+70+!Y7! "!TERBIT_7!" ^
        -font "%FONT_BODY%" -annotate 0x0+330+!Y1! "!TERBENAM_1!" ^
        -font "%FONT_BODY%" -annotate 0x0+330+!Y2! "!TERBENAM_2!" ^
        -font "%FONT_BODY%" -annotate 0x0+330+!Y3! "!TERBENAM_3!" ^
        -font "%FONT_BODY%" -annotate 0x0+330+!Y4! "!TERBENAM_4!" ^
        -font "%FONT_BODY%" -annotate 0x0+330+!Y5! "!TERBENAM_5!" ^
        -font "%FONT_BODY%" -annotate 0x0+330+!Y6! "!TERBENAM_6!" ^
        -font "%FONT_BODY%" -annotate 0x0+330+!Y7! "!TERBENAM_7!" ^
        "%OUTPUT_DIR%\%%~nF.png"

    echo Success! Image saved as %%~nF.png.
)

echo =======================================================================================================================
echo [SUCCESS 4/5] Content images generated successfully for each CSV file! Now merging everything into one video with FFmpeg...
echo =======================================================================================================================

:: --- V. Merge it All in one video ---

echo All files processed successfully!
echo Starting FFmpeg process...

:: Absolute path for filters.txt using forward slashes (required by FFmpeg's filter engine)
set "FILTER_FILE=%SCRIPT_DIR%filters.txt"
set "FILTER_FILE=!FILTER_FILE:\=/!"

:: Define inputs (Base video is assumed to be in INPUT_DIR)
set BASE=-i "%OUTPUT_DIR%\Assets\base.mp4"

:: Define images (Pointed to OUTPUT_DIR where they were just generated)
set IMAGES=-loop 1 -i "%OUTPUT_DIR%\cover_temp.png" -loop 1 -i "%OUTPUT_DIR%\cover_temp.png" -loop 1 -i "%OUTPUT_DIR%\Maritaing_temp1.png" -loop 1 -i "%OUTPUT_DIR%\Kalabahi_temp1.png" -loop 1 -i "%OUTPUT_DIR%\Kabir_temp1.png" -loop 1 -i "%OUTPUT_DIR%\Lewoleba_temp1.png" -loop 1 -i "%OUTPUT_DIR%\Larantuka_temp1.png"

:: Run the command
:: Note: Using !FILTER_FILE! inside quotes for the filter_complex_script option
ffmpeg -y -hwaccel cuda %BASE% %IMAGES% -filter_complex_script "!FILTER_FILE!" -c:a copy -c:v h264_nvenc -preset p6 -rc vbr -cq 20 -pix_fmt yuv420p -t 34.19 "%OUTPUT_DIR%\!DATE_TEXT!.mp4"

echo =======================================================================================================================
echo [SUCCESS 5/5] Process complete! Check the folder for %DATE_TEXT%.mp4.
echo =======================================================================================================================

del "%OUTPUT_DIR%\*_temp*"

echo =======================================================================================================================
echo [SUCCESS Bonus/5] Cleaned up temporary files! Your final video is ready in the output folder. Thank you for using this batch script!
echo =======================================================================================================================

pause
