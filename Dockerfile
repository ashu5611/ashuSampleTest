FROM openjdk:17-oracle
RUN groupadd ashu && useradd  asgup3 -g ashu
USER ashu:asgup3
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","/app.jar"]