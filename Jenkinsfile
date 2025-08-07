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
        TERRAFORM_DIR         = "terraform/module/${params.component.toLowerCase()}"
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Branch & Parameter Validation') {
            steps {
                script {
                    // Get branch name from Git
                    def branchName = sh(returnStdout: true, script: 'git rev-parse --abbrev-ref HEAD').trim()
                    env.CURRENT_BRANCH = branchName
                    
                    echo "Current branch: ${env.CURRENT_BRANCH}"
                    echo "Component: ${params.component}"
                    echo "Auto Approve: ${params.autoApprove}"
                    echo "Terraform directory: ${env.TERRAFORM_DIR}"
                    
                    // Warning for autoApprove on non-main branches
                    if (params.autoApprove && env.CURRENT_BRANCH != 'main') {
                        echo "WARNING: autoApprove=true is set, but terraform apply will only run on 'main' branch."
                        echo "Current branch '${env.CURRENT_BRANCH}' will only execute init and plan stages."
                    }
                    
                    // Info about branch behavior
                    if (env.CURRENT_BRANCH == 'main') {
                        echo "Running on main branch - full pipeline (init, plan, approval, apply) will execute"
                    } else {
                        echo "Running on '${env.CURRENT_BRANCH}' branch - only init and plan will execute"
                    }
                }
            }
        }
        
        stage('Terraform Init & Plan') {
            steps {
                script {
                    // Check if Terraform directory exists
                    def dirExists = sh(returnStatus: true, script: "test -d ${env.TERRAFORM_DIR}") == 0
                    if (!dirExists) {
                        error("Terraform directory '${env.TERRAFORM_DIR}' does not exist. Please check the component name and directory structure.")
                    }
                    
                    // Check if .tf files exist
                    def tfFilesExist = sh(returnStatus: true, script: "find ${env.TERRAFORM_DIR} -name '*.tf' | head -1") == 0
                    if (!tfFilesExist) {
                        error("No Terraform configuration files (.tf) found in '${env.TERRAFORM_DIR}'. Please ensure the directory contains Terraform files.")
                    }
                }
                
                dir("${env.TERRAFORM_DIR}") {
                    sh 'terraform init'
                    sh 'terraform plan -var-file=../../terraform.tfvars -out=tfplan'
                    sh 'terraform show -no-color tfplan > tfplan.txt'
                }
            }
        }
        
        stage('Manual Approval') {
            when {
                allOf {
                    expression { env.CURRENT_BRANCH == 'main' }
                    not {
                        equals expected: true, actual: params.autoApprove
                    }
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
                expression { env.CURRENT_BRANCH == 'main' }
            }
            steps {
                dir("${env.TERRAFORM_DIR}") {
                    echo "Applying Terraform changes on main branch..."
                    sh 'terraform apply -input=false tfplan'
                }
            }
        }
        
        stage('Non-Main Branch Summary') {
            when {
                expression { env.CURRENT_BRANCH != 'main' }
            }
            steps {
                script {
                    echo "SUMMARY FOR '${env.CURRENT_BRANCH}' BRANCH:"
                    echo "Terraform init completed successfully"
                    echo "Terraform plan completed successfully"
                    echo "Terraform apply skipped (only runs on main branch)"
                    echo "Plan file generated: ${env.TERRAFORM_DIR}/tfplan"
                    echo "Plan summary saved: ${env.TERRAFORM_DIR}/tfplan.txt"
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "Pipeline completed for branch: ${env.CURRENT_BRANCH}"
                if (env.CURRENT_BRANCH != 'main') {
                    echo "To apply these changes, merge to main branch and run the pipeline there"
                }
            }
        }
        success {
            echo "Pipeline executed successfully"
        }
        failure {
            echo "Pipeline failed"
        }
    }
}