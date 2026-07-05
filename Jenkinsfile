pipeline {
    agent any

    tools {
        maven 'maven3'
        jdk 'jdk17'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKER_IMAGE = "fairozb/devsecops-app"
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_CREDENTIALS = 'docker-hub-credentials'
        SONARQUBE_SERVER = 'sonar-server'
        TOMCAT_URL = 'http://localhost:8080'
        TOMCAT_CREDENTIALS = 'tomcat-credentials'
        KUBE_CONFIG = credentials('kubeconfig')
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            steps {
                git branch: 'main', credentialsId: 'github-credentials', url: 'https://github.com/fairozb/devsecops-project.git'
            }
        }

        stage('Maven Compile') {
            steps {
                sh 'mvn clean compile'
            }
        }

        stage('Maven Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                    jacoco execPattern: '**/target/jacoco.exec'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    sh '''
                        mvn sonar:sonar \
                            -Dsonar.projectKey=devsecops-project \
                            -Dsonar.projectName="DevSecOps Project" \
                            -Dsonar.java.binaries=target/classes \
                            -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                }
            }
        }

        stage('Maven Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.war', fingerprint: true
                }
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '''
                    --scan ./ 
                    --format ALL 
                    --disableYarnAudit 
                    --prettyPrint''', odcInstallation: 'dp-check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: "${DOCKER_CREDENTIALS}", toolName: 'docker') {
                        sh """
                            docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} -f docker/Dockerfile .
                            docker build -t ${DOCKER_IMAGE}:latest -f docker/Dockerfile .
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker push ${DOCKER_IMAGE}:latest
                        """
                    }
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh """
                    trivy image --format table --output trivy-report.html \
                        --severity HIGH,CRITICAL \
                        ${DOCKER_IMAGE}:${DOCKER_TAG}
                """
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-report.html', fingerprint: true
                }
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                deploy adapters: [
                    tomcat9(
                        credentialsId: "${TOMCAT_CREDENTIALS}",
                        path: '',
                        url: "${TOMCAT_URL}"
                    )
                ],
                contextPath: '/devsecops-app',
                war: 'target/*.war'
            }
        }

        stage('Deploy to Container') {
            steps {
                sh """
                    docker stop devsecops-app || true
                    docker rm devsecops-app || true
                    docker run -d --name devsecops-app \
                        -p 8085:8080 \
                        --restart unless-stopped \
                        ${DOCKER_IMAGE}:${DOCKER_TAG}
                """
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig(caCertificate: '', clusterName: 'devsecops-cluster', contextName: '', credentialsId: 'kubeconfig', namespace: 'devsecops', restrictKubeConfigAccess: false, serverUrl: '') {
                    sh """
                        # Update image tag in deployment manifest
                        sed -i 's|IMAGE_TAG|${DOCKER_TAG}|g' kubernetes/deployment.yaml
                        sed -i 's|DOCKER_IMAGE|${DOCKER_IMAGE}|g' kubernetes/deployment.yaml
                        
                        kubectl apply -f kubernetes/namespace.yaml
                        kubectl apply -f kubernetes/deployment.yaml
                        kubectl apply -f kubernetes/service.yaml
                        
                        # Verify deployment
                        kubectl rollout status deployment/devsecops-app -n devsecops --timeout=300s
                    """
                }
            }
        }
    }

    post {
        always {
            script {
                def jobName = env.JOB_NAME
                def buildNumber = env.BUILD_NUMBER
                def pipelineStatus = currentBuild.result ?: 'SUCCESS'
                def bannerColor = pipelineStatus.toUpperCase() == 'SUCCESS' ? 'green' : 'red'

                def body = """
                    <html>
                        <body>
                            <div style="border: 4px solid ${bannerColor}; padding: 10px;">
                                <h2>${jobName} - Build #${buildNumber}</h2>
                                <div style="background-color: ${bannerColor}; padding: 10px;">
                                    <h3 style="color: white;">Pipeline Status: ${pipelineStatus.toUpperCase()}</h3>
                                </div>
                                <p>Check the <a href="${env.BUILD_URL}">console output</a>.</p>
                                <h4>Build Details:</h4>
                                <ul>
                                    <li>Job Name: ${jobName}</li>
                                    <li>Build Number: ${buildNumber}</li>
                                    <li>Build URL: ${env.BUILD_URL}</li>
                                    <li>Duration: ${currentBuild.durationString}</li>
                                </ul>
                            </div>
                        </body>
                    </html>
                """

                emailext(
                    subject: "${pipelineStatus.toUpperCase()} - ${jobName} - Build #${buildNumber}",
                    body: body,
                    to: 'fairozb11@gmail.com',
                    from: 'jenkins@devsecops.com',
                    replyTo: 'jenkins@devsecops.com',
                    mimeType: 'text/html',
                    attachmentsPattern: 'trivy-report.html'
                )
            }
            cleanWs()
        }
        success {
            echo 'Pipeline SUCCESS: All security gates passed! Application deployed successfully.'
        }
        failure {
            echo 'Pipeline FAILURE: Check the logs for details.'
        }
    }
}
