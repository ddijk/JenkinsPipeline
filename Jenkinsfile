#!/usr/bin/env groovy

pipeline {
    agent any

    environment {
        pom = readMavenPom file: 'pom.xml'
        VERSION = readMavenPom().getVersion()
       ver = "${VERSION.replaceAll('-SNAPSHOT', '')}"
    }

     //tools {
        // maven 'maven_3.5.4'
      //  jdk 'jdk11'
  //  }

    stages {

         // to prevent endless loop, abort when Jenkins job is triggerd by Maven Release commits
         stage('Check for GitLab trigger on commit by Maven Release Plugin') {
            steps {
                  script {
   		   echo "java home is $JAVA_X"
   		   echo "java home LINUX is $JAVA_HOME_LINUX"
                       echo "ver is $ver"
//    		sh "./make_release.sh release-core-${ver}}"
                  }
            }
         }
         stage('Checkout other repo') {
          steps {
           checkout([$class: 'GitSCM', 
            branches: [[name: '*/master']], 
            doGenerateSubmoduleConfigurations: false, 
            extensions: [[$class: 'CleanBeforeCheckout'], 
                [$class: 'RelativeTargetDirectory', relativeTargetDir: 'targetDir']], 
            submoduleCfg: [], 
            userRemoteConfigs: [[credentialsId: 'github',
                url: 'https://github.com/ddijk/JacksonWeb']]])

            }
         }
    }
}

private boolean lastCommitIsBumpCommit() {
    lastCommit = sh([script: 'git log -1', returnStdout: true])
    return lastCommit.contains("[maven-release-plugin]")
}
