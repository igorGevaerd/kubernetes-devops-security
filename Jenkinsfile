pipeline {
  agent any

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
            post {
              always {
                junit 'target/surefire-reports/*.xml'
                jacoco execPattern: 'target/jacoco.exec'
              }
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
    
        stage('Docker Build and Push') {
            steps {
              withDockerRegistry (credentialsId: "docker", url: "") {
                sh "printenv"
                sh "docker build -t igev/numeric-app:${GIT_COMMIT} ."
                sh "docker push igev/numeric-app:${GIT_COMMIT}"
              }
            }
        }
    
        stage('Kubernetes Deployment - DEV') {
            steps {
              withKubeConfig (credentialsId: "kubeconfig") {
                sh "sed -i 's#replace#igev/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
                sh "kubectl apply -f k8s_deployment_service.yaml"
              }
            }
        }
    }
}
