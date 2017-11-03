node ('master') {
  step([$class: 'GitHubSetCommitStatusBuilder'])
  agent { label 'ubuntu-16-04' }

  stage('Checkout') {
    checkout scm
    sh 'git submodule update --init --recursive'
  }

  stage ('Build') {
      echo "Branch: ${env.BRANCH_NAME}"
      echo "Build#: ${env.BUILD_NUMBER}"
      echo "ID: ${env.CHANGE_ID}"
      echo "Author: ${env.CHANGE_AUTHOR}"
      env.DEBUG_BUILD="true"
      sh "rm -rf build"
      sh "./build-all.sh clean"
  }

  stage ('Archive') {
    step([$class: 'ArtifactArchiver', artifacts: 'build/**', fingerprint: true])
  }
}
