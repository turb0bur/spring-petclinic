# Spring PetClinic Sample Application [![Build Status](https://github.com/spring-projects/spring-petclinic/actions/workflows/maven-build.yml/badge.svg)](https://github.com/spring-projects/spring-petclinic/actions/workflows/maven-build.yml)

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/spring-projects/spring-petclinic) [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=7517918)

## Understanding the Spring Petclinic application with a few diagrams

[See the presentation here](https://speakerdeck.com/michaelisvy/spring-petclinic-sample-application)

## Run Petclinic locally via Docker Compose

Spring Petclinic is a [Spring Boot](https://spring.io/guides/gs/spring-boot) application built
using [Maven](https://spring.io/guides/gs/maven/) or [Gradle](https://spring.io/guides/gs/gradle/). You can build a jar
file and run it from the command line (it should work just as well with Java 17 or newer):

### Clone the repository:

```bash
git clone https://github.com/spring-projects/spring-petclinic.git
cd spring-petclinic
```

### Start the application:

```bash
docker-compose up --build
```

### Access the application:

Visit [http://localhost:8081](http://localhost:8081) in your browser.

<img width="1042" alt="petclinic-screenshot" src="https://cloud.githubusercontent.com/assets/838318/19727082/2aee6d6c-9b8e-11e6-81fe-e889a5ddfded.png">

## Running on AWS via Jenkins

To deploy the Spring PetClinic application on AWS using Jenkins, follow these steps:

### Set up Jenkins:

    - Install Jenkins on your server or use Jenkins as a Service.
    - Install necessary plugins: Git, AWS CLI, Docker.

### Create Jenkins Pipeline:

    - Create a new pipeline in Jenkins using provided Jenkinsfile.

## Running on Minikube via Kubernetes Manifests

To run the Spring PetClinic application on Minikube using a Helm chart, follow these steps:

### Start Minikube:

```bash
minikube start
```

### Deploy the Helm chart

Navigate to the directory containing your Helm chart and install it:

```bash
cd helm
helm install petclinic .
```

### Create Docker Registry Secret

Before deploying the application, you need to create a Kubernetes secret for accessing your ECR (Elastic Container
Registry). This secret will store your Docker credentials, allowing Kubernetes to pull the Docker image from ECR.

```bash
export AWS_ACCESS_KEY_ID=<your-access-key>
export AWS_SECRET_ACCESS_KEY=<your-secret-key>
kubectl -n petclinic create secret docker-registry ecr-secret \
	--docker-server 278336501300.dkr.ecr.eu-central-1.amazonaws.com \
	--docker-username=AWS \
	--docker-password=$(aws ecr get-login-password)
```

### Access the application:

```bash
minikube service -n petclinic petclinic-service
```

Access the application at provided by Minikube IP and port.
