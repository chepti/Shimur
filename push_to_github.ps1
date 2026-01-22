# Script to push changes to GitHub
Set-Location "t:\CURSOR2\Shimur"

Write-Host "Checking git status..." -ForegroundColor Cyan
git status

Write-Host "`nAdding all changes..." -ForegroundColor Cyan
git add .

Write-Host "`nCommitting changes..." -ForegroundColor Cyan
git commit -m "Add dashboard screen, fix dropdown error, add deployment configuration"

Write-Host "`nPushing to GitHub..." -ForegroundColor Cyan
git push origin main

Write-Host "`nDone! Changes pushed to GitHub." -ForegroundColor Green
