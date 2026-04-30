@echo off
setlocal enabledelayedexpansion
title Adobe Connect Full Merger (All Parts)
echo ===================================================
echo  Merging ALL screenshare and cameraVoip parts
echo ===================================================
echo.

:: 1. Collect and sort video files (screenshare_x_y.flv)
set video_list=_video_list.txt
if exist %video_list% del %video_list%
for /f "delims=" %%f in ('dir /b screenshare_*.flv 2^>nul') do (
    for /f "tokens=2,3 delims=_." %%a in ("%%f") do (
        set "num1=%%a"
        set "num2=%%b"
        :: Remove leading zeros
        for /f "tokens=* delims=0" %%c in ("!num1!") do set "num1=%%c"
        for /f "tokens=* delims=0" %%c in ("!num2!") do set "num2=%%c"
        if "!num1!"=="" set num1=0
        if "!num2!"=="" set num2=0
        echo !num1! !num2! %%f >> _video_temp.txt
    )
)
if not exist _video_temp.txt (
    echo No screenshare .flv files found!
    pause
    exit /b
)
sort _video_temp.txt /o _video_sorted.txt
for /f "tokens=3,*" %%a in (_video_sorted.txt) do (
    echo file '%%a' >> %video_list%
)
del _video_temp.txt _video_sorted.txt

:: 2. Collect and sort audio files (cameraVoip_x_y.flv)
set audio_list=_audio_list.txt
if exist %audio_list% del %audio_list%
for /f "delims=" %%f in ('dir /b cameraVoip_*.flv 2^>nul') do (
    for /f "tokens=2,3 delims=_." %%a in ("%%f") do (
        set "num1=%%a"
        set "num2=%%b"
        for /f "tokens=* delims=0" %%c in ("!num1!") do set "num1=%%c"
        for /f "tokens=* delims=0" %%c in ("!num2!") do set "num2=%%c"
        if "!num1!"=="" set num1=0
        if "!num2!"=="" set num2=0
        echo !num1! !num2! %%f >> _audio_temp.txt
    )
)
if not exist _audio_temp.txt (
    echo No cameraVoip .flv files found!
    pause
    exit /b
)
sort _audio_temp.txt /o _audio_sorted.txt
for /f "tokens=3,*" %%a in (_audio_sorted.txt) do (
    echo file '%%a' >> %audio_list%
)
del _audio_temp.txt _audio_sorted.txt

:: 3. User selects quality and frame rate
echo.
echo Select output quality:
echo   1 - 480p  (854x480) - fast, small
echo   2 - 576p  (1024x576) - good balance
echo   3 - 720p  (1280x720) - better quality
echo   4 - 1080p (1920x1080) - high quality, slower
set /p q="Enter 1-4: "
if "%q%"=="1" set scale=854:480
if "%q%"=="2" set scale=1024:576
if "%q%"=="3" set scale=1280:720
if "%q%"=="4" set scale=1920:1080
if "%scale%"=="" set scale=854:480

echo.
echo Select frame rate (fps):
echo   1 - 30 fps  (smooth)
echo   2 - 15 fps  (half, smaller file)
echo   3 - 10 fps  (fast, good for slides)
echo   4 - 60 fps  (very smooth, larger file)
echo   5 - 90 fps  (extra smooth, largest file)
set /p f="Enter 1-5: "
if "%f%"=="1" set fps=30
if "%f%"=="2" set fps=15
if "%f%"=="3" set fps=10
if "%f%"=="4" set fps=60
if "%f%"=="5" set fps=90
if "%fps%"=="" set fps=30

:: 4. Concatenate video files
echo.
echo Merging video parts...
if exist ".\ffmpeg.exe" (
    .\ffmpeg.exe -f concat -safe 0 -i %video_list% -c copy video_merged.flv
) else (
    ffmpeg -f concat -safe 0 -i %video_list% -c copy video_merged.flv
)
if %errorlevel% neq 0 goto error

:: 5. Concatenate audio files
echo Merging audio parts...
if exist ".\ffmpeg.exe" (
    .\ffmpeg.exe -f concat -safe 0 -i %audio_list% -c copy audio_merged.flv
) else (
    ffmpeg -f concat -safe 0 -i %audio_list% -c copy audio_merged.flv
)
if %errorlevel% neq 0 goto error

:: 6. Final conversion to MP4
echo.
echo Creating final MP4...
if exist ".\ffmpeg.exe" (
    .\ffmpeg.exe -i video_merged.flv -i audio_merged.flv -c:v libx264 -preset ultrafast -vf "scale=%scale%,fps=%fps%" -c:a aac -b:a 128k -movflags +faststart final_video.mp4
) else (
    ffmpeg -i video_merged.flv -i audio_merged.flv -c:v libx264 -preset ultrafast -vf "scale=%scale%,fps=%fps%" -c:a aac -b:a 128k -movflags +faststart final_video.mp4
)
if %errorlevel% neq 0 goto error

:: 7. Cleanup and success
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