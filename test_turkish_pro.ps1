# AI-Assisted Configuration Tool Türkçe Test Scripti
$baseUrl = "http://localhost:5003"
$headers = @{ "Content-Type" = "application/json" }

function Test-AI {
    param ([string]$mesaj, [string]$baslik)
    Write-Host "`n>>> Test Ediliyor: $baslik" -ForegroundColor Cyan
    Write-Host "Kullanıcı Mesajı: $mesaj" -ForegroundColor Gray
    
    $body = @{ input = $mesaj } | ConvertTo-Json
    try {
        $start = Get-Date
        $response = Invoke-RestMethod -Uri "$baseUrl/message" -Method Post -Headers $headers -Body $body -ErrorAction Stop
        $end = Get-Date
        $sure = ($end - $start).TotalSeconds
        
        Write-Host "Başarılı! (Süre: $sure sn)" -ForegroundColor Green
        $response | ConvertTo-Json -Depth 5
    }
    catch {
        Write-Host "Hata Oluştu!" -ForegroundColor Red
        Write-Host $_.Exception.Message
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            Write-Host "Sunucu Yanıtı: $($reader.ReadToEnd())" -ForegroundColor Red
        }
    }
}

Write-Host "Servislere bağlanılıyor..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 1. Senaryo: Bellek güncelleme (Tournament)
Test-AI -mesaj "tournament servisi bellek miktarını 1923mb yap" -baslik "Bellek Güncelleme"

# 2. Senaryo: Ortam değişkeni güncelleme (Matchmaking)
Test-AI -mesaj "matchmaking servisi için GAME_NAME değişkenini 'final-test' olarak ayarla" -baslik "Env Değişkeni Güncelleme"

# 3. Senaryo: CPU limiti düşürme (Chat)
Test-AI -mesaj "chat servisi cpu limitini %70 seviyesine çek" -baslik "CPU Limit Güncelleme"

# 4. Senaryo: Büyük/Küçük harf duyarlılığı testi
Test-AI -mesaj "TOURNAMENT servisini kontrol et ve belleği 512mb yap" -baslik "Case-Insensitivity Testi"

Write-Host "`nTestler tamamlandı. data/values/ klasöründeki dosyaları kontrol ederek kalıcılığı teyit edebilirsiniz." -ForegroundColor Cyan
