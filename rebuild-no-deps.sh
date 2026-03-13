#!/bin/bash

echo "=== Rebuild Application Without RabbitMQ/Memcached ==="
echo ""

# Check if we're in the right directory
if [ ! -f "pom.xml" ]; then
    echo "❌ Error: pom.xml not found. Please run this script from Project-4-Deploy-to-EKS-app directory"
    exit 1
fi

echo "1. Cleaning previous builds..."
mvn clean
echo ""

echo "2. Building application (this may take a few minutes)..."
mvn package -DskipTests

if [ $? -ne 0 ]; then
    echo "❌ Build failed! Check the errors above."
    exit 1
fi

echo ""
echo "✅ Build successful!"
echo ""

# Check if WAR file exists
if [ -f "target/lumiatech-v1.war" ]; then
    echo "✅ WAR file created: target/lumiatech-v1.war"
    ls -lh target/lumiatech-v1.war
else
    echo "❌ WAR file not found!"
    exit 1
fi

echo ""
echo "3. Building Docker image..."
echo ""

# Prompt for Docker Hub username
read -p "Enter your Docker Hub username (default: ndzenyuy): " DOCKER_USER
DOCKER_USER=${DOCKER_USER:-ndzenyuy}

IMAGE_TAG="$DOCKER_USER/lumia-app:v2-no-deps"

echo "Building image: $IMAGE_TAG"
docker build -t $IMAGE_TAG -f Docker-files/app/Dockerfile .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed!"
    exit 1
fi

echo ""
echo "✅ Docker image built successfully!"
echo ""

# Ask if user wants to push
read -p "Do you want to push the image to Docker Hub? (y/n): " PUSH_IMAGE

if [ "$PUSH_IMAGE" = "y" ] || [ "$PUSH_IMAGE" = "Y" ]; then
    echo ""
    echo "4. Logging in to Docker Hub..."
    docker login
    
    if [ $? -ne 0 ]; then
        echo "❌ Docker login failed!"
        exit 1
    fi
    
    echo ""
    echo "5. Pushing image to Docker Hub..."
    docker push $IMAGE_TAG
    
    if [ $? -ne 0 ]; then
        echo "❌ Docker push failed!"
        exit 1
    fi
    
    echo ""
    echo "✅ Image pushed successfully!"
fi

echo ""
echo "=========================================="
echo "=== Build Complete ==="
echo "=========================================="
echo ""
echo "Docker Image: $IMAGE_TAG"
echo ""
echo "Next Steps:"
echo "1. Update kubedefs/appdeploy.yaml with the new image:"
echo "   image: $IMAGE_TAG"
echo ""
echo "2. Deploy to Kubernetes:"
echo "   kubectl apply -f kubedefs/appdeploy.yaml"
echo ""
echo "3. Check pod status:"
echo "   kubectl get pods -w"
echo ""
echo "4. Check logs (should have NO RabbitMQ errors):"
echo "   kubectl logs -f -l app=lumia-app"
echo ""
