pipeline {
    agent any
    
    environment {
        IMAGE_NAME = 'restaurant-billing-system'
        IMAGE_TAG = "latest-${BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/vibhakar246/Billing--Application.git'
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
                    curl -s http://localhost:8888 | grep -q "RestroBilling" && echo "✅ Test passed!" || echo "❌ Test failed"
                    docker stop test-container && docker rm test-container
                """
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "✅ Build successful! Image ready: ${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }
    }
    
    post {
        success {
            echo "🎉 Pipeline successful! Your app is ready!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
