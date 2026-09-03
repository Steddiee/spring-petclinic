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
                script {
                    // Check if credentials exist
                    def hasJfrog = false
                    try {
                        withCredentials([
                            string(credentialsId: 'jfrog-access-token', variable: 'JFROG_ACCESS_TOKEN'),
                            string(credentialsId: 'jfrog-url', variable: 'JFROG_URL')
                        ]) {
                            if (env.JFROG_ACCESS_TOKEN && env.JFROG_URL) {
                                hasJfrog = true
                                echo "JFrog credentials detected. Configuring JFrog CLI..."
                                sh '''
                                    jf c add cloud-server --url="${JFROG_URL}" --access-token="${JFROG_ACCESS_TOKEN}" --overwrite=true
                                    jf mvnc --repo-resolve-releases=maven-virtual --repo-resolve-snapshots=maven-virtual
                                '''
                            }
                        }
                    } catch (Exception e) {
                        echo "JFrog credentials not found or invalid in Jenkins. Falling back to standard Maven wrapper."
                    }

                    // Save state for subsequent stages
                    env.USE_JFROG = hasJfrog ? "true" : "false"

                    // Execute compile step

                    if (env.USE_JFROG == "true") {
                        sh 'jf mvn clean compile'
                    } else {
                        sh 'chmod +x mvnw'
                        sh './mvnw clean compile'
                    }
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    if (env.USE_JFROG == "true") {
                        sh 'jf mvn test'
                    } else {
                        sh 'chmod +x mvnw'
                        sh './mvnw test'
                    }
                }
            }
        }

        stage('Package Application') {
            steps {
                script {
                    if (env.USE_JFROG == "true") {
                        sh 'jf mvn package -DskipTests'
                    } else {
                        sh 'chmod +x mvnw'
                        sh './mvnw package -DskipTests'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t spring-petclinic:latest .'
            }
        }

        stage('Export Docker Image Archive') {
            steps {
                sh 'docker save -o spring-petclinic-image.tar spring-petclinic:latest'
                archiveArtifacts artifacts: 'spring-petclinic-image.tar', fingerprint: true
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
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
