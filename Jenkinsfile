pipeline {
    agent any

    stages {

        stage('Checkout Jenkins Repo') {
            steps {
                git branch: 'main', url: 'https://github.com/prabhajayaraj/garments-website.git'
            }
        }

        stage('Clone Terraform Repo') {
            steps {
                git branch: 'main', url: 'https://github.com/prabhajayaraj/garments.git', credentialsId: 'github-token'
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve'
            }
        }

    }
}
