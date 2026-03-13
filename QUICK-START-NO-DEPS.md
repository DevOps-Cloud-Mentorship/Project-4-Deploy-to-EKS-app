# Quick Start: Remove RabbitMQ & Memcached Dependencies

## What I've Done For You

I've already modified these files to disable RabbitMQ and Memcached:

✅ **appconfig-root.xml** - Commented out RabbitMQ import
✅ **application.properties** - Disabled RabbitMQ, Memcached, Elasticsearch configs
✅ **application.properties** - Updated to use environment variables for database

## What You Need To Do

### Option 1: Quick Rebuild (Recommended)

```bash
# Navigate to app directory
cd Project-4-Deploy-to-EKS-app

# Run rebuild script (Linux/Mac)
chmod +x rebuild-no-deps.sh
./rebuild-no-deps.sh

# Or on Windows
rebuild-no-deps.bat
```

The script will:
1. Clean and rebuild the application
2. Build Docker image
3. Optionally push to Docker Hub
4. Show you next steps

---

### Option 2: Manual Steps

#### Step 1: Remove Dependencies from pom.xml

Edit `pom.xml` and remove these dependencies:

```xml
<!-- Remove these lines -->
<dependency>
    <groupId>org.springframework.amqp</groupId>
    <artifactId>spring-rabbit</artifactId>
    <version>3.1.6</version>
</dependency>
<dependency>
    <groupId>com.rabbitmq</groupId>
    <artifactId>amqp-client</artifactId>
    <version>5.21.0</version>
</dependency>
<dependency>
    <groupId>net.spy</groupId>
    <artifactId>spymemcached</artifactId>
    <version>2.12.3</version>
</dependency>
```

#### Step 2: Rebuild Application

```bash
cd Project-4-Deploy-to-EKS-app

# Clean and build
mvn clean package -DskipTests

# Verify WAR file
ls -lh target/lumiatech-v1.war
```

#### Step 3: Rebuild Docker Image

```bash
# Build image
docker build -t <your-dockerhub-username>/lumia-app:v2 -f Docker-files/app/Dockerfile .

# Login to Docker Hub
docker login

# Push image
docker push <your-dockerhub-username>/lumia-app:v2
```

#### Step 4: Update Kubernetes Deployment

Edit `../Project-4-Deploy-to-EKS-manifest/kubedefs/appdeploy.yaml`:

Change the image line:
```yaml
image: <your-dockerhub-username>/lumia-app:v2
```

#### Step 5: Deploy to Kubernetes

```bash
cd ../Project-4-Deploy-to-EKS-manifest

# Delete old deployment
kubectl delete deployment lumia-app

# Deploy new version
kubectl apply -f kubedefs/appdeploy.yaml

# Watch pods
kubectl get pods -w
```

#### Step 6: Verify No Errors

```bash
# Check logs - should have NO RabbitMQ errors
kubectl logs -f -l app=lumia-app

# Should see successful startup without RabbitMQ connection attempts
```

---

## Files Already Modified

1. ✅ `src/main/webapp/WEB-INF/appconfig-root.xml`
   - Commented out: `<import resource="appconfig-rabbitmq.xml" />`

2. ✅ `src/main/resources/application.properties`
   - Disabled RabbitMQ configuration
   - Disabled Memcached configuration
   - Disabled Elasticsearch configuration
   - Updated JDBC URL to use environment variables

---

## What Still Needs Manual Edit

### pom.xml - Remove Dependencies

You need to manually remove these dependency blocks from `pom.xml`:

**Lines to remove:**
- Spring AMQP (spring-rabbit)
- RabbitMQ client (amqp-client)
- Memcached client (spymemcached)
- Elasticsearch dependencies (3 blocks)

**Why manual?** These are in the middle of the file and removing them incorrectly could break the XML structure.

---

## Verification Checklist

After rebuilding and redeploying:

### ✅ Build Verification
```bash
# Should complete without errors
mvn clean package -DskipTests
```

### ✅ Docker Image Verification
```bash
# Should build successfully
docker build -t test-image -f Docker-files/app/Dockerfile .
```

### ✅ Kubernetes Deployment Verification
```bash
# Pod should be Running
kubectl get pods -l app=lumia-app

# Logs should NOT show RabbitMQ errors
kubectl logs -l app=lumia-app --tail=100 | grep -i rabbit
# Should return nothing

# Application should start successfully
kubectl logs -l app=lumia-app --tail=50
```

### ✅ Application Access Verification
```bash
# Get Load Balancer URL
LB_URL=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test application
curl -I http://$LB_URL

# Should return HTTP 200 or 302
```

---

## Architecture After Changes

### Before (3 Services):
```
Application → MySQL
           → RabbitMQ
           → Memcached
```

### After (1 Service):
```
Application → MySQL
```

---

## Troubleshooting

### Issue: Build fails with "package does not exist"

**Solution:** You forgot to remove dependencies from pom.xml

```bash
# Edit pom.xml and remove RabbitMQ/Memcached dependencies
# Then rebuild
mvn clean package -DskipTests
```

### Issue: Application still tries to connect to RabbitMQ

**Solution:** Check that appconfig-root.xml has RabbitMQ import commented out

```bash
# Verify the change
grep "appconfig-rabbitmq" src/main/webapp/WEB-INF/appconfig-root.xml

# Should show:
# <!-- <import resource="appconfig-rabbitmq.xml" /> -->
```

### Issue: Pod keeps restarting

**Solution:** Check application logs for errors

```bash
kubectl logs -l app=lumia-app --tail=100

# Look for:
# - Database connection errors
# - Missing environment variables
# - Configuration errors
```

---

## Quick Commands Reference

```bash
# Rebuild application
cd Project-4-Deploy-to-EKS-app
mvn clean package -DskipTests

# Build Docker image
docker build -t myuser/lumia-app:v2 -f Docker-files/app/Dockerfile .

# Push to Docker Hub
docker push myuser/lumia-app:v2

# Update Kubernetes
cd ../Project-4-Deploy-to-EKS-manifest
kubectl apply -f kubedefs/appdeploy.yaml

# Check status
kubectl get pods
kubectl logs -f -l app=lumia-app

# Test application
curl -I http://$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

---

## Need Help?

Check these files for detailed instructions:
- **REMOVE-DEPENDENCIES-GUIDE.md** - Complete step-by-step guide
- **rebuild-no-deps.sh** - Automated rebuild script (Linux/Mac)
- **rebuild-no-deps.bat** - Automated rebuild script (Windows)
