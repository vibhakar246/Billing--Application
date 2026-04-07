# 🍽️ RestroBilling - Smart Restaurant Billing System

[![Jenkins](https://img.shields.io/badge/Jenkins-CI/CD-blue?logo=jenkins)](https://www.jenkins.io/)
[![Docker](https://img.shields.io/badge/Docker-Container-blue?logo=docker)](https://www.docker.com/)
[![AWS](https://img.shields.io/badge/AWS-EC2%20%7C%20ECR-orange?logo=amazon-aws)](https://aws.amazon.com/)
[![Trivy](https://img.shields.io/badge/Security-Trivy-red)](https://trivy.dev/)
[![HTML5](https://img.shields.io/badge/HTML5-E34F26?logo=html5&logoColor=white)](https://developer.mozilla.org/en-US/docs/Web/HTML)
[![CSS3](https://img.shields.io/badge/CSS3-1572B6?logo=css3&logoColor=white)](https://developer.mozilla.org/en-US/docs/Web/CSS)
[![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?logo=javascript&logoColor=black)](https://developer.mozilla.org/en-US/docs/Web/JavaScript)

A modern, responsive restaurant billing system with real-time cart management, GST calculation, and bill generation. Complete CI/CD pipeline with Jenkins, Docker, AWS ECR, and automated deployment to EC2.

---

## 📸 Screenshots

### 🖥️ Restaurant Web Application
![Restaurant Billing UI](./screenshots/restaurant-webui.png)

### 🔧 Jenkins CI/CD Pipeline - Stage View
![Jenkins Pipeline](./screenshots/Jenkins-Pipeline.png)
*8-stage automated pipeline with successful build, test, security scan, and deployment*

### 📊 Pipeline Execution Details
| Build # | Date | Status | Total Time |
|---------|------|--------|------------|
| #29 | Mar 30 | ✅ Success | ~30s |
| #28 | Mar 30 10:13 | ✅ Success | ~28s |
| #27 | Mar 30 10:06 | ✅ Success | ~35s |

---

## 🏗️ Complete System Architecture

```mermaid
graph TB
    subgraph Developer["👨‍💻 Developer"]
        GIT[Git Push<br/>to GitHub]
    end

    subgraph Jenkins["⚙️ Jenkins CI/CD Pipeline"]
        SCM[1. Checkout SCM]
        BUILD[2. Build Docker Image]
        TEST[3. Test Docker Image]
        SECURITY[4. Security Scan - Trivy]
        ECR_LOGIN[5. Login to ECR]
        PUSH_ECR[6. Push to ECR]
        DEPLOY[7. Deploy to EC2]
        VERIFY[8. Verify Deployment]
    end

    subgraph AWS["☁️ AWS Cloud"]
        ECR_REPO[(Amazon ECR)]
        EC2[🖥️ EC2 Instance<br/>Nginx + Docker]
    end

    GIT --> SCM --> BUILD --> TEST --> SECURITY
    SECURITY --> ECR_LOGIN --> PUSH_ECR --> ECR_REPO
    ECR_REPO --> DEPLOY --> EC2 --> VERIFY
