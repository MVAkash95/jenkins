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
        
        stage('Branch & Parameter Validation') {
            steps {
                script {
                    echo "Current branch: ${env.BRANCH_NAME}"
                    echo "Component: ${params.component}"
                    echo "Auto Approve: ${params.autoApprove}"
                    
                    // Warning for autoApprove on non-main branches
                    if (params.autoApprove && env.BRANCH_NAME != 'main') {
                        echo "WARNING: autoApprove=true is set, but terraform apply will only run on 'main' branch."
                        echo "Current branch '${env.BRANCH_NAME}' will only execute init and plan stages."
                    }
                    
                    // Info about branch behavior
                    if (env.BRANCH_NAME == 'main') {
                        echo "Running on main branch - full pipeline (init, plan, approval, apply) will execute"
                    } else {
                        echo "Running on '${env.BRANCH_NAME}' branch - only init and plan will execute"
                    }
                }
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
                allOf {
                    branch 'main'
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
                branch 'main'
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
                not {
                    branch 'main'
                }
            }
            steps {
                script {
                    echo "SUMMARY FOR '${env.BRANCH_NAME}' BRANCH:"
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
                echo "Pipeline completed for branch: ${env.BRANCH_NAME}"
                if (env.BRANCH_NAME != 'main') {
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