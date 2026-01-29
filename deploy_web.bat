@echo off
chcp 65001 >nul
cd /d t:\CURSOR2\Shimur

echo ===== 1. Push to GitHub =====
git add .
git status
git commit -m "Update SHIMUR: manager settings, engagement survey, weekly summary, Hebrew date widget, Firestore and UI"
git push origin main
if errorlevel 1 (
  echo Git push failed. Check and run manually if needed.
  pause
  exit /b 1
)

echo.
echo ===== 2. Build Flutter Web =====
flutter build web --release
if errorlevel 1 (
  echo Flutter build failed.
  pause
  exit /b 1
)

echo.
echo ===== 3. Deploy to Firebase Hosting =====
firebase deploy --only hosting
if errorlevel 1 (
  echo Firebase deploy failed. Run: firebase login
  pause
  exit /b 1
)

echo.
echo Done! Web version updated at https://shimur.web.app
pause
