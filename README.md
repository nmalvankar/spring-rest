# Spring Rest - A RESTful API written in Spring Boot

This is a simple app using Spring Boot as part of [Red Hat OpenShift Application Runtimes](https://middlewareblog.redhat.com/2017/05/05/red-hat-openshift-application-runtimes-and-spring-boot-details-you-want-to-know/).

## Usage to Run Locally

1. `git clone`
2. `mvn spring-boot:run`

## OpenAPI (formerly known as Swagger) Support

The app uses [Spring Fox](http://springfox.github.io/springfox/) to generate an [OpenAPI spec](https://www.openapis.org/). You can view the spec at /swagger.json or [Swagger UI](https://swagger.io/swagger-ui/) at /swagger-ui.html. 

## Added Plugins for Quality and Security

1. SonarQube Scanner Plugin. *NOTE: This plugin is a client and needs to connect to a running sonar server.*
	- Usage:
	  - `mvn sonar:sonar` to execute. 
	  - Plugin is currently not tied to the standard maven lifecyle.
	- To help execute the scan in Jenkins pipelines, the `sonarqubeStaticAnalysis()` function from the [pipeline-library](https://github.com/redhat-cop/pipeline-library) will execute the goal in your build process.
	- [SonarQube plugin docs](https://docs.sonarqube.org/display/SCAN/Analyzing+with+SonarQube+Scanner+for+Maven)

2. Jacoco Maven Plugin
	- Usage:
		- `mvn package` to execute in standard maven lifecycle
		- `mvn jacoco:report` to execute the plugin standalone
	- Code coverage reports will then be found in `target/site`.
	- [Jacoco plugin docs](https://www.eclemma.org/jacoco/trunk/doc/maven.html)

3. OWASP Dependency Check
	- Usage:
	  - `mvn verify` to execute in standard maven lifecycle
	  - `mvn dependency-check:check` to execute the plugin standalone
	- The dependency-check plugin will check dependencies for vulnerabilities against the National Vulnerability Database hosted by NIST and fail should there be any dependency with a [CVSS score](https://searchsecurity.techtarget.com/definition/CVSS-Common-Vulnerability-Scoring-System) greater or equal to that specified in the pom file.
	- [Maven plugin docs](https://jeremylong.github.io/DependencyCheck/dependency-check-maven/)
	- [OWASP Dependency Check docs](https://www.owasp.org/index.php/OWASP_Dependency_Check)
	- [Continuous security and OWASP Dependency Check blog](https://blog.lanyonm.org/articles/2015/12/22/continuous-security-owasp-java-vulnerability-check.html)

# A Sample OpenShift Pipeline for a Spring Boot Application

This example demonstrates how to implement a full end-to-end Jenkins Pipeline for a Java application in OpenShift Container Platform. This sample demonstrates the following capabilities:

* Deploying an integrated Jenkins server inside of OpenShift
* Running both custom and oob Jenkins slaves as pods in OpenShift
* "One Click" instantiation of a Jenkins Pipeline using OpenShift's Jenkins Pipeline Strategy feature
* Building a Jenkins pipeline with library functions from our [pipeline-library](https://github.com/redhat-cop/pipeline-library)
* Automated rollout using the [openshift-appler](https://github.com/redhat-cop/openshift-applier) project.

## Automated Deployment

This quickstart can be deployed quickly using Ansible. Here are the steps.

1. Clone [this repo](https://github.com/redhat-cop/container-pipelines)
2. `cd container-pipelines/basic-spring-boot`
3. Run `ansible-galaxy install -r requirements.yml --roles-path=galaxy`
2. Log into an OpenShift cluster, then run the following command.
```
$ ansible-playbook -i ./.applier/ galaxy/openshift-applier/playbooks/openshift-cluster-seed.yml
```

At this point you should have 4 projects created (`basic-spring-boot-build`, `basic-spring-boot-dev`, `basic-spring-boot-stage`, and `basic-spring-boot-prod`) with a pipeline in the `-build` project, and our [Spring Rest](https://github.com/redhat-cop/spring-rest) demo app deployed to the dev/stage/prod projects.


## Running this on OpenShift 3.11

`oc process -f .openshift/templates/deployment.yml -p=APPLICATION_NAME=basic-spring-boot -p NAMESPACE=basic-spring-boot-dev -p=SA_NAMESPACE=basic-spring-boot-build -p=READINESS_PATH="/health" -p=READINESS_RESPONSE="status.:.UP"  | oc apply -f-`

`oc process -f .openshift/templates/deployment.yml -p=APPLICATION_NAME=basic-spring-boot -p NAMESPACE=basic-spring-boot-stage -p=SA_NAMESPACE=basic-spring-boot-build -p=READINESS_PATH="/health" -p=READINESS_RESPONSE="status.:.UP" | oc apply -f-`

`oc process -f .openshift/templates/deployment.yml -p=APPLICATION_NAME=basic-spring-boot -p NAMESPACE=basic-spring-boot-prod -p=SA_NAMESPACE=basic-spring-boot-build -p=READINESS_PATH="/health" -p=READINESS_RESPONSE="status.:.UP" | oc apply -f-`

`oc process -f .openshift/templates/build.yml -p=APPLICATION_NAME=basic-spring-boot -p NAMESPACE=basic-spring-boot-build -p=SOURCE_REPOSITORY_URL="https://github.com/nmalvankar/spring-rest.git" -p=APPLICATION_SOURCE_REPO="https://github.com/nmalvankar/spring-rest.git" | oc apply -f-`

## Architecture

The following breaks down the architecture of the pipeline deployed, as well as walks through the manual deployment steps

### OpenShift Templates

The components of this pipeline are divided into two templates.

The first template, `.openshift/templates/build.yml` is what we are calling the "Build" template. It contains:

* A `jenkinsPipelineStrategy` BuildConfig
* An `s2i` BuildConfig
* An ImageStream for the s2i build config to push to

The build template contains a default source code repo for a java application compatible with this pipelines architecture (https://github.com/redhat-cop/spring-rest).

The second template, `.openshift/templates/deployment.yml` is the "Deploy" template. It contains:

* A tomcat8 DeploymentConfig
* A Service definition
* A Route

The idea behind the split between the templates is that I can deploy the build template only once (to my build project) and that the pipeline will promote my image through all of the various stages of my application's lifecycle. The deployment template gets deployed once to each of the stages of the application lifecycle (once per OpenShift project).

### Pipeline Script

This project includes a sample `Jenkinsfile` pipeline script that could be included with a Java project in order to implement a basic CI/CD pipeline for that project, under the following assumptions:

* The project is built with Maven
* The OpenShift projects that represent the Application's lifecycle stages are of the naming format: `<app-name>-dev`, `<app-name>-stage`, `<app-name>-prod`.

This pipeline defaults to use our [Spring Boot Demo App](https://github.com/redhat-cop/spring-rest).

## Bill of Materials

* One or Two OpenShift Container Platform Clusters
  * OpenShift 3.5+ is required
  * [Red Hat OpenJDK 1.8](https://access.redhat.com/containers/?tab=overview#/registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift) image is required
* Access to GitHub

## Manual Deployment Instructions

### 1. Create Lifecycle Stages

For the purposes of this demo, we are going to create three stages for our application to be promoted through.

- `basic-spring-boot-build`
- `basic-spring-boot-dev`
- `basic-spring-boot-stage`
- `basic-spring-boot-prod`

In the spirit of _Infrastructure as Code_ we have a YAML file that defines the `ProjectRequests` for us. This is as an alternative to running `oc new-project`, but will yeild the same result.

```
$ oc create -f .openshift/projects/projects.yml
projectrequest "basic-spring-boot-build" created
projectrequest "basic-spring-boot-dev" created
projectrequest "basic-spring-boot-stage" created
projectrequest "basic-spring-boot-prod" created
```

### 2. Stand up Jenkins master in dev

For this step, the OpenShift default template set provides exactly what we need to get jenkins up and running.

```
$ oc process openshift//jenkins-ephemeral | oc apply -f- -n basic-spring-boot-build
route "jenkins" created
deploymentconfig "jenkins" created
serviceaccount "jenkins" created
rolebinding "jenkins_edit" created
service "jenkins-jnlp" created
service "jenkins" created
```

### 4. Instantiate Pipeline

A _deploy template_ is provided at `.openshift/templates/deployment.yml` that defines all of the resources required to run our Tomcat application. It includes:

* A `Service`
* A `Route`
* An `ImageStream`
* A `DeploymentConfig`
* A `RoleBinding` to allow Jenkins to deploy in each namespace.

This template should be instantiated once in each of the namespaces that our app will be deployed to. For this purpose, we have created a param file to be fed to `oc process` to customize the template for each environment.

Deploy the deployment template to all three projects.
```
$ oc process -f .openshift/templates/deployment.yml -p=APPLICATION_NAME=basic-spring-boot -p NAMESPACE=basic-spring-boot-dev -p=SA_NAMESPACE=basic-spring-boot-build -p=READINESS_PATH="/health" -p=READINESS_RESPONSE="status.:.UP"  | oc apply -f-
service "spring-rest" created
route "spring-rest" created
imagestream "spring-rest" created
deploymentconfig "spring-rest" created
rolebinding "jenkins_edit" configured
$ oc process -f .openshift/templates/deployment.yml -p=APPLICATION_NAME=basic-spring-boot -p NAMESPACE=basic-spring-boot-stage -p=SA_NAMESPACE=basic-spring-boot-build -p=READINESS_PATH="/health" -p=READINESS_RESPONSE="status.:.UP" | oc apply -f-
service "spring-rest" created
route "spring-rest" created
imagestream "spring-rest" created
deploymentconfig "spring-rest" created
rolebinding "jenkins_edit" created
$ oc process -f .openshift/templates/deployment.yml -p=APPLICATION_NAME=basic-spring-boot -p NAMESPACE=basic-spring-boot-prod -p=SA_NAMESPACE=basic-spring-boot-build -p=READINESS_PATH="/health" -p=READINESS_RESPONSE="status.:.UP" | oc apply -f-
service "spring-rest" created
route "spring-rest" created
imagestream "spring-rest" created
deploymentconfig "spring-rest" created
rolebinding "jenkins_edit" created
```

A _build template_ is provided at `applier/templates/build.yml` that defines all the resources required to build our java app. It includes:

* A `BuildConfig` that defines a `JenkinsPipelineStrategy` build, which will be used to define out pipeline.
* A `BuildConfig` that defines a `Source` build with `Binary` input. This will build our image.

Deploy the pipeline template in build only.
```
$ oc process -f .openshift/templates/build.yml -p=APPLICATION_NAME=basic-spring-boot -p NAMESPACE=basic-spring-boot-build -p=SOURCE_REPOSITORY_URL="https://github.com/nmalvankar/spring-rest.git" -p=APPLICATION_SOURCE_REPO="https://github.com/nmalvankar/spring-rest.git" | oc apply -f-
buildconfig "spring-rest-pipeline" created
buildconfig "spring-rest" created
```

At this point you should be able to go to the Web Console and follow the pipeline by clicking in your `basic-spring-boot-build` project, and going to *Builds* -> *Pipelines*. At several points you will be prompted for input on the pipeline. You can interact with it by clicking on the _input required_ link, which takes you to Jenkins, where you can click the *Proceed* button. By the time you get through the end of the pipeline you should be able to visit the Route for your app deployed to the `myapp-prod` project to confirm that your image has been promoted through all stages.

## Cleanup

Cleaning up this example is as simple as deleting the projects we created at the beginning.

```
oc delete project basic-spring-boot-build basic-spring-boot-dev basic-spring-boot-prod basic-spring-boot-stage
```

