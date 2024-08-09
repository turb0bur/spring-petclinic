pipeline {
    agent any

    environment {
        RELEASE_VERSION = sh(script: 'git describe --tags --always', returnStdout: true).trim()
        SPRING_PROFILES_ACTIVE = 'testing' // Set the profile for Jenkins pipeline
    }

    parameters {
        booleanParam(
            name: 'RUN_TESTS',
            defaultValue: false,
            description: 'Should tests be run'
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
        stage('Run Application') {
            steps {
                sh 'docker run -d --name spring-petclinic -p 8081:8081 -e SPRING_PROFILES_ACTIVE=${SPRING_PROFILES_ACTIVE} spring-petclinic:${RELEASE_VERSION}'
            }
        }
    }
    post {
        always {
            script {
                sh '''
                        CONTAINER_ID=$(docker ps -aq -f name=spring-petclinic)
                        if [ -n "$CONTAINER_ID" ]; then
                            docker stop spring-petclinic || true
                            docker rm -f spring-petclinic
                        fi
                    '''
            }
        }
    }
}
