# Test Script for AI-Assisted Configuration Tool (Windows/PowerShell)

$baseUrl = "http://localhost:5003"
$headers = @{ "Content-Type" = "application/json" }

function Test-Endpoint {
    param (
        [string]$InputText,
        [string]$Description
    )

    Write-Host "--------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Testing: $Description" -ForegroundColor Yellow
    Write-Host "Input: $InputText" -ForegroundColor Gray

    $body = @{ input = $InputText } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/message" -Method Post -Headers $headers -Body $body -ErrorAction Stop
        Write-Host "Response:" -ForegroundColor Green
        $response | ConvertTo-Json -Depth 5
    }
    catch {
        Write-Host "Error:" -ForegroundColor Red
        Write-Host $_.Exception.Message
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "Server Response: $responseBody" -ForegroundColor Red
        }
    }
}

# Wait for service to be up
Write-Host "Waiting for service at $baseUrl..."
$retries = 0
while ($retries -lt 5) {
    try {
        Invoke-WebRequest -Uri "$baseUrl/message" -Method Options -ErrorAction Stop | Out-Null
        Write-Host "Service is UP!" -ForegroundColor Green
        break
    }
    catch {
        Start-Sleep -Seconds 2
        $retries++
    }
}

# 1. Update Tournament Service Memory
Test-Endpoint -InputText "set tournament service memory to 1024mb" -Description "Update Tournament Memory"

# 2. Update Matchmaking Env
Test-Endpoint -InputText "set GAME_NAME env to toyblast for matchmaking service" -Description "Update Matchmaking Environment Variable"

# 3. Update Chat Service CPU
Test-Endpoint -InputText "lower cpu limit of chat service to %80" -Description "Update Chat CPU Limit"

Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host "Tests Completed."
