# Remove RabbitMQ and Memcached Dependencies

## Overview

This guide will help you remove RabbitMQ and Memcached dependencies from the application so it only requires MySQL database.

## Changes Required

### 1. Remove Dependencies from pom.xml
### 2. Remove Spring Configuration
### 3. Disable/Remove Controllers and Utils
### 4. Update application.properties
### 5. Rebuild Docker Image
### 6. Redeploy to Kubernetes

---

## Step 1: Update pom.xml

Remove these dependencies from `pom.xml`:

```xml
<!-- REMOVE THESE -->
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
<dependency>
    <groupId>org.elasticsearch.plugin</groupId>
    <artifactId>aggs-matrix-stats-client</artifactId>
    <version>7.10.2</version>
</dependency>
```

---

## Step 2: Update appconfig-root.xml

Remove the RabbitMQ import:

**File:** `src/main/webapp/WEB-INF/appconfig-root.xml`

**Change from:**
```xml
<import resource="appconfig-mvc.xml" />
<import resource="appconfig-data.xml" />
<import resource="appconfig-rabbitmq.xml" />
<import resource="appconfig-security.xml" />
```

**Change to:**
```xml
<import resource="appconfig-mvc.xml" />
<import resource="appconfig-data.xml" />
<!-- <import resource="appconfig-rabbitmq.xml" /> -->
<import resource="appconfig-security.xml" />
```

---

## Step 3: Update application.properties

Comment out or remove RabbitMQ, Memcached, and Elasticsearch configurations:

**File:** `src/main/resources/application.properties`

```properties
#JDBC Configuration for Database Connection
jdbc.driverClassName=com.mysql.cj.jdbc.Driver
jdbc.url=jdbc:mysql://${DB_HOST:lumiadb}:${DB_PORT:3306}/${DB_NAME:accounts}?useUnicode=true&characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull
jdbc.username=${DB_USER:admin}
jdbc.password=${DB_PASS:admin123}

# Memcached Configuration - DISABLED
#memcached.active.host=mc01
#memcached.active.port=11211
#memcached.standBy.host=127.0.0.2 
#memcached.standBy.port=11211

# RabbitMQ Configuration - DISABLED
#rabbitmq.address=rmq01
#rabbitmq.port=5672
#rabbitmq.username=test
#rabbitmq.password=test

# Elasticsearch Configuration - DISABLED
#elasticsearch.host=localhost
#elasticsearch.port=9300
#elasticsearch.cluster=vprofile
#elasticsearch.node=vprofilenode

spring.servlet.multipart.max-file-size=128KB
spring.servlet.multipart.max-request-size=128KB

logging.level.org.springframework.security=DEBUG

spring.security.user.name=admin_vp
spring.security.user.password=admin_vp
spring.security.user.roles=ADMIN

spring.mvc.view.prefix=/WEB-INF/views/
spring.mvc.view.suffix=.jsp

# Hibernate SQL Queries
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.format_sql=false
logging.level.org.hibernate.SQL=OFF
logging.level.org.hibernate.type=OFF

# Debug Logging for SecurityServiceImpl
logging.level.com.visualpathit.account.service.SecurityServiceImpl=OFF
```

---

## Step 4: Rename/Disable RabbitMQ Controller

**Option A: Rename the file (Recommended)**
```bash
cd src/main/java/com/visualpathit/account/controller/
mv RabbitMqController.java RabbitMqController.java.disabled
```

**Option B: Add @Profile annotation**

Edit `RabbitMqController.java` and add at the top of the class:
```java
@Profile("rabbitmq")  // Only load if 'rabbitmq' profile is active
@Controller
public class RabbitMqController {
    // ... existing code
}
```

---

## Step 5: Rebuild Application

```bash
# Navigate to project directory
cd Project-4-Deploy-to-EKS-app

# Clean and build
mvn clean package -DskipTests

# Verify WAR file is created
ls -lh target/lumiatech-v1.war
```

---

## Step 6: Rebuild Docker Image

```bash
# Build new application image
docker build -t ndzenyuy/lumia-app:v2-no-rabbit -f Docker-files/app/Dockerfile .

# Or use your Docker Hub username
docker build -t <your-dockerhub-username>/lumia-app:v2 -f Docker-files/app/Dockerfile .

# Push to Docker Hub
docker push ndzenyuy/lumia-app:v2-no-rabbit

# Or
docker push <your-dockerhub-username>/lumia-app:v2
```

---

## Step 7: Update Kubernetes Deployment

Update `kubedefs/appdeploy.yaml` to use the new image:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lumia-app
  labels: 
    app: lumia-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: lumia-app
  template:
    metadata:
      labels:
        app: lumia-app
    spec:
      containers:
      - name: lumia-app
        image: ndzenyuy/lumia-app:v2-no-rabbit  # Updated image
        imagePullPolicy: Always
        ports:
        - name: lumia-app-port
          containerPort: 8080
        env:
        - name: DB_HOST
          value: "lumiadb"
        - name: DB_PORT
          value: "3306"
        - name: DB_NAME
          value: "accounts"
        - name: DB_USER
          value: "admin"
        - name: DB_PASS
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: db-pass
      initContainers:
      - name: init-mydb
        image: busybox
        command: ['sh', '-c']
        args: ['until nslookup lumiadb.$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace).svc.cluster.local; do echo waiting for mydb; sleep 2; done;']
```

---

## Step 8: Deploy to Kubernetes

```bash
# Delete old deployment
kubectl delete deployment lumia-app

# Apply new deployment
kubectl apply -f kubedefs/appdeploy.yaml

# Watch pod status
kubectl get pods -w

# Check logs (should have no RabbitMQ errors)
kubectl logs -f -l app=lumia-app
```

---

## Verification

### Check Application Logs

```bash
# Should NOT see RabbitMQ errors anymore
kubectl logs -l app=lumia-app --tail=100 | grep -i rabbit

# Should see successful startup
kubectl logs -l app=lumia-app --tail=50
```

### Test Application

```bash
# Get Load Balancer URL
LB_URL=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test application
curl -I http://$LB_URL

# Or access in browser
echo "Access: http://$LB_URL"
```

---

## Quick Script to Apply All Changes

I'll create automated scripts for you in the next files.

---

## What Gets Removed

✅ **RabbitMQ** - Message queue (not needed)
✅ **Memcached** - Caching layer (not needed)
✅ **Elasticsearch** - Search engine (not needed)

## What Remains

✅ **MySQL** - Database (required)
✅ **Spring MVC** - Web framework
✅ **Spring Security** - Authentication
✅ **Hibernate** - ORM

---

## Troubleshooting

### Issue: Build Fails

```bash
# Clean Maven cache
mvn clean

# Rebuild
mvn package -DskipTests -X
```

### Issue: Docker Build Fails

```bash
# Check Dockerfile
cat Docker-files/app/Dockerfile

# Build with verbose output
docker build --no-cache -t lumia-app:v2 -f Docker-files/app/Dockerfile .
```

### Issue: Pod Still Shows Errors

```bash
# Ensure using new image
kubectl describe pod -l app=lumia-app | grep Image

# Force pull new image
kubectl delete pod -l app=lumia-app
```

---

## Files to Modify

1. ✅ `pom.xml` - Remove dependencies
2. ✅ `appconfig-root.xml` - Comment out RabbitMQ import
3. ✅ `application.properties` - Comment out RabbitMQ/Memcached config
4. ✅ `RabbitMqController.java` - Disable or rename
5. ✅ `appdeploy.yaml` - Update image tag
6. ✅ Rebuild Docker image
7. ✅ Redeploy to Kubernetes
