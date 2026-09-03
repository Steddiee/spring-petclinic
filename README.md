# Spring PetClinic — CI/CD Pipeline

This repository includes a complete CI/CD pipeline for the Spring PetClinic sample application.

---

## Architecture & Design Highlights

- **Multi-Stage Containerization:** Built with an initial JDK stage for compilation and an unprivileged Alpine JRE runtime to minimize attack surface and image size.
- **Non-Root Execution:** Runs Jenkins as an unprivileged user (`jenkins`) by dynamically mapping container group permissions to the host's `/var/run/docker.sock` GID.
- **Native JFrog Integration:** Bundles the official `jf` CLI directly into the runner image using multi-stage builds (`releases-docker.jfrog.io/jfrog/jfrog-cli-v2-jf`), enabling artifact and build-info publishing to JFrog Artifactory / JFrog Cloud.
- **Zero Plugin Overhead:** Uses native Groovy pipeline logic and standard shell executions, removing strict dependencies on third-party Jenkins plugins.
- **Artifact Archiving:** Generates test reports via JUnit and exposes the final compiled Docker image tarball (`spring-petclinic-image.tar`) directly in the Jenkins UI.

---

## Prerequisites

- `git`
- `docker`

### Option 1: Prerequisites for External Jenkins Environments

To run this `Jenkinsfile` on an external Jenkins or remote agent:

1. **Docker & JFrog CLIs Installed:** The agent executing the job must have `docker` and `jf` binaries in its standard `PATH`.
2. **Socket Access (DooD):** The Jenkins agent user requires read/write access to `/var/run/docker.sock`.

### Option 2: New Jenkins Container (Docker outside of Docker) Setup

The provided `Dockerfile.jenkins` extracts static `docker` and `jf` binaries from their official registry images and handles non-root socket permissions dynamically.

```bash
# 1. Build image with dynamic GID matching
docker build --build-arg DOCKER_GID=$(stat -c '%g' /var/run/docker.sock) -t jenkins-dood -f Dockerfile.jenkins .

# 2. (Optional) Ensure volume permissions match non-root jenkins user UID 1000
docker run --rm -v jenkins_home:/var/jenkins_home alpine chown -R 1000:1000 /var/jenkins_home

# 3. Launch container
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8081:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins-dood

# Get initial admin password:
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Open http://localhost:8081, follow setup wizard
```

## Jenkins Credentials Setup (Optional - for JFrog Cloud)

To enable JFrog Cloud dependency resolution, add the following global credentials in Jenkins (Manage Jenkins -> Credentials):

- jfrog-url (Secret text): JFrog instance URL (e.g., https://<your-org>.jfrog.io).
- jfrog-access-token (Secret text): Identity token generated from JFrog User Profile -> Access Tokens.

_Note: If these credentials are missing, the pipeline automatically bypasses JFrog steps and resolves dependency through Maven._

## Running the Pipeline

The pipeline handles compilation, testing, and Docker image packaging.

1. Complete the prerequisites above
2. In Jenkins, create a **Pipeline** job pointing to `https://github.com/Steddiee/spring-petclinic.git`
3. Set pipeline definition to "Pipeline script from SCM"
4. Update SCM to Git
5. Update respository URL
6. Set Branch Specifier to */main
7. Script Path to Jenkinsfile
8. Save and run the job

## How to Run the Application

### Using the Exported Docker Image Archive

Download the `spring-petclinic-image.tar` file from Build Artifacts, load and run it directly:

```bash
# 1. Load the image tar archive into Docker
docker load -i spring-petclinic-image.tar

# 2. Run the container
docker run -d -p 8082:8080 --name petclinic-app spring-petclinic:latest

# 3. Visit localhost:8082
```
