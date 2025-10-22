# Stage 1 - DevOps Bootcamp Deployment Script

## 👨‍💻 Author
**Name:** Solomon Joseph/SolomonJ
**Track:** DevOps Engineer  
**Cohort:** HNG 13  

---

## 🚀 Project Overview
This repository contains my **Stage 1 DevOps Bootcamp deployment automation script (`deploy.sh`)**.  
The script automates the deployment of a simple **Python Flask web application** on an **AWS EC2 instance** using **Docker**.

---

## ⚙️ What the Script Does
The `deploy.sh` script performs the following tasks automatically:
1. Prompts the user for inputs such as:
   - Git repository URL  
   - Branch name  
   - EC2 SSH credentials  
   - Application port number  
2. Establishes a secure SSH connection to the remote EC2 server.  
3. Clones the specified Git repository onto the server.  
4. Installs and configures Docker if not already installed.  
5. Builds a Docker image for the Flask app.  
6. Runs a Docker container and exposes the app on the chosen port.  
7. Verifies that the deployment was successful by checking container status.

---

## 🧩 Technologies Used
- **Bash scripting**  
- **Docker**  
- **AWS EC2**  
- **Git & GitHub**  

---

## 🧠 How to Run the Script
1. Clone this repository:
   ```bash
   git clone https://github.com/Wisesolo1137/stage1-SolomonJ.git
   cd stage1-SolomonJ
Make the script executable:

bash
Copy code
chmod +x deploy.sh
Run the deployment script:

bash
Copy code
./deploy.sh
Follow the on-screen prompts to provide:

Repository link

Branch name

SSH key path

EC2 username (e.g., ec2-user)

EC2 public IP

Port number (e.g., 5000)

✅ Expected Output
Once deployment completes successfully, the app will be accessible at:

cpp
Copy code
http://<your-ec2-public-ip>:5000
Example:

cpp
Copy code
http://54.221.142.98:5000
When opened in a browser or tested via curl, it should return:

vbnet
Copy code
This is Kefas Lungu's HNG 13 stage 1 task.
💡 Notes
Ensure your EC2 security group allows inbound traffic on port 5000.

You must have your .pem SSH key ready and accessible.

Use your GitHub Personal Access Token (PAT) for secure authentication when pushing code.

🏁 Acknowledgement
Special thanks to the HNG DevOps Team and mentors for the guidance, support, and the opportunity to demonstrate real-world DevOps automation.

