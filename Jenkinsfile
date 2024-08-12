pipeline {
    agent any
    
    environment {
        PATH = "${tool 'nodejs21'}/bin:$PATH"
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {
        stage('Git Checkout') {
            steps {
                git changelog: false, poll: false, url: 'https://github.com/yashaswi29/ChatApp.git'
            }
        }
        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }
        stage('Start Server') {
            steps {
                sh 'node server.js &'
            }
        }
        // stage('SonarQube Analysis') {
        //     steps {
        //         sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.url=http://localhost:9000/ -Dsonar.login=ce8e6c04cd96290b928cfa2671fc2a5c15ed369e -Dsonar.projectName=Chat-App \
        //         -Dsonar.projectKey=Chat-App '''
        //     }
        // }
        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '', odcInstallation: 'DP'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        stage('Build && Push Docker Image') {
            steps {
                script {
                        withDockerRegistry(credentialsId: '0284e0a7-42f2-40a2-bd0e-6325c538ef01', toolName: 'docker') {
                        sh "docker build -t chatapp:v1 -f docker/Dockerfile ."
                        sh "docker tag chatapp:v1 yashaswi29/chatapp:v1"
                        sh "docker push yashaswi29/chatapp:v1"
                    }
                }
            }
        }
        stage('Trigger CD Pipeline'){
            steps {
                build job: "CD_Pipeline", wait: true
            }
        }
    }
}
