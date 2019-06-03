#!/usr/bin/env groovy

pipeline {
    agent any

    environment {
        swaggerImageName = "explorer-java-swagger"
        coreImageName = "explorer-core"
        nexusCredentialsId = 'jenkins-nexus'
        pom = readMavenPom file: 'pom.xml'
        VERSION = readMavenPom().getVersion()
    }

    tools {
        maven 'maven_3.5.4'
        jdk 'jdk11'
    }

    stages {
         // to prevent endless loop, abort when Jenkins job is triggerd by Maven Release commits
         stage('Check for GitLab trigger on commit by Maven Release Plugin') {
                 when {
                        branch "develop"
                 }
                 steps {
                     script {
                         checkout scm
                         if (lastCommitIsBumpCommit()) {
                             currentBuild.result = 'ABORTED'
                             error('Last commit bumped the version, aborting the build to prevent a loop.')
                         } else {
                             echo('Last commit is not a bump commit, job continues as normal.')
                         }
                     }
                 }
            }
         stage('Build, Test & SonarQube Scan') {
                         steps {
                              echo 'expected branch = ' + env.BRANCH_NAME
                              withSonarQubeEnv('StuComm SonarQube Server') {
                                sh 'mvn clean test sonar:sonar -P sonar -Dsonar.branch=' + env.BRANCH_NAME
                               }
                         }
         }

         stage("Quality Gate") {
                         steps {
                            timeout(time: 1, unit: 'HOURS') { // Just in case something goes wrong, pipeline will be killed after a timeout
                              script {
                              def qg = waitForQualityGate() // Reuse taskId previously collected by withSonarQubeEnv
                              if (qg.status != 'OK') {
                                error "Pipeline aborted due to quality gate failure: ${qg.status}"
                              }
                              }
                            }
                         }
         }
        stage('Package & upload to Nexus') {
            when {
                branch "develop"
            }
            steps {
                echo 'deploying ' + env.BRANCH_NAME
                sh 'mvn release:prepare release:perform -Dmaven.test.skip=true'
            }
        }
        stage('Upload Docker images') {
            when {
                branch "develop"
            }
            steps {

                //save version
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    version = pom.version
                }

                echo 'pushing Docker images for Core and Swagger for:' + env.BRANCH_NAME

                //throw it in a docker container and upload it.
                script {

                    sh 'jlink --output custom_jre --add-modules java.instrument,java.security.jgss,java.compiler,java.desktop,java.logging,java.rmi,java.security.sasl,java.xml,java.sql,java.naming,java.management,jdk.management.agent,jdk.httpserver'

                    docker.withRegistry('https://nexus.stucomm.com/', nexusCredentialsId) {
                        def swaggerImage = docker.build( "nexus.stucomm.com/" + swaggerImageName , "--no-cache ./docker/swagger")
                        swaggerImage.push() //update :latest tag
                        swaggerImage.push(version)

                        // core
                        def coreImage = docker.build( "nexus.stucomm.com/" + coreImageName , "--no-cache .")
                        coreImage.push() //update :latest tag
                        coreImage.push(version)
                    }
                }

            }
        }
        stage('Deploy application and API docs on Test server') {
            when {
                branch "develop"
            }
            steps {
                sshPublisher(publishers: [sshPublisherDesc(configName: 'Explorer Java', transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand: '', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '', remoteDirectorySDF: false, removePrefix: 'docker', sourceFiles: 'docker/docker-compose.yml')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
                sshPublisher(publishers: [sshPublisherDesc(configName: 'Explorer Java', transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand: '', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '', remoteDirectorySDF: false, removePrefix: 'scripts', sourceFiles: 'scripts/update.sh')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
                sshPublisher(publishers: [sshPublisherDesc(configName: 'Explorer Java', transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand: 'sh update.sh', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '', remoteDirectorySDF: false, removePrefix: 'scripts', sourceFiles: 'scripts/update.sh')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
            }
        }
        stage('Run Integration Tests') {
            when {
                branch "develop"
            }
            steps {
                echo 'Running Integration Tests, branch: ' + env.BRANCH_NAME
                sh 'mvn -Dserver.host=http://explorer-java.stucomm.com -Dserver.port=80 verify'
            }
        }
        stage('Build and upload to Nexus') {
            when {
                branch "master"
            }
            steps {
                sh 'mvn -DskipTests package'
                // release will be packaged in zipfile, e.g. release-x.y.zip
                echo "Creating Release release-core-${VERSION.replaceAll('-SNAPSHOT', '')}"
                sh "./make_release.sh release-core-${VERSION.replaceAll('-SNAPSHOT', '')}"
                echo "About to upload Release version of Explorer Core: ${VERSION.replaceAll('-SNAPSHOT', '')}"
                echo 'Deploying release of Explorer Core to Nexus'
                echo "mvn deploy:deploy-file -Dfile=release-core-${VERSION.replaceAll('-SNAPSHOT', '')}.zip -DrepositoryId=nexus-releases -Durl=https://nexus.stucomm.com/repository/stucomm-explorer/ -DgroupId=com.stucomm.explorer.core -DartifactId=core-release -Dversion=${VERSION.replaceAll('-SNAPSHOT', '')}"
                sh "mvn deploy:deploy-file -Dfile=release-core-${VERSION.replaceAll('-SNAPSHOT', '')}.zip -DrepositoryId=nexus-releases -Durl=https://nexus.stucomm.com/repository/stucomm-explorer/ -DgroupId=com.stucomm.explorer.core -DartifactId=core-release -Dversion=${VERSION.replaceAll('-SNAPSHOT', '')}"
            }
        }
    }
}

private boolean lastCommitIsBumpCommit() {
    lastCommit = sh([script: 'git log -1', returnStdout: true])
    return lastCommit.contains("[maven-release-plugin]")
}
