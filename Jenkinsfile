pipeline {
    agent any

    environment {
        RELEASE_VERSION = sh(script: 'git describe --tags --always', returnStdout: true).trim()
        SPRING_PROFILES_ACTIVE = 'testing'
        AWS_CREDENTIALS = 'aws-credentials'
    }

    parameters {
        booleanParam(
            name: 'RUN_TESTS',
            defaultValue: false,
            description: 'Should tests be run'
       )
       string(
           name: 'AWS_REGION',
           defaultValue: 'eu-central-1',
           description: 'AWS region'
       )
       string(
           name: 'ECR_REPOSITORY',
           defaultValue: 'turb0bur/spring-petclinic',
           description: 'AWS ECR repository name'
       )
       string(
           name: 'AWS_ACCOUNT_ID',
           defaultValue: '123456789000',
           description: 'AWS account ID'
       )
    }

    stages {
        stage('Checkout') {
            steps {
                git(
                    url: 'git@github.com:turb0bur/spring-petclinic.git',
                    credentialsId: 'github-turb0bur',
                    branch: 'main'
                )
            }
        }
        stage('Test Application') {
            when {
                expression {
                    params.RUN_TESTS == true
                }
            }
            steps {
                sh 'mvn clean test -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE}'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t spring-petclinic:${RELEASE_VERSION} -f Dockerfile .'
            }
        }
        stage('Set ECR URI') {
            steps {
                script {
                    env.ECR_URI = "${params.AWS_ACCOUNT_ID}.dkr.ecr.${params.AWS_REGION}.amazonaws.com/${params.ECR_REPOSITORY}"
                }
            }
        }
        stage('Login to ECR') {
            steps {
                withAWS(credentials: "${env.AWS_CREDENTIALS}", region: "${params.AWS_REGION}") {
                    sh """
                        aws ecr get-login-password --region ${params.AWS_REGION} | docker login --username AWS --password-stdin ${env.ECR_URI}
                    """
                }
            }
        }
        stage('Tag Docker Image') {
            steps {
                sh 'docker tag spring-petclinic:${RELEASE_VERSION} ${env.ECR_URI}:${RELEASE_VERSION}'
            }
        }
        stage('Push Docker Image to ECR') {
            steps {
                sh 'docker push ${env.ECR_URI}:${RELEASE_VERSION}'
            }
        }
    }
}
