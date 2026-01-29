# Push to GitHub, build web, deploy to Firebase Hosting
Set-Location "t:\CURSOR2\Shimur"

Write-Host "===== 1. Push to GitHub =====" -ForegroundColor Cyan
git add .
git status
git commit -m "Update SHIMUR: manager settings, engagement survey, weekly summary, Hebrew date widget, Firestore and UI"
git push origin main
if ($LASTEXITCODE -ne 0) { Write-Host "Git push failed." -ForegroundColor Red; exit 1 }

Write-Host "`n===== 2. Build Flutter Web =====" -ForegroundColor Cyan
flutter build web --release
if ($LASTEXITCODE -ne 0) { Write-Host "Flutter build failed." -ForegroundColor Red; exit 1 }

Write-Host "`n===== 3. Deploy to Firebase Hosting =====" -ForegroundColor Cyan
firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) { Write-Host "Firebase deploy failed. Run: firebase login" -ForegroundColor Red; exit 1 }

Write-Host "`nDone! Web updated at https://shimur.web.app" -ForegroundColor Green
