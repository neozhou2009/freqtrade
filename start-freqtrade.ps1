#!/usr/bin/env pwsh

Write-Host "Starting Freqtrade Bot with Docker Compose..." -ForegroundColor Green
Write-Host ""

# 检查 Docker 是否运行
try {
    $dockerVersion = docker --version
    Write-Host "Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "Error: Docker is not installed or not running" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# 检查 Docker Compose 文件是否存在
if (-not (Test-Path "docker-compose-freqtrade-standalone.yml")) {
    Write-Host "Error: docker-compose-freqtrade-standalone.yml not found" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# 停止可能存在的容器
Write-Host "Stopping existing containers..." -ForegroundColor Yellow
docker-compose -f docker-compose-freqtrade-standalone.yml down

# 构建并启动服务
Write-Host "Starting Freqtrade Bot..." -ForegroundColor Green
docker-compose -f docker-compose-freqtrade-standalone.yml up -d

# 等待服务启动
Write-Host "Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 检查服务状态
Write-Host ""
Write-Host "Checking service status..." -ForegroundColor Green
docker-compose -f docker-compose-freqtrade-standalone.yml ps

Write-Host ""
Write-Host "Freqtrade Bot started successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Access points:" -ForegroundColor Cyan
Write-Host "- Freqtrade API: http://localhost:8080" -ForegroundColor White
Write-Host "- Redis: localhost:6379" -ForegroundColor White
Write-Host "- PostgreSQL: localhost:5432" -ForegroundColor White
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Cyan
Write-Host "- View logs: docker-compose -f docker-compose-freqtrade-standalone.yml logs -f freqtrade-bot" -ForegroundColor White
Write-Host "- Stop: docker-compose -f docker-compose-freqtrade-standalone.yml down" -ForegroundColor White
Write-Host "- Restart: docker-compose -f docker-compose-freqtrade-standalone.yml restart" -ForegroundColor White
Write-Host ""

# 显示实时日志选项
$showLogs = Read-Host "Do you want to view the logs now? (y/n)"
if ($showLogs -eq "y" -or $showLogs -eq "Y") {
    Write-Host "Showing Freqtrade Bot logs (Ctrl+C to exit)..." -ForegroundColor Yellow
    docker-compose -f docker-compose-freqtrade-standalone.yml logs -f freqtrade-bot
}

Read-Host "Press Enter to exit"
