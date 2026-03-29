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
                sh '''
                    docker build -t restaurant-billing-system:latest .
                '''
                echo '✅ Docker image built successfully'
            }
        }

        stage('Test Docker Image') {
            steps {
                echo '🧪 Testing Docker image...'
                sh '''
                    docker stop test-container 2>/dev/null || true
                    docker rm test-container 2>/dev/null || true

                    docker run -d --name test-container -p 8888:80 restaurant-billing-system:latest
                    sleep 5

                    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888)

                    if [ "$RESPONSE" = "200" ]; then
                        echo "✅ Test passed!"
                    else
                        echo "❌ Test failed"
                        docker logs test-container
                        exit 1
                    fi

                    docker stop test-container
                    docker rm test-container
                '''
            }
        }

        stage('Deploy') {
            steps {
                echo '🚀 Deploying application...'
                sh '''
                    docker stop restaurant-app 2>/dev/null || true
                    docker rm restaurant-app 2>/dev/null || true

                    docker run -d --name restaurant-app -p 8081:80 restaurant-billing-system:latest
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '🔍 Verifying deployment...'
                sh '''
                    sleep 3
                    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081)

                    if [ "$RESPONSE" = "200" ]; then
                        echo "🎉 APP IS LIVE!"
                        echo "🌐 http://13.233.131.239:8081"
                    else
                        echo "❌ Deployment failed"
                        docker logs restaurant-app
                        exit 1
                    fi
                '''
            }
        }
    }

    post {
        success {
            echo "🎉 PIPELINE SUCCESSFUL 🚀"
        }
        failure {
            echo "❌ PIPELINE FAILED"
        }
        always {
            sh 'docker system prune -f || true'
        }
    }
}
