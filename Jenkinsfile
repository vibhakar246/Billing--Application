pipeline {
    agent any
    
    environment {
        IMAGE_NAME = 'restaurant-billing-system'
        CONTAINER_NAME = 'restaurant-app'
        PORT = '8081'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📦 Checking out code from GitHub...'
                checkout scm
                echo '✅ Code checked out successfully'
            }
        }
        
        stage('Verify Files') {
            steps {
                echo '🔍 Verifying files...'
                sh '''
                    echo "Files in workspace:"
                    ls -la
                    echo ""
                    echo "Checking index.html..."
                    if [ -f "index.html" ]; then
                        echo "✅ index.html found ($(wc -l < index.html) lines)"
                        grep -q "RestroBilling" index.html && echo "✅ Contains Restaurant Billing content"
                    else
                        echo "❌ index.html not found!"
                        exit 1
                    fi
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                script {
                    sh """
                        docker build -t ${IMAGE_NAME}:latest .
                        docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${BUILD_NUMBER}
                    """
                }
                echo '✅ Docker image built successfully'
            }
        }
        
        stage('Test Docker Image') {
            steps {
                echo '🧪 Testing Docker image...'
                script {
                    sh """
                        # Stop and remove existing test container
                        docker stop test-container 2>/dev/null || true
                        docker rm test-container 2>/dev/null || true
                        
                        # Run test container
                        docker run -d --name test-container -p 8888:80 ${IMAGE_NAME}:latest
                        sleep 3
                        
                        # Test if app is working
                        if curl -s http://localhost:8888 | grep -q "RestroBilling"; then
                            echo "✅ Test passed! Restaurant app is working"
                        else
                            echo "❌ Test failed"
                            docker logs test-container
                            exit 1
                        fi
                        
                        # Cleanup
                        docker stop test-container
                        docker rm test-container
                    """
                }
            }
        }
        
        stage('Deploy Locally') {
            steps {
                echo '🚀 Deploying locally...'
                script {
                    sh """
                        # Stop and remove existing container
                        docker stop ${CONTAINER_NAME} 2>/dev/null || true
                        docker rm ${CONTAINER_NAME} 2>/dev/null || true
                        
                        # Run new container
                        docker run -d --name ${CONTAINER_NAME} -p ${PORT}:80 ${IMAGE_NAME}:latest
                        
                        echo "✅ Container deployed successfully"
                        echo "🌐 Access your app at: http://localhost:${PORT}"
                    """
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo '🔍 Verifying deployment...'
                script {
                    sh """
                        sleep 2
                        if curl -s http://localhost:${PORT} | grep -q "RestroBilling"; then
                            echo "✅ Restaurant Billing System is running!"
                            echo "========================================="
                            echo "🌐 Open your browser: http://localhost:${PORT}"
                            echo "========================================="
                        else
                            echo "❌ Deployment verification failed"
                            docker logs ${CONTAINER_NAME}
                            exit 1
                        fi
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo """
            ╔═══════════════════════════════════════════╗
            ║   🎉 PIPELINE SUCCESSFUL! 🎉               ║
            ╠═══════════════════════════════════════════╣
            ║   Restaurant Billing System is LIVE!      ║
            ║   URL: http://localhost:${PORT}           ║
            ╚═══════════════════════════════════════════╝
            """
        }
        failure {
            echo """
            ╔═══════════════════════════════════════════╗
            ║   ❌ PIPELINE FAILED!                     ║
            ╠═══════════════════════════════════════════╣
            ║   Check the logs above for details.       ║
            ╚═══════════════════════════════════════════╝
            """
        }
        always {
            echo '📝 Cleaning up old Docker images...'
            sh 'docker system prune -f 2>/dev/null || true'
        }
    }
}
