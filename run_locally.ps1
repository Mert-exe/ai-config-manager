# Run All Services Locally (Without Docker)

# Configuration
$env:SCHEMA_SERVICE_URL = "http://localhost:5001"
$env:VALUES_SERVICE_URL = "http://localhost:5002"
$env:OLLAMA_URL = "http://localhost:11434/api/generate"
$env:MODEL_NAME = "llama3"

Write-Host "Starting Schema Service on port 5001..." -ForegroundColor Cyan
$schemaJob = Start-Job -ScriptBlock {
    param($cwd)
    Set-Location $cwd
    if ($env:VIRTUAL_ENV) { . "$env:VIRTUAL_ENV/Scripts/Activate.ps1" }
    python schema-server/app.py --schema-dir data/schemas --listen 0.0.0.0:5001
} -ArgumentList $PWD

Write-Host "Starting Values Service on port 5002..." -ForegroundColor Cyan
$valuesJob = Start-Job -ScriptBlock {
    param($cwd)
    Set-Location $cwd
    if ($env:VIRTUAL_ENV) { . "$env:VIRTUAL_ENV/Scripts/Activate.ps1" }
    python values-server/app.py --values-dir data/values --listen 0.0.0.0:5002
} -ArgumentList $PWD

Write-Host "Starting Bot Service on port 5003..." -ForegroundColor Cyan
$botJob = Start-Job -ScriptBlock {
    param($cwd)
    Set-Location $cwd
    if ($env:VIRTUAL_ENV) { . "$env:VIRTUAL_ENV/Scripts/Activate.ps1" }
    # Pass environment variables explicitly if needed, but Start-Job isolates scope. 
    # We need to set env vars inside the job block or pass them.
    $env:SCHEMA_SERVICE_URL = "http://localhost:5001"
    $env:VALUES_SERVICE_URL = "http://localhost:5002"
    $env:OLLAMA_URL = "http://localhost:11434/api/generate"
    $env:MODEL_NAME = "llama3"
    
    python bot-server/app.py --listen 0.0.0.0:5003
} -ArgumentList $PWD

Write-Host "All services started in background jobs." -ForegroundColor Green
Write-Host "Jobs: $($schemaJob.Id), $($valuesJob.Id), $($botJob.Id)"
Write-Host "Press any key to stop all services and exit..."

$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Stop-Job $schemaJob
Stop-Job $valuesJob
Stop-Job $botJob
Remove-Job $schemaJob
Remove-Job $valuesJob
Remove-Job $botJob

Write-Host "Services stopped." -ForegroundColor Yellow
