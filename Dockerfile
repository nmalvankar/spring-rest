FROM registry.redhat.io/redhat-openjdk-18/openjdk18-openshift
COPY target/shift-rest-1.0.0-SNAPSHOT.jar /deployments
