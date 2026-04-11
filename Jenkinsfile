pipeline {
    agent any
    
    triggers {
        githubPush()
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📦 Checking out code...'
                git url: 'https://github.com/vibhakar246/Billing--Application.git', branch: 'main'
            }
        }
        
        stage('Build Docker') {
            steps {
                echo '🐳 Building Docker image...'
                sh 'docker build -t restaurant-billing:latest .'
            }
        }
        
        stage('Test') {
            steps {
                echo '🧪 Testing container...'
                sh '''
                    docker run -d --name test-container -p 8889:80 restaurant-billing:latest
                    sleep 3
                    curl -f http://localhost:8889 || exit 1
                    docker stop test-container
                    docker rm test-container
                '''
            }
        }
        
        stage('Deploy') {
            steps {
                echo '🚀 Deploying application...'
                sh '''
                    docker stop restaurant-app || true
                    docker rm restaurant-app || true
                    docker run -d --name restaurant-app -p 8081:80 restaurant-billing:latest
                '''
            }
        }
        
        stage('Verify') {
            steps {
                echo '✅ Deployment verified at http://localhost:8081'
            }
        }
    }
    
    post {
        success {
            echo '🎉 Pipeline succeeded!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
    }
}
