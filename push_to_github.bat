@echo off
chcp 65001 >nul
cd /d t:\CURSOR2\Shimur

echo Checking git status...
git status

echo.
echo Adding all changes...
git add .

echo.
echo Committing changes...
git commit -m "Update SHIMUR: manager settings, engagement survey, weekly summary, Hebrew date widget, Firestore and UI"

echo.
echo Pushing to GitHub...
git push origin main

echo.
echo Done! Changes pushed to GitHub.
pause
