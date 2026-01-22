# סקריפט לתיקון PATH של FlutterFire CLI
# הרץ את הסקריפט הזה אם flutterfire לא מזוהה

Write-Host "בודק נתיב FlutterFire CLI..." -ForegroundColor Cyan

$pubCacheBin = "$env:LOCALAPPDATA\Pub\Cache\bin"

# בדיקה אם הנתיב קיים
if (Test-Path $pubCacheBin) {
    Write-Host "✓ נתיב Pub Cache נמצא: $pubCacheBin" -ForegroundColor Green
} else {
    Write-Host "✗ נתיב Pub Cache לא נמצא: $pubCacheBin" -ForegroundColor Red
    exit 1
}

# הוספה ל-PATH של הסשן הנוכחי
$env:PATH += ";$pubCacheBin"
Write-Host "✓ הוסף ל-PATH של הסשן הנוכחי" -ForegroundColor Green

# בדיקה אם כבר ב-PATH של המשתמש
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -like "*Pub\Cache\bin*") {
    Write-Host "✓ Pub Cache כבר ב-PATH של המשתמש" -ForegroundColor Green
} else {
    Write-Host "! Pub Cache לא ב-PATH של המשתמש" -ForegroundColor Yellow
    Write-Host "מוסיף ל-PATH של המשתמש..." -ForegroundColor Cyan
    
    # הוספה ל-PATH של המשתמש
    $newPath = $userPath + ";$pubCacheBin"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "✓ הוסף ל-PATH של המשתמש" -ForegroundColor Green
    Write-Host "! הפעל מחדש את PowerShell/VS Code כדי שהשינוי ייכנס לתוקף" -ForegroundColor Yellow
}

# בדיקה אם flutterfire עובד
Write-Host "`nבודק אם flutterfire עובד..." -ForegroundColor Cyan
try {
    $version = flutterfire --version 2>&1 | Select-Object -First 1
    if ($version -like "*flutterfire*" -or $version -like "*version*") {
        Write-Host "✓ flutterfire עובד!" -ForegroundColor Green
    } else {
        Write-Host "✗ flutterfire לא עובד" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ שגיאה: $_" -ForegroundColor Red
}

Write-Host "`nסיימתי!" -ForegroundColor Cyan
Write-Host "אם flutterfire עדיין לא עובד, הפעל מחדש את VS Code או PowerShell" -ForegroundColor Yellow
