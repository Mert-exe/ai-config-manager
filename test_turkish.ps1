# Turkish Language Test Script

$baseUrl = "http://localhost:5003/message"

Write-Host "Testing Turkish Language Support..." -ForegroundColor Cyan
Write-Host "=" * 50

# Test 1: Turkish prompt for tournament
Write-Host "`nTest 1: Turkish - Tournament Memory" -ForegroundColor Yellow
$body1 = @{
    input = "turnuva servisinin bellek limitini 1907mb yap"
} | ConvertTo-Json

try {
    $response1 = Invoke-RestMethod -Uri $baseUrl -Method POST -ContentType "application/json" -Body $body1
    Write-Host "Success!" -ForegroundColor Green
    Write-Host ($response1 | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n" + ("=" * 50)

# Test 2: Turkish prompt for chat
Write-Host "`nTest 2: Turkish - Chat CPU Limit" -ForegroundColor Yellow
$body2 = @{
    input = "chat servisinin cpu limitini %77 yap"
} | ConvertTo-Json

try {
    $response2 = Invoke-RestMethod -Uri $baseUrl -Method POST -ContentType "application/json" -Body $body2
    Write-Host "Success!" -ForegroundColor Green
    Write-Host ($response2 | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n" + ("=" * 50)
Write-Host "`nTurkish Language Tests Completed." -ForegroundColor Cyan
