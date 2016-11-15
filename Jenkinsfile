node ('master') {
  step([$class: 'GitHubSetCommitStatusBuilder'])

  stage('Checkout') {
    checkout scm
    sh 'git submodule update --init --recursive'
  }

  stage ('Build') {
      echo "Branch: ${env.BRANCH_NAME}"
      echo "Build#: ${env.BUILD_NUMBER}"
      echo "ID: ${env.CHANGE_ID}"
      echo "Author: ${env.CHANGE_AUTHOR}"
      sh "./build-all.sh"
  }

  stage ('Archive') {
    step([$class: 'ArtifactArchiver', artifacts: 'build/**', fingerprint: true])
  }
}
