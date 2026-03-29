pipeline {
    agent any

    environment {
        IMAGE_NAME = 'restaurant-billing-system'
        ECR_REPO = '343770680577.dkr.ecr.ap-south-1.amazonaws.com/restaurant-billing-system'
        AWS_REGION = 'ap-south-1'
        CONTAINER_NAME = 'restaurant-app'
        PORT = '8081'
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
                    if [ ! -f "index.html" ]; then
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
                    docker build -t $IMAGE_NAME:latest .
                '''
            }
        }

        stage('Test Docker Image') {
            steps {
                echo '🧪 Testing Docker image...'
                sh '''
                    docker stop test-container 2>/dev/null || true
                    docker rm test-container 2>/dev/null || true

                    docker run -d --name test-container -p 8888:80 $IMAGE_NAME:latest
                    sleep 5

                    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888)

                    if [ "$RESPONSE" != "200" ]; then
                        echo "❌ Test failed"
                        docker logs test-container
                        exit 1
                    fi

                    docker stop test-container
                    docker rm test-container
                '''
            }
        }

        stage('Login to ECR') {
            steps {
                echo '🔐 Logging into ECR...'
                sh '''
                    aws ecr get-login-password --region $AWS_REGION | \
                    docker login --username AWS --password-stdin 343770680577.dkr.ecr.ap-south-1.amazonaws.com
                '''
            }
        }

        stage('Push to ECR') {
            steps {
                echo '📦 Pushing image to ECR...'
                sh '''
                    docker tag $IMAGE_NAME:latest $ECR_REPO:latest
                    docker push $ECR_REPO:latest
                '''
            }
        }

        stage('Deploy from ECR') {
            steps {
                echo '🚀 Deploying from ECR...'
                sh '''
                    docker stop $CONTAINER_NAME || true
                    docker rm $CONTAINER_NAME || true

                    docker pull $ECR_REPO:latest

                    docker run -d -p $PORT:80 \
                    --name $CONTAINER_NAME \
                    $ECR_REPO:latest
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '🔍 Verifying deployment...'
                sh '''
                    sleep 5
                    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT)

                    if [ "$RESPONSE" = "200" ]; then
                        echo "🎉 APP IS LIVE!"
                        echo "🌐 http://13.233.131.239:$PORT"
                    else
                        echo "❌ Deployment failed"
                        docker logs $CONTAINER_NAME
                        exit 1
                    fi
                '''
            }
        }
    }

    post {
        success {
            echo "🎉 PRODUCTION PIPELINE SUCCESS 🚀"
        }
        failure {
            echo "❌ PIPELINE FAILED"
        }
    }
}
