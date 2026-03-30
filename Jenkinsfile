pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '343770680577'
        AWS_REGION = 'ap-south-1'
        REPOSITORY_NAME = 'restaurant-billing-system'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG = "latest"
        CONTAINER_NAME = "restaurant-app"
        PORT = "8081"
    }

    stages {

        stage('Checkout') {
            steps {
                echo '📦 Checking out code...'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                timeout(time: 5, unit: 'MINUTES') {
                    sh 'docker build -t $REPOSITORY_NAME:$IMAGE_TAG .'
                }
            }
        }

        stage('Test Docker Image') {
            steps {
                echo '🧪 Testing Docker container...'
                sh '''
                    docker stop test-container || true
                    docker rm test-container || true

                    docker run -d --name test-container -p 8888:80 $REPOSITORY_NAME:$IMAGE_TAG

                    sleep 5

                    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://172.17.0.1:8888)

                    if [ "$RESPONSE" = "200" ]; then
                        echo "✅ Test Passed"
                    else
                        echo "❌ Test Failed"
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
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    sh '''
                        aws ecr get-login-password --region $AWS_REGION | \
                        docker login --username AWS --password-stdin $ECR_REGISTRY
                    '''
                }
            }
        }

        stage('Push to ECR') {
            steps {
                echo '📤 Pushing image...'
                sh '''
                    docker tag $REPOSITORY_NAME:$IMAGE_TAG $ECR_REGISTRY/$REPOSITORY_NAME:$IMAGE_TAG
                    docker push $ECR_REGISTRY/$REPOSITORY_NAME:$IMAGE_TAG
                '''
            }
        }

        stage('Deploy') {
            steps {
                echo '🚀 Deploying application...'
                sh '''
                    docker stop $CONTAINER_NAME || true
                    docker rm $CONTAINER_NAME || true

                    docker pull $ECR_REGISTRY/$REPOSITORY_NAME:$IMAGE_TAG

                    docker run -d \
                        --name $CONTAINER_NAME \
                        -p $PORT:80 \
                        $ECR_REGISTRY/$REPOSITORY_NAME:$IMAGE_TAG
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '🔍 Verifying deployment...'
                sh '''
                    sleep 5

                    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://172.17.0.1:$PORT)

                    if [ "$RESPONSE" = "200" ]; then
                        echo "✅ Deployment Verified"
                    else
                        echo "❌ Deployment Failed"
                        exit 1
                    fi
                '''
            }
        }
    }

    post {
        success {
            echo "🎉 PIPELINE SUCCESS 🚀"
        }
        failure {
            echo "❌ PIPELINE FAILED"
        }
    }
}
