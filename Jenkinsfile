pipeline {
  agent any

  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "igev/numeric-app:${GIT_COMMIT}"
    applicationURL = "http://my-devsecops-demo.eastus.cloudapp.azure.com"
    applicationURI = "/increment/99"
  }

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar'
            }
        }
      
      stage('Unit Tests - JUnit and Jacoco') {
            steps {
              sh "mvn test"
            }
        }
    
//       stage('Mutation Tests - PIT') {
//             steps {
//               sh "mvn org.pitest:pitest-maven:mutationCoverage"
//             }
//             post {
//               always {
//                 pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
//               }
//             }
//         }
    
        stage('SonarQube - SAST') {
            steps {
              withSonarQubeEnv('SonarQube') { 
                sh "mvn sonar:sonar -Dsonar.projectKey=numeric-application -Dsonar.host.url=http://my-devsecops-demo.eastus.cloudapp.azure.com:9000 -Dsonar.login=56ef883d5bb9cc19ed3dfac5595ac0a29494596c"
              }
              timeout(time: 2, unit: 'MINUTES') {
                waitForQualityGate abortPipeline: true
              }
            }
        }
        
        stage('Vulnerability Scan - Docker') {
          steps {
            parallel(
              "Dependency Scan": {
                sh 'mvn dependency-check:check'
              },
              "Trivy Scan": {
                sh "bash trivy-docker-image-scan.sh"
              }
            )
          }
        }
    
        stage('Docker Build and Push') {
            steps {
              withDockerRegistry (credentialsId: "docker", url: "") {
                sh "printenv"
                sh "sudo docker build -t igev/numeric-app:${GIT_COMMIT} ."
                sh "docker push igev/numeric-app:${GIT_COMMIT}"
              }
            }
        }

        stage('Vulnerability Scan - Kubernetes') {
          steps {
            parallel(
              "Kubesec scan": {
                sh "bash kubesec-scan.sh"
              },
              "Trivy scan": {
                sh "bash trivy-k8s-scan.sh"
              }
            )            
          }
        }
    
        stage('Kubernetes Deployment - DEV') {
            steps {
              parallel(
                "Deployment": {
                  withKubeConfig (credentialsId: "kubeconfig") {
                    sh "bash k8s-deployment.sh"
                  }
                },
                "Rollout Status": {
                  withKubeConfig (credentialsId: "kubeconfig") {
                    sh "bash k8s-deployment-rollout-status.sh"
                  }
                }
              )
            }
        }

        stage('Integration Tests - DEV') {
          steps {
            script {
              try {
                withKubeConfig(credentialsId: 'kubeconfig') {
                  sh "bash integration-test.sh"
                }
              } catch (e) {
                withKubeConfig(credentialsId: 'kubeconfig') {
                  sh "kubectl -n default rollout undo deploy ${deploymentName}"
                }
                throw e
              }
            }
          }
        }

    }
  post {
    always {
      junit 'target/surefire-reports/*.xml'
      jacoco execPattern: 'target/jacoco.exec'
      dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
    }
    
//     success {
      
//     }
    
//     failure {
      
//     }
  }
}
