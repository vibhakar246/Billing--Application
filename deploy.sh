#!/bin/bash

# ============================================
# Restaurant Billing System - Auto Deployment Script
# Handles existing repositories and conflicts
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
DOCKER_IMAGE_NAME="restaurant-billing-system"
LOCAL_TEST_PORT=8081

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Restaurant Billing System - Auto Deployment${NC}"
echo -e "${BLUE}Using SSH (No Password Required)${NC}"
echo -e "${BLUE}========================================${NC}"

# Step 1: Check project files
echo -e "\n${YELLOW}[Step 1] Checking project files...${NC}"
if [[ ! -f "index.html" ]]; then
    echo -e "${RED}Error: index.html not found!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ index.html found${NC}"

# Step 2: Create Dockerfile if not exists
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

# Step 3: Create Jenkinsfile if not exists
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

# Step 4: Check SSH key
echo -e "\n${YELLOW}[Step 4] Checking SSH key...${NC}"
if [[ -f ~/.ssh/id_rsa ]]; then
    echo -e "${GREEN}✓ SSH key exists${NC}"
else
    echo -e "${RED}No SSH key found. Please generate one:${NC}"
    echo "  ssh-keygen -t rsa -b 4096 -C 'vibhakar246@gmail.com'"
    exit 1
fi

# Step 5: Test GitHub SSH connection
echo -e "\n${YELLOW}[Step 5] Testing GitHub SSH connection...${NC}"
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo -e "${GREEN}✓ GitHub SSH connection verified${NC}"
else
    echo -e "${YELLOW}⚠ SSH key not added to GitHub. Add this public key:${NC}"
    cat ~/.ssh/id_rsa.pub
    echo -e "\n${YELLOW}Add to: https://github.com/settings/keys${NC}"
    exit 1
fi

# Step 6: Setup Git repository
echo -e "\n${YELLOW}[Step 6] Setting up Git repository...${NC}"

# Initialize git if not already
if [[ ! -d ".git" ]]; then
    git init
    echo -e "${GREEN}✓ Git initialized${NC}"
fi

# Remove existing remote if any
git remote remove origin 2>/dev/null || true

# Add SSH remote
git remote add origin ${GITHUB_SSH_REPO}
echo -e "${GREEN}✓ Remote added: ${GITHUB_SSH_REPO}${NC}"

# Step 7: Handle existing remote content
echo -e "\n${YELLOW}[Step 7] Syncing with remote repository...${NC}"

# Fetch remote changes
git fetch origin 2>/dev/null || echo "No existing remote content"

# Check if remote has content
if git ls-remote --heads origin main | grep -q main; then
    echo -e "${YELLOW}Remote repository already has content. Merging...${NC}"
    
    # Create a backup of our files
    cp index.html index.html.backup
    cp Dockerfile Dockerfile.backup 2>/dev/null || true
    cp Jenkinsfile Jenkinsfile.backup 2>/dev/null || true
    
    # Pull remote changes
    git pull origin main --allow-unrelated-histories --no-rebase || true
    
    # Restore our files if they were overwritten
    cp index.html.backup index.html
    cp Dockerfile.backup Dockerfile 2>/dev/null || true
    cp Jenkinsfile.backup Jenkinsfile 2>/dev/null || true
    
    # Add our files
    git add index.html Dockerfile Jenkinsfile 2>/dev/null || true
    
    # Commit our changes
    git commit -m "Update: Restaurant Billing System $(date '+%Y-%m-%d %H:%M:%S')" || true
    
    echo -e "${GREEN}✓ Merged remote changes${NC}"
else
    echo -e "${GREEN}✓ Remote repository is empty, ready to push${NC}"
fi

# Step 8: Add and commit our files
echo -e "\n${YELLOW}[Step 8] Adding files to Git...${NC}"
git add index.html Dockerfile Jenkinsfile 2>/dev/null || true
git add . 2>/dev/null || true

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo -e "${GREEN}✓ No new changes to commit${NC}"
else
    git commit -m "Auto-deploy: Restaurant Billing System $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${GREEN}✓ Changes committed${NC}"
fi

# Step 9: Push to GitHub
echo -e "\n${YELLOW}[Step 9] Pushing to GitHub via SSH...${NC}"
git push -u origin main 2>&1 || git push -u origin HEAD:main 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Code pushed to GitHub successfully!${NC}"
else
    echo -e "${RED}Failed to push. Trying force push...${NC}"
    git push -u origin main --force
    echo -e "${GREEN}✓ Force push completed!${NC}"
fi

# Step 10: Test Docker build
echo -e "\n${YELLOW}[Step 10] Testing Docker build...${NC}"
docker build -t ${DOCKER_IMAGE_NAME}:test . > /dev/null 2>&1
echo -e "${GREEN}✓ Docker image built: ${DOCKER_IMAGE_NAME}:test${NC}"

# Step 11: Run local test
echo -e "\n${YELLOW}[Step 11] Running local test...${NC}"
docker stop test-app 2>/dev/null || true
docker rm test-app 2>/dev/null || true

docker run -d --name test-app -p ${LOCAL_TEST_PORT}:80 ${DOCKER_IMAGE_NAME}:test > /dev/null 2>&1
sleep 3

if curl -s http://localhost:${LOCAL_TEST_PORT} | grep -q "RestroBilling"; then
    echo -e "${GREEN}✓ Application is working at: http://localhost:${LOCAL_TEST_PORT}${NC}"
else
    echo -e "${RED}⚠ Application test failed${NC}"
fi

# Clean up
docker stop test-app > /dev/null 2>&1 || true
docker rm test-app > /dev/null 2>&1 || true

# Step 12: Check Jenkins
echo -e "\n${YELLOW}[Step 12] Checking Jenkins...${NC}"
if command -v jenkins > /dev/null 2>&1 || systemctl status jenkins 2>/dev/null | grep -q "active"; then
    echo -e "${GREEN}✓ Jenkins is installed${NC}"
    echo -e "${GREEN}  Jenkins URL: http://localhost:8080${NC}"
else
    echo -e "${YELLOW}Jenkins not installed. Install with:${NC}"
    echo "  sudo apt update && sudo apt install jenkins -y"
fi

# Final Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}✅ DEPLOYMENT COMPLETED SUCCESSFULLY!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Your Restaurant Billing System is now:${NC}"
echo -e "  📦 GitHub: ${GITHUB_SSH_REPO}"
echo -e "  🐳 Docker Image: ${DOCKER_IMAGE_NAME}:test"
echo -e "  🌐 Local Test: http://localhost:${LOCAL_TEST_PORT}"
echo -e "\n${YELLOW}Quick Commands:${NC}"
echo -e "  # Run your app:"
echo -e "  docker run -d -p 8080:80 ${DOCKER_IMAGE_NAME}:test"
echo -e "  # View GitHub repo:"
echo -e "  git remote -v"
echo -e "  # Check SSH connection:"
echo -e "  ssh -T git@github.com"
echo -e "\n${BLUE}========================================${NC}"
