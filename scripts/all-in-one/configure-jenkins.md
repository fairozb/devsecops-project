# Jenkins Configuration Guide (All-in-One Server)

After running `setup-all-in-one.sh`, follow these steps to configure Jenkins.

## Step 1: Access Jenkins

1. Open browser: `http://<YOUR-EC2-IP>:8080`
2. Paste the initial admin password (shown at the end of setup script)
3. Click **"Install suggested plugins"** (wait ~3 minutes)
4. Create admin user → Save and Continue → Save and Finish

## Step 2: Install Additional Plugins

Go to **Manage Jenkins → Plugins → Available plugins**

Search and install each:
- ✅ `SonarQube Scanner`
- ✅ `OWASP Dependency-Check`
- ✅ `Docker Pipeline`
- ✅ `Docker Commons`
- ✅ `docker-build-step`
- ✅ `Deploy to container` (for Tomcat)
- ✅ `Email Extension`
- ✅ `Eclipse Temurin installer` (for JDK auto-install)
- ✅ `Pipeline: Stage View`
- ✅ `JaCoCo`

Click **"Install without restart"**, then **check "Restart Jenkins"** at the bottom.

## Step 3: Configure Global Tools

### Manage Jenkins → Tools

#### JDK installations:
- Click **Add JDK**
- Name: `jdk17`
- Uncheck "Install automatically"
- JAVA_HOME: `/usr/lib/jvm/java-17-openjdk-amd64`

#### Maven installations:
- Click **Add Maven**
- Name: `maven3`
- Check "Install automatically"
- Version: `3.9.6`

#### SonarQube Scanner installations:
- Click **Add SonarQube Scanner**
- Name: `sonar-scanner`
- Check "Install automatically"
- Version: latest

#### Dependency-Check installations:
- Click **Add Dependency-Check**
- Name: `dp-check`
- Check "Install automatically"
- Version: `9.0.9` (or latest)

#### Docker installations:
- Click **Add Docker**
- Name: `docker`
- Check "Install automatically"
- Docker version: `latest`

Click **Save**.

## Step 4: Configure SonarQube Server

### First: Get SonarQube Token
1. Open `http://<YOUR-EC2-IP>:9000`
2. Login: `admin` / `admin` → Change password → Use `Admin@123`
3. Go to **My Account → Security → Generate Tokens**
4. Name: `jenkins`, Type: `Global Analysis Token`
5. Click **Generate** → **COPY THE TOKEN** (you'll need it below)

### Then: Configure in Jenkins
1. **Manage Jenkins → Credentials → System → Global credentials → Add Credentials**
   - Kind: `Secret text`
   - Secret: (paste SonarQube token)
   - ID: `sonar-token`
   - Click **Create**

2. **Manage Jenkins → System → SonarQube servers**
   - Check "Environment variables"
   - Click **Add SonarQube**
   - Name: `sonar-server`
   - Server URL: `http://localhost:9000`
   - Server authentication token: Select `sonar-token`
   - Click **Save**

## Step 5: Add All Credentials

Go to **Manage Jenkins → Credentials → System → Global credentials → Add Credentials**

### 5.1 GitHub Credentials
- Kind: `Username with password`
- Username: Your GitHub username (`fairozb`)
- Password: GitHub Personal Access Token ([Create here](https://github.com/settings/tokens))
  - Scopes needed: `repo`, `admin:repo_hook`
- ID: `github-credentials`

### 5.2 Docker Hub Credentials
- Kind: `Username with password`
- Username: Your Docker Hub username
- Password: Docker Hub Access Token ([Create here](https://hub.docker.com/settings/security))
- ID: `docker-hub-credentials`

### 5.3 Tomcat Credentials
- Kind: `Username with password`
- Username: `admin`
- Password: `admin123`
- ID: `tomcat-credentials`

### 5.4 SonarQube Token (already done in Step 4)

## Step 6: Create the Pipeline Job

1. **Jenkins Dashboard → New Item**
2. Enter name: `devsecops-pipeline`
3. Select: **Pipeline**
4. Click **OK**

### Configure the job:
- **General:**
  - ✅ GitHub project: `https://github.com/fairozb/devsecops-project/`
  
- **Pipeline:**
  - Definition: `Pipeline script from SCM`
  - SCM: `Git`
  - Repository URL: `https://github.com/fairozb/devsecops-project.git`
  - Credentials: Select `github-credentials`
  - Branch Specifier: `*/main`
  - Script Path: `Jenkinsfile`

5. Click **Save**

## Step 7: Update Jenkinsfile for All-in-One

Since everything is on one server, you need to update the Tomcat URL in the Jenkinsfile.

Change this line:
```groovy
TOMCAT_URL = 'http://localhost:8080'
```
To:
```groovy
TOMCAT_URL = 'http://localhost:8090'
```

(Because we changed Tomcat port to 8090 to avoid conflict with Jenkins on 8080)

## Step 8: Build Now! 🚀

1. Go to `devsecops-pipeline` job
2. Click **Build Now**
3. Watch the pipeline execute all 14 stages!

## Troubleshooting

### "Permission denied" for Docker
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### SonarQube not responding
```bash
# Check if running
sudo docker ps | grep sonarqube

# If not running, start it
sudo docker start sonarqube

# Check logs
sudo docker logs sonarqube
```

### Tomcat deployment fails
```bash
# Verify Tomcat is running on port 8090
curl http://localhost:8090

# Restart Tomcat
sudo /opt/tomcat/bin/shutdown.sh
sudo /opt/tomcat/bin/startup.sh
```

### Jenkins out of memory
```bash
# Increase Jenkins memory
sudo sed -i 's/^JAVA_OPTS.*/JAVA_OPTS="-Xmx1024m -Xms512m"/' /etc/default/jenkins
sudo systemctl restart jenkins
```
