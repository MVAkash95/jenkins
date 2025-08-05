pipeline {
    agent any

    parameters {
        string(name: 'component', defaultValue: 'EC2', description: 'Terraform module to deploy (e.g., EC2, VPC)')
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION    = 'us-east-1'
        TERRAFORM_DIR         = "terraform/${params.component}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init & Plan') {
            steps {
                dir("${env.TERRAFORM_DIR}") {
                    sh 'terraform init'
                    sh 'terraform plan -var-file=../terraform.tfvars -out=tfplan'
                    sh 'terraform show -no-color tfplan > tfplan.txt'
                }
            }
        }

        stage('Manual Approval') {
            when {
                not {
                    equals expected: true, actual: params.autoApprove
                }
            }
            steps {
                script {
                    def plan = readFile("${env.TERRAFORM_DIR}/tfplan.txt")
                    input message: "Do you want to apply the plan?",
                    parameters: [
                        text(name: 'Plan', description: 'Review the plan before applying', defaultValue: plan)
                    ]
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir("${env.TERRAFORM_DIR}") {
                    sh 'terraform apply -input=false tfplan'
                }
            }
        }
    }
}
