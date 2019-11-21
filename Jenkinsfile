pipeline {
  agent {
    label 'maven'
  }
  stages {
    // Checkout source code
    // This is required as Pipeline code is originally checkedout to
    // Jenkins Master but this will also pull this same code to this slave
    stage('Git Checkout') {
      steps {
        // Turn off Git's SSL cert check, uncomment if needed
        // sh 'git config --global http.sslVerify false'
        git url: "https://github.com/nmalvankar/spring-rest.git", branch: "docker"
      }
    }

    // Run Maven build, skipping tests
    stage('Build'){
      steps {
        sh "mvn -B clean install -DskipTests=true -f pom.xml"
      }
    }

    // Run Maven unit tests
    stage('Unit Test'){
      steps {
        sh "mvn -B test -f pom.xml"
      }
    }

    //Build the application image

    //Push the image to Gitlab Registry

    //Import the image into OpenShift
    stage('Import Image') {
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject() {
              def result = openshift.raw("import-image spring-rest:1.0 --from=registry.gitlab.com/nmalvankar/spring-rest:1.0 --reference-policy=local --confirm")
              echo "Import Image Status: ${result.out}"
            }
          }
        }
      }
    }

    //Apply the application template

    // Deploy the image
    stage('Deploy') {
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject() {
              apply = openshift.apply(openshift.process(".openshift/templates/deployment.yml", "-p", "APPLICATION_NAME=basic-spring-boot", "-p", "NAMESPACE=dev01", "-p", "SA_NAMESPACE=dev01", "-p", "READINESS_PATH=/health", "-p", "READINESS_RESPONSE=status.:.UP"))
              dc = openshift.selector("dc", "basic-spring-boot")
              dc.rollout().latest()
              timeout(10) {
                  dc.rollout().status()
              }
            }
          }
        }
      }
    }
    // stage('Component Test') {
    //   steps {
    //     script {
    //       sh "curl -s -X POST http://cart:8080/api/cart/dummy/666/1"
    //       sh "curl -s http://cart:8080/api/cart/dummy | grep 'Dummy Product'"
    //     }
    //   }
    // }
  }
}
