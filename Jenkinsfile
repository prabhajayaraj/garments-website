
pipeline {
    agent any

    stages {

        stage('Clone Terraform Repo') {
            steps {
                git 'https://github.com/prabhajayaraj/garments.git'
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                sh 'terraform init'
                sh 'terraform apply -auto-approve'
            }
        }

        stage('Clone Website Repo') {
            steps {
                git 'https://github.com/prabhajayaraj/garments-website-2.git'
            }
        }

    }
}
