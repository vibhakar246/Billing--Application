pipeline {
    agent any

    environment {
        // AWS ECR Configuration
        AWS_ACCOUNT_ID = 'your-account-id'  // Replace with your AWS account ID
        AWS_REGION = 'us-east-1'            // Replace with your region
        REPOSITORY_NAME = 'restaurant-billing-system'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG = "latest"
    }

    stages {
        stage('Checkout') {
            steps {
                echo '📦 Checking out code from GitHub...'
                checkout scm
            }
        }

        stage('Verify Files') {
            steps {
                echo '🔍 Verifying files...'
                sh '''
                    ls -la
                    if [ ! -f index.html ]; then
                        echo "❌ index.html not found!"
                        exit 1
                    fi
                    echo "✅ All required files present"
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                sh '''
                    docker build -t ${REPOSITORY_NAME}:${IMAGE_TAG} .
                    docker tag ${REPOSITORY_NAME}:${IMAGE_TAG} ${REPOSITORY_NAME}:${BUILD_NUMBER}
                '''
            }
        }

        stage('Test Docker Image') {
            steps {
                echo '🧪 Testing Docker image...'
                script {
                    // Clean up any existing test container
                    sh 'docker stop test-container || true'
                    sh 'docker rm test-container || true'
                    
                    // Run container with better diagnostics
                    sh '''
                        docker run -d --name test-container -p 8888:80 ${REPOSITORY_NAME}:${IMAGE_TAG}
                        
                        # Wait for container to be ready with health checks
                        echo "Waiting for container to start..."
                        for i in $(seq 1 30); do
                            if docker ps | grep -q test-container; then
                                echo "Container is running"
                                break
                            fi
                            sleep 1
                        done
                        
                        # Check container logs
                        echo "Container logs:"
                        docker logs test-container
                        
                        # Wait for nginx to be fully ready
                        sleep 3
                        
                        # Test the endpoint with retry logic
                        echo "Testing HTTP endpoint..."
                        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888 || echo "000")
                        
                        if [ "$RESPONSE" = "200" ]; then
                            echo "✅ Container test successful! HTTP $RESPONSE"
                        else
                            echo "❌ Container test failed with HTTP $RESPONSE"
                            echo "Container processes:"
                            docker exec test-container ps aux
                            echo "Container network:"
                            docker exec test-container netstat -tulpn 2>/dev/null || echo "netstat not available"
                            exit 1
                        fi
                    '''
                }
            }
            post {
                always {
                    // Clean up test container
                    sh 'docker stop test-container || true'
                    sh 'docker rm test-container || true'
                }
            }
        }

        stage('Login to ECR') {
            when {
                expression { return env.AWS_ACCOUNT_ID != 'your-account-id' }
            }
            steps {
                echo '🔐 Logging into Amazon ECR...'
                script {
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    '''
                }
            }
        }

        stage('Push to ECR') {
            when {
                expression { return env.AWS_ACCOUNT_ID != 'your-account-id' }
            }
            steps {
                echo '📤 Pushing image to Amazon ECR...'
                script {
                    // Create repository if it doesn't exist
                    sh '''
                        aws ecr describe-repositories --repository-names ${REPOSITORY_NAME} --region ${AWS_REGION} || \
                        aws ecr create-repository --repository-name ${REPOSITORY_NAME} --region ${AWS_REGION}
                    '''
                    
                    // Tag and push images
                    sh '''
                        docker tag ${REPOSITORY_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${REPOSITORY_NAME}:${IMAGE_TAG}
                        docker tag ${REPOSITORY_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${REPOSITORY_NAME}:${BUILD_NUMBER}
                        docker push ${ECR_REGISTRY}/${REPOSITORY_NAME}:${IMAGE_TAG}
                        docker push ${ECR_REGISTRY}/${REPOSITORY_NAME}:${BUILD_NUMBER}
                    '''
                    echo "✅ Image pushed to ECR: ${ECR_REGISTRY}/${REPOSITORY_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('Deploy from ECR') {
            when {
                expression { return env.AWS_ACCOUNT_ID != 'your-account-id' }
            }
            steps {
                echo '🚀 Deploying from ECR...'
                script {
                    sh '''
                        # Stop and remove existing container if running
                        docker stop billing-app || true
                        docker rm billing-app || true
                        
                        # Pull latest image from ECR
                        docker pull ${ECR_REGISTRY}/${REPOSITORY_NAME}:${IMAGE_TAG}
                        
                        # Run new container
                        docker run -d \
                            --name billing-app \
                            --restart unless-stopped \
                            -p 80:80 \
                            ${ECR_REGISTRY}/${REPOSITORY_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '✅ Verifying deployment...'
                script {
                    sh '''
                        sleep 5
                        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80 || echo "000")
                        if [ "$RESPONSE" = "200" ]; then
                            echo "✅ Application deployed successfully! HTTP $RESPONSE"
                        else
                            echo "❌ Deployment verification failed with HTTP $RESPONSE"
                            echo "Container logs:"
                            docker logs billing-app || echo "Container not running"
                            exit 1
                        fi
                    '''
                }
            }
        }
    }

    post {
        always {
            echo '🧹 Cleaning up...'
            script {
                // Keep test container cleanup but don't stop production container
                sh 'docker ps -a --filter "name=test-container" -q | xargs -r docker rm -f || true'
            }
        }
        success {
            echo '🎉 PIPELINE SUCCESSFUL! Application is deployed and running.'
        }
        failure {
            echo '❌ PIPELINE FAILED'
            script {
                // Get logs from failed container for debugging
                sh '''
                    echo "=== Last 50 lines of container logs ==="
                    docker logs --tail 50 test-container 2>&1 || echo "No container logs available"
                    docker logs --tail 50 billing-app 2>&1 || true
                '''
            }
        }
    }
}
