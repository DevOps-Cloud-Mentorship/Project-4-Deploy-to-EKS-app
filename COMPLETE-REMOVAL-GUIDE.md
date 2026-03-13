# COMPLETE GUIDE: Remove All RabbitMQ & Memcached Dependencies

## Summary of Changes Made

I've already modified these files for you:

### ✅ Files Already Modified:
1. **appconfig-root.xml** - Commented out RabbitMQ configuration import
2. **application.properties** - Disabled RabbitMQ, Memcached, Elasticsearch configs
3. **pom-no-deps.xml** - Created clean pom.xml without unwanted dependencies

### ⚠️ Files You Need to Handle:
1. **pom.xml** - Replace with pom-no-deps.xml
2. **RabbitMqController.java** - Rename to disable it

---

## Quick Start (3 Steps)

### Step 1: Replace pom.xml

```bash
cd Project-4-Deploy-to-EKS-app

# Backup original
cp pom.xml pom.xml.backup

# Use the cleaned version
cp pom-no-deps.xml pom.xml
```

### Step 2: Disable RabbitMQ Controller

```bash
# Rename the controller to disable it
mv src/main/java/com/visualpathit/account/controller/RabbitMqController.java \
   src/main/java/com/visualpathit/account/controller/RabbitMqController.java.disabled
```

### Step 3: Rebuild and Deploy

```bash
# Run the automated script
chmod +x rebuild-no-deps.sh
./rebuild-no-deps.sh

# Or on Windows
rebuild-no-deps.bat
```

---

## Detailed Manual Steps

### 1. Update pom.xml

**Option A: Use the cleaned version (Recommended)**
```bash
cp pom-no-deps.xml pom.xml
```

**Option B: Manual edit**

Remove these dependency blocks from `pom.xml`:

```xml
<!-- DELETE THESE BLOCKS -->

<!-- Elasticsearch -->
<dependency>
    <groupId>org.elasticsearch.client</groupId>
    <artifactId>elasticsearch-rest-high-level-client</artifactId>
    <version>7.10.2</version>
</dependency>
<dependency>
    <groupId>org.elasticsearch</groupId>
    <artifactId>elasticsearch</artifactId>
    <version>7.10.2</version>
</dependency>

<!-- RabbitMQ -->
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

<!-- Memcached -->
<dependency>
    <groupId>net.spy</groupId>
    <artifactId>spymemcached</artifactId>
    <version>2.12.3</version>
</dependency>

<!-- Elasticsearch plugin -->
<dependency>
    <groupId>org.elasticsearch.plugin</groupId>
    <artifactId>aggs-matrix-stats-client</artifactId>
    <version>7.10.2</version>
</dependency>
```

### 2. Disable RabbitMQ Controller

The RabbitMQ controller will cause compilation errors after removing dependencies.

**Rename it to disable:**
```bash
mv src/main/java/com/visualpathit/account/controller/RabbitMqController.java \
   src/main/java/com/visualpathit/account/controller/RabbitMqController.java.disabled
```

**Note:** MemcachedUtils.java can stay - it won't cause errors since it's only used if called.

### 3. Verify Configuration Files

These should already be updated:

**Check appconfig-root.xml:**
```bash
grep "appconfig-rabbitmq" src/main/webapp/WEB-INF/appconfig-root.xml
```
Should show: `<!-- <import resource="appconfig-rabbitmq.xml" /> -->`

**Check application.properties:**
```bash
grep "^rabbitmq" src/main/resources/application.properties
```
Should return nothing (all commented out)

### 4. Clean and Build

```bash
# Clean previous builds
mvn clean

# Build application
mvn package -DskipTests

# Verify WAR file
ls -lh target/lumiatech-v1.war
```

### 5. Build Docker Image

```bash
# Build image (replace with your Docker Hub username)
docker build -t <your-username>/lumia-app:v2-mysql-only -f Docker-files/app/Dockerfile .

# Login to Docker Hub
docker login

# Push image
docker push <your-username>/lumia-app:v2-mysql-only
```

### 6. Update Kubernetes Deployment

Edit `../Project-4-Deploy-to-EKS-manifest/kubedefs/appdeploy.yaml`:

```yaml
spec:
  template:
    spec:
      containers:
      - name: lumia-app
        image: <your-username>/lumia-app:v2-mysql-only  # Update this line
        imagePullPolicy: Always
```

### 7. Deploy to Kubernetes

```bash
cd ../Project-4-Deploy-to-EKS-manifest

# Delete old deployment
kubectl delete deployment lumia-app

# Deploy new version
kubectl apply -f kubedefs/appdeploy.yaml

# Watch deployment
kubectl get pods -w
```

### 8. Verify Deployment

```bash
# Check pod status (should be Running)
kubectl get pods -l app=lumia-app

# Check logs (NO RabbitMQ errors)
kubectl logs -l app=lumia-app --tail=100

# Should NOT see:
# "Failed to check/redeclare auto-delete queue(s)"

# Test application
LB_URL=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -I http://$LB_URL
```

---

## What Gets Removed

### Dependencies Removed:
- ❌ spring-rabbit (Spring AMQP)
- ❌ amqp-client (RabbitMQ client)
- ❌ spymemcached (Memcached client)
- ❌ elasticsearch-rest-high-level-client
- ❌ elasticsearch
- ❌ aggs-matrix-stats-client

### Configuration Disabled:
- ❌ RabbitMQ connection factory
- ❌ RabbitMQ listeners
- ❌ Memcached configuration
- ❌ Elasticsearch configuration

### Controllers Disabled:
- ❌ RabbitMqController (renamed to .disabled)

### What Remains:
- ✅ MySQL database connection
- ✅ Spring MVC
- ✅ Spring Security
- ✅ Hibernate/JPA
- ✅ All user management features

---

## Architecture Comparison

### Before:
```
┌─────────────────┐
│  Application    │
└────┬─┬─┬────────┘
     │ │ │
     │ │ └──────────┐
     │ └────────┐   │
     │          │   │
     ▼          ▼   ▼
┌────────┐ ┌────┐ ┌────┐
│ MySQL  │ │RMQ │ │ MC │
└────────┘ └────┘ └────┘
```

### After:
```
┌─────────────────┐
│  Application    │
└────────┬────────┘
         │
         ▼
    ┌────────┐
    │ MySQL  │
    └────────┘
```

---

## Troubleshooting

### Build Error: "package org.springframework.amqp does not exist"

**Cause:** pom.xml still has RabbitMQ dependencies or RabbitMqController.java not disabled

**Fix:**
```bash
# Ensure pom.xml is updated
cp pom-no-deps.xml pom.xml

# Disable controller
mv src/main/java/com/visualpathit/account/controller/RabbitMqController.java \
   src/main/java/com/visualpathit/account/controller/RabbitMqController.java.disabled

# Rebuild
mvn clean package -DskipTests
```

### Build Error: "package net.spy.memcached does not exist"

**Cause:** Memcached dependency still in pom.xml

**Fix:**
```bash
# Use cleaned pom.xml
cp pom-no-deps.xml pom.xml
mvn clean package -DskipTests
```

### Application Logs Still Show RabbitMQ Errors

**Cause:** Using old Docker image

**Fix:**
```bash
# Verify you're using new image
kubectl describe pod -l app=lumia-app | grep Image:

# Should show your new image tag
# If not, update appdeploy.yaml and reapply
kubectl apply -f kubedefs/appdeploy.yaml
kubectl delete pod -l app=lumia-app
```

### Pod Keeps Restarting

**Cause:** Database connection issue

**Fix:**
```bash
# Check database pod
kubectl get pods -l app=lumiadb

# Check database logs
kubectl logs -l app=lumiadb

# Check app logs for specific error
kubectl logs -l app=lumia-app --tail=100

# Verify database service
kubectl get svc lumiadb
kubectl get endpoints lumiadb
```

---

## Verification Checklist

### ✅ Build Verification
```bash
# Should complete without errors
mvn clean package -DskipTests
echo $?  # Should output: 0
```

### ✅ Docker Build Verification
```bash
# Should build successfully
docker build -t test-image -f Docker-files/app/Dockerfile .
echo $?  # Should output: 0
```

### ✅ Deployment Verification
```bash
# Pod should be Running
kubectl get pods -l app=lumia-app
# STATUS should be: Running

# No RabbitMQ errors in logs
kubectl logs -l app=lumia-app --tail=100 | grep -i "rabbit\|amqp"
# Should return nothing or very few lines

# Application should respond
curl -I http://$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
# Should return HTTP 200 or 302
```

---

## Files Reference

### Created for You:
1. **REMOVE-DEPENDENCIES-GUIDE.md** - Detailed guide
2. **QUICK-START-NO-DEPS.md** - Quick reference
3. **pom-no-deps.xml** - Cleaned pom.xml
4. **rebuild-no-deps.sh** - Automated rebuild script (Linux/Mac)
5. **rebuild-no-deps.bat** - Automated rebuild script (Windows)
6. **THIS FILE** - Complete guide

### Modified for You:
1. **appconfig-root.xml** - RabbitMQ import commented out
2. **application.properties** - RabbitMQ/Memcached configs disabled

### You Need to Modify:
1. **pom.xml** - Replace with pom-no-deps.xml
2. **RabbitMqController.java** - Rename to .disabled
3. **appdeploy.yaml** - Update image tag after rebuild

---

## Quick Commands Reference

```bash
# === BUILD ===
cd Project-4-Deploy-to-EKS-app
cp pom-no-deps.xml pom.xml
mv src/main/java/com/visualpathit/account/controller/RabbitMqController.java{,.disabled}
mvn clean package -DskipTests

# === DOCKER ===
docker build -t myuser/lumia-app:v2 -f Docker-files/app/Dockerfile .
docker push myuser/lumia-app:v2

# === KUBERNETES ===
cd ../Project-4-Deploy-to-EKS-manifest
# Edit kubedefs/appdeploy.yaml - update image
kubectl delete deployment lumia-app
kubectl apply -f kubedefs/appdeploy.yaml

# === VERIFY ===
kubectl get pods -w
kubectl logs -f -l app=lumia-app
curl -I http://$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

---

## Success Criteria

Your application is successfully running without RabbitMQ/Memcached when:

1. ✅ Maven build completes without errors
2. ✅ Docker image builds successfully
3. ✅ Pod status shows "Running"
4. ✅ Logs show NO RabbitMQ connection errors
5. ✅ Application responds to HTTP requests
6. ✅ Only MySQL database pod is required

---

## Need Help?

If you encounter issues:

1. Check build logs: `mvn clean package -DskipTests -X`
2. Check pod logs: `kubectl logs -l app=lumia-app --tail=200`
3. Check pod events: `kubectl describe pod -l app=lumia-app`
4. Verify image: `kubectl describe pod -l app=lumia-app | grep Image:`
5. Test database: `kubectl exec -it deployment/lumiadb -- mysql -uadmin -padmin123 -e "SELECT 1;"`

---

## Final Notes

- The application will work with ONLY MySQL database
- RabbitMQ and Memcached features will be disabled
- The `/user/rabbit` endpoint will return 404 (controller disabled)
- All other features (user management, authentication) will work normally
- Performance may be slightly different without caching (Memcached)
- No message queue functionality (RabbitMQ)

This is a simpler, more maintainable setup for development and testing!
