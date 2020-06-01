pipeline {
  environment {
    SERVICE_NAME = 'mb-service-1'
    AMAZON_ECR_HOST = '693885100167.dkr.ecr.us-east-2.amazonaws.com'
    AMAZON_ECR_NAMESPACE = 'master-builder'
    AMAZON_ECR_REPOSITORY = 'sample-service-1'
    AWS_REGION = 'us-east-2'
    GIT_ORG = 'black-mirror-1'
  }
  agent {
    kubernetes {
      //cloud 'kubernetes'
      defaultContainer 'jnlp'
      label 'Jenkins-Slave'
      yaml """
kind: Pod
metadata:
  name: docker
spec:
  containers:
  - name: docker
    image: docker:latest
    imagePullPolicy: Always
    command:
    - cat
    tty: true
    env: 
      - name: DOCKER_HOST 
        value: tcp://localhost:2375
      - name: BUILD_NUMBER
        value: ${env.BUILD_NUMBER}
    volumeMounts:
      - name: aws-ecr-creds
        mountPath: /root/.aws/
  - name: dind-daemon 
    image: docker:1.12.6-dind 
    resources: 
        requests: 
            cpu: 20m 
            memory: 512Mi 
    securityContext: 
        privileged: true 
    volumeMounts: 
      - name: docker-graph-storage 
        mountPath: /var/lib/docker
  volumes:
    - name: aws-ecr-creds
      secret:
        secretName: aws-ecr-creds
    - name: docker-graph-storage 
      emptyDir: {}
"""
    }
  }
  stages {
    stage('Pull code from Git') {
      steps {
        git "https://github.com/${GIT_ORG}/${SERVICE_NAME}"
        sh '''
        sed -i "s/<h1>Version: V.*/<h1>Version: V${BUILD_NUMBER} <\\/h1>\\\\\\/g" main.js
        cat main.js
        '''
      }
    }
    stage('Build with docker') {
      steps {
        container(name: 'docker') {
          sh '''
          export DOCKER_API_VERSION=1.24
          docker run --rm -i -v ~/.aws:/root/.aws amazon/aws-cli ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AMAZON_ECR_HOST}
          docker build -t ${AMAZON_ECR_NAMESPACE}/${AMAZON_ECR_REPOSITORY} .
          docker tag ${AMAZON_ECR_NAMESPACE}/${AMAZON_ECR_REPOSITORY}:latest ${AMAZON_ECR_HOST}/${AMAZON_ECR_NAMESPACE}/${AMAZON_ECR_REPOSITORY}:v${BUILD_NUMBER}
          '''
        }
      }
    }
    stage('Unit Tests') {
      steps {
        echo "Run Unit tests here"
      }
    }
    stage('push Image to ECR') {
      steps {
        container(name: 'docker') {
          sh '''
          export DOCKER_API_VERSION=1.24
          docker push ${AMAZON_ECR_HOST}/${AMAZON_ECR_NAMESPACE}/${AMAZON_ECR_REPOSITORY}:v${BUILD_NUMBER}
          '''
        }
      }
    }
    stage('update Image tag on deploy repo'){
      steps {
        withCredentials([usernamePassword(credentialsId: 'jenkins-github', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
            sh """
            git clone https://github.com/${GIT_ORG}/${SERVICE_NAME}-deploy.git
            git config --global user.email "you@example.com"
            git config --global user.name "${GIT_USERNAME}"
            cd ${SERVICE_NAME}-deploy
            sed -i "s/- image: .*/- image: ${AMAZON_ECR_HOST}\\/${AMAZON_ECR_NAMESPACE}\\/${AMAZON_ECR_REPOSITORY}:v${BUILD_NUMBER}/g" pre-prod/deployment.yml
            sed -i "s/- image: .*/- image: ${AMAZON_ECR_HOST}\\/${AMAZON_ECR_NAMESPACE}\\/${AMAZON_ECR_REPOSITORY}:v${BUILD_NUMBER}/g" prod/deployment.yml
            git add pre-prod/deployment.yml
            git add prod/deployment.yml
            git commit -m "Updating image tag to v${BUILD_NUMBER}"
            git push https://${GIT_USERNAME}:${URLEncoder.encode(GIT_PASSWORD, "UTF-8")}@github.com/${GIT_ORG}/${SERVICE_NAME}-deploy.git
            """
        }
      }
    }
  }
}