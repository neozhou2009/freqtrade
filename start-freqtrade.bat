@echo off
echo Starting Freqtrade Bot with Docker Compose...
echo.

REM 检查 Docker 是否运行
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Docker is not installed or not running
    pause
    exit /b 1
)

REM 检查 Docker Compose 文件是否存在
if not exist "docker-compose-freqtrade-standalone.yml" (
    echo Error: docker-compose-freqtrade-standalone.yml not found
    pause
    exit /b 1
)

REM 停止可能存在的容器
echo Stopping existing containers...
docker-compose -f docker-compose-freqtrade-standalone.yml down

REM 构建并启动服务
echo Starting Freqtrade Bot...
docker-compose -f docker-compose-freqtrade-standalone.yml up -d

REM 检查服务状态
echo.
echo Checking service status...
docker-compose -f docker-compose-freqtrade-standalone.yml ps

echo.
echo Freqtrade Bot started successfully!
echo.
echo Access points:
echo - Freqtrade API: http://localhost:8080
echo - Redis: localhost:6379
echo - PostgreSQL: localhost:5432
echo.
echo To view logs: docker-compose -f docker-compose-freqtrade-standalone.yml logs -f freqtrade-bot
echo To stop: docker-compose -f docker-compose-freqtrade-standalone.yml down
echo.
pause
