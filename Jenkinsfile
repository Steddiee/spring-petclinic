pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {
        stage('Compile') {
            steps {
                sh 'chmod +x mvnw'
                sh './mvnw clean compile'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'chmod +x mvnw'
                sh './mvnw test'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'chmod +x mvnw'
                sh './mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=spring-petclinic:latest'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check the console output.'
        }
    }
}
