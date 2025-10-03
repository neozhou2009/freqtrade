#!/usr/bin/env pwsh

Write-Host "=== Freqtrade Bot Test Script ===" -ForegroundColor Green
Write-Host ""

# 测试API连接
Write-Host "1. Testing API connectivity..." -ForegroundColor Yellow
try {
    $pingResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/ping" -Method Get -TimeoutSec 5
    if ($pingResponse.StatusCode -eq 200) {
        Write-Host "✓ API Ping successful: $($pingResponse.Content)" -ForegroundColor Green
    } else {
        Write-Host "✗ API Ping failed with status: $($pingResponse.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ API Ping failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 测试容器状态
Write-Host "2. Checking container status..." -ForegroundColor Yellow
try {
    $containers = docker ps --filter "name=freqtrade" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    Write-Host "Container Status:" -ForegroundColor Cyan
    Write-Host $containers -ForegroundColor White
} catch {
    Write-Host "✗ Failed to check container status: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 测试Redis连接
Write-Host "3. Testing Redis connectivity..." -ForegroundColor Yellow
try {
    $redisTest = docker exec freqtrade-redis redis-cli ping
    if ($redisTest -eq "PONG") {
        Write-Host "✓ Redis connection successful" -ForegroundColor Green
    } else {
        Write-Host "✗ Redis connection failed" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Redis test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 测试PostgreSQL连接
Write-Host "4. Testing PostgreSQL connectivity..." -ForegroundColor Yellow
try {
    $pgTest = docker exec freqtrade-postgres pg_isready -U freqtrade
    if ($pgTest -match "accepting connections") {
        Write-Host "✓ PostgreSQL connection successful" -ForegroundColor Green
    } else {
        Write-Host "✗ PostgreSQL connection failed" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ PostgreSQL test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 检查Freqtrade日志中的关键信息
Write-Host "5. Checking Freqtrade bot status..." -ForegroundColor Yellow
try {
    $logs = docker logs freqtrade-standalone-bot --tail 10
    Write-Host "Recent logs:" -ForegroundColor Cyan
    Write-Host $logs -ForegroundColor White
    
    # 检查关键状态
    if ($logs -match "RUNNING") {
        Write-Host "✓ Bot is running" -ForegroundColor Green
    } else {
        Write-Host "✗ Bot may not be running properly" -ForegroundColor Red
    }
    
    if ($logs -match "Dry run is enabled") {
        Write-Host "✓ Dry run mode is active" -ForegroundColor Green
    } else {
        Write-Host "✗ Dry run mode not detected" -ForegroundColor Red
    }
    
} catch {
    Write-Host "✗ Failed to check bot logs: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 显示访问信息
Write-Host "6. Access Information:" -ForegroundColor Yellow
Write-Host "Freqtrade API: http://localhost:8080" -ForegroundColor Cyan
Write-Host "API Username: fq_user1" -ForegroundColor Cyan
Write-Host "API Password: fq_uer1" -ForegroundColor Cyan
Write-Host "Redis: localhost:6380" -ForegroundColor Cyan
Write-Host "PostgreSQL: localhost:5433" -ForegroundColor Cyan
Write-Host ""

# 显示有用的命令
Write-Host "7. Useful Commands:" -ForegroundColor Yellow
Write-Host "View logs: docker logs freqtrade-standalone-bot -f" -ForegroundColor Cyan
Write-Host "Stop bot: docker-compose -f docker-compose-freqtrade-standalone.yml down" -ForegroundColor Cyan
Write-Host "Restart bot: docker-compose -f docker-compose-freqtrade-standalone.yml restart" -ForegroundColor Cyan
Write-Host ""

Write-Host "=== Test Complete ===" -ForegroundColor Green
