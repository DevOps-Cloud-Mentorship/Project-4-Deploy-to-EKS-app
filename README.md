# Project 4 — Lumiatech App Repository

This repository contains the **Java Spring MVC application source code, Docker images, and GitHub Actions CI pipeline**. On every push to `main`, the pipeline builds the app, pushes Docker images to Docker Hub, and updates the image tags in the manifest repository so the EKS cluster picks up the new version automatically.

Kubernetes manifests and cluster setup are maintained separately in **[Project-4-Deploy-to-EKS-manifest](https://github.com/Ndzenyuy/Project-4-Deploy-to-EKS-manifest)**.

![Architecture](images/project-4-deploy-to-eks.png)

---

## Pipeline Overview

```
[Push to main]
      │
      ▼
[GitHub Actions]
  ├── Build WAR (Maven)
  ├── Build & Push Docker images → Docker Hub
  │     ├── ndzenyuy/lumia-app:<git-sha>
  │     └── ndzenyuy/lumia-db:<git-sha>
  └── Clone manifest repo → update image tags → push
```

---

## Application Stack

| Service    | Technology         | Purpose               |
|------------|--------------------|-----------------------|
| App        | Tomcat 10 / JDK 21 | Spring MVC WAR        |
| Database   | MySQL 8.0.33       | Accounts data         |
| Cache      | Memcached          | Session/query caching |
| Messaging  | RabbitMQ           | Async message queue   |
| Search     | Elasticsearch 7.10 | Full-text search      |
| Web/Proxy  | Nginx              | Reverse proxy (local) |

---

## Prerequisites

| Tool       | Version | Install Reference                                      |
|------------|---------|--------------------------------------------------------|
| Java (JDK) | 17      | [Adoptium](https://adoptium.net)                       |
| Maven      | 3.8+    | [maven.apache.org](https://maven.apache.org)           |
| Docker     | 24+     | [docs.docker.com](https://docs.docker.com/get-docker/) |
| Git        | any     |                                                        |

---

## Repository Structure

```
.
├── .github/workflows/
│   └── build-and-update.yml   # CI/CD pipeline
├── Docker-files/
│   ├── app/Dockerfile          # Tomcat app image
│   ├── db/Dockerfile           # MySQL image with seed data
│   ├── web/Dockerfile          # Nginx reverse proxy (local)
│   └── docker-compose.yml      # Local development stack
└── src/                        # Java Spring MVC source
```

---

## Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Ndzenyuy/Project-4-Deploy-to-EKS-app.git
cd Project-4-Deploy-to-EKS-app
```

---

### 2. Configure Application Properties

Edit `src/main/resources/application.properties` with your environment's connection details:

```properties
# Database
jdbc.url=jdbc:mysql://<db-host>:3306/accounts
jdbc.username=<db-username>
jdbc.password=<db-password>

```

> When deploying to EKS, these hostnames must match the Kubernetes service names defined in the manifest repo.

---

### 3. Build the Application

```bash
mvn clean package -DskipTests
```

Output: `target/lumiatech-v1.war`

---

### 4. Build and Push Docker Images Manually (Optional)

Use this to push images without triggering the CI pipeline:

```bash
docker login
mvn clean package -DskipTests
docker build -t ndzenyuy/lumia-app:latest -f Docker-files/app/Dockerfile .
docker build -t ndzenyuy/lumia-db:latest -f Docker-files/db/Dockerfile Docker-files/db/
docker push ndzenyuy/lumia-app:latest
docker push ndzenyuy/lumia-db:latest
```

---

### 5. Configure GitHub Actions Secrets

Go to **Settings → Secrets and variables → Actions** in this repository and add:

| Secret Name             | Description                                            |
|-------------------------|--------------------------------------------------------|
| `DOCKERHUB_USERNAME`    | Your Docker Hub username                               |
| `DOCKERHUB_TOKEN`       | Docker Hub access token (not your password)            |
| `MANIFEST_REPO_SSH_KEY` | Private SSH key with write access to the manifest repo |

Generate the SSH key pair for the manifest repo:

```bash
ssh-keygen -t ed25519 -C "github-actions" -f manifest_deploy_key -N ""
```

- Add `manifest_deploy_key.pub` as a **Deploy Key** in the manifest repository (with write access)
- Add `manifest_deploy_key` (private key) as the `MANIFEST_REPO_SSH_KEY` secret here

---

### 6. CI/CD Pipeline

On every push to `main`, `.github/workflows/build-and-update.yml` runs two jobs:

**Job 1 — `build-and-push`**
1. Checks out this repo
2. Sets up JDK 17 and builds the WAR with Maven
3. Logs in to Docker Hub
4. Builds and pushes `ndzenyuy/lumia-app:<git-sha>` and `:latest`
5. Builds and pushes `ndzenyuy/lumia-db:<git-sha>` and `:latest`

**Job 2 — `update-manifests`** (runs after Job 1)
1. Clones the manifest repo via SSH
2. Updates `helm/lumiatech/values.yaml` with the new `<git-sha>` image tags
3. Commits and pushes the change back to the manifest repo

ArgoCD in the EKS cluster detects the manifest change and rolls out the new images automatically.

---

### 7. Local Development with Docker Compose

```bash
cd Docker-files
docker compose up --build
```

| Service   | Port  |
|-----------|-------|
| Nginx     | 80    |
| Tomcat    | 8080  |
| MySQL     | 3306  |


---

## Related Repository

Kubernetes manifests (Helm chart) and EKS cluster setup:  
**[Project-4-Deploy-to-EKS-manifest](https://github.com/Ndzenyuy/Project-4-Deploy-to-EKS-manifest)**
