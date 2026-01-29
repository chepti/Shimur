# Script to push changes to GitHub
Set-Location "t:\CURSOR2\Shimur"

Write-Host "Checking git status..." -ForegroundColor Cyan
git status

Write-Host "`nAdding all changes..." -ForegroundColor Cyan
git add .

Write-Host "`nCommitting changes..." -ForegroundColor Cyan
git commit -m "Update SHIMUR: manager settings, engagement survey, weekly summary, Hebrew date widget, Firestore and UI"

Write-Host "`nPushing to GitHub..." -ForegroundColor Cyan
git push origin main

Write-Host "`nDone! Changes pushed to GitHub." -ForegroundColor Green
