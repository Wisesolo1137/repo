# Blue/Green Deployment with Nginx Auto-Failover

A complete implementation of Blue/Green deployment pattern with Nginx load balancing and auto-failover capability, built for DevOps bootcamp stage 2 task.

## 🏗️ Architecture Overview
┌─────────────────┐ ┌──────────────────┐ ┌─────────────────┐
│ Client │───▶│ Nginx LB │───▶│ Blue Service │
│ │ │ (:8080) │ │ (:8081) │
└─────────────────┘ └──────────────────┘ └─────────────────┘
│
└───────────────▶│ Green Service │
│ (:8082) │
└─────────────────┘

## 📋 Features Implemented

- ✅ **Blue/Green Deployment** - Active/backup service pattern
- ✅ **Nginx Load Balancing** - Traffic routing with backup configuration
- ✅ **Header Preservation** - X-App-Pool and X-Release-Id headers
- ✅ **Auto-Failover** - Automatic switch to backup on failure
- ✅ **Health Checks** - Service health monitoring
- ✅ **Zero-Downtime Ready** - Production-ready deployment pattern

## 🚀 Quick Start

### Prerequisites
- Docker
- Docker Compose

### Installation & Running
```bash
# Clone the repository
git clone <your-repo-url>
cd blue-green-deployment

# Copy environment template
cp .env.example .env

# Start all services
docker-compose up -d

# Verify deployment
curl http://localhost:8080/version


Verification Commands

# Check container status
docker-compose ps

# Test through load balancer
curl -I http://localhost:8080/version

# Test services directly
curl http://localhost:8081/version    # Blue service
curl http://localhost:8082/version    # Green service

🔧 Configuration
Environment Variables (.env)

# Service Images
BLUE_IMAGE=node:18-alpine
GREEN_IMAGE=node:18-alpine

# Active Pool (blue/green)
ACTIVE_POOL=blue

# Release Identifiers
RELEASE_ID_BLUE=blue-release-1.0.0
RELEASE_ID_GREEN=green-release-1.0.0

# Port Configuration
NGINX_PORT=8080
BLUE_PORT=8081
GREEN_PORT=8082
PORT=3000

Port Mapping
8080 - Nginx Load Balancer (Public access)

8081 - Blue Service (Direct access)

8082 - Green Service (Direct access)

3000 - Internal application port

📊 API Endpoints
All endpoints return appropriate headers (X-App-Pool, X-Release-Id):

Through Nginx (Port 8080)

# Service information
GET http://localhost:8080/version

# Health check
GET http://localhost:8080/healthz

Direct Service Access

# Blue service direct
GET http://localhost:8081/version

# Green service direct  
GET http://localhost:8082/version


🎯 Auto-Failover Testing
Simulate Blue Service Failure

# Stop blue service
docker-compose stop app_blue

# Nginx will automatically route to Green
curl -I http://localhost:8080/version

# Restore blue service
docker-compose start app_blue

Expected Behavior
Normal state: All traffic routes to Blue (active)

Blue failure: Automatic switch to Green (backup)

Headers preserved: X-App-Pool and X-Release-Id maintained

🛠️ Technical Details
Nginx Configuration
Load Balancing: Round-robin with backup server

Failover: Automatic on error/timeout/5xx status

Timeouts: Optimized for quick failure detection

Headers: Preserved and forwarded to clients

Docker Compose Services
nginx: Load balancer with custom configuration

app_blue: Primary/active service

app_green: Backup/standby service

app_network: Internal network for service communication

📁 Project Structure

blue-green-deployment/
├── docker-compose.yml      # Container orchestration
├── .env                    # Environment configuration
├── .env.example            # Environment template
├── nginx/
│   └── nginx.conf          # Nginx load balancer config
├── README.md               # This file
└── DECISION.md             # Implementation decisions

🐛 Troubleshooting
Common Issues
Port conflicts: Change ports in .env file

Container not starting: Check docker-compose logs

Headers missing: Verify service is running correctly

Debug Commands

# Check service logs
docker-compose logs

# Check individual service
docker-compose logs app_blue

# Test Nginx configuration
docker-compose exec nginx nginx -t

📝 Task Requirements Status
✅ Deploy Blue/Green Node.js services behind Nginx

✅ Configure automatic failover with zero failed requests

✅ Preserve and forward X-App-Pool and X-Release-Id headers

✅ Use Docker Compose for orchestration

✅ Parameterize configuration via environment variables

✅ Expose direct ports for chaos testing (8081/8082)

👨‍💻 Author
Your Name - DevOps Bootcamp Participant

📄 License
This project is created for educational purposes as part of DevOps bootcamp training.

---

## **HOW TO CREATE THE FILE:**

### **Step 1: Create and Open the File**
```bash
nano README.md


Step 2: Paste the Entire Content Above
Select and copy all the text above from # Blue/Green Deployment to the end

Paste into nano (Ctrl+Shift+V or right-click paste)
