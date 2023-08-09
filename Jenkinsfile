properties([
  parameters([
    choice(
      name: 'DELETE_RESOURCES',
      choices: ['Yes', 'No'],
      description: 'Delete AKS Cluster and other resources after build?'
    )
  ])
])

pipeline {
    agent any

    environment {
        IMAGE = 'gfakx/gf-amazon-app'
    }

    stages {
        // Clone the Terraform code and other configurations
        stage('Clone repository') {
            steps {
                git branch: 'main', url: 'https://github.com/gfakx/fully-automated-cicd-argocd-aks.git'
            }
        }

        // Create AKS Cluster using Terraform
        stage('Create AKS Cluster') {
            steps {
                script {
                    sh "terraform init"
                    sh "terraform validate"
                    sh "terraform Plan"
                    sh "terraform apply -auto-approve"
                }
            }
        }

        // Install Argo CD on the newly created AKS cluster
        stage('Install and Configure Argo CD') {
    steps {
        script {
            // Install Argo CD
            sh "kubectl create namespace argocd"
            sh "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

            // Download Argo CD CLI
            sh "curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
            sh "sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd"

            // Expose API server
            sh "kubectl patch svc argocd-server -n argocd -p '{\"spec\": {\"type\": \"LoadBalancer\"}}'"

            // Retrieve initial password
            def initialPassword = sh(script: "argocd admin initial-password -n argocd", returnStdout: true).trim()

            // Change password (replace NEW_PASSWORD with a secure value)
            sh "argocd account update-password --current-password ${initialPassword} --new-password NEW_PASSWORD"

            // Set the current namespace to argocd
            sh "kubectl config set-context --current --namespace=argocd"
        }
    }
}

// Get Argo CD Server URL
        stage('Get Argo CD Server URL') {
            steps {
                script {
                    def externalIp = sh(script: "kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}'", returnStdout: true).trim()
                    env.ARGOCD_SERVER_URL = "https://${externalIp}:443"
                    echo "Argo CD Server URL: ${env.ARGOCD_SERVER_URL}"
                }
            }
        }



        // Update the deployment.yml file with the new Docker image tag
        stage('Update GIT') {
            steps {
                script {
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                        withCredentials([usernamePassword(credentialsId: 'gf-github-jenkins-usrpwd', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                            sh "git config user.email gfakx@outlook.com"
                            sh "git config user.name gfakx"
                            sh "cat deployment.yml"
                            sh "sed -i 's+${IMAGE}.*+${IMAGE}:${DOCKERTAG}+g' deployment.yml"
                            sh "cat deployment.yml"
                            sh "git add ."
                            sh "git commit -m 'Done by Jenkins Job changemanifest: ${env.BUILD_NUMBER}'"
                            sh "git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/${GIT_USERNAME}/argocd-amazon-manifest.git HEAD:main"
                        }
                    }
                }
            }
        }

        // Apply the Argo CD Application manifest to deploy the application
        stage('Deploy with Argo CD') {
    steps {
        script {
            withCredentials([string(credentialsId: 'argocd-admin-password', variable: 'ARGOCD_PASSWORD')]) {
            // Login to Argo CD
            sh "argocd login <argocd-server> --username admin --password NEW_PASSWORD"

            // Apply the Argo CD Application manifest
            sh "argocd app create -f argocd-app.yml"

            // Optional: Sync the application if needed
            sh "argocd app sync <app-name>"
        }
    }
}

stage('Cleanup Resources') {
          when {
            expression { params.DELETE_RESOURCES == 'Yes' }
          }
          steps {
            script {
              sh "terraform destroy -auto-approve"
              echo "Resources deleted successfully."
            }
          }
        }
    }


    post {
        always {
            // Notify the team or perform cleanup activities
            echo "Build ${currentBuild.result}: Job ${env.JOB_NAME} [${env.BUILD_NUMBER}]. Check the build details at ${env.BUILD_URL}"
        }
    }
}
