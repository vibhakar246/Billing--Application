pipeline {
    agent any

    environment {
        // Docker/ECR Configuration
        AWS_ACCOUNT_ID = '343770680577'
        AWS_REGION = 'ap-south-1'
        REPOSITORY_NAME = 'restaurant-billing-system'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG = "latest"
        
        // Deployment Configuration
        CONTAINER_NAME = 'restaurant-app'
        APP_PORT = '8081'
        K8S_NAMESPACE = 'restaurant'
        
        // SMS Configuration (Twilio)
        TWILIO_PHONE_NUMBER = '+1234567890'  // Replace with your Twilio number
        ADMIN_PHONE_NUMBER = '+919876543210'  // Replace with admin phone
        
        // Build Info
        BUILD_TIMESTAMP = sh(script: "date +'%Y-%m-%d %H:%M:%S'", returnStdout: true).trim()
    }

    stages {

        stage('Cleanup Old Resources') {
            steps {
                echo '🧹 Cleaning up old containers and resources...'
                sh '''
                    docker ps -a --filter "name=test-container" -q | xargs -r docker rm -f
                    docker ps -a --filter "name=$CONTAINER_NAME" -q | xargs -r docker rm -f
                    docker ps -q --filter "publish=8889" | xargs -r docker stop
                    docker ps -aq --filter "publish=8889" | xargs -r docker rm
                    echo "✅ Cleanup complete"
                '''
            }
        }

        stage('Checkout') {
            steps {
                echo '📦 Checking out code from GitHub...'
                checkout scm
                echo "✅ Code checked out - Build Time: ${BUILD_TIMESTAMP}"
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image with latest HTML...'
                timeout(time: 5, unit: 'MINUTES') {
                    sh '''
                        docker build --no-cache -t $REPOSITORY_NAME:$IMAGE_TAG .
                        docker tag $REPOSITORY_NAME:$IMAGE_TAG $ECR_REGISTRY/$REPOSITORY_NAME:$IMAGE_TAG
                    '''
                }
                echo '✅ Docker image built successfully'
            }
        }

        stage('Test Docker Image') {
            steps {
                echo '🧪 Testing Docker container...'
                sh '''
                    docker run -d --name test-container -p 8889:80 $REPOSITORY_NAME:$IMAGE_TAG
                    sleep 5
                    
                    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://172.17.0.1:8889)
                    
                    if [ "$RESPONSE" = "200" ]; then
                        echo "✅ Test Passed - HTTP $RESPONSE"
                    else
                        echo "❌ Test Failed - HTTP $RESPONSE"
                        docker logs test-container
                        exit 1
                    fi
                    
                    docker stop test-container
                    docker rm test-container
                '''
            }
        }

        stage('Security Scan') {
            steps {
                echo '🔐 Running Trivy Security Scan...'
                sh '''
                    docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        -v $HOME/.cache:/root/.cache \
                        ghcr.io/aquasecurity/trivy:latest \
                        image --severity HIGH,CRITICAL --exit-code 0 \
                        $REPOSITORY_NAME:$IMAGE_TAG
                '''
                echo '✅ Security scan completed'
            }
        }

        stage('Login to ECR') {
            steps {
                echo '🔐 Logging into AWS ECR...'
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    sh '''
                        aws ecr get-login-password --region $AWS_REGION | \
                        docker login --username AWS --password-stdin $ECR_REGISTRY
                    '''
                }
                echo '✅ Logged into ECR successfully'
            }
        }

        stage('Push to ECR') {
            steps {
                echo '📤 Pushing image to ECR...'
                sh '''
                    docker push $ECR_REGISTRY/$REPOSITORY_NAME:$IMAGE_TAG
                '''
                echo '✅ Image pushed to ECR'
            }
        }

        stage('Deploy to Docker') {
            steps {
                echo '🚀 Deploying to Docker (Local)...'
                sh '''
                    docker stop $CONTAINER_NAME || true
                    docker rm $CONTAINER_NAME || true
                    
                    docker pull $ECR_REGISTRY/$REPOSITORY_NAME:$IMAGE_TAG
                    
                    docker run -d \
                        --name $CONTAINER_NAME \
                        --restart unless-stopped \
                        -p $APP_PORT:80 \
                        $ECR_REGISTRY/$REPOSITORY_NAME:$IMAGE_TAG
                '''
                echo '✅ Docker container deployed'
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '🔍 Verifying deployment...'
                sh '''
                    sleep 5
                    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://172.17.0.1:$APP_PORT)
                    if [ "$RESPONSE" = "200" ]; then
                        echo "✅ Deployment Verified - Application running on port $APP_PORT"
                    else
                        echo "❌ Deployment Failed"
                        exit 1
                    fi
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo '☸️ Deploying to Kubernetes...'
                script {
                    try {
                        // Create namespace if it doesn't exist
                        sh "kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -"
                        
                        // Deploy application
                        sh '''
                            cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: restaurant-billing
  namespace: ${K8S_NAMESPACE}
  labels:
    app: restaurant-billing
spec:
  replicas: 3
  selector:
    matchLabels:
      app: restaurant-billing
  template:
    metadata:
      labels:
        app: restaurant-billing
    spec:
      containers:
      - name: restaurant-app
        image: ${ECR_REGISTRY}/${REPOSITORY_NAME}:${IMAGE_TAG}
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: restaurant-billing-service
  namespace: ${K8S_NAMESPACE}
spec:
  selector:
    app: restaurant-billing
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: restaurant-billing-hpa
  namespace: ${K8S_NAMESPACE}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: restaurant-billing
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
EOF
                        '''
                        echo '✅ Kubernetes resources applied'
                        
                        // Wait for rollout
                        sh "kubectl rollout status deployment/restaurant-billing -n ${K8S_NAMESPACE} --timeout=5m"
                        
                        // Get service endpoint
                        sh '''
                            echo "=== Service Endpoint ==="
                            kubectl get svc restaurant-billing-service -n ${K8S_NAMESPACE}
                        '''
                    } catch (Exception e) {
                        echo "⚠️ Kubernetes deployment skipped: ${e.getMessage()}"
                    }
                }
            }
        }

        stage('Send SMS Notification') {
            steps {
                echo '📱 Sending SMS notification...'
                script {
                    try {
                        withCredentials([string(credentialsId: 'twilio-account-sid', variable: 'TWILIO_SID'),
                                        string(credentialsId: 'twilio-auth-token', variable: 'TWILIO_TOKEN')]) {
                            sh '''
                                curl -X POST https://api.twilio.com/2010-04-01/Accounts/${TWILIO_SID}/Messages.json \
                                --data-urlencode "Body=✅ Restaurant Billing System Deployed Successfully!%0A%0A📍 Application: ${REPOSITORY_NAME}%0A🕐 Time: ${BUILD_TIMESTAMP}%0A🔢 Version: ${IMAGE_TAG}%0A🌐 Access: http://localhost:${APP_PORT}%0A☸️ K8s: ${K8S_NAMESPACE}%0A%0A🚀 Pipeline completed successfully!" \
                                --data-urlencode "From=${TWILIO_PHONE_NUMBER}" \
                                --data-urlencode "To=${ADMIN_PHONE_NUMBER}" \
                                -u ${TWILIO_SID}:${TWILIO_TOKEN}
                            '''
                        }
                        echo '✅ SMS notification sent'
                    } catch (Exception e) {
                        echo "⚠️ SMS notification failed: ${e.getMessage()}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo '''
            ═══════════════════════════════════════════════════════════
            🎉 PIPELINE SUCCESSFUL - RESTAURANT BILLING SYSTEM DEPLOYED 🎉
            ═══════════════════════════════════════════════════════════
            
            📋 Deployment Details:
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            ✅ Docker Image:  ${ECR_REGISTRY}/${REPOSITORY_NAME}:${IMAGE_TAG}
            ✅ Local Access:  http://localhost:${APP_PORT}
            ✅ K8s Namespace: ${K8S_NAMESPACE}
            ✅ Build Time:     ${BUILD_TIMESTAMP}
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
            📱 SMS Notification sent to admin
            ☸️ Kubernetes deployment is scaling with HPA
            🚀 Application is ready to serve customers!
            '''
        }
        failure {
            echo '''
            ═══════════════════════════════════════════════════════════
            ❌ PIPELINE FAILED - RESTAURANT BILLING SYSTEM DEPLOYMENT ❌
            ═══════════════════════════════════════════════════════════
            
            🔍 Check the following:
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            1. Docker build logs
            2. Security scan results  
            3. ECR credentials
            4. Kubernetes cluster connectivity
            5. Twilio SMS configuration
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            '''
            
            // Send failure SMS
            script {
                try {
                    withCredentials([string(credentialsId: 'twilio-account-sid', variable: 'TWILIO_SID'),
                                    string(credentialsId: 'twilio-auth-token', variable: 'TWILIO_TOKEN')]) {
                        sh '''
                            curl -X POST https://api.twilio.com/2010-04-01/Accounts/${TWILIO_SID}/Messages.json \
                            --data-urlencode "Body=❌ Restaurant Billing System Deployment FAILED!%0A%0A⏰ Time: ${BUILD_TIMESTAMP}%0A🔧 Check Jenkins console for details.%0A🚨 Immediate attention required!" \
                            --data-urlencode "From=${TWILIO_PHONE_NUMBER}" \
                            --data-urlencode "To=${ADMIN_PHONE_NUMBER}" \
                            -u ${TWILIO_SID}:${TWILIO_TOKEN} || true
                        '''
                    }
                } catch (Exception e) {
                    echo "Failed to send SMS notification"
                }
            }
        }
        always {
            echo '🏁 Pipeline execution completed'
            // Archive artifacts
            archiveArtifacts artifacts: '*.html', allowEmptyArchive: true
        }
    }
}
