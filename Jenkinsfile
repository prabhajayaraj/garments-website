pipeline {
    agent any

    stages {

        stage('Checkout Website Repo') {
            steps {
                git branch: 'main', url: 'https://github.com/prabhajayaraj/garments-website.git'
            }
        }

        stage('Clone Terraform Repo') {
            steps {
                dir('terraform') {
                    git branch: 'main',
                    url: 'https://github.com/prabhajayaraj/garments.git',
                    credentialsId: 'github-token'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

    }
}
