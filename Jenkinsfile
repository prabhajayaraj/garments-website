pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        S3_BUCKET = 'demo-surya-01 '
    }

    stages {
        stage('Checkout Build Repo') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/prabhajayaraj/garments-website',
                    credentialsId: 'aws-credentials'
            }
        }

        stage('Build Project') {
            steps {
                sh 'chmod +x build.sh'
                sh './build.sh'
            }
        }

        // stage('Checkout Code Repo') {
        //     steps {
        //         git branch: 'main',
        //             url: 'https://github.com/prabhajayaraj/garments-website-2',
        //             credentialsId: 'aws-credentials'
        //     }
        // }

        
// New Terraform stage
        // stage('Terraform Init & Apply') {
        //     steps {
        //         withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
        //                 sh 'terraform init'
        //                 sh 'terraform apply -auto-approve'
        //         }
        //     }
        // }
        
        // stage('Build React') {
        //     steps {
        //         sh 'chmod +x build.sh'
        //         sh './build.sh'
        //     }
        // }

        // stage('Deploy to S3 & Invalidate CloudFront') {
        //     steps {
        //         withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
        //             sh 'aws s3 sync build/ s3://$S3_BUCKET --delete'
        //             sh 'aws cloudfront create-invalidation --distribution-id E38MNKXRCVLOIR --paths "/*"'
        //         }
        //     }
        // }
    }
}
