# Edge Case / Chaos Test Script
# Purpose: To observe how the system handles boundary conditions, invalid inputs, and nonsense requests.

$baseUrl = "http://localhost:5003"
$headers = @{ "Content-Type" = "application/json" }

function Test-Chaos {
    param (
        [string]$Message,
        [string]$Scenario,
        [string]$ExpectedResult
    )

    Write-Host "--------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Scenario: $Scenario" -ForegroundColor Yellow
    Write-Host "Input: '$Message'" -ForegroundColor Gray
    Write-Host "Expected: $ExpectedResult" -ForegroundColor Magenta

    $body = @{ input = $Message } | ConvertTo-Json -Compress

    try {
        $start = Get-Date
        $response = Invoke-RestMethod -Uri "$baseUrl/message" -Method Post -Headers $headers -Body $body -ErrorAction Stop
        $end = Get-Date
        
        Write-Host "Status: 200 OK (Time: $(($end - $start).TotalSeconds) sec)" -ForegroundColor Green
        
        # Show only relevant fields (Summary)
        $summary = $response.workloads.statefulsets.tournament.containers.tournament.resources
        if ($null -eq $summary) { 
            $summary = $response.workloads.deployments.matchmaking.containers.matchmaking.resources 
        }
        
        Write-Host "Returned Values (Resources):"
        $summary | ConvertTo-Json -Depth 2
    }
    catch {
        Write-Host "ERROR OCCURRED!" -ForegroundColor Red
        if ($_.Exception.Response) {
            $errBody = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            Write-Host "Server Response: $($errBody.ReadToEnd())" -ForegroundColor Red
        }
        else {
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
}

Write-Host " CHAOS TESTS STARTING " -ForegroundColor Red
Start-Sleep -Seconds 2

# 1. Text-to-Number Input
# TinyLlama might fail to parse text numbers, system is expected to ignore or regex might fail.
Test-Chaos -Message "set tournament memory to one thousand twenty four mb" `
    -Scenario "Text-to-Number Input" `
    -ExpectedResult "Should not change (or set to 1024 if AI is smart enough)"

# 2. Typo Tolerance
# "tournament" -> "turnament", "memory" -> "memry"
Test-Chaos -Message "set turnament memry to 500" `
    -Scenario "Typos / Fuzzy Matching" `
    -ExpectedResult "Should set to 500 if App name is detected (Regex Fallback)"

# 3. Impossible Values (Validation)
# Negative memory input
Test-Chaos -Message "set tournament memory to -50" `
    -Scenario "Negative Value" `
    -ExpectedResult "Should reject if Schema validation works, otherwise -50 (Dangerous!)"

# 4. Irrelevant Application (Hallucination Check)
# Non-existent app name
Test-Chaos -Message "set minecraft server cpu to 5000" `
    -Scenario "Non-existent App" `
    -ExpectedResult "404 App Name Not Found error"

# 5. SQL/Code Injection Attempt (Security)
# Code injection attempt within the command
Test-Chaos -Message "set tournament memory to 1024; DROP DATABASE;" `
    -Scenario "Injection Attempt" `
    -ExpectedResult "Should only extract 1024, ignore the rest (Safe via Regex)"

# 6. Ambiguous / Complex Sentence
Test-Chaos -Message "I hate this game but please set matchmaking cpu to 333 because it implies half evil" `
    -Scenario "Noisy Sentence" `
    -ExpectedResult "Should find 333 and update"

Write-Host " Tests Completed. Analyze the results." -ForegroundColor Cyan