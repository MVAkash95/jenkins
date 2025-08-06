pipeline {
    agent any

    parameters {
        choice(name: 'component', choices: ['root'], description: 'Terraform module to deploy (use "root" for full infra)')
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION    = 'us-east-1'
        TERRAFORM_DIR         = "${params.component == 'root' ? 'terraform' : "terraform/modules/${params.component}"}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.BRANCH_NAME = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    echo "Git Branch: ${env.BRANCH_NAME}"
                    echo "Terraform Working Dir: ${env.TERRAFORM_DIR}"
                }
            }
        }

        stage('Terraform Init & Plan') {
            steps {
                dir("${env.TERRAFORM_DIR}") {
                    sh 'terraform init'
                    script {
                        if (params.component == 'root') {
                            sh 'terraform plan -var-file=terraform.tfvars -out=tfplan'
                        } else {
                            sh 'terraform plan -out=tfplan'
                        }
                        sh 'terraform show -no-color tfplan > tfplan.txt'
                    }
                }
            }
        }

        stage('Manual Approval') {
            when {
                allOf {
                    not { equals expected: true, actual: params.autoApprove }
                    expression { return env.BRANCH_NAME == 'main' }
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
            when {
                allOf {
                    expression { return env.BRANCH_NAME == 'main' }
                    anyOf {
                        equals expected: true, actual: params.autoApprove
                        not { equals expected: true, actual: params.autoApprove }
                    }
                }
            }
            steps {
                dir("${env.TERRAFORM_DIR}") {
                    sh 'terraform apply -input=false tfplan'
                }
            }
        }
    }
}
