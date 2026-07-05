# QUICK START - All-in-One DevSecOps (5 Minutes to Launch!)

## Cost: ~$35/month (t2.large) - Stop when not using to save money!

---

## Step 1: Launch EC2 (2 minutes)

1. Go to AWS Console → EC2 → Launch Instance
2. Settings:
   - **Name:** `DevSecOps-All-In-One`
   - **AMI:** Ubuntu 22.04 LTS
   - **Instance Type:** `t2.large` (2 vCPU, 8 GB RAM)
   - **Key Pair:** Create or select existing
   - **Storage:** 30 GB gp3
   - **Security Group:** Open ports 22, 8080, 8085, 8090, 9000

3. Click **Launch Instance**

---

## Step 2: SSH & Run Setup (10 minutes)

```bash
# SSH into your instance
ssh -i your-key.pem ubuntu@<EC2-PUBLIC-IP>

# Download and run setup script
git clone https://github.com/fairozb/devsecops-project.git
cd devsecops-project/scripts/all-in-one
chmod +x setup-all-in-one.sh
sudo ./setup-all-in-one.sh
```

Wait for script to complete (~10 minutes).

---

## Step 3: Configure Jenkins (5 minutes)

1. Open `http://<EC2-IP>:8080`
2. Paste the initial password (shown at end of script)
3. Install suggested plugins
4. Create admin user
5. Follow `configure-jenkins.md` for tool & credential setup

---

## Step 4: Run Pipeline! (2 minutes)

1. Create Pipeline job pointing to your GitHub repo
2. Script path: `Jenkinsfile`
3. Click **Build Now**
4. Watch all 14 stages execute!

---

## All URLs (replace <IP> with your EC2 public IP):

| Service | URL | Login |
|---------|-----|-------|
| Jenkins | http://<IP>:8080 | admin / (your password) |
| SonarQube | http://<IP>:9000 | admin / admin |
| Tomcat | http://<IP>:8090 | admin / admin123 |
| Your App | http://<IP>:8085 | - |

---

## Save Money Tips:
- **Stop EC2** when not using (AWS Console → Instances → Stop)
- **Start EC2** when ready to work again
- After restart, start SonarQube & Tomcat manually:
  ```bash
  sudo docker start sonarqube
  sudo /opt/tomcat/bin/startup.sh
  ```
