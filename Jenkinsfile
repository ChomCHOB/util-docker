def gitUrl = 'https://github.com/ChomCHOB/util-docker'
def gitBranch = 'refs/heads/master'

def label = "pod.${env.JOB_NAME}".replace('-', '_').replace('/', '_').take(55) + ".${env.BUILD_NUMBER}"

node('master') {
  stage('build docker image') {
    def buildParameters = [
      string(name: 'GIT_URL', value: gitUrl), 
      string(name: 'GIT_BRANCH', value: gitBranch), 

      booleanParam(name: 'BUILD_DOCKER_IMAGE', value: true),
      booleanParam(name: 'PUBLISH_TO_DOCKER_HUB', value: true),
      booleanParam(name: 'PUBLISH_LATEST', value: true),
    ]

    // build
    build(
      job: '../../deploy-pipeline', 
      parameters: buildParameters
    )
  }
}