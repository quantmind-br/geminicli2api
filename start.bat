@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

REM Start Script for geminicli2api Local Development
REM Usage: start.bat [command]

REM Configuration
SET COMPOSE_FILE=docker-compose.local.yml
SET SERVICE_NAME=geminicli2api
SET PROJECT_NAME=geminicli2api-local
SET DEFAULT_PORT=8888

REM Helper functions
:log_info
    echo [INFO] %~1
    goto :eof

:log_success
    echo [SUCCESS] %~1
    goto :eof

:log_warning
    echo [WARNING] %~1
    goto :eof

:log_error
    echo [ERROR] %~1
    goto :eof

:log_header
    echo =====================================
    echo  %~1
    echo =====================================
    goto :eof

REM Check if Docker is running
:check_docker
    docker info > NUL 2>&1
    IF %ERRORLEVEL% NEQ 0 (
        CALL :log_error "Docker is not running. Please start Docker and try again."
        EXIT /B 1
    )
    goto :eof

REM Check if .env file exists
:check_env
    IF NOT EXIST .env (
        CALL :log_warning ".env file not found. Creating from .env.example..."
        IF EXIST .env.example (
            copy .env.example .env > NUL
            CALL :log_info "Please edit .env file with your configuration:"
            CALL :log_info "  - GEMINI_AUTH_PASSWORD: Your API password"
            CALL :log_info "  - GOOGLE_APPLICATION_CREDENTIALS: Path to your Google credentials"
            echo.
            SET /P DUMMY="Press Enter to continue after editing .env file..."
        ) ELSE (
            CALL :log_error ".env.example file not found. Please create .env file manually."
            EXIT /B 1
        )
    )
    goto :eof

REM Check if the image exists
:check_image
    docker image inspect drnit29/geminicli2api:latest > NUL 2>&1
    IF %ERRORLEVEL% NEQ 0 (
        CALL :log_warning "Image drnit29/geminicli2api:latest not found locally."
        SET /P REPLY="Do you want to pull it from Docker Hub? (y/N): "
        echo.
        IF /I "%REPLY%"=="y" (
            CALL :log_info "Pulling image from Docker Hub..."
            docker pull drnit29/geminicli2api:latest
        ) ELSE (
            CALL :log_info "You can build the image locally with: build-and-push.bat"
            EXIT /B 1
        )
    )
    goto :eof

REM Start services
:start_services
    CALL :log_header "Starting geminicli2api Local Development"
    
    CALL :check_docker
    CALL :check_env
    CALL :check_image
    
    CALL :log_info "Starting services..."
    docker-compose -f %COMPOSE_FILE% -p %PROJECT_NAME% up -d
    IF %ERRORLEVEL% NEQ 0 (
        CALL :log_error "docker-compose up failed."
        EXIT /B 1
    )
    
    REM Wait for service to be healthy
    CALL :log_info "Waiting for service to be healthy..."
    SET /A timeout=60
    SET /A counter=0
    
    :wait_loop
    IF %counter% GE %timeout% GOTO :wait_loop_end
    
    docker-compose -f %COMPOSE_FILE% -p %PROJECT_NAME% ps | findstr /I "healthy" > NUL
    IF %ERRORLEVEL% EQU 0 (
        CALL :log_success "Service is healthy!"
        GOTO :wait_loop_end
    )
    
    docker-compose -f %COMPOSE_FILE% -p %PROJECT_NAME% ps | findstr /I "unhealthy" > NUL
    IF %ERRORLEVEL% EQU 0 (
        CALL :log_error "Service is unhealthy. Check logs with: start.bat logs"
        EXIT /B 1
    )
    
    <NUL SET /P =.
    timeout /t 2 /nobreak > NUL
    SET /A counter=!counter! + 2
    GOTO :wait_loop
    
    :wait_loop_end
    IF %counter% GE %timeout% (
        CALL :log_warning "Service health check timeout. Service may still be starting..."
    )
    
    REM Get the actual port
    FOR /F "tokens=2 delims=:" %%i IN ('docker-compose -f %COMPOSE_FILE% -p %PROJECT_NAME% port %SERVICE_NAME% 8888 2^>NUL') DO SET PORT=%%i
    IF "%PORT%"=="" (
        SET PORT=%DEFAULT_PORT%
    )
    
    echo.
    CALL :log_success "geminicli2api is running!"
    echo.
    echo Service Information:
    echo   ^> API URL: http://localhost:%PORT%
    echo   ^> Health Check: http://localhost:%PORT%/health
    echo   ^> OpenAI API: http://localhost:%PORT%/v1/chat/completions
    echo   ^> Gemini API: http://localhost:%PORT%/v1beta/models
    echo.
    echo Useful Commands:
    echo   start.bat logs     - View logs
    echo   start.bat status   - Check status
    echo   start.bat stop     - Stop services
    echo   start.bat restart  - Restart services
    echo   start.bat test     - Test API
    echo.
    goto :eof

REM Stop services
:stop_services
    CALL :log_header "Stopping geminicli2api Local Development"
    
    CALL :check_docker
    
    CALL :log_info "Stopping services..."
    docker-compose -f %COMPOSE_FILE% -p %PROJECT_NAME% down
    IF %ERRORLEVEL% NEQ 0 (
        CALL :log_error "docker-compose down failed."
        EXIT /B 1
    )
    
    CALL :log_success "Services stopped successfully!"
    goto :eof

REM Restart services
:restart_services
    CALL :log_header "Restarting geminicli2api Local Development"
    
    CALL :stop_services
    timeout /t 2 /nobreak > NUL
    CALL :start_services
    goto :eof

REM Show logs
:show_logs
    CALL :check_docker
    
    CALL :log_info "Showing logs (press Ctrl+C to exit)..."
    docker-compose -f %COMPOSE_FILE% -p %PROJECT_NAME% logs -f
    goto :eof

REM Show status
:show_status
    CALL :check_docker
    
    CALL :log_header "Service Status"
    
    docker-compose -f %COMPOSE_FILE% -p %PROJECT_NAME% ps
    
    echo.
    CALL :log_info "Container details:"
    docker-compose -f %COMPOSE_FILE% -p %PROJECT_NAME% exec %SERVICE_NAME% curl -s http://localhost:8888/health 2>NUL || echo Health check failed
    goto :eof

REM Test API
:test_api
    CALL :check_docker
    
    CALL :log_header "Testing API"
    
    REM Get the actual port
    FOR /F "tokens=2 delims=:" %%i IN ('docker-compose -f %COMPOSE_FILE% -p %PROJECT_NAME% port %SERVICE_NAME% 8888 2^>NUL') DO SET PORT=%%i
    IF "%PORT%"=="" (
        SET PORT=%DEFAULT_PORT%
    )
    
    REM Test health endpoint
    CALL :log_info "Testing health endpoint..."
    curl -s -f "http://localhost:%PORT%/health" > NUL
    IF %ERRORLEVEL% EQU 0 (
        CALL :log_success "Health check passed!"
    ) ELSE (
        CALL :log_error "Health check failed!"
        EXIT /B 1
    )
    
    REM Test API with dummy request (requires auth)
    CALL :log_info "Testing API endpoint..."
    echo Note: This will fail without proper authentication configured in .env
    
    REM Read password from .env if exists
    IF EXIST .env (
        FOR /F "tokens=* USEBACKQ" %%i IN (`findstr /B "GEMINI_AUTH_PASSWORD" .env`) DO (
            SET "LINE=%%i"
            SET "PASSWORD=!LINE:GEMINI_AUTH_PASSWORD==!"
        )
        IF NOT "%PASSWORD%"=="" (
            CALL :log_info "Testing with configured password..."
            SET "RESPONSE="
            FOR /F "tokens=* USEBACKQ" %%i IN (`curl -s -w "HTTP_STATUS:%%{http_code}" ^
                -X POST "http://localhost:%PORT%/v1/models" ^
                -H "Authorization: Bearer !PASSWORD!" ^
                -H "Content-Type: application/json"`
            ) DO (
                SET "RESPONSE=%%i"
            )
            
            ECHO !RESPONSE! | findstr /R "HTTP_STATUS:[0-9]*" > NUL
            IF %ERRORLEVEL% EQU 0 (
                FOR /F "tokens=2 delims=:" %%j IN ('ECHO !RESPONSE! | findstr /R "HTTP_STATUS:[0-9]*"') DO SET HTTP_STATUS=%%j
                IF "%HTTP_STATUS%"=="200" (
                    CALL :log_success "API test passed!"
                ) ELSE (
                    CALL :log_warning "API test returned status: %HTTP_STATUS%"
                )
            ) ELSE (
                CALL :log_error "Failed to get HTTP status from response."
            )
        )
    )
    goto :eof

REM Pull latest image
:pull_image
    CALL :check_docker
    
    CALL :log_header "Pulling Latest Image"
    
    CALL :log_info "Pulling drnit29/geminicli2api:latest..."
    docker pull drnit29/geminicli2api:latest
    IF %ERRORLEVEL% NEQ 0 (
        CALL :log_error "Docker pull failed."
        EXIT /B 1
    )
    
    CALL :log_success "Image pulled successfully!"
    CALL :log_info "Restart services to use the new image: start.bat restart"
    goto :eof

REM Show help
:show_help
    echo geminicli2api Local Development Script
    echo.
    echo Usage: start.bat [command]
    echo.
    echo Commands:
    echo   start     - Start services (default)
    echo   stop      - Stop services
    echo   restart   - Restart services
    echo   logs      - Show logs
    echo   status    - Show service status
    echo   test      - Test API endpoints
    echo   pull      - Pull latest image
    echo   help      - Show this help
    echo.
    echo Examples:
    echo   start.bat           REM Start services
    echo   start.bat logs      REM View logs
    echo   start.bat test      REM Test API
    echo.
    goto :eof

REM Main logic
IF "%~1"=="" (
    SET COMMAND=start
) ELSE (
    SET COMMAND=%~1
)

IF /I "%COMMAND%"=="start" (
    CALL :start_services
) ELSE IF /I "%COMMAND%"=="stop" (
    CALL :stop_services
) ELSE IF /I "%COMMAND%"=="restart" (
    CALL :restart_services
) ELSE IF /I "%COMMAND%"=="logs" (
    CALL :show_logs
) ELSE IF /I "%COMMAND%"=="status" (
    CALL :show_status
) ELSE IF /I "%COMMAND%"=="test" (
    CALL :test_api
) ELSE IF /I "%COMMAND%"=="pull" (
    CALL :pull_image
) ELSE IF /I "%COMMAND%"=="help" (
    CALL :show_help
) ELSE IF /I "%COMMAND%"=="--help" (
    CALL :show_help
) ELSE IF /I "%COMMAND%"=="-h" (
    CALL :show_help
) ELSE (
    CALL :log_error "Unknown command: %COMMAND%"
    CALL :show_help
    EXIT /B 1
)

ENDLOCAL
