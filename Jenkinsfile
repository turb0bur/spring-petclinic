pipeline {
    agent any

    environment {
        RELEASE_VERSION = sh(script: 'git describe --tags --always', returnStdout: true).trim()
        SPRING_PROFILES_ACTIVE = "${params.ENVIRONMENT}"
        AWS_CREDENTIALS = 'aws-credentials'
        ECS_CLUSTER_NAME = "${params.AWS_REGION}-${params.ENVIRONMENT}-petclinic-cluster"
        ECS_SERVICE_NAME = "${params.AWS_REGION}-${params.ENVIRONMENT}-petclinic-service"
        AWS_ECS_TASK_EXECUTION_ROLE = "${params.AWS_REGION}-${params.ENVIRONMENT}-ecs-task-execution-role"
        AWS_ECS_TASK_DEFINITION_FAMILY = "${params.AWS_REGION}-${params.ENVIRONMENT}-petclinic-task"
        DB_CREDENTIALS_PARAM = "/${params.ENVIRONMENT}/petclinic/db/credentials"
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
       choice(
           name: 'ENVIRONMENT',
           choices: ['dev', 'prod'],
           description: 'Select the environment'
       )
       string(
           name: 'ECR_REPOSITORY',
           defaultValue: 'turb0bur/spring-petclinic',
           description: 'AWS ECR repository name'
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
        stage('Get AWS Account ID') {
            steps {
                withCredentials([
                    aws(
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        credentialsId: "${AWS_CREDENTIALS}",
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    script {
                        env.AWS_ACCOUNT_ID = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
                    }
                }
            }
        }
        stage('Set ECR URI') {
            steps {
                script {
                    env.ECR_URI = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${params.AWS_REGION}.amazonaws.com/${params.ECR_REPOSITORY}"
                }
            }
        }
        stage('Login to ECR') {
            steps {
                withCredentials([
                    aws(
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        credentialsId: "${AWS_CREDENTIALS}",
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh """
                        aws ecr get-login-password --region ${params.AWS_REGION} | docker login --username AWS --password-stdin ${env.ECR_URI}
                    """
                }
            }
        }
        stage('Tag Docker Image') {
            steps {
                sh """
                    docker tag spring-petclinic:${RELEASE_VERSION} ${env.ECR_URI}:${RELEASE_VERSION}
                """
            }
        }
        stage('Push Docker Image to ECR') {
            steps {
                sh """
                    docker push ${env.ECR_URI}:${RELEASE_VERSION}
                """
            }
        }
        stage('Deregister Current Task Definition') {
            steps {
                withCredentials([
                        aws(
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            credentialsId: "${AWS_CREDENTIALS}",
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        )
                ]) {
                    sh """
                        CURRENT_TASK_DEFINITION_FAMILY=\$(aws ecs describe-task-definition \\
                            --task-definition ${env.TASK_DEFINITION_FAMILY} \\
                            --query 'taskDefinition.taskDefinitionArn' \\
                            --output text)

                        aws ecs deregister-task-definition \\
                            --task-definition \${CURRENT_TASK_DEFINITION_FAMILY}
                    """
                }
            }
        }
        stage('Fetch DB Credentials') {
            steps {
                withCredentials([
                    aws(
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        credentialsId: "${AWS_CREDENTIALS}",
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    script {
                        def dbCredentials = sh(script: "aws ssm get-parameter --name ${env.DB_CREDENTIALS_PARAM} --with-decryption --query 'Parameter.Value' --output text", returnStdout: true).trim()
                        def dbCredentialsJson = readJSON text: dbCredentials
                        env.DB_USER = dbCredentialsJson.user
                        env.DB_PASSWORD = dbCredentialsJson.password
                        env.DB_NAME = dbCredentialsJson.name
                    }
                }
            }
        }
        stage('Register Task Definition') {
            steps {
                withCredentials([
                    aws(
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        credentialsId: "${AWS_CREDENTIALS}",
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    script {
                        def containerDefinition = """
                        [
                           {
                              "name": "${env.ECS_CONTAINER_NAME}",
                              "image": "${env.ECR_URI}:${RELEASE_VERSION}",
                              "memory": 1024,
                              "cpu": 1000,
                              "essential": true,
                              "portMappings": [
                                 {
                                    "containerPort": ${env.ECS_CONTAINER_PORT},
                                    "hostPort": 0,
                                    "protocol": "tcp"
                                 }
                              ],
                              "environment": [
                                 {
                                    "name": "DB_HOST",
                                    "value": "${env.DB_HOST}"
                                 },
                                 {
                                    "name": "DB_PORT",
                                    "value": "${env.DB_PORT}"
                                 },
                                 {
                                    "name": "SPRING_PROFILES_ACTIVE",
                                    "value": "${env.SPRING_PROFILES_ACTIVE}"
                                 }
                              ],
                              "secrets": [
                                 {
                                    "name": "DB_NAME",
                                    "valueFrom": "arn:aws:ssm:${params.AWS_REGION}:${env.AWS_ACCOUNT_ID}:parameter/${params.ENVIRONMENT}/petclinic/db/name"
                                 },
                                 {
                                    "name": "DB_USER",
                                    "valueFrom": "arn:aws:ssm:${params.AWS_REGION}:${env.AWS_ACCOUNT_ID}:parameter/${params.ENVIRONMENT}/petclinic/db/user"
                                 },
                                 {
                                    "name": "DB_PASSWORD",
                                    "valueFrom": "arn:aws:ssm:${params.AWS_REGION}:${env.AWS_ACCOUNT_ID}:parameter/${params.ENVIRONMENT}/petclinic/db/password"
                                 }
                              ]
                           }
                        ]
                        """
                        def taskDefinition = """
                        {
                            "family": "${params.AWS_REGION}-${params.ENVIRONMENT}-petclinic-task",
                            "networkMode": "bridge",
                            "requiresCompatibilities": ["EC2"],
                            "executionRoleArn": "arn:aws:iam::${env.AWS_ACCOUNT_ID}:role/${env.AWS_ECS_TASK_EXECUTION_ROLE}",
                            "taskRoleArn": "arn:aws:iam::${env.AWS_ACCOUNT_ID}:role/${env.AWS_ECS_TASK_EXECUTION_ROLE}",
                            "containerDefinitions": ${containerDefinition}
                        }
                        """
                        writeFile file: 'petclinic-task-definition.json', text: taskDefinition
                        sh 'aws ecs register-task-definition --cli-input-json file://petclinic-task-definition.json'
                    }
                }
            }
        }
        stage('Deploy to ECS') {
            steps {
                withCredentials([
                    aws(
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        credentialsId: "${AWS_CREDENTIALS}",
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh """
                        aws ecs update-service \\
                            --cluster ${env.ECS_CLUSTER_NAME} \\
                            --service ${env.ECS_SERVICE_NAME} \\
                            --force-new-deployment \\
                            --region ${params.AWS_REGION}
                    """
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
