pipeline {
    agent any

    environment {
        TF_VAR_aws_access_key = credentials('aws-access-key')   // Jenkins credentials
        TF_VAR_aws_secret_key = credentials('aws-secret-key')
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform plan -var-file=terraform.tfvars'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -var-file=terraform.tfvars -auto-approve'
                }
            }
        }
    }

    post {
        failure {
            echo "Terraform deployment failed."
        }
        success {
            echo "Terraform deployment succeeded."
        }
    }
}
