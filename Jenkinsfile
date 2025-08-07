pipeline {
    agent any
    parameters {
        choice(name: 'targetBranch', choices: ['main', 'dev'], description: 'Select branch to run pipeline on')
        string(name: 'component', defaultValue: 'EC2', description: 'Terraform module to deploy (e.g., EC2, VPC)')
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan? (Only works on main branch)')
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
                    // Get current Git branch
                    def currentGitBranch = sh(returnStdout: true, script: 'git rev-parse --abbrev-ref HEAD').trim()
                    env.CURRENT_BRANCH = currentGitBranch
                    env.TARGET_BRANCH = params.targetBranch
                    
                    echo "PIPELINE CONFIGURATION:"
                    echo "Current Git Branch: ${env.CURRENT_BRANCH}"
                    echo "Target Branch Selected: ${env.TARGET_BRANCH}"
                    echo "Component: ${params.component}"
                    echo "Auto Approve: ${params.autoApprove}"
                    echo "Terraform Directory: ${env.TERRAFORM_DIR}"
                    
                    // Branch validation
                    if (env.CURRENT_BRANCH != env.TARGET_BRANCH) {
                        echo ""
                        echo " WARNING: Branch Mismatch!"
                        echo "   Current Git branch: ${env.CURRENT_BRANCH}"
                        echo "   Selected target branch: ${env.TARGET_BRANCH}"
                        echo ""
                        echo "RECOMMENDATION: Switch to the correct branch or select the matching target branch."
                        echo "   - To switch branch: git checkout ${env.TARGET_BRANCH}"
                        echo "   - Or select '${env.CURRENT_BRANCH}' as target branch in pipeline parameters"
                        echo ""
                        
                        input message: "Branch mismatch detected. Do you want to continue with current branch '${env.CURRENT_BRANCH}'?",
                              ok: "Yes, continue with ${env.CURRENT_BRANCH}",
                              parameters: [
                                  text(name: 'confirmation', 
                                       description: "Type 'CONTINUE' to proceed with current branch '${env.CURRENT_BRANCH}' instead of selected target '${env.TARGET_BRANCH}'", 
                                       defaultValue: '')
                              ]
                        
                        // Override target branch with current branch after user confirmation
                        env.TARGET_BRANCH = env.CURRENT_BRANCH
                        echo "Continuing with current branch: ${env.CURRENT_BRANCH}"
                    } else {
                        echo "Branch alignment confirmed: ${env.TARGET_BRANCH}"
                    }
                    
                    echo ""
                    echo "PIPELINE EXECUTION PLAN:"
                    
                    // Warning for autoApprove on non-main branches
                    if (params.autoApprove && env.TARGET_BRANCH != 'main') {
                        echo "WARNING: autoApprove=true is set, but terraform apply will only run on 'main' branch."
                        echo "Current target branch '${env.TARGET_BRANCH}' will only execute init and plan stages."
                        echo ""
                    }
                    
                    // Info about branch behavior
                    if (env.TARGET_BRANCH == 'main') {
                        echo "MAIN BRANCH EXECUTION:"
                        echo "Terraform Init & Plan"
                        if (params.autoApprove) {
                            echo "Manual Approval (skipped - autoApprove=true)"
                        } else {
                            echo "Manual Approval (manual approval required)"
                        }
                        echo "Terraform Apply (INFRASTRUCTURE CHANGES WILL BE APPLIED)"
                    } else {
                        echo "DEVELOPMENT BRANCH EXECUTION:"
                        echo "Terraform Init & Plan"
                        echo "Manual Approval (skipped - not main branch)"
                        echo "Terraform Apply (skipped - not main branch)"
                        echo "Summary Report"
                        echo ""
                        echo "Note: To apply changes, merge to main branch and run pipeline there."
                    }
                    echo ""
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
                    expression { env.TARGET_BRANCH == 'main' }
                    not {
                        equals expected: true, actual: params.autoApprove
                    }
                }
            }
            steps {
                script {
                    def plan = readFile("${env.TERRAFORM_DIR}/tfplan.txt")
                    
                    echo "MANUAL APPROVAL REQUIRED"
                    echo "Terraform plan has been generated and is ready for review."
                    echo "ATTENTION: Approving will apply changes to your infrastructure!"
                    echo ""
                    
                    input message: "Ready to apply Terraform changes to PRODUCTION?",
                    ok: "Yes, Apply Changes",
                    submitterParameter: 'APPROVER',
                    parameters: [
                        text(name: 'Plan', 
                             description: 'Review the Terraform plan below before approving:', 
                             defaultValue: plan),
                        text(name: 'ApprovalReason', 
                             description: 'Briefly explain why you are approving this deployment:', 
                             defaultValue: '')
                    ]
                    
                    echo "Deployment approved by: ${APPROVER}"
                    if (ApprovalReason?.trim()) {
                        echo "Approval reason: ${ApprovalReason}"
                    }
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                expression { env.TARGET_BRANCH == 'main' }
            }
            steps {
                dir("${env.TERRAFORM_DIR}") {
                    echo "APPLYING TERRAFORM CHANGES ON MAIN BRANCH"
                    echo "Starting infrastructure deployment..."
                    echo ""
                    
                    sh 'terraform apply -input=false tfplan'
                    
                    echo ""
                    echo "Terraform apply completed successfully!"
                    echo "Infrastructure changes have been applied."
                }
            }
        }
        
        stage('Non-Main Branch Summary') {
            when {
                expression { env.TARGET_BRANCH != 'main' }
            }
            steps {
                script {
                    echo ""
                    echo "DEVELOPMENT BRANCH EXECUTION SUMMARY"
                    echo "════════════════════════════════════════"
                    echo "Target Branch: ${env.TARGET_BRANCH}"
                    echo "Component: ${params.component}"
                    echo ""
                    echo "COMPLETED STAGES:"
                    echo "   ├── Terraform Init"
                    echo "   ├── Terraform Plan"
                    echo "   └── Plan Validation"
                    echo ""
                    echo "SKIPPED STAGES:"
                    echo "   ├── Manual Approval (dev branch)"
                    echo "   └── Terraform Apply (dev branch)"
                    echo ""
                    echo "GENERATED FILES:"
                    echo "   ├── Plan file: ${env.TERRAFORM_DIR}/tfplan"
                    echo "   └── Plan summary: ${env.TERRAFORM_DIR}/tfplan.txt"
                    echo ""
                    echo "NEXT STEPS:"
                    echo "   1. Review the generated plan"
                    echo "   2. If satisfied, merge changes to main branch"
                    echo "   3. Run pipeline on main branch to apply changes"
                    echo "   4. Infrastructure changes will be applied to production"
                    echo ""
                    echo "TIP: Use 'terraform show tfplan' to review the detailed plan"
                    echo "════════════════════════════════════════"
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo ""
                echo "PIPELINE EXECUTION COMPLETED"
                echo "════════════════════════════════════════"
                echo "Target Branch: ${env.TARGET_BRANCH ?: 'Unknown'}"
                echo "Component: ${params.component}"
                echo "Execution Time: ${new Date().format('yyyy-MM-dd HH:mm:ss')}"
                
                if (env.TARGET_BRANCH != 'main') {
                    echo ""
                    echo "💡 PRODUCTION DEPLOYMENT GUIDE:"
                    echo "   1. Verify plan output above"
                    echo "   2. Merge changes to main branch"  
                    echo "   3. Select 'main' as target branch"
                    echo "   4. Re-run pipeline to apply changes"
                }
                echo "════════════════════════════════════════"
            }
        }
        success {
            script {
                if (env.TARGET_BRANCH == 'main') {
                    echo "SUCCESS: Infrastructure changes applied to production!"
                } else {
                    echo "SUCCESS: Development pipeline completed successfully!"
                }
            }
        }
        failure {
            script {
                echo "FAILURE: Pipeline execution failed"
                echo "Check the logs above for error details"
                echo "Contact your DevOps team if you need assistance"
            }
        }
    }
}