pipeline {
    agent any
    parameters {
        string(name: 'component', defaultValue: 'ec2', description: 'Terraform module to deploy (e.g., ec2, vpc)')
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
        
        stage('Branch Detection & Validation') {
            steps {
                script {
                    // Multiple methods to detect current branch
                    def currentBranch = 'unknown'
                    
                    // Method 1: Jenkins environment variable
                    if (env.GIT_BRANCH) {
                        currentBranch = env.GIT_BRANCH.replace('origin/', '')
                        echo "Branch detected from Jenkins GIT_BRANCH: ${currentBranch}"
                    } else {
                        // Method 2: Git command
                        try {
                            currentBranch = sh(returnStdout: true, script: 'git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main"').trim()
                            if (currentBranch == 'HEAD' || currentBranch == '') {
                                currentBranch = 'main' // fallback
                            }
                            echo "Branch detected using git command: ${currentBranch}"
                        } catch (Exception e) {
                            currentBranch = 'main' // safe fallback
                            echo " Using fallback branch: ${currentBranch}"
                        }
                    }
                    
                    env.CURRENT_BRANCH = currentBranch
                    
                    echo ""
                    echo "PIPELINE CONFIGURATION:"
                    echo "Current Branch: ${env.CURRENT_BRANCH}"
                    echo "Component: ${params.component}"
                    echo "Auto Approve: ${params.autoApprove}"
                    echo "Terraform Directory: ${env.TERRAFORM_DIR}"
                    echo ""
                    
                    // Show execution plan based on branch
                    if (env.CURRENT_BRANCH == 'main') {
                        echo "MAIN BRANCH EXECUTION PLAN:"
                        echo "   Terraform Init & Plan"
                        if (params.autoApprove) {
                            echo "   Manual Approval (skipped - autoApprove=true)"
                        } else {
                            echo "   Manual Approval (manual approval required)"
                        }
                        echo "  Terraform Apply ( PRODUCTION CHANGES )"
                        echo ""
                        echo "WARNING: This will modify your production infrastructure!"
                    } else {
                        echo "DEVELOPMENT BRANCH EXECUTION PLAN:"
                        echo "   Terraform Init & Plan"  
                        echo "   Manual Approval (skipped - not main branch)"
                        echo "   Terraform Apply (skipped - not main branch)"
                        echo "    Summary Report"
                        echo ""
                        echo " Note: To apply changes, merge to main branch and run pipeline there."
                    }
                    
                    // Warning for autoApprove on non-main branches
                    if (params.autoApprove && env.CURRENT_BRANCH != 'main') {
                        echo ""
                        echo " WARNING: autoApprove=true is set, but terraform apply only runs on main branch."
                        echo "    Current branch '${env.CURRENT_BRANCH}' will only execute init and plan stages."
                    }
                    
                    echo "════════════════════════════════════════"
                }
            }
        }
        
        stage('Terraform Init & Plan') {
            steps {
                script {
                    // Check if Terraform directory exists
                    def dirExists = sh(returnStatus: true, script: "test -d ${env.TERRAFORM_DIR}") == 0
                    if (!dirExists) {
                        echo "Directory '${env.TERRAFORM_DIR}' not found"
                        echo "Available directories in terraform/module/:"
                        sh 'find terraform/module -type d -name "*" | head -10'
                        error("Terraform directory '${env.TERRAFORM_DIR}' does not exist. Please check the component name.")
                    }
                    
                    // Check if .tf files exist
                    def tfFilesExist = sh(returnStatus: true, script: "find ${env.TERRAFORM_DIR} -name '*.tf' | head -1") == 0
                    if (!tfFilesExist) {
                        echo " No .tf files found in '${env.TERRAFORM_DIR}'"
                        sh "ls -la ${env.TERRAFORM_DIR}/ || echo 'Directory listing failed'"
                        error("No Terraform configuration files (.tf) found in '${env.TERRAFORM_DIR}'.")
                    }
                    
                    echo "Terraform directory and files validated"
                }
                
                dir("${env.TERRAFORM_DIR}") {
                    echo "🔧 Initializing Terraform..."
                    sh 'terraform init'
                    
                    echo "📋 Generating Terraform plan..."
                    // Check if terraform.tfvars exists at root level
                    script {
                        def varsFileExists = sh(returnStatus: true, script: "test -f ../../terraform.tfvars") == 0
                        if (varsFileExists) {
                            sh 'terraform plan -var-file=../../terraform.tfvars -out=tfplan'
                        } else {
                            echo " terraform.tfvars not found at root, running plan without var file"
                            sh 'terraform plan -out=tfplan'
                        }
                    }
                    sh 'terraform show -no-color tfplan > tfplan.txt'
                    
                    echo " Terraform plan generated successfully"
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
                    
                    echo " MANUAL APPROVAL REQUIRED"
                    echo "Terraform plan has been generated and is ready for review."
                    echo "ATTENTION: Approving will apply changes to your infrastructure!"
                    echo ""
                    
                    input message: " Ready to apply Terraform changes to PRODUCTION?",
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
                expression { env.CURRENT_BRANCH == 'main' }
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
        
        stage('Development Branch Summary') {
            when {
                expression { env.CURRENT_BRANCH != 'main' }
            }
            steps {
                script {
                    echo ""
                    echo "DEVELOPMENT BRANCH EXECUTION SUMMARY"
                    echo "════════════════════════════════════════"
                    echo "Current Branch: ${env.CURRENT_BRANCH}"
                    echo "Component: ${params.component}"
                    echo ""
                    echo "COMPLETED STAGES:"
                    echo "   Branch Detection"
                    echo "   Terraform Init"
                    echo "   Terraform Plan"
                    echo "   Plan Validation"
                    echo ""
                    echo " SKIPPED STAGES:"
                    echo "   Manual Approval (${env.CURRENT_BRANCH} branch)"
                    echo "   Terraform Apply (${env.CURRENT_BRANCH} branch)"
                    echo ""
                    echo "GENERATED FILES:"
                    echo "   Plan file: ${env.TERRAFORM_DIR}/tfplan"
                    echo "   Plan summary: ${env.TERRAFORM_DIR}/tfplan.txt"
                    echo ""
                    echo "NEXT STEPS TO DEPLOY TO PRODUCTION:"
                    echo "   1. Review the generated plan output above"
                    echo "   2. Merge your changes to main branch"
                    echo "   3. Run this pipeline on main branch"
                    echo "   4. Review and approve the plan"
                    echo "   5. Infrastructure will be applied to production"
                    echo ""
                    echo "TIP: Use 'terraform show tfplan' to review detailed plan"
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
                echo "Branch: ${env.CURRENT_BRANCH ?: 'Unknown'}"
                echo "Component: ${params.component}"
                echo "Execution Time: ${new Date().format('yyyy-MM-dd HH:mm:ss')}"
                
                if (env.CURRENT_BRANCH != 'main') {
                    echo ""
                    echo "TO DEPLOY TO PRODUCTION:"
                    echo "   1. Switch to main branch: git checkout main"
                    echo "   2. Merge your changes: git merge ${env.CURRENT_BRANCH}"
                    echo "   3. Push to remote: git push origin main"
                    echo "   4. Run this pipeline from main branch"
                    echo "   5. Review and approve the deployment"
                }
                echo "════════════════════════════════════════"
            }
        }
        success {
            script {
                if (env.CURRENT_BRANCH == 'main') {
                    echo "SUCCESS: Infrastructure changes applied to production!"
                } else {
                    echo "SUCCESS: Development pipeline completed - ready for main branch deployment!"
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
        cleanup {
            echo "Pipeline cleanup completed"
        }
    }
}