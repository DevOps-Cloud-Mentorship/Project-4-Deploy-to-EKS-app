@echo off
echo === Rebuild Application Without RabbitMQ/Memcached ===
echo.

REM Check if pom.xml exists
if not exist "pom.xml" (
    echo Error: pom.xml not found. Please run this script from Project-4-Deploy-to-EKS-app directory
    exit /b 1
)

echo 1. Cleaning previous builds...
call mvn clean
echo.

echo 2. Building application (this may take a few minutes)...
call mvn package -DskipTests

if %ERRORLEVEL% neq 0 (
    echo Build failed! Check the errors above.
    exit /b 1
)

echo.
echo Build successful!
echo.

REM Check if WAR file exists
if exist "target\lumiatech-v1.war" (
    echo WAR file created: target\lumiatech-v1.war
    dir target\lumiatech-v1.war
) else (
    echo WAR file not found!
    exit /b 1
)

echo.
echo 3. Building Docker image...
echo.

set /p DOCKER_USER="Enter your Docker Hub username (default: ndzenyuy): "
if "%DOCKER_USER%"=="" set DOCKER_USER=ndzenyuy

set IMAGE_TAG=%DOCKER_USER%/lumia-app:v2-no-deps

echo Building image: %IMAGE_TAG%
docker build -t %IMAGE_TAG% -f Docker-files/app/Dockerfile .

if %ERRORLEVEL% neq 0 (
    echo Docker build failed!
    exit /b 1
)

echo.
echo Docker image built successfully!
echo.

set /p PUSH_IMAGE="Do you want to push the image to Docker Hub? (y/n): "

if /i "%PUSH_IMAGE%"=="y" (
    echo.
    echo 4. Logging in to Docker Hub...
    docker login
    
    if %ERRORLEVEL% neq 0 (
        echo Docker login failed!
        exit /b 1
    )
    
    echo.
    echo 5. Pushing image to Docker Hub...
    docker push %IMAGE_TAG%
    
    if %ERRORLEVEL% neq 0 (
        echo Docker push failed!
        exit /b 1
    )
    
    echo.
    echo Image pushed successfully!
)

echo.
echo ==========================================
echo === Build Complete ===
echo ==========================================
echo.
echo Docker Image: %IMAGE_TAG%
echo.
echo Next Steps:
echo 1. Update kubedefs/appdeploy.yaml with the new image:
echo    image: %IMAGE_TAG%
echo.
echo 2. Deploy to Kubernetes:
echo    kubectl apply -f kubedefs/appdeploy.yaml
echo.
echo 3. Check pod status:
echo    kubectl get pods -w
echo.
echo 4. Check logs (should have NO RabbitMQ errors):
echo    kubectl logs -f -l app=lumia-app
echo.

pause
