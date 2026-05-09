@echo off
title Adobe Connect Smart Merger
setlocal enabledelayedexpansion
echo ===================================================
echo  Smart Adobe Connect to MP4 Converter
echo  (Merges ALL video/audio parts including indexstream)
echo ===================================================
echo.

:: -----------------------------------------------
:: 1. Find and sort all video files (including indexstream)
:: -----------------------------------------------
set video_temp=_video_temp.txt
if exist %video_temp% del %video_temp%

for %%f in (*screenshare*.flv *screenshot*.flv *mainstream.flv *indexstream*.flv) do (
    set "fname=%%f"
    set num1=0
    set num2=0
    :: Extract two numbers from patterns like "screenshare_1_3.flv" or "screenshot_3_7.flv" or "indexstream_0_1.flv"
    for /f "tokens=2,3 delims=_." %%a in ("%%f") do (
        set num1=%%a
        set num2=%%b
    )
    :: Remove leading zeros
    for /f "tokens=* delims=0" %%c in ("!num1!") do set num1=%%c
    for /f "tokens=* delims=0" %%c in ("!num2!") do set num2=%%c
    if "!num1!"=="" set num1=0
    if "!num2!"=="" set num2=0
    echo !num1! !num2! %%f >> %video_temp%
)

if not exist %video_temp% (
    echo ERROR: No video files found!
    pause
    exit /b
)

:: Sort numerically by first then second number
sort %video_temp% /o _video_sorted.txt
set video_list=_video_list.txt
if exist %video_list% del %video_list%
for /f "tokens=3,*" %%a in (_video_sorted.txt) do (
    echo file '%%a' >> %video_list%
)
del %video_temp% _video_sorted.txt

echo Video parts found and sorted:
for /f "tokens=3,*" %%a in (%video_list%) do echo   %%a

:: -----------------------------------------------
:: 2. Find and sort all audio files
:: -----------------------------------------------
set audio_temp=_audio_temp.txt
if exist %audio_temp% del %audio_temp%

for %%f in (cameraVoip_*.flv) do (
    set "fname=%%f"
    set num1=0
    set num2=0
    for /f "tokens=2,3 delims=_." %%a in ("%%f") do (
        set num1=%%a
        set num2=%%b
    )
    for /f "tokens=* delims=0" %%c in ("!num1!") do set num1=%%c
    for /f "tokens=* delims=0" %%c in ("!num2!") do set num2=%%c
    if "!num1!"=="" set num1=0
    if "!num2!"=="" set num2=0
    echo !num1! !num2! %%f >> %audio_temp%
)

if not exist %audio_temp% (
    echo ERROR: No cameraVoip audio files found!
    pause
    exit /b
)

sort %audio_temp% /o _audio_sorted.txt
set audio_list=_audio_list.txt
if exist %audio_list% del %audio_list%
for /f "tokens=3,*" %%a in (_audio_sorted.txt) do (
    echo file '%%a' >> %audio_list%
)
del %audio_temp% _audio_sorted.txt

echo Audio parts found and sorted:
for /f "tokens=3,*" %%a in (%audio_list%) do echo   %%a

:: -----------------------------------------------
:: 3. User selects quality and frame rate
:: -----------------------------------------------
echo.
echo Select output quality:
echo   1 - 480p   (854x480)
echo   2 - 576p   (1024x576)
echo   3 - 720p   (1280x720)
echo   4 - 1080p  (1920x1080)
set /p q="Enter 1-4: "
if "%q%"=="1" set scale=854:480
if "%q%"=="2" set scale=1024:576
if "%q%"=="3" set scale=1280:720
if "%q%"=="4" set scale=1920:1080
if "%scale%"=="" set scale=854:480

echo.
echo Select frame rate (fps):
echo   1 - 30 fps
echo   2 - 15 fps
echo   3 - 10 fps
echo   4 - 60 fps
echo   5 - 90 fps
set /p f="Enter 1-5: "
if "%f%"=="1" set fps=30
if "%f%"=="2" set fps=15
if "%f%"=="3" set fps=10
if "%f%"=="4" set fps=60
if "%f%"=="5" set fps=90
if "%fps%"=="" set fps=30

:: -----------------------------------------------
:: 4. Concatenate all video parts
:: -----------------------------------------------
echo.
echo Merging video parts...
if exist ".\ffmpeg.exe" (
    .\ffmpeg.exe -f concat -safe 0 -i %video_list% -c copy video_merged.flv
) else (
    ffmpeg -f concat -safe 0 -i %video_list% -c copy video_merged.flv
)
if %errorlevel% neq 0 goto error

:: -----------------------------------------------
:: 5. Concatenate all audio parts
:: -----------------------------------------------
echo Merging audio parts...
if exist ".\ffmpeg.exe" (
    .\ffmpeg.exe -f concat -safe 0 -i %audio_list%-c copy audio_merged.flv
) else (
    ffmpeg -f concat -safe 0 -i %audio_list% -c copy audio_merged.flv
)
if %errorlevel% neq 0 goto error

:: -----------------------------------------------
:: 6. Final MP4 conversion
:: -----------------------------------------------
echo.
echo Creating final MP4...
if exist ".\ffmpeg.exe" (
    .\ffmpeg.exe -i video_merged.flv -i audio_merged.flv -c:v libx264 -preset ultrafast -vf "scale=%scale%,fps=%fps%" -c:a aac -b:a 128k -movflags +faststart final_video.mp4
) else (
    ffmpeg -i video_merged.flv -i audio_merged.flv -c:v libx264 -preset ultrafast -vf "scale=%scale%,fps=%fps%" -c:a aac -b:a 128k -movflags +faststart final_video.mp4
)
if %errorlevel% neq 0 goto error

:: Cleanup
del video_merged.flv audio_merged.flv %video_list% %audio_list% 2>nul
echo.
echo ===================================================
echo SUCCESS! final_video.mp4 has been created.
echo ===================================================
pause
exit /b

:error
echo.
echo ===================================================
echo ERROR! Conversion failed.
echo Make sure ffmpeg.exe is in this folder or PATH.
echo ===================================================
pause