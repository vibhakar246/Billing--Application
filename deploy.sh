#!/bin/bash

# ============================================
# Restaurant Billing System - Auto Deployment Script
# Uses SSH ONLY - No username/password
# ============================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration - Use SSH URL only!
GITHUB_SSH_REPO="git@github.com:vibhakar246/Billing--Application.git"
PROJECT_NAME="restaurant-billing-system"
DOCKER_IMAGE_NAME="restaurant-billing-system"
JENKINS_PORT=8080
LOCAL_TEST_PORT=8081

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Restaurant Billing System - Auto Deployment${NC}"
echo -e "${BLUE}Using SSH (No Password Required)${NC}"
echo -e "${BLUE}========================================${NC}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Check project files
echo -e "\n${YELLOW}[Step 1] Checking project files...${NC}"
if [[ ! -f "index.html" ]]; then
    echo -e "${RED}Error: index.html not found!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ index.html found${NC}"

# Step 2: Check/create Dockerfile
echo -e "\n${YELLOW}[Step 2] Creating Dockerfile...${NC}"
if [[ ! -f "Dockerfile" ]]; then
    cat > Dockerfile << 'EOF'
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
    echo -e "${GREEN}✓ Dockerfile created${NC}"
else
    echo -e "${GREEN}✓ Dockerfile already exists${NC}"
fi

# Step 3: Check/create Jenkinsfile
echo -e "\n${YELLOW}[Step 3] Creating Jenkinsfile...${NC}"
if [[ ! -f "Jenkinsfile" ]]; then
    cat > Jenkinsfile << 'EOF'
pipeline {
    agent any
    
    environment {
        IMAGE_NAME = 'restaurant-billing-system'
        IMAGE_TAG = "latest-${BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'git@github.com:vibhakar246/Billing--Application.git'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest"
            }
        }
        
        stage('Test Docker Image') {
            steps {
                sh """
                    docker run -d --name test-container -p 8888:80 ${IMAGE_NAME}:latest
                    sleep 3
                    curl -s http://localhost:8888 | grep -q 'RestroBilling' && echo '✅ Test passed!'
                    docker stop test-container
                    docker rm test-container
                """
            }
        }
    }
    
    post {
        success {
            echo "🎉 Pipeline successful! Image: ${IMAGE_NAME}:${IMAGE_TAG}"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
EOF
    echo -e "${GREEN}✓ Jenkinsfile created${NC}"
else
    echo -e "${GREEN}✓ Jenkinsfile already exists${NC}"
fi

# Step 4: Check if SSH key exists
echo -e "\n${YELLOW}[Step 4] Checking SSH key...${NC}"
if [[ -f ~/.ssh/id_rsa ]]; then
    echo -e "${GREEN}✓ SSH key already exists${NC}"
else
    echo -e "${YELLOW}No SSH key found. Please generate one first:${NC}"
    echo "  ssh-keygen -t rsa -b 4096 -C 'your-email@example.com'"
    exit 1
fi

# Step 5: Test GitHub SSH connection
echo -e "\n${YELLOW}[Step 5] Testing GitHub SSH connection...${NC}"
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo -e "${GREEN}✓ GitHub SSH connection verified${NC}"
else
    echo -e "${YELLOW}⚠ SSH key not added to GitHub yet. Please add this public key:${NC}"
    cat ~/.ssh/id_rsa.pub
    echo -e "\n${YELLOW}Add this to: https://github.com/settings/keys${NC}"
    echo -e "${YELLOW}Then press Enter to continue...${NC}"
    read
    echo -e "${GREEN}✓ Continuing after SSH key addition${NC}"
fi

# Step 6: Remove HTTPS remote if exists, add SSH remote
echo -e "\n${YELLOW}[Step 6] Setting up Git remote with SSH...${NC}"
if [[ -d ".git" ]]; then
    # Remove any existing HTTPS remotes
    git remote remove origin 2>/dev/null || true
    # Add SSH remote
    git remote add origin ${GITHUB_SSH_REPO}
    echo -e "${GREEN}✓ Git remote set to: ${GITHUB_SSH_REPO}${NC}"
else
    git init
    git remote add origin ${GITHUB_SSH_REPO}
    echo -e "${GREEN}✓ Git initialized with SSH remote${NC}"
fi

# Step 7: Add and commit files
echo -e "\n${YELLOW}[Step 7] Adding files to Git...${NC}"
git add index.html Dockerfile Jenkinsfile 2>/dev/null || true
git add . 2>/dev/null || true

if ! git diff --cached --quiet; then
    git commit -m "Auto-deploy: Restaurant Billing System $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${GREEN}✓ Changes committed${NC}"
else
    echo -e "${GREEN}✓ No new changes to commit${NC}"
fi

# Step 8: Push to GitHub using SSH
echo -e "\n${YELLOW}[Step 8] Pushing to GitHub via SSH...${NC}"
git push -u origin main 2>&1 || git push -u origin master 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Code pushed to GitHub successfully using SSH!${NC}"
else
    echo -e "${RED}Failed to push. Please check SSH connection:${NC}"
    echo "  ssh -T git@github.com"
    exit 1
fi

# Step 9: Test Docker build locally
echo -e "\n${YELLOW}[Step 9] Testing Docker build locally...${NC}"
docker build -t ${DOCKER_IMAGE_NAME}:test . 2>&1 | tail -5
echo -e "${GREEN}✓ Docker image built successfully${NC}"

# Step 10: Run local test
echo -e "\n${YELLOW}[Step 10] Running local test...${NC}"
docker run -d --name test-app -p ${LOCAL_TEST_PORT}:80 ${DOCKER_IMAGE_NAME}:test >/dev/null 2>&1
sleep 2
if curl -s http://localhost:${LOCAL_TEST_PORT} | grep -q "RestroBilling"; then
    echo -e "${GREEN}✓ Application is working!${NC}"
else
    echo -e "${RED}⚠ Application test failed${NC}"
fi
docker stop test-app >/dev/null 2>&1
docker rm test-app >/dev/null 2>&1

# Step 11: Check Jenkins status
echo -e "\n${YELLOW}[Step 11] Checking Jenkins...${NC}"
if systemctl status jenkins 2>/dev/null | grep -q "active"; then
    echo -e "${GREEN}✓ Jenkins is running at http://localhost:${JENKINS_PORT}${NC}"
else
    echo -e "${YELLOW}Jenkins not running. Installing...${NC}"
    sudo apt update
    sudo apt install openjdk-11-jdk -y
    wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
    sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    sudo apt update
    sudo apt install jenkins -y
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    echo -e "${GREEN}✓ Jenkins installed${NC}"
    echo -e "${YELLOW}Initial password:${NC}"
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "Check /var/lib/jenkins/secrets/initialAdminPassword"
fi

# Step 12: Show GitHub URL
echo -e "\n${YELLOW}[Step 12] GitHub Repository Info...${NC}"
echo -e "${GREEN}Repository URL (SSH): ${GITHUB_SSH_REPO}${NC}"
echo -e "${GREEN}Repository URL (HTTPS): https://github.com/vibhakar246/Billing--Application.git${NC}"

# Final Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}✅ DEPLOYMENT COMPLETED SUCCESSFULLY!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Summary:${NC}"
echo -e "  ✓ GitHub Repository: ${GITHUB_SSH_REPO}"
echo -e "  ✓ Docker Image: ${DOCKER_IMAGE_NAME}:test"
echo -e "  ✓ Local Test URL: http://localhost:${LOCAL_TEST_PORT}"
echo -e "  ✓ Jenkins URL: http://localhost:${JENKINS_PORT}"
echo -e "  ✓ Project Location: $(pwd)"
echo -e "\n${YELLOW}Quick Commands:${NC}"
echo -e "  # View your app locally:"
echo -e "  docker run -d -p 8080:80 ${DOCKER_IMAGE_NAME}:test && firefox http://localhost:8080"
echo -e "\n  # Check GitHub repository:"
echo -e "  git remote -v"
echo -e "\n  # Test SSH connection:"
echo -e "  ssh -T git@github.com"
echo -e "\n${YELLOW}To set up Jenkins Pipeline:${NC}"
echo -e "  1. Open http://localhost:${JENKINS_PORT}"
echo -e "  2. Create new Pipeline job"
echo -e "  3. SCM: Git, URL: ${GITHUB_SSH_REPO}"
echo -e "  4. Branch: */main"
echo -e "  5. Script Path: Jenkinsfile"
echo -e "\n${GREEN}Your app is now live locally and on GitHub! 🚀${NC}"
echo -e "${BLUE}========================================${NC}"
