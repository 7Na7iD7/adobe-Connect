@echo off
echo ========================================
echo Adobe Connect to MP4 Converter
echo ========================================
echo.

:: Find video and audio files
set video=
for %%v in (*screenshare*.flv) do set video=%%v
set audio=
for %%a in (*cameraVoip*.flv) do set audio=%%a

if "%video%"=="" (
    echo ERROR: No screenshare .flv file found!
    pause
    exit /b
)
if "%audio%"=="" (
    echo ERROR: No cameraVoip .flv file found!
    pause
    exit /b
)

echo Video: %video%
echo Audio: %audio%
echo.

:: User selects quality
echo Select output quality (height in pixels):
echo   1 - 480p  (fast, smaller file)
echo   2 - 576p  (good balance)
echo   3 - 720p  (better quality, slower)
echo.
set /p choice="Enter 1, 2, or 3: "

if "%choice%"=="1" set scale=854:480
if "%choice%"=="2" set scale=1024:576
if "%choice%"=="3" set scale=1280:720

if "%scale%"=="" (
    echo Invalid choice. Please run again.
    pause
    exit /b
)

:: User selects frame rate
echo.
echo Select output frame rate (fps):
echo   1 - 30 fps  (original, smooth)
echo   2 - 15 fps  (half, smaller file)
echo   3 - 10 fps  (very small, good for slides)
echo.
set /p fps_choice="Enter 1, 2, or 3: "

if "%fps_choice%"=="1" set fps=30
if "%fps_choice%"=="2" set fps=15
if "%fps_choice%"=="3" set fps=10

if "%fps%"=="" (
    echo Invalid choice. Using default 30 fps.
    set fps=30
)

echo.
echo ========================================
echo Converting to MP4 (%scale%) at %fps% fps - Fast mode...
echo ========================================

if exist ".\ffmpeg.exe" (
    .\ffmpeg.exe -i "%video%" -i "%audio%" -c:v libx264 -preset ultrafast -vf scale=%scale% -r %fps% -c:a aac -b:a 128k final_video.mp4
) else (
    ffmpeg -i "%video%" -i "%audio%" -c:v libx264 -preset ultrafast -vf scale=%scale% -r %fps% -c:a aac -b:a 128k final_video.mp4
)

if %errorlevel% equ 0 (
    echo ========================================
    echo SUCCESS! File: final_video.mp4
    echo Resolution: %scale%, Frame rate: %fps% fps
    echo ========================================
) else (
    echo ========================================
    echo ERROR! Conversion failed.
    echo Make sure ffmpeg.exe is in this folder or PATH
    echo ========================================
)

pause