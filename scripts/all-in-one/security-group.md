# EC2 Security Group Configuration

## Instance: All-in-One DevSecOps Server

| Type | Protocol | Port Range | Source | Description |
|------|----------|-----------|--------|-------------|
| SSH | TCP | 22 | Your IP/32 | SSH access |
| Custom TCP | TCP | 8080 | 0.0.0.0/0 | Jenkins |
| Custom TCP | TCP | 8085 | 0.0.0.0/0 | App (Docker) |
| Custom TCP | TCP | 8090 | 0.0.0.0/0 | Tomcat |
| Custom TCP | TCP | 9000 | 0.0.0.0/0 | SonarQube |

## Outbound Rules
| Type | Protocol | Port Range | Destination | Description |
|------|----------|-----------|-------------|-------------|
| All traffic | All | All | 0.0.0.0/0 | Allow all outbound |
