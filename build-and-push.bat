@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

REM Build and Push Script for geminicli2api
REM Usage: build-and-push.bat [tag]

REM Configuration
SET DOCKER_USERNAME="drnit29"
SET DOCKER_REPOSITORY="geminicli2api"
SET DEFAULT_TAG="latest"
SET PLATFORMS="linux/amd64,linux/arm64"

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

REM Parse arguments
IF "%~1"=="" (
    SET TAG=%DEFAULT_TAG%
) ELSE (
    SET TAG=%~1
)
SET FULL_IMAGE_NAME=%DOCKER_USERNAME%/%DOCKER_REPOSITORY%:%TAG%

CALL :log_info "Starting build and push process for %FULL_IMAGE_NAME%"

REM Check if Docker is running
docker info > NUL 2>&1
IF %ERRORLEVEL% NEQ 0 (
    CALL :log_error "Docker is not running. Please start Docker and try again."
    EXIT /B 1
)

REM Check if logged in to Docker Hub
docker info | findstr /I "Username" > NUL
IF %ERRORLEVEL% NEQ 0 (
    CALL :log_warning "You may not be logged in to Docker Hub."
    CALL :log_info "Please run: docker login"
    SET /P REPLY="Continue anyway? (y/N): "
    IF /I NOT "%REPLY%"=="y" (
        EXIT /B 1
    )
)

REM Create buildx builder if not exists
docker buildx ls | findstr /I "multi-platform" > NUL
IF %ERRORLEVEL% NEQ 0 (
    CALL :log_info "Creating multi-platform builder..."
    docker buildx create --name multi-platform --use --platform %PLATFORMS%
    IF %ERRORLEVEL% NEQ 0 (
        CALL :log_error "Failed to create multi-platform builder."
        EXIT /B 1
    )
)

REM Build multi-platform image
CALL :log_info "Building multi-platform Docker image..."
docker buildx build ^
    --platform %PLATFORMS% ^
    --tag %FULL_IMAGE_NAME% ^
    --push ^
    --progress=plain ^
    .
IF %ERRORLEVEL% NEQ 0 (
    CALL :log_error "Docker buildx build failed."
    EXIT /B 1
)

REM Verify the push
CALL :log_info "Verifying the pushed image..."
docker manifest inspect %FULL_IMAGE_NAME% > NUL 2>&1
IF %ERRORLEVEL% NEQ 0 (
    CALL :log_error "Failed to verify the pushed image."
    EXIT /B 1
) ELSE (
    CALL :log_success "Image successfully pushed to Docker Hub!"
    CALL :log_info "Image: %FULL_IMAGE_NAME%"
    CALL :log_info "Platforms: %PLATFORMS%"
)

REM Also tag and push as 'latest' if not already latest
IF /I NOT "%TAG%"=="latest" (
    CALL :log_info "Also tagging as 'latest'..."
    SET LATEST_IMAGE_NAME=%DOCKER_USERNAME%/%DOCKER_REPOSITORY%:latest
    
    docker buildx build ^
        --platform %PLATFORMS% ^
        --tag %LATEST_IMAGE_NAME% ^
        --push ^
        --progress=plain ^
        .
    IF %ERRORLEVEL% NEQ 0 (
        CALL :log_error "Docker buildx build for latest tag failed."
        EXIT /B 1
    )
    CALL :log_success "Also pushed as: %LATEST_IMAGE_NAME%"
)

REM Show usage instructions
echo.
CALL :log_success "Build and push completed successfully!"
echo.
CALL :log_info "Usage instructions:"
echo   Pull the image: docker pull %FULL_IMAGE_NAME%
echo   Run locally: docker run -p 8888:8888 -e GEMINI_AUTH_PASSWORD=yourpassword %FULL_IMAGE_NAME%
echo   Use in docker-compose:
echo     services:
echo       geminicli2api:
echo         image: %FULL_IMAGE_NAME%
echo         ports:
echo           - "8888:8888"
echo         environment:
echo           - GEMINI_AUTH_PASSWORD=yourpassword
echo.
CALL :log_info "Docker Hub: https://hub.docker.com/r/%DOCKER_USERNAME%/%DOCKER_REPOSITORY%"
