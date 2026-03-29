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

                    if [ -f "index.html" ]; then
                        echo "✅ index.html found"
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
                sh """
                    docker build -t ${IMAGE_NAME}:latest .
                    docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${BUILD_NUMBER}
                """
                echo '✅ Docker image built successfully'
            }
        }
        
        stage('Test Docker Image') {
            steps {
                echo '🧪 Testing Docker image...'
                sh """
                    docker stop test-container 2>/dev/null || true
                    docker rm test-container 2>/dev/null || true

                    docker run -d --name test-container -p 8888:80 ${IMAGE_NAME}:latest
                    sleep 3

                    # SIMPLE TEST (NO STRING MATCH)
                    if curl -s http://localhost:8888 > /dev/null; then
                        echo "✅ Test passed! App is responding"
                    else
                        echo "❌ Test failed"
                        docker logs test-container
                        exit 1
                    fi

                    docker stop test-container
                    docker rm test-container
                """
            }
        }
        
        stage('Deploy Locally') {
            steps {
                echo '🚀 Deploying locally...'
                sh """
                    docker stop ${CONTAINER_NAME} 2>/dev/null || true
                    docker rm ${CONTAINER_NAME} 2>/dev/null || true

                    docker run -d --name ${CONTAINER_NAME} -p ${PORT}:80 ${IMAGE_NAME}:latest

                    echo "✅ Deployment done"
                """
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo '🔍 Verifying deployment...'
                sh """
                    sleep 2

                    if curl -s http://localhost:${PORT} > /dev/null; then
                        echo "✅ App is LIVE!"
                        echo "🌐 http://13.233.131.239:${PORT}"
                    else
                        echo "❌ Deployment failed"
                        docker logs ${CONTAINER_NAME}
                        exit 1
                    fi
                """
            }
        }
    }
    
    post {
        success {
            echo "🎉 PIPELINE SUCCESSFUL - APP LIVE 🚀"
        }
        failure {
            echo "❌ PIPELINE FAILED"
        }
        always {
            sh 'docker system prune -f || true'
        }
    }
}
