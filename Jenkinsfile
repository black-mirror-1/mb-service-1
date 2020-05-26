pipeline {
  agent {
    kubernetes {
      //cloud 'kubernetes'
      defaultContainer 'jnlp'
      label 'mb-service-1'
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
        git 'https://github.com/black-mirror-1/mb-service-1'
      }
      
    }
    stage('Build with docker') {
      steps {
        container(name: 'docker') {
          sh '''
          export DOCKER_API_VERSION=1.24
          docker version
          docker run --rm -i -v ~/.aws:/root/.aws amazon/aws-cli ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 693885100167.dkr.ecr.us-east-2.amazonaws.com
          docker build -t master-builder/sample-service-1 .
          docker tag master-builder/sample-service-1:latest 693885100167.dkr.ecr.us-east-2.amazonaws.com/master-builder/sample-service-1:${env.GIT_COMMIT}
          '''
        }
      }
    }
    stage('push Image to ECR') {
      steps {
        container(name: 'docker') {
          sh '''
          export DOCKER_API_VERSION=1.24
          docker version
          docker push 693885100167.dkr.ecr.us-east-2.amazonaws.com/master-builder/sample-service-1:${env.GIT_COMMIT}
          '''
        }
      }
    }
  }
}