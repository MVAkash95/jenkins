pipeline {
    agent any
    parameters {
        choice(name: 'targetBranch', choices: ['main', 'dev'], description: 'Select branch to run pipeline from')
        // string(name: 'component', defaultValue: 'ec2', description: 'Terraform module to deploy (e.g., ec2, vpc)')
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan? (Only works on main branch)')
    }
    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION    = 'us-east-1'
        // TERRAFORM_DIR         = "terraform/module/${params.component.toLowerCase()}"
        // TERRAFORM_DIR         = "terraform/${params.component.toLowerCase()}"
        TERRAFORM_DIR         = "terraform/"
    }
    
    stages {
        stage('Checkout Selected Branch') {
            steps {
                script {
                    echo " CHECKING OUT SELECTED BRANCH: ${params.targetBranch}"
                    echo "════════════════════════════════════════"
                }
                
                // Checkout the selected branch
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${params.targetBranch}"]],
                    userRemoteConfigs: [[
                        url: 'https://github.com/MVAkash95/jenkins',
                        credentialsId: 'bdbc5114-b2d0-4244-ac0d-93cff1db0538'
                    ]]
                ])
                
                script {
                    // Verify which branch we're on
                    def actualBranch = sh(returnStdout: true, script: 'git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"').trim()
                    env.CURRENT_BRANCH = actualBranch
                    
                    echo "Successfully checked out branch: ${env.CURRENT_BRANCH}"
                    echo " Target branch parameter: ${params.targetBranch}"
                    
                    if (env.CURRENT_BRANCH != params.targetBranch && env.CURRENT_BRANCH != "HEAD") {
                        echo "  Warning: Checked out branch (${env.CURRENT_BRANCH}) differs from target (${params.targetBranch})"
                    }
                }
            }
        }
        
        stage('Branch & Parameter Validation') {
            steps {
                script {
                    echo ""
                    echo " PIPELINE CONFIGURATION:"
                    echo "Selected Branch: ${params.targetBranch}"
                    echo "Actual Branch: ${env.CURRENT_BRANCH}"
                    // echo " Component: ${params.component}"
                    echo "Auto Approve: ${params.autoApprove}"
                    echo "Terraform Directory: ${env.TERRAFORM_DIR}"
                    echo ""
                    
                    // Show execution plan based on selected branch
                    if (params.targetBranch == 'main') {
                        echo "MAIN BRANCH EXECUTION PLAN:"
                        echo "    Terraform Init & Plan"
                        if (params.autoApprove) {
                            echo "     Manual Approval (skipped - autoApprove=true)"
                        } else {
                            echo "    Manual Approval (manual approval required)"
                        }
                        echo "    Terraform Apply ( PRODUCTION CHANGES )"
                        echo ""
                        echo " WARNING: This will modify your production infrastructure!"
                    } else if (params.targetBranch == 'dev') {
                        echo " DEVELOPMENT BRANCH EXECUTION PLAN:"
                        echo "   Terraform Init & Plan"  
                        echo "   Manual Approval (skipped - dev branch)"
                        echo "   Terraform Apply (skipped - dev branch)"
                        echo "   Summary Report"
                        echo ""
                        echo "💡 Note: This will only validate your infrastructure changes."
                    }
                    
                    // Warning for autoApprove on non-main branches
                    if (params.autoApprove && params.targetBranch != 'main') {
                        echo ""
                        echo "WARNING: autoApprove=true is set, but terraform apply only runs on main branch."
                        echo "    Selected branch '${params.targetBranch}' will only execute init and plan stages."
                    }
                    
                    echo "════════════════════════════════════════"
                }
            }
        }
        
        stage('Terraform Init & Plan') {
            steps {
                script {
                    // Check if we're using new structure (dev branch) or old structure (main branch)
                    // def newStructureDir = "terraform/module/${params.component.toLowerCase()}"
                    // def oldStructureDir = "terraform/${params.component.toUpperCase()}"
                    def terraformRootDir = "terraform"
                    env.TERRAFORM_DIR = terraformRootDir
                    env.VAR_FILE_PATH = "${terraformRootDir}/terraform.tfvars"

                    
                    def useNewStructure = sh(returnStatus: true, script: "test -d ${newStructureDir}") == 0
                    def useOldStructure = sh(returnStatus: true, script: "test -d ${oldStructureDir}") == 0
                    
                    if (useNewStructure) {
                        env.TERRAFORM_DIR = newStructureDir
                        env.VAR_FILE_PATH = "../../terraform.tfvars"
                        echo "Using NEW directory structure: ${env.TERRAFORM_DIR}"
                    } else if (useOldStructure) {
                        env.TERRAFORM_DIR = oldStructureDir  
                        env.VAR_FILE_PATH = "../terraform.tfvars"
                        echo "Using OLD directory structure: ${env.TERRAFORM_DIR}"
                    } else {
                        echo "❌ Neither directory structure found:"
                        echo "   - New structure: ${newStructureDir}"
                        echo "   - Old structure: ${oldStructureDir}"
                        echo ""
                        echo "Available directories:"
                        sh 'find terraform -type d -name "*" | head -10 || echo "No terraform directories found"'
                        // error("Terraform directory not found for component '${params.component}'")
                    }
                    
                    // Check if .tf files exist
                    def tfFilesExist = sh(returnStatus: true, script: "find ${env.TERRAFORM_DIR} -name '*.tf' | head -1") == 0
                    if (!tfFilesExist) {
                        echo "No .tf files found in '${env.TERRAFORM_DIR}'"
                        sh "ls -la ${env.TERRAFORM_DIR}/ || echo 'Directory listing failed'"
                        error("No Terraform configuration files (.tf) found in '${env.TERRAFORM_DIR}'.")
                    }
                    
                    echo "Terraform directory and files validated"
                }
                
                dir("${env.TERRAFORM_DIR}") {
                    echo "Initializing Terraform..."
                    sh 'terraform init'
                    
                    echo "Generating Terraform plan..."
                    script {
                        def varsFileExists = sh(returnStatus: true, script: "test -f ${env.VAR_FILE_PATH}") == 0
                        if (varsFileExists) {
                            echo "Using variables file: ${env.VAR_FILE_PATH}"
                            sh "terraform plan -var-file=${env.VAR_FILE_PATH} -out=tfplan"
                        } else {
                            echo "Variables file not found: ${env.VAR_FILE_PATH}"
                            echo "Running plan without variables file"
                            sh 'terraform plan -out=tfplan'
                        }
                    }
                    sh 'terraform show -no-color tfplan > tfplan.txt'
                    
                    echo "Terraform plan generated successfully"
                }
            }
        }
        
        stage('Manual Approval') {
            when {
                allOf {
                    expression { params.targetBranch == 'main' }
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
                expression { params.targetBranch == 'main' }
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
                expression { params.targetBranch != 'main' }
            }
            steps {
                script {
                    echo ""
                    echo "DEVELOPMENT BRANCH EXECUTION SUMMARY"
                    echo "════════════════════════════════════════"
                    echo "Selected Branch: ${params.targetBranch}"
                    // echo "Component: ${params.component}"
                    echo "Directory Structure: ${env.TERRAFORM_DIR}"
                    echo ""
                    echo "COMPLETED STAGES:"
                    echo "   Branch Checkout"
                    echo "   Terraform Init"
                    echo "   Terraform Plan"
                    echo "   Plan Validation"
                    echo ""
                    echo "SKIPPED STAGES:"
                    echo "   Manual Approval (${params.targetBranch} branch)"
                    echo "   Terraform Apply (${params.targetBranch} branch)"
                    echo ""
                    echo "GENERATED FILES:"
                    echo "   Plan file: ${env.TERRAFORM_DIR}/tfplan"
                    echo "   Plan summary: ${env.TERRAFORM_DIR}/tfplan.txt"
                    echo ""
                    echo " NEXT STEPS TO DEPLOY TO PRODUCTION:"
                    echo "   1. Review the generated plan output above"
                    echo "   2. If satisfied with dev branch testing, merge to main"
                    echo "   3. Run pipeline again with 'main' branch selected"
                    echo "   4. Review and approve the production deployment"
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
                echo "Selected Branch: ${params.targetBranch}"
                // echo "Component: ${params.component}"
                echo "Directory: ${env.TERRAFORM_DIR ?: 'Not determined'}"
                echo "Execution Time: ${new Date().format('yyyy-MM-dd HH:mm:ss')}"
                
                if (params.targetBranch != 'main') {
                    echo ""
                    echo " TO DEPLOY TO PRODUCTION:"
                    echo "   1. Select 'main' as target branch in next run"
                    echo "   2. Review and approve the deployment plan"  
                    echo "   3. Infrastructure changes will be applied"
                } else {
                    echo ""
                    echo "PRODUCTION DEPLOYMENT COMPLETED"
                }
                echo "════════════════════════════════════════"
            }
        }
        success {
            script {
                if (params.targetBranch == 'main') {
                    echo "SUCCESS: Infrastructure changes applied to production!"
                } else {
                    echo "SUCCESS: Development branch validation completed!"
                }
            }
        }
        failure {
            script {
                echo "FAILURE: Pipeline execution failed on branch '${params.targetBranch}'"
                echo "Check the logs above for error details"
                echo "Contact your DevOps team if you need assistance"
            }
        }
    }
}