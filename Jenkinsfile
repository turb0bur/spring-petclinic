pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git url: 'git@github.com:turb0bur/spring-petclinic.git', credentialsId: 'github-turb0bur'
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build('app', '-f Dockerfile .')
                }
            }
        }
        stage('Run Application') {
            steps {
                script {
                    app = docker.run('app', '-p 8081:8081')
                }
            }
        }
        stage('Run Tests') {
            steps {
                script {
                    app.exec('./mvnw test')
                }
            }
        }
        stage('Stop Application') {
            steps {
                script {
                    app.stop()
                }
            }
        }
    }
}
