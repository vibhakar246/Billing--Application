#!/bin/bash

# ============================================
# Restaurant Billing System - Auto Deployment Script
# Uses SSH for GitHub (no password)
# ============================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GITHUB_SSH_REPO="git@github.com:vibhakar246/Billing--Application.git"
PROJECT_NAME="restaurant-billing-system"
DOCKER_IMAGE_NAME="restaurant-billing-system"
JENKINS_PORT=8080
LOCAL_TEST_PORT=8081

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Restaurant Billing System - Auto Deployment${NC}"
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

# Step 4: Check SSH key for GitHub
echo -e "\n${YELLOW}[Step 4] Checking GitHub SSH setup...${NC}"
if [[ ! -f ~/.ssh/id_rsa ]]; then
    echo -e "${YELLOW}SSH key not found. Generating new SSH key...${NC}"
    ssh-keygen -t rsa -b 4096 -C "vibhakar246@gmail.com" -f ~/.ssh/id_rsa -N ""
    echo -e "${GREEN}✓ SSH key generated${NC}"
    echo -e "${YELLOW}Add this public key to GitHub:${NC}"
    cat ~/.ssh/id_rsa.pub
    echo -e "\n${YELLOW}Please add this key to GitHub -> Settings -> SSH and GPG keys${NC}"
    echo -e "${YELLOW}Then press Enter to continue...${NC}"
    read
else
    echo -e "${GREEN}✓ SSH key already exists${NC}"
fi

# Step 5: Test GitHub SSH connection
echo -e "\n${YELLOW}[Step 5] Testing GitHub SSH connection...${NC}"
ssh -T git@github.com 2>&1 | grep -q "successfully authenticated" || echo -e "${YELLOW}Note: First time connecting to GitHub${NC}"
echo -e "${GREEN}✓ GitHub SSH connection working${NC}"

# Step 6: Initialize Git and push to GitHub
echo -e "\n${YELLOW}[Step 6] Pushing to GitHub...${NC}"
if [[ ! -d ".git" ]]; then
    git init
    echo -e "${GREEN}✓ Git initialized${NC}"
fi

# Add remote if not exists
if ! git remote | grep -q origin; then
    git remote add origin ${GITHUB_SSH_REPO}
    echo -e "${GREEN}✓ Remote added: ${GITHUB_SSH_REPO}${NC}"
fi

# Add all files
git add index.html Dockerfile Jenkinsfile 2>/dev/null || true
git add . 2>/dev/null || true

# Commit if there are changes
if ! git diff --cached --quiet; then
    git commit -m "Auto-deploy: Restaurant Billing System $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${GREEN}✓ Changes committed${NC}"
else
    echo -e "${GREEN}✓ No new changes to commit${NC}"
fi

# Push to GitHub
git push -u origin main || git push -u origin master
echo -e "${GREEN}✓ Code pushed to GitHub successfully!${NC}"

# Step 7: Test Docker build locally
echo -e "\n${YELLOW}[Step 7] Testing Docker build locally...${NC}"
docker build -t ${DOCKER_IMAGE_NAME}:test .
echo -e "${GREEN}✓ Docker image built successfully${NC}"

# Step 8: Run local test
echo -e "\n${YELLOW}[Step 8] Running local test...${NC}"
docker run -d --name test-app -p ${LOCAL_TEST_PORT}:80 ${DOCKER_IMAGE_NAME}:test
sleep 2
if curl -s http://localhost:${LOCAL_TEST_PORT} | grep -q "RestroBilling"; then
    echo -e "${GREEN}✓ Application is working! Access at: http://localhost:${LOCAL_TEST_PORT}${NC}"
else
    echo -e "${RED}⚠ Application test failed${NC}"
fi
docker stop test-app >/dev/null 2>&1
docker rm test-app >/dev/null 2>&1

# Step 9: Check Jenkins
echo -e "\n${YELLOW}[Step 9] Checking Jenkins...${NC}"
if command_exists jenkins || systemctl status jenkins 2>/dev/null | grep -q "active"; then
    echo -e "${GREEN}✓ Jenkins is installed${NC}"
else
    echo -e "${YELLOW}Installing Jenkins...${NC}"
    sudo apt update
    sudo apt install openjdk-11-jdk -y
    wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
    sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    sudo apt update
    sudo apt install jenkins -y
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    echo -e "${GREEN}✓ Jenkins installed successfully${NC}"
    echo -e "${YELLOW}Jenkins initial password:${NC}"
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
fi

# Step 10: Create Jenkins job via CLI (optional)
echo -e "\n${YELLOW}[Step 10] Setting up Jenkins job...${NC}"
echo -e "${GREEN}Jenkins is running at: http://localhost:${JENKINS_PORT}${NC}"
echo -e "${YELLOW}To create Jenkins job manually:${NC}"
echo "1. Open http://localhost:${JENKINS_PORT}"
echo "2. Click 'New Item'"
echo "3. Enter name: ${PROJECT_NAME}"
echo "4. Select 'Pipeline'"
echo "5. In Pipeline section:"
echo "   - Definition: Pipeline script from SCM"
echo "   - SCM: Git"
echo "   - Repository URL: ${GITHUB_SSH_REPO}"
echo "   - Branch: */main"
echo "   - Script Path: Jenkinsfile"
echo "6. Click Save"
echo "7. Click 'Build Now'"

# Step 11: Show summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}DEPLOYMENT COMPLETED SUCCESSFULLY!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Summary:${NC}"
echo -e "  ✓ GitHub Repository: ${GITHUB_SSH_REPO}"
echo -e "  ✓ Docker Image: ${DOCKER_IMAGE_NAME}:test"
echo -e "  ✓ Local Test URL: http://localhost:${LOCAL_TEST_PORT}"
echo -e "  ✓ Jenkins URL: http://localhost:${JENKINS_PORT}"
echo -e "  ✓ Project Location: $(pwd)"
echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "  1. Access your app: http://localhost:${LOCAL_TEST_PORT}"
echo -e "  2. Set up Jenkins job using the instructions above"
echo -e "  3. Build and test your pipeline"
echo -e "  4. Your code is now on GitHub: ${GITHUB_SSH_REPO}"
echo -e "\n${GREEN}To run the app without Docker:${NC}"
echo -e "  Just open index.html in your browser"
echo -e "\n${GREEN}To run with Docker:${NC}"
echo -e "  docker run -d -p 8080:80 ${DOCKER_IMAGE_NAME}:test"
echo -e "${BLUE}========================================${NC}"
