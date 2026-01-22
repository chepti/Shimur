# סקריפט לתיקון PATH של Flutter ב-PowerShell
# הרץ את הסקריפט הזה אם Flutter לא מזוהה

Write-Host "בודק נתיב Flutter..." -ForegroundColor Cyan

$flutterPath = "T:\CURSOR2\Programs\flutter\bin"

# בדיקה אם Flutter קיים
if (Test-Path "$flutterPath\flutter.bat") {
    Write-Host "✓ Flutter נמצא בנתיב: $flutterPath" -ForegroundColor Green
} else {
    Write-Host "✗ Flutter לא נמצא בנתיב: $flutterPath" -ForegroundColor Red
    Write-Host "בדוק שהנתיב נכון!" -ForegroundColor Yellow
    exit 1
}

# הוספה ל-PATH של הסשן הנוכחי
$env:PATH += ";$flutterPath"
Write-Host "✓ הוסף ל-PATH של הסשן הנוכחי" -ForegroundColor Green

# בדיקה אם כבר ב-PATH של המשתמש
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -like "*flutter*") {
    Write-Host "✓ Flutter כבר ב-PATH של המשתמש" -ForegroundColor Green
} else {
    Write-Host "! Flutter לא ב-PATH של המשתמש" -ForegroundColor Yellow
    Write-Host "מוסיף ל-PATH של המשתמש..." -ForegroundColor Cyan
    
    # הוספה ל-PATH של המשתמש
    $newPath = $userPath + ";$flutterPath"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "✓ הוסף ל-PATH של המשתמש" -ForegroundColor Green
    Write-Host "! הפעל מחדש את PowerShell/VS Code כדי שהשינוי ייכנס לתוקף" -ForegroundColor Yellow
}

# בדיקה אם Flutter עובד
Write-Host "`nבודק אם Flutter עובד..." -ForegroundColor Cyan
try {
    $version = flutter --version 2>&1 | Select-Object -First 1
    if ($version -like "*Flutter*") {
        Write-Host "✓ Flutter עובד! $version" -ForegroundColor Green
    } else {
        Write-Host "✗ Flutter לא עובד" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ שגיאה: $_" -ForegroundColor Red
}

Write-Host "`nסיימתי!" -ForegroundColor Cyan
Write-Host "אם Flutter עדיין לא עובד, הפעל מחדש את VS Code או PowerShell" -ForegroundColor Yellow
