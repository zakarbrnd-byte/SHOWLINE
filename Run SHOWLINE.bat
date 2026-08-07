@echo off
title Showline
cd /d "C:\Users\Win10-User\Desktop\SHOWLINE"
echo Starting Showline in Chrome...
echo.
if not exist "build\web\assets\assets\catalog" mkdir "build\web\assets\assets\catalog"
if exist "S:\Public\#2 CATALOGUE\2026 CATALOG\KND5001_BLACK.jpg" (
  copy /Y "S:\Public\#2 CATALOGUE\2026 CATALOG\KND5001_BLACK.jpg" "assets\catalog\KND5001_BLACK.jpg" >nul
  copy /Y "S:\Public\#2 CATALOGUE\2026 CATALOG\KND5001_BLACK.jpg" "build\web\assets\assets\catalog\KND5001_BLACK.jpg" >nul
)
if exist "S:\Public\#2 CATALOGUE\2026 CATALOG\KNT136_BLACK_WHITE.jpg" (
  copy /Y "S:\Public\#2 CATALOGUE\2026 CATALOG\KNT136_BLACK_WHITE.jpg" "assets\catalog\KNT136_BLACK_WHITE.jpg" >nul
  copy /Y "S:\Public\#2 CATALOGUE\2026 CATALOG\KNT136_BLACK_WHITE.jpg" "build\web\assets\assets\catalog\KNT136_BLACK_WHITE.jpg" >nul
)
start "" "http://localhost:53741"
python -m http.server 53741 --directory "build\web"
if errorlevel 1 (
  echo.
  echo Showline could not start. Review the message above.
  pause
)
