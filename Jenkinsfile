
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
                git 'stage('Clone Terraform Repo') {
    steps {
        git url: 'https://github.com/prabhajayaraj/garments.git', credentialsId: 'github-token'
    }
}'
            }
        }

    }
}
